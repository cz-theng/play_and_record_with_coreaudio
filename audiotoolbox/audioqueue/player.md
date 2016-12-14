# 使用AudioQueueNewOutput播放音频

在前面"AVFoundation"的章节中，我们看到了怎样用AVAudioReader进行文件内容的播放，过程非常简单，但是对于流数据却无法支持。这时候我们就该考虑用“Audio Queue Services”了。

使用“Audio Queue Services”进行音频播放的过程，可以分为如下几步。

1. 定义一个自定义的数据结构来维护当前的状态、音频数据格式以及文件路径等信息。
2. 打开一个文件或者数据流并解析文件格式
3. 确定要用的AudioQueueBufferRef的Buffer的大小并为每个Packet分配AudioStreamPacketDescription空间。
2. 实现AudioQueueOutputCallback回调函数，用来提供音频数据。


5. 创建一个Audio Queue用于播放音频使用
6. 分配并将buffer内容enqueue到上面的队列中，准备播放和停止操作
7. 最后释放Queue对象以及其他资源。

## 播放器状态
“Audio Queue Services”虽然也是提供的一套相对高级好用的接口，但是其是C/C++接口，一些状态需要我们自己定义数据结构来进行维护。那么要维护哪些中间状态呢？

主要是根据后面需要的要求来组织，这里我们提供一个参考，也是文中Demo配套的结构：

	enum {
	    kNumberBuffers = 3, // buffer的数目
	    kNumberPackages = 10*1000,  // 一次读取的package数目
	};
	
	struct PlayerStat
	{
	    AudioStreamBasicDescription   mDataFormat;  // 源数据的格式信息
	    AudioQueueRef                 mQueue;  // Queue对象
	    AudioQueueBufferRef           mBuffers[kNumberBuffers]; // Buffer数组，用来装数据
	    AudioFileID                   mAudioFile; // 文件ID
	    UInt32                        bufferByteSize; // 单个Buffer长度
	    SInt64                        mCurrentPacket; // 当前读到哪个packet了
	    AudioStreamPacketDescription  *mPacketDescs; // 每个Packet的描述
	};
每个变量的意义在注释中已经标出，可能现在还是不太理解，后面的文章的介绍中会一一用上。

## 获取数据源格式
“Audio Queue Services”播放音频时，其操作的对象是（void *）的音频数据，所以既可以对AudioFileService/ExtAudioFileService读取的文件中的数据进行播放，也可以对AduioStreamService获得的流数据进行播放。不论哪种播放，都需要先获得要播放数据的基本格式，比如通道数、采样率等。这里我们以AudioFileService读取文件为例：

    // step 1: open a file
    
    CFURLRef url = (__bridge CFURLRef) _musicURL;
    if (nil == url) {
        url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"]];
    }
    OSStatus stts = AudioFileOpenURL(url, kAudioFileReadPermission, 0, &playerStat_.mAudioFile);
    VStatusBOOL(stts, @"AudioFileOpenURL");
    NSLog(@"open file %@ success!", url);
    
    // step 2: read file's properity
    UInt32 descSize = sizeof(playerStat_.mDataFormat);

    stts =  AudioFileGetProperty(playerStat_.mAudioFile, kAudioFilePropertyDataFormat, &descSize, &playerStat_.mDataFormat);
    VStatusBOOL(stts, @"AudioFileGetProperty-kAudioFilePropertyDataFormat");
    
首先打开文件并读取kAudioFilePropertyDataFormat属性，同样的对于流数据可以在回调中取得AudioStreamBasicDescription表示的数据格式。    

## 内存管理
根据前面文章中介绍的AudioQueue基本结构，可以将其看成一个包含三类Buffer的内存队列，其中一个已经处理了，一个正在处理，还有一个有待处理。所以上面我们将Buffer的数组设置成3个，表示三类Buffer。每次处理一个Buffer，而处理的单位是一个个的数据包Packet，所以我们要确定每个Buffer的长度，以及每个包的描述。

