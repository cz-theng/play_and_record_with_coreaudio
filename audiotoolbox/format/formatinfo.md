# 4.2.1 获取格式内容

## 获取的方法

## 属性的键值

AudioFormatPropertyID| 意义 |输入数据| 输出结果
---|---|---|---
kAudioFormatProperty_FormatInfo | 获取magic cookie的格式信息 | 音频文件的Magic值 |AudioStreamBasicDescription（至少会返回mFormatID字段）
kAudioFormatProperty_FormatName | 获取Format名称 | AudioStreamBasicDescription | CFStringRef表示的格式名称如“MPEG Layer 3, 2 channels, 44100 Hz”
kAudioFormatProperty_EncodeFormatIDs |支持的编码格式|NULL|UInt32数组表示的编码格式 
kAudioFormatProperty_DecodeFormatIDs |支持的解码格式| NULL | UInt32数组表示的解码格式
kAudioFormatProperty_FormatList   |压缩的音频流里面所有的格式信息|AudioFormatInfo|  AudioFormatListItem数组   
kAudioFormatProperty_ASBDFromESDS    
kAudioFormatProperty_ChannelLayoutFromESDS  
kAudioFormatProperty_OutputFormatList       
kAudioFormatProperty_Encoders               
kAudioFormatProperty_Decoders               
kAudioFormatProperty_FormatIsVBR            
kAudioFormatProperty_FormatIsExternallyFramed 
kAudioFormatProperty_AvailableEncodeBitRates  
kAudioFormatProperty_AvailableEncodeSampleRates 
kAudioFormatProperty_AvailableEncodeChannelLayoutTags 
kAudioFormatProperty_AvailableEncodeNumberChannels  
kAudioFormatProperty_ASBDFromMPEGPacket             
|||
kAudioFormatProperty_BitmapForLayoutTag          
kAudioFormatProperty_MatrixMixMap                
kAudioFormatProperty_ChannelMap                  
kAudioFormatProperty_NumberOfChannelsForLayout   
kAudioFormatProperty_ValidateChannelLayout       
kAudioFormatProperty_ChannelLayoutForTag         
kAudioFormatProperty_TagForChannelLayout         
kAudioFormatProperty_ChannelLayoutName           
kAudioFormatProperty_ChannelLayoutSimpleName     
kAudioFormatProperty_ChannelLayoutForBitmap      
kAudioFormatProperty_ChannelName                 
kAudioFormatProperty_ChannelShortName            
kAudioFormatProperty_TagsForNumberOfChannels     
kAudioFormatProperty_PanningMatrix               
kAudioFormatProperty_BalanceFade                 
|||
kAudioFormatProperty_ID3TagSize        
kAudioFormatProperty_ID3TagToDictionary

上面列举了各个属性的意义和使用方法，下面列举几个例子

### kAudioFormatProperty_FormatInfo
通过Magic获得文件类型信息，首先要用"AudioFileGetProperty"获得Magic信息：

	    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, &prprtyWriteable);
    VStatus(stts, @"AudioFileGetPropertyInfo: kAudioFilePropertyMagicCookieData");
    void * magic = malloc(prprtySize);
    if (NULL == magic) {
        NSLog(@"malloc magic is NULL");
        return ;
    }
    memset(magic, 0, prprtySize);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, magic);
    VStatus(stts, @"AudioFileGetProperty: kAudioFilePropertyMagicCookieData");
    NSLog(@"get magic with length %d", prprtySize);
    AudioStreamBasicDescription desc;
    UInt32 descSize = sizeof(desc);
    stts = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, prprtySize, magic, &descSize, &desc);
    VStatus(stts, @"kAudioFormatProperty_FormatInfo");
    NSLog(@"mFormat is %d", desc.mFormatID);
然后传入Magic并从结果AudioStreamBasicDescription获得表示文件格式的AudioFormatID值。

### kAudioFormatProperty_FormatName
获得AudioStreamBasicDescription中表示的格式信息:

	  AudioStreamBasicDescription desc;
    UInt32 descSize = sizeof(desc);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyDataFormat, &descSize, &desc);
    VStatus(stts, @"AudioFileGetProperty: kAudioFilePropertyDataFormat");
    NSLog(@"get data with length %d", descSize);
    CFStringRef formatName;
    UInt32 formatNameSize = sizeof(formatName);
    stts = AudioFormatGetProperty(kAudioFormatProperty_FormatName, descSize, &desc, &formatNameSize, &formatName);
    VStatus(stts, @"kAudioFormatProperty_FormatInfo");
    NSLog(@"Format is %@", formatName);
    
这里首先通过AudioFileGetProperty读取文件的kAudioFilePropertyDataFormat然后算得其格式名称，结果如“MPEG Layer 3, 2 channels, 44100 Hz”

### kAudioFormatProperty_FormatList
这里首先要介绍两个数据结构：

	struct AudioFormatListItem
	{
		AudioStreamBasicDescription mASBD;
		AudioChannelLayoutTag		  mChannelLayoutTag;
	};
	typedef struct AudioFormatListItem AudioFormatListItem;
	
	struct AudioFormatInfo
	{
		AudioStreamBasicDescription   mASBD;
		const void*						    mMagicCookie;
		UInt32								    mMagicCookieSize;
	};
	typedef struct AudioFormatInfo AudioFormatInfo;
	
一个AudioFormatInfo一个AudioFormatListItem，前者是一个AudioStreamBasicDescription加上Magic信息，后者是AudioStreamBasicDescription加上声道信息。

在使用时，首先要要获得一个Magic Cookie值，比如用通过AudioFileGetProperty，但是大部分音频数据是没有Magic Cookie。这个属性的作用就是从Magic Cookie里面获取各个部分的音频数据，并存放在AudioFormatListItem的list里面。

首先用Magic填充一个AudioFormatInfo，然后获取List的长度：

	finfo.mASBD = desc;
	finfo.mMagicCookie = magic;
	finfo.mMagicCookieSize = prprtySize;
	
	UInt32 finfoSize = sizeof(finfo);
	UInt32 finfosSize  = 0;
	stts = AudioFormatGetPropertyInfo(kAudioFormatProperty_FormatList, sizeof(finfo), &finfo, &finfosSize);
	VStatus(stts, @"AudioFormatGetPropertyInfo:kAudioFormatProperty_FormatList");
	size_t itemCount = finfosSize / sizeof(AudioFormatListItem);
	AudioFormatListItem *finfos = (AudioFormatListItem *) malloc(finfosSize);
	
然后在获取每个Item并遍历结果：

	stts = AudioFormatGetProperty(kAudioFormatProperty_FormatList, finfoSize, &finfo, &finfosSize, finfos);
	VStatus(stts, @"AudioFormatGetProperty: kAudioFormatProperty_FormatList");
	for (int i=0; i< itemCount; i++) {
	    AudioFormatListItem *item = finfos + i ;
	    NSLog(@"channel layout tag is %d", item->mChannelLayoutTag);
	}
内存释放需要自己手动处理下。



## 参考
1. [Audio Format Services Reference](https://developer.apple.com/library/mac/documentation/AudioToolbox/Reference/AudioFormatServicesReference/index.html#//apple_ref/doc/constant_group/Audio_Format_Property_Identifiers)
