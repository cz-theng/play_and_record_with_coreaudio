# 使用Audio File读写音频文件
对于音频文件的读取，我们可以用fopen这样一段buffer一段buffer的段，但是这之后就需要自己去根据文件的头来推断文件的类型、编码格式等，然后进行解析到有效的音频数据，想想这是何等的麻烦。Apple也知道这样的麻烦，所以她在AudioToolBox中提供了音频文件的读写工具接口：“Audio File Services”以及其扩展"Extended Audio File Services"。扩展中的接口提供了音频格式转换的功能，同时也是对常用读取模式的一个Helper接口。想来是Apple在使用过程中也觉得最常用的读取就那么几个步骤，而前者的基础接口过于繁琐了。

使用“Audio File Services”时，我们需要先根据系统和文件属性，比如文件类型，长度等，然后再决定如何进行读取。比如[Demo]() 中的按钮，先打开文件，然后读取文件属性，再读取文件内容，最后将文件关闭。

![audio_file_demo](./images/audio_file_demo.png)

## 获得“Audio File Services”基本属性
“Audio File Services”作为一个服务，有其自己的限制和功能范围。通过其提供的GlobalInfo接口，可以获得其基本信息，比如支持哪些文件格式、支持哪些编码格式以及文件格式的MIME类型值查询等服务。比如：

	OSStatus stts;
	UInt32 infoSize = 0;
	stts = AudioFileGetGlobalInfoSize(kAudioFileGlobalInfo_AllMIMETypes, 0, NULL, &infoSize);
	VStatus(stts, @"AudioFileGetGlobalInfoSize");
	
	NSArray *MIMEs;
	stts = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_AllMIMETypes, 0, NULL, &infoSize, &MIMEs);
	VStatus(stts, @"AudioFileGetGlobalInfo");
	NSLog(@"fileType is %@", MIMEs);
	
	UInt32 propertySize;
	OSType readOrwrite = kAudioFileGlobalInfo_ReadableTypes;
	
	stts = AudioFileGetGlobalInfoSize(readOrwrite, 0, NULL, &propertySize);
	VStatus(stts, @"AudioFileGetGlobalInfoSize");
	
	OSType *types = (OSType*)malloc(propertySize);
	stts = AudioFileGetGlobalInfo(readOrwrite, 0, NULL, &propertySize,  types);
	VStatus(stts, @"AudioFileGetGlobalInfo");
	
	UInt32 numTypes = propertySize / sizeof(OSType);
	for (UInt32 i=0; i<numTypes; ++i){
	    CFStringRef name;
	    UInt32 outSize = sizeof(name);
	    stts = AudioFileGetGlobalInfo(kAudioFileGlobalInfo_FileTypeName, sizeof(OSType), types+i, &outSize, &name);
	    VStatus(stts, @"AudioFileGetGlobalInfo");
	    NSLog(@"readalbe types: %@", name);
	}
	
这里VStatus是一个检查返回值的宏定义。这里先获得Info的Size:

	OSStatus AudioFileGetGlobalInfoSize ( AudioFilePropertyID inPropertyID, UInt32 inSpecifierSize, void *inSpecifier, UInt32 *outDataSize );

然后在获取具体的info值：

	OSStatus AudioFileGetGlobalInfo ( AudioFilePropertyID inPropertyID, UInt32 inSpecifierSize, void *inSpecifier, UInt32 *ioDataSize, void *outPropertyData );

两个函数先将`UInt32 inSpecifierSize, void *inSpecifier`忽略掉，这样比较好理解，当获取InfoSize的时候传入一个AudioFilePropertyID 然后属性的大小值在outDataSize被返回；而当获得具体的Info的时候，则用ioDataSize指定传入buffer的大小和返回值的大小，具体的值存在outPropertyData中。

而“Specifier”也是一个buffer加上长度，在不同的AudioFilePropertyID中，需要指定不同的值，比如上面，开始用“0”和“NULL”，当要查询OSType的文件名称时，传入`sizeof(OSType), types+i`，也就是要查询的OSType的内容。

AudioFilePropertyID | 意义| 结果 | Specifier组合
---|---|---|---
kAudioFileGlobalInfo_ReadableTypes | 可以用来读的文件类型 | Uint32的数组 | NULL
kAudioFileGlobalInfo_WritableTypes |可以用来写的文件类型 | Uint32的数组 | NULL
kAudioFileGlobalInfo_FileTypeName  | 文件类型名 | CFStringRef 类型值| 文件类型ID的OSType的值
kAudioFileGlobalInfo_AvailableStreamDescriptionsForFormat |指定文件类型中可包含的StreamDescription| StreamDescription数组| 文件类型ID的OSType的值
kAudioFileGlobalInfo_AvailableFormatIDs| 指定文件类型中可以容纳的编码格式| 格式ID的数组|文件类型ID的OSType的值                
|||
kAudioFileGlobalInfo_AllExtensions |支持的文件扩展名| CFStrings的数组（CFArray）|NULL
kAudioFileGlobalInfo_AllHFSTypeCodes| 支持的HFS的编码格式| HFS类型数组 | NULL
kAudioFileGlobalInfo_AllUTIs | 支持的UTIs | CFStrings的数组（CFArray）| NULL
kAudioFileGlobalInfo_AllMIMETypes |支持的MIME类型| CFStrings的数组（CFArray） | NULL
|||
kAudioFileGlobalInfo_ExtensionsForType|指定类型文件可用的扩展名|CFStrings的数组（CFArray）|文件类型ID的OSType的值 
kAudioFileGlobalInfo_HFSTypeCodesForType |指定类型支持的HFS的编码格式| HFS类型数组 | 文件类型ID的OSType的值
kAudioFileGlobalInfo_UTIsForType |指定类型支持UTIs | CFStrings的数组（CFArray）| 文件类型ID的OSType的值        
kAudioFileGlobalInfo_MIMETypesForType |指定类型支持的MIME类型  | CFStrings的数组（CFArray） |文件类型ID的OSType的值 
|||
kAudioFileGlobalInfo_TypesForMIMEType |支持指定MIME的文件类型|文件类型ID数组 | CFStringRef表示的MIME
kAudioFileGlobalInfo_TypesForUTI | 支持指定UTIs的文件类型|文件类型ID数组 |CFStringRef表示的UTI
kAudioFileGlobalInfo_TypesForHFSTypeCode | 支持指定HFS的文件类型|文件类型ID数组 | HFSTypeCode 表示的HFS
kAudioFileGlobalInfo_TypesForExtension  | 支持指定扩展名的文件类型|文件类型ID数组 |CFStringRef表示的扩展名

对照这表格再来看上面的代码就比较好容易理解了，首先kAudioFileGlobalInfo_AllMIMETypes查询属性的大小，然后Specifier为NULL查询所有
支持的MIME类型，结果为表示MIME值的CFStrings的数组（CFArray）。

接着在用kAudioFileGlobalInfo_ReadableTypes查询到属性大小，其实表示文件类型ID的UInt32数组大小。然后逐个遍历各个得到的文件类型
ID用kAudioFileGlobalInfo_FileTypeName查询到这个文件类型ID对应的CFStringRef表示的文件类型名。

## 打开文件
要想对音频文件进行操作，和操作普通文件一样，首先是要打开文件。其接口为：
	
	OSStatus AudioFileOpenURL ( CFURLRef inFileRef, AudioFilePermissions inPermissions, AudioFileTypeID inFileTypeHint, AudioFileID _Nullable *outAudioFile );
各个参数很直白，文件的路径通过CFURLRef指定，其可以通过NSURL桥接转义过来，支持NSBundle路径、MediaPicker得到的路径等。表示打开来读还是什么的权限位：

	enum {
	   kAudioFileReadPermission      = 0x01,
	   kAudioFileWritePermission     = 0x02,
	   kAudioFileReadWritePermission = 0x03 
	};

inFileTypeHint是打开文件的类型，iOS下可以直接用"0"。outAudioFile为真实的文件句柄或叫文件描述符。返回值通过OSStatus表示，成功返回“noErr”其他错误码参考官方文档中的[Result Codes](https://developer.apple.com/library/mac/documentation/MusicAudio/Reference/AudioFileConvertRef/index.html#//apple_ref/c/func/AudioFileOpenURL)或者去[OSStatus](https://www.osstatus.com/)查询。

与Open对应的是Close:
	
	OSStatus AudioFileClose ( AudioFileID inAudioFile );
关闭打开的文件描述符。

## 读取文件属性
在打开文件获得文件描述符后，我们就可以读取音频数据的格式信息了，比如采样率、位深度、通道数等等。和上面一样，这里的接口也是分为获得InfoSize和Info的两个步骤。

先获得属性的大小：
	
	OSStatus AudioFileGetPropertyInfo ( AudioFileID inAudioFile, AudioFilePropertyID inPropertyID, UInt32 *outDataSize, UInt32 *isWritable );

在获得属性的具体内容

	OSStatus AudioFileGetProperty ( AudioFileID inAudioFile, AudioFilePropertyID inPropertyID, UInt32 *ioDataSize, void *outPropertyData );
	
这里看到的就加单多了，没有了Specifier的干扰。直接就是给定一个打开的文件`AudioFileID inAudioFile`，然后查询的属性`AudioFilePropertyID inPropertyID`，接着是两个输出结果，分别是属性大小和是否可写 `UInt32 *outDataSize, UInt32 *isWritable`

对于可写的属性，还可以调用

	OSStatus AudioFileSetProperty ( AudioFileID inAudioFile, AudioFilePropertyID inPropertyID, UInt32 inDataSize, const void *inPropertyData );
	
对其进行设置，当创建文件的时候就需要设置生成的文件的相关格式了。

查询接口中也是一样，查询文件“inAudioFile”的“inPropertyID”的属性值，结果存放在长度为“ioDataSize”的buffer“outPropertyData”中。属性值有：

AudioFilePropertyID | 意义| 结果类型
---|---|---
kAudioFilePropertyFileFormat  | 音频文件的格式 | char *
kAudioFilePropertyDataFormat  | 音频数据格式 | AudioStreamPacketDescription
kAudioFilePropertyIsOptimized | 是否可以优化| 0/1
kAudioFilePropertyMagicCookieData | Magic Cookie文件头| char *
kAudioFilePropertyAudioDataByteCount | 文件长度 | Uint64
kAudioFilePropertyAudioDataPacketCount | Packet的数目 | Uint64
kAudioFilePropertyMaximumPacketSize | 最大的Packet大小 | Uint32
kAudioFilePropertyDataOffset | 数据的偏移量| Uint64
kAudioFilePropertyChannelLayout | 声道结构 | AudioFormatListItem
kAudioFilePropertyDeferSizeUpdates | 是否更新文件头信息 | 1/0
kAudioFilePropertyMarkerList | 音频中所有markers | CFStringRef表示的Markers列表
kAudioFilePropertyRegionList | 音频中所有Region  | CFStringRef表示的Region列表
kAudioFilePropertyPacketToFrame | 将包数转换成帧数|AudioFramePacketTranslation中mPacket做输入，mFrame做输出
kAudioFilePropertyFrameToPacket | 将帧数转换成包数|AudioFramePacketTranslation中mFrame做输入，mFrameOffsetInPacket，mPacket做输出
kAudioFilePropertyPacketToByte | 将包数转换成字节数| AudioFramePacketTranslation中mPacket做输入，mByte做输出
kAudioFilePropertyByteToPacket | 将字节数转换成包数| AudioFramePacketTranslation中mByte做输入，mPacket和mByteOffsetInPacket做输出
kAudioFilePropertyChunkIDs  | 文件中的chunk编码格式 | 4字符编码格式数组
kAudioFilePropertyInfoDictionary|字典表示的Info | CFDictionary
kAudioFilePropertyPacketTableInfo |设置PacketTableInfo | PacketTableInfo
kAudioFilePropertyFormatList |支持的格式列表| 编码格式list
kAudioFilePropertyPacketSizeUpperBound | 理论上的最大Packet大小| Uint64
kAudioFilePropertyReserveDuration  | 设置写保护区大小，单位为秒 | Uint32
kAudioFilePropertyEstimatedDuration | 估算的音频时长 ， 单位秒 | Uint32
kAudioFilePropertyBitRate  | 码率 | Uint32
kAudioFilePropertyID3Tag  | ID3 tag | void * 
kAudioFilePropertySourceBitDepth| 位深度 | Uint32
kAudioFilePropertyAlbumArtwork | 专辑名| CFDataRef

读取文件的属性后，我们可以根据这个来进行后续的操作，比如格式转换、重采样、声道变换等操作。

## 读取音频数据
读取文件总共有三个接口：

	OSStatus AudioFileReadBytes ( AudioFileID inAudioFile, Boolean inUseCache, SInt64 inStartingByte, UInt32 *ioNumBytes, void *outBuffer );
	OSStatus AudioFileReadPacketData ( AudioFileID inAudioFile, Boolean inUseCache, UInt32 *ioNumBytes, AudioStreamPacketDescription *outPacketDescriptions, SInt64 inStartingPacket, UInt32 *ioNumPackets, void *outBuffer );
	OSStatus AudioFileReadPackets ( AudioFileID inAudioFile, Boolean inUseCache, UInt32 *outNumBytes, AudioStreamPacketDescription *outPacketDescriptions, SInt64 inStartingPacket, UInt32 *ioNumPackets, void *outBuffer );
	
其中AudioFileReadPackets已经被Deprecated(OS X v10.10)了，所以不再推荐。AudioFileReadBytes官方不推荐用这个接口，实际我在测试时发现对MP3数据总是返回失败，PCM可读，所以也不推荐。

最后看仅剩下的AudioFileReadPacketData。这个函数首先传入一个文件描述符，这个毫无疑问。然后“inUseCache”表示是否缓存读取的数据。接着的五个参数才是控制读取的内容：
 
* UInt32 *outNumBytes  ： 最终读到数据的大小
* AudioStreamPacketDescription *outPacketDescriptions ： 一个存放AudioStreamPacketDescription的Buffer，要足够大
* SInt64 inStartingPacket ： 起始的Packet
* UInt32 *ioNumPackets ： 当输入时表示要读取的Packet数目，输出时表示最终读入的Packet数目
* void *outBuffer ： 数据读到的具体buffer位置

代码示例：
	
	OSStatus stts;

    char *packetBuf = (char *) malloc( maxPkgSize_ *2);
    if (NULL == packetBuf) {
        NSLog(@"NULL == packetBuf ");
        return ;
    }
    
    for (int i=0;i<pkgNum_ ;i+=2 ) {
        
        UInt32 packetBufLen = maxPkgSize_*2;
        memset(packetBuf, packetBufLen, 0);
        memset(byteBuf, maxPkgSize_, 0);
        
        AudioStreamPacketDescription aspDesc[2];


        UInt32 pktNum = 2;
        if ((i+2)>pkgNum_) {
            pktNum = 1;
        }
        stts = AudioFileReadPacketData(musicFD_, NO, &packetBufLen, aspDesc, i, &pktNum, packetBuf);
        if (kAudioFileEndOfFileError == stts) {
            NSLog(@"End of File");
            break;
        }
        VStatus(stts, @"AudioFileReadPacketData");
        NSLog(@"[%d/%lld]Read two packet data,desc is %d,%d [packetBufLen:%d], [pktNum:%d]", i+2, pkgNum_, aspDesc[0].mDataByteSize, aspDesc[1].mDataByteSize, packetBufLen, pktNum);
    }

    if (NULL != packetBuf) {
        free(packetBuf);
        packetBuf = NULL;
    }

这里先按照最大的PacketSize分配两个Packet的空间，然后每次读取两个Packet，每次分配两个AudioStreamPacketDescription用来存取对应Packet的数据格式，对于CBR基本都是一样的。


## 写入音频数据
和读入一样，写入也有两个接口：

	OSStatus AudioFileWriteBytes ( AudioFileID inAudioFile, Boolean inUseCache, SInt64 inStartingByte, UInt32 *ioNumBytes, const void *inBuffer );
	OSStatus AudioFileWritePackets ( AudioFileID inAudioFile, Boolean inUseCache, UInt32 inNumBytes, const AudioStreamPacketDescription *inPacketDescriptions, SInt64 inStartingPacket, UInt32 *ioNumPackets, const void *inBuffer );

同样“AudioFileWriteBytes” Apple官方不再推荐，这里任然看“AudioFileWritePackets”,文件描述符和是否缓存和Read一样：

* UInt32 inNumBytes ：要写的数据大小
* const AudioStreamPacketDescription *inPacketDescriptions ： 每个packet对应的数据格式
* SInt64 inStartingPacket ： 其实packet偏移
* UInt32 *ioNumPackets ： 输入时表示要写入的packet数目，输出时表示真实写入的packet数目
* const void *inBuffer ： 源数据buffer

接口和Read基本雷同，使用方式也类似。

## 总结
使用“Audio File Service”操作文件，首先其有一定的受用范围，比如文件类型。然后对适用的文件先打开文件，在读取属性确定数据格式，比如最大Packet大小，根据这些信息分配内存读取数据；如果是写入数据，则要设置文件的属性信息，然后调用写入接口写入音频文件，最后调用Close关掉文件，避免资源泄露。

## 参考资料
1. [Apple Core Audio Format Specification 1.0](https://developer.apple.com/library/content/documentation/MusicAudio/Reference/CAFSpec/CAF_spec/CAF_spec.html)
2. [Audio File Services Reference](https://developer.apple.com/reference/audiotoolbox/1653446-audio_file_services?language=objc)