这里我们用了一个简单的方法：设定每次处理kNumberPackages（一个自定义常量）个固定的Packet，不管CBR或者VBR以最大的包大小来分配空间：

	  // step 4: allocat memeory for pacakge's dscription
    UInt32 maxPacketSize;
    UInt32 propertySize = sizeof (maxPacketSize);
    stts =  AudioFileGetProperty(playerStat_.mAudioFile, kAudioFilePropertyPacketSizeUpperBound, &propertySize, &maxPacketSize);
    VStatusBOOL(stts, @"AudioFileGetProperty-kAudioFilePropertyDataFormat");
    playerStat_.bufferByteSize = kNumberPackages * maxPacketSize;
    playerStat_.mPacketDescs =(AudioStreamPacketDescription *) malloc(kNumberPackages * sizeof(AudioStreamPacketDescription));
    
这样就分配好AudioStreamPacketDescription的空间了，而Buffer的空间由Queue来帮我们分配，等到后面Queue创建了再创建，而这里的bufferByteSize保存下来，在处理的回调中使用。

在有了Queue对象后，通过调用：

	AudioQueueAllocateBuffer (playerStat_.mQueue, playerStat_.bufferByteSize, &playerStat_.mBuffers[i]);
创建Buffer对象并保存在	 mBuffers 数组中。其释放在调用Queue的Dispose的时候会自动进行释放。   

## 控制一切的回调
在获得了源数据的基本格式后，最重要的步骤来了。“Audio Queue Services”本质就是从Buffer队列中取数据进行播放，播放是其提供的服务，而我们要做的就是往这个队列中送入数据。当AudioQueue播放数据过程中需要数据时，就会回调一个预定义的函数，在函数的实现中，我们填入数据：

	typedef void (*AudioQueueOutputCallback)(
                                    void * __nullable       inUserData,
                                    AudioQueueRef           inAQ,
                                    AudioQueueBufferRef     inBuffer);
函数原型很简单。第一个可以认为是self。就是我们上面定义的那个数据结构。会透传过来。inAQ是我们要操作的Queue对象。而inBuffer 就是要操作的Buffer了。                                

首先我们需要获得要播放的数据，这里我们以从文件中读取为例：

	  // step1: read data from your file
    UInt32 bufLen = playerStat->bufferByteSize;
    UInt32 numPkgs = kNumberPackages;
    OSStatus stts = AudioFileReadPacketData(playerStat->mAudioFile, NO, &bufLen, playerStat->mPacketDescs, playerStat->mCurrentPacket, &numPkgs, inBuffer->mAudioData);
    VStatus(stts, @"AudioFileReadPacketData");
    inBuffer->mAudioDataByteSize = bufLen;
    
从文件中读取一段数据到Buffer中，因为读取过程中操作的是void *的内存，所以我们还需要手动的为  AudioQueueBufferRef的大小进行赋值`inBuffer->mAudioDataByteSize = bufLen;`  。

填好数据了，就可以将其放入队列中了：
    
    // step2: enqueue data buffer to AudioQueueBufferRef
    stts = AudioQueueEnqueueBuffer(playerStat->mQueue, inBuffer, numPkgs, playerStat->mPacketDescs);
    VStatus(stts, @"AudioQueueEnqueueBuffer");
    playerStat->mCurrentPacket  += numPkgs;
这里调用AudioQueueEnqueueBuffer将其如队列，这里的操作对象是每个数据包Packet，数目也是以包为单位的。同时要给的还有每个Packet的描述。    

因为我们要顺序的进行文件内容的播放，所以这里记录了已经处理的Packet数目，用于下一次读取。

正常情况下，这样就完成了。但是这里如果读到了EOF了要怎么处理呢？一般就是进行停止动作，所以Demo中加了：

	  // step3: decid wheather should stop the AduioQueue
    if (0 == numPkgs) {
        AudioQueueStop(playerStat->mQueue, false);
    }
表示EOF时进行停止。

## Queue对象

“Audio Queue Services”的主体是"AudioQueueRef"表示的 Queue对象。不论是录制还是播放都是用的这个数据结构，但是创建函数不一样。由于“Audio Queue Services”提供的是一套C的接口，没有重载，所以根据函数名来创建不同类型的Queue，比如这里我们要用`AudioQueueNewOutput `来创建一个用于播放的Queue。

创建Queue的时候，我们需要提供:

* 一个要播放的音频数据的格式描述：AudioStreamBasicDescription
* 一个播放完buffer内容的回调函数:AudioQueueOutputCallback
* 当前播放使用的RunLoop：CFRunLoopRef 以及对应的模式：CFStringRef

通过调用：

	OSStatus AudioQueueNewOutput(const AudioStreamBasicDescription *inFormat,          // 要播放音频的格式
					                    AudioQueueOutputCallback        inCallbackProc,        // 回调
					                    void * __nullable               inUserData,            // 自定义数据
					                    CFRunLoopRef __nullable         inCallbackRunLoop,     // RunLoop
					                    CFStringRef __nullable          inCallbackRunLoopMode, // RunLoop的模式
					                    UInt32                          inFlags,               // 保留字段，传0
					                    AudioQueueRef __nullable * __nonnull outAQ)            // 返回的Queue结果对象 
					                    
创建一个用于播放使用的Queue。这里通过检查OSStatus是否为noErr判断是否出错了。					                    
## 设置Magic头、Gain等音频属性
对于MP4格式等部分音频数据，这些信息也需要从文件中同步给到AudioQueue:

    // step 5: deal magic cookie data
    UInt32 cookieSize = sizeof(UInt32);
    bool couldNotGetProperty = AudioFileGetPropertyInfo (playerStat_.mAudioFile, kAudioFilePropertyMagicCookieData,&cookieSize,  NULL);
    
    if (!couldNotGetProperty && cookieSize) {
        char* magicCookie = (char *) malloc (cookieSize);
        AudioFileGetProperty ( playerStat_.mAudioFile, kAudioFilePropertyMagicCookieData, &cookieSize, magicCookie);
        AudioQueueSetProperty ( playerStat_.mQueue,  kAudioQueueProperty_MagicCookie,  magicCookie,  cookieSize);
        free (magicCookie);
    }
    
使用过程很简单，就是一个SetProperty的过程，因此其他属性也可以通过类似File的方式进行设置，比如Gain:

    Float32 gain = 1.0;
    AudioQueueSetParameter ( playerStat_.mQueue, kAudioQueueParam_Volume, gain );  	
    
## 播放控制

播放控制很简单，既然是高级接口，肯定就提供了Start/Stop/Pause的方法：

	AudioQueueStart(AudioQueueRef inAQ, const AudioTimeStamp *inStartTime)
	AudioQueuePause( AudioQueueRef inAQ)    
	AudioQueueStop( AudioQueueRef inAQ, Boolean inImmediate) 
	
很直观的提供了几个接口，不过还是有些容易疑惑的地方。比如AudioQueueStart可以通过指定inStartTime，和AVAudioPlayer一样，表示相对于Device时间延迟的时间，从而可以精准的进行混音操作。而AudioQueueStop中的inImmediate表示是否立马停止播放，因为调用这个接口的时候，可能AudioQueue中已经有一些被压入的Buffer数据了，此时是播放完了在停止呢？还是立马停止。

## SeeK动作
如果去头文件中去找接口的话，会发现AudioQueue没有类似AudioPlayer快进、跳跃的接口。那要如何实现流媒体的拉动播放呢？

答案就在上面的回调里面，要记住AudioQueue的灵魂就在这个回调，而回调的本质就是从Buffer队列中取数据进行播放，在上面的Demo中，我们是每次都从文件中读取下一段位置的数据并放入到Buffer队列中，如果在这个回调中往Buffer列中压入之前的或者之后的数据，就相当于进行了Seek动作了。

## 总结
“Audio Queue Services”提供了一套高级的C/C++的接口，通过Queue对象来管理存放音频的数据的各个Buffer，当需要取数据进行播放的时候，就从队列中Dequeue Buffer出来播放，而我们要做的就是不听的往Buffer队列中送数据，想播什么数据就送什么数据，这样既可以从AudioFile中获得源数据、也可以从AudioStream中甚至自己解析源数据得到PCM数据进行快进、快退、点播等复杂操作了。

文中Demo参考[GitHub](https://github.com/cz-it/play_and_record_with_coreaudio/tree/master/audiotoolbox/audioqueue/examples/AudioQueueReaderDemo)

## 参考：

1. [Audio Queue Services Programming Guide](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioQueueProgrammingGuide/AboutAudioQueues/AboutAudioQueues.html)
2. [AudioQueueBuffer Class Reference](https://developer.apple.com/reference/audiotoolbox/audioqueuebuffer)
3. [Audio Queue Services Class Reference](https://developer.apple.com/reference/audiotoolbox/1651080-audio_queue_services)