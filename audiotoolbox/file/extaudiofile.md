#使用扩展的Audio File读写音频文件
如果看完了前面说的AudioToolBox中提音频文件的读写工具接口“Audio File Services”使用，并进行了实验的话，就会发现音频的读取非常麻烦，首先要读取属性，然后分配内存，读到了数据还要考虑重采样、格式转换，完整的写完一个“MP3双通道到PCM单通道的转换”功能都要写N行代码。

Apple也注意到了这样一套基本的API虽然强大，但是在最多的使用场景只用到了其中一些固定的模式，所以他又提供了一套更简洁的API："Extended Audio File Services"。扩展中的接口提供了音频格式转换的功能，同时也是对常用读取模式的一个Helper接口。

## 打开文件
和之前的"Audio File Service"一样，在操作音频数据之前首先要打开文件：

	OSStatus ExtAudioFileOpenURL ( CFURLRef inURL, ExtAudioFileRef _Nullable *outExtAudioFile );
稍微注意下会发现这里的Open和之前的Open已经文件的Open都不一样，他没有权限参数，接口非常简单，一个路径和一个输出的文件描述符结果，那到底是可读还是可写呢？上面说到Ext考虑的是通常情况，而一般对于音频我们都是读为主，所以Aplle的这个接口专门用来读音频文件内容。

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
和其他属性操作一样，Ext接口提供的属性操作也是分为两步，先获取属性基本信息，如大小：
	
	OSStatus ExtAudioFileGetPropertyInfo ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 *outSize, Boolean *outWritable );
	
然后在获得属性内容：

	OSStatus ExtAudioFileGetProperty ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 *ioPropertyDataSize, void *outPropertyData );
	
或者设置属性内容：

	OSStatus ExtAudioFileSetProperty ( ExtAudioFileRef inExtAudioFile, ExtAudioFilePropertyID inPropertyID, UInt32 inPropertyDataSize, const void *inPropertyData );
	
获取属性基本信息和前面的“AudioFileGetPropertyInfo”基本一致，一个获得属性大小“outSize"一个表示属性是否可写“outWritable”。

而“ExtAudioFileGetProperty”和“ExtAudioFileSetProperty”也与“AudioFileGetProperty”和“AudioFileSetProperty“保持一致，获取/设置文件inExtAudioFile的ExtAudioFilePropertyID属性。只是其属性的意义会不一样。

ExtAudioFilePropertyID | 意义| 结果数据类型 | 是否可读写
---|---|--
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


## 读取文件内容

## 写入文件内容

## 总结

可以看到，使用Ext的接口可以很方便的几行代码就可以实现了“MP3双通道到PCM单通道的转换”的功能，而对于通常的场景，我们也仅仅是读取一种音频格式，然后做个格式转换，或者先转成PCM数据，再做些算法处理，比如降噪、回声消除或者加速等处理再写回另一个格式存储。这个过程用Ext的接口可以很简介的表达。

## 参考
1. [Extended Audio File Services Reference](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/ExtendedAudioFileServicesReference/index.html#//apple_ref/c/func/ExtAudioFileRead)
2. [Core Audio Data Types Reference:AudioBuffer](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/CoreAudioDataTypesRef/index.html#//apple_ref/c/tdef/AudioBuffer)
2. [OSStatus](https://www.osstatus.com/)