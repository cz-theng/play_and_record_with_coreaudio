# 使用扩展的Audio File读写音频文件
如果看完了前面说的AudioToolBox中提音频文件的读写工具接口[“使用Audio File读写音频文件”](../file/audiofile.html)使用，并进行了实验的话，就会发现音频的读取非常麻烦，首先要读取属性，然后分配内存，读到了数据还要考虑重采样、格式转换，完整的写完一个“MP3双通道到PCM单通道的转换”功能都要写N行代码。

Apple也注意到了这样一套基本的API虽然强大，但是在最多的使用场景只用到了其中一些固定的模式，所以他又提供了一套更简洁的API："Extended Audio File Services"。扩展中的接口提供了音频格式转换的功能，同时也是对常用读取模式的一个Helper接口。如例子中的按钮提示：

![ext_audio_file_demo](./images/ext_audio_file_demo.png)

Demo参见[GitHub](https://github.com/cz-it/play_and_record_with_coreaudio/tree/master/audiotoolbox/file/examples/ExtAudioFileServicesDemo)

## 打开文件
和之前的"Audio File Service"一样，在操作音频数据之前首先要打开文件：

	OSStatus ExtAudioFileOpenURL ( CFURLRef inURL, ExtAudioFileRef _Nullable *outExtAudioFile );
稍微注意下会发现这里的Open和之前的Open以及文件的Open都不一样，他没有权限参数，接口非常简单，一个路径和一个输出的文件描述符结果，那到底是可读还是可写呢？上面说到Ext考虑的是通常情况，而一般对于音频我们都是读为主，所以Aplle的这个接口专门用来读音频文件内容。

那如果要写怎么办呢？有两种方法，一种是用其包装的打开并写的接口：

	OSStatus ExtAudioFileCreateWithURL ( CFURLRef inURL, AudioFileTypeID inFileType, const AudioStreamBasicDescription *inStreamDesc, const AudioChannelLayout *inChannelLayout, UInt32 inFlags, ExtAudioFileRef _Nullable *outExtAudioFile );
这时需要设定写入音频的相关属性

* 文件的类型：AudioFileTypeID； 
* 文件的数据格式：AudioStreamBasicDescription； 
* 音频数据的通道结构：AudioChannelLayout 

和fopen一样，还可以通过flag来指定“ kAudioFileFlags_EraseFile”当文件存在时直接删除重新创建。最后的结果通过outExtAudioFile返回文件描述符。

另一种方法是用“Audio File Service”中介绍的“AudioFileOpenURL”以“kAudioFileWritePermission”的方式打开，然后再类似"open"->"fopen"的方式得到一个Ext的描述符：

	OSStatus ExtAudioFileWrapAudioFileID ( AudioFileID inFileID, Boolean inForWriting, ExtAudioFileRef _Nullable *outExtAudioFile );  
将AudioFileID 转换成一个ExtAudioFileRef。当然，此时将 inForWriting 置为true为可写。

当操作完以后，通过Dispose来回收资源，区分于其他的Close:
	
	OSStatus ExtAudioFileDispose ( ExtAudioFileRef inExtAudioFile );
	
直接传入ExtAudioFileRef表示的文件描述符，返回值参见Apple文档[Result Codes](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/ExtendedAudioFileServicesReference/index.html#//apple_ref/c/func/ExtAudioFileDispose)

## 读取属性
和“Audio ToolBox”的其他属性操作一样，Ext接口提供的属性操作也是分为两步，先获取属性基本信息，如大小：
	
	OSStatus ExtAudioFileGetPropertyInfo ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 *outSize, Boolean *outWritable );
	
然后在获得属性内容：

	OSStatus ExtAudioFileGetProperty ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 *ioPropertyDataSize, void *outPropertyData );
	
或者设置属性内容：

	OSStatus ExtAudioFileSetProperty ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 inPropertyDataSize, const void *inPropertyData );
	
获取属性基本信息和前面的“AudioFileGetPropertyInfo”基本一致，一个获得属性大小“outSize"一个表示属性是否可写“outWritable”。

而“ExtAudioFileGetProperty”和“ExtAudioFileSetProperty”也与“AudioFileGetProperty”和“AudioFileSetProperty“保持一致，获取/设置文件inExtAudioFile的ExtAudioFilePropertyID属性。只是其属性的意义会不一样。


ExtAudioFilePropertyID | 意义| 结果数据类型 | 是否可读写
---|---|---|---
kExtAudioFileProperty_FileDataFormat|源音频数据的格式|    AudioStreamBasicDescription  | 只读
kExtAudioFileProperty_FileChannelLayout| 源音频数据的通道格式| AudioChannelLayout | 读写
kExtAudioFileProperty_ClientDataFormat  | 读出来后的音频数据的格式|AudioStreamBasicDescription| 读写
kExtAudioFileProperty_ClientChannelLayout|读出来后的音频数据的通道格式|AudioChannelLayout| 读写
kExtAudioFileProperty_CodecManufacturer  |是否使用硬件编解码|UInt32（kAppleHardwareAudioCodecManufacturer or kAppleSoftwareAudioCodecManufacturer）| 读写
||
kExtAudioFileProperty_AudioConverter     |指定的编解码工具| AudioConverterRef| 只读
kExtAudioFileProperty_AudioFile          |对应的AudioFileID|AudioFileID| 只读
kExtAudioFileProperty_FileMaxPacketSize  |源音频数据最大的Packet大小|Uint32| 只读
kExtAudioFileProperty_ClientMaxPacketSize|读出后音频数据最大的Packet大小|Uint32| 只读
kExtAudioFileProperty_FileLengthFrames   |帧数|SInt64| 只读
||
kExtAudioFileProperty_ConverterConfig   |指定编解码器|CFArray| 读写
kExtAudioFileProperty_IOBufferSizeBytes |编解码使用的缓冲区大小|UInt32| 读写
kExtAudioFileProperty_IOBuffer          |编解码使用的缓冲区|void *| 读写
kExtAudioFileProperty_PacketTable       |设置PacketTable| AudioFilePacketTableInfo| 读写

这里列了一大堆属性的值，看的人发慌。仔细看下属性名，其实也是有规律可循的，而且有一个必须知道的点。这里的大部分属性可以分为

* kExtAudioFileProperty_Xxxx : 源文件的相关属性，也就是原来什么格式的数据（MP3/AAC），他的基本属性。
* kExtAudioFileProperty_ClientXxx: 读出时的数据格式，Ext在读出时会自动帮我们做编解码操作，这个是处理后的结果

所以在读取之前，一定要记得设置“kExtAudioFileProperty_ClientDataFormat”属性，设置其输出的数据格式，否则Seek等操作会永远失败。
其他的根据需要选择是否要进行输出格式的自定义。比如是否使用Iphone的硬件解码（目前硬件仅支持部分格式:.aif/.caf/.mp3/.aac/.mp4/.wav）、是否用自定义的编解码、编解码的缓存空间等。比如：

    // set the output format
    AudioStreamBasicDescription outDesc = desc_;
    outDesc.mSampleRate = 44100;
    outDesc.mFormatID = kAudioFormatLinearPCM;
    outDesc.mFormatFlags = kLinearPCMFormatFlagIsFloat;
    outDesc.mBitsPerChannel = 16; // 16bit sample depth
    outDesc.mChannelsPerFrame = 2;
    outDesc.mBytesPerFrame = outDesc.mChannelsPerFrame * outDesc.mBitsPerChannel/8;
    outDesc.mFramesPerPacket = 1;
    outDesc.mBytesPerPacket = outDesc.mFramesPerPacket * outDesc.mBytesPerFrame;
    UInt32 outDescSize = sizeof(outDesc);
    
    stts = ExtAudioFileSetProperty(extMusicFD_, kExtAudioFileProperty_ClientDataFormat, &outDescSize, &outDesc);
    VStatus(stts, @"ExtAudioFileSetProperty");

## 读取文件内容
和属性不一样，读取接口与“AudioFileReadPacketData”不是很相似，但是这次到没有提供多个接口选择，就一个接口：

	OSStatus stts;
	AudioBufferList bufferList;
	bufferList.mNumberBuffers = 1;
	bufferList.mBuffers[0].mNumberChannels = desc_.mChannelsPerFrame;
	bufferList.mBuffers[0].mDataByteSize = extMaxPktSize_;
	bufferList.mBuffers[0].mData = malloc(extMaxPktSize_);
	if (NULL ==bufferList.mBuffers[0].mData ) {
	    NSLog(@"malloc bufferList.mBuffers[0].mData nullptr");
	    return ;
	}
	
	UInt32 frameNum = 1;
	stts = ExtAudioFileRead(extMusicFD_, &frameNum, &bufferList);
	VStatus(stts, @"AudioBufferList"); // also need free
	
	if (NULL !=bufferList.mBuffers[0].mData) {
	    free(bufferList.mBuffers[0].mData);
	    bufferList.mBuffers[0].mData = NULL;
	}
	NSLog(@"ExtAudioFileRead frame[%d] with %d", frameNum, bufferList.mBuffers[0].mDataByteSize);

这里首先引入了一个AudioBufferList：

	struct AudioBufferList
	{
	    UInt32      mNumberBuffers;
	    AudioBuffer mBuffers[1]; // this is a variable length array of mNumberBuffers elements
	    
	#if defined(__cplusplus) && CA_STRICT
	public:
	    AudioBufferList() {}
	private:
	    //  Copying and assigning a variable length struct is problematic so turn their use into a
	    //  compile time error for eacy spotting.
	    AudioBufferList(const AudioBufferList&);
	    AudioBufferList&    operator=(const AudioBufferList&);
	#endif
	
	};
	typedef struct AudioBufferList  AudioBufferList;
	
以及一个AudioBuffer：

	struct AudioBuffer
	{
	    UInt32              mNumberChannels;
	    UInt32              mDataByteSize;
	    void* __nullable    mData;
	};
	typedef struct AudioBuffer  AudioBuffer;
	
其实就是对void *的buffer管理，以一个List为表像。先初始化这个List，给一个Buffer的总数目“mNumberBuffers”。然后对每个Buffer做内存分配，每个buffer还有个声道数的属性mNumberChannels，设置成读出来的格式即可。

然后就可以用这个BufferList啦进行读取了，传入文件描述符和要读取的帧数给ExtAudioFileRead。即可将具体的数据读到BufferList中。这里有个文档上模棱两可的说明，就是读取的时候实际上是按照源数据的数据格式按照帧为单位进行读取的。比如一帧MP3是1044字节，然后BufferList里面只有一个Buffer为1024个字节，那么读到的结果为0，因为Buffer不够装，所以一帧也没有读出来；而如果Buffer为1054字节,那么读到的是一帧数据1044，返回的结果帧数为1。

上面说的具体读到哪一帧了，可以通过Tell来获得：

	OSStatus ExtAudioFileTell ( ExtAudioFileRef inExtAudioFile, SInt64 *outFrameOffset );
	
给定一个打开的文件描述符，然后已经读到的或者写入的帧数偏移就通过outFrameOffset返回。

和fopen对应的有fseek一样，这里也有个seek接口，以帧数为单位：

		OSStatus ExtAudioFileSeek ( ExtAudioFileRef inExtAudioFile, SInt64 inFrameOffset );
也很简单，将文件inExtAudioFile seek到inFrameOffset帧数位置。

    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"before current position %lld", curPos);
    
    stts = ExtAudioFileSeek(extMusicFD_, 2 );
    VStatus(stts, @"ExtAudioFileSeek");
    
    stts = ExtAudioFileTell(extMusicFD_, &curPos);
    VStatus(stts, @"ExtAudioFileTell");
    NSLog(@"after current position %lld", curPos);
    
这里可以看到都是以帧数作为单位。

## 写入文件内容
写入和读取类似，只是要预先填好BufferList的内容：

	OSStatus ExtAudioFileWrite ( ExtAudioFileRef inExtAudioFile, UInt32 inNumberFrames, const AudioBufferList *ioData );
	
同时写入还有个非阻塞的版本：

	OSStatus ExtAudioFileWriteAsync ( ExtAudioFileRef inExtAudioFile, UInt32 inNumberFrames, const AudioBufferList *ioData );
	
相当于没有调用fwrite的非阻塞写。当调用“ ExtAudioFileDispose ”会最终保证所有数据都写入到磁盘中。

## 总结

可以看到，使用Ext的接口可以很方便的几行代码就可以实现了“MP3双通道到PCM单通道的转换”的功能，Ext以帧为而对于通常的场景，我们也仅仅是读取一种音频格式，然后做个格式转换，或者先转成PCM数据，再做些算法处理，比如降噪、回声消除或者加速等处理再写回另一个格式存储。这个过程用Ext的接口可以很简介的表达。

## 参考
1. [Extended Audio File Services Reference](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/ExtendedAudioFileServicesReference/index.html#//apple_ref/c/func/ExtAudioFileRead)
2. [Core Audio Data Types Reference:AudioBuffer](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/CoreAudioDataTypesRef/index.html#//apple_ref/c/tdef/AudioBuffer)
2. [OSStatus](https://www.osstatus.com/)