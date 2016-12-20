# Audio Unit范式

## AuidoUnit种类
当前的iOS上面主要提供了七种Unit：

作用 | 名称
---|---
均衡器| iPod 均衡
混音| 3D 混音
混音| 多路混音
输入输出| 远端输入输出
输入输出| VoIP 输入输出
输入输出| 通用输出
格式转换| 格式转换

这七种Unit可以分成四类：

### 均衡器单元
Effect Unit提供了类似“设置-》iPod-》EQ（均衡器）”里面调节iPod的均衡器效果，

### 混音单元
混音单元包括了多路混音和3D混音两类，3D混音单元是实现OpenAL的基础，OpenAL就是使用它来实现3D音效的，所以正常情况下，我们不需要自己来操纵这个3D混音单元来实现3D音效，更好的选择是使用后面章节介绍到的OpenAL。

而多路混音就比较常见了，假设在游戏里面的实时语音场景，此时既需要播放从网络上接受到的队友的声音，同时也需要播放游戏背景，那这个时候就可以将两路声音数据在混音单元中进行混音后再由输出单元进行播放。

### 输入输出单元
输入输出单元则有三类，其实可以认为是两类，一类是连接硬件的，一类是不连接硬件。

* 连接硬件的有“Remote I/O unit ”和“Voice-Processing I/O unit”，他们的输入就是硬件设备：麦克风，而输出就是硬件设备：扬声器。
* 不连接设备的有“Generic Output unit”只能表示输出，从其输出可以得到具体的音频数据Buffer，此时可以选择存文件或者发送到网络。

### 格式转换单元
顾名思义此单元的作用就是做为一个中间处理节点，将源数据格式，转换成另一种数据格式，比如修改编码、修改采样率等。


## AudioUnit的描述
不同的AudioUnit要如何区别或者说怎样表示呢？AudioUnit提供了"AudioComponentDescription"对象来描述一个具体的AudioUnit:

	typedef struct AudioComponentDescription {
	    OSType              componentType;
	    OSType              componentSubType;
	    OSType              componentManufacturer;
	    UInt32              componentFlags;
	    UInt32              componentFlagsMask;
	} AudioComponentDescription;
	
其中“componentType”和“componentSubType”表示了这个Unit是上面描述的那种类型。前者表示四大类，后者表示所述子类细分。“componentManufacturer”目前对于iOS就只有一个值：`kAudioUnitManufacturer_Apple `。而“componentFlags”和“componentFlagsMask”一般可以忽略给0就可以了。所以基本上就是用三个值类确定一个类型，而Apple官方文档中的
[Identifier Key](https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/UsingSpecificAudioUnits/UsingSpecificAudioUnits.html#//apple_ref/doc/uid/TP40009492-CH17-SW14)表格列出了每个种类个的值。

类别 | componentType | componentSubType | componentManufacturer
---|---|---|---
均衡器| kAudioUnitType_Effect  | kAudioUnitSubType_AUiPodEQ  | kAudioUnitManufacturer_Apple
3D 混音| kAudioUnitType_Mixer |  kAudioUnitSubType_AU3DMixerEmbedded  | kAudioUnitManufacturer_Apple
多路混音 | kAudioUnitType_Mixer  | kAudioUnitSubType_MultiChannelMixer  | kAudioUnitManufacturer_Apple
远端输入输出 | kAudioUnitType_Output |  kAudioUnitSubType_RemoteIO  | kAudioUnitManufacturer_Apple
VoIP 输入输出 | kAudioUnitType_Output  | kAudioUnitSubType_VoiceProcessingIO |  kAudioUnitManufacturer_Apple
通用输出 | kAudioUnitType_Output |  kAudioUnitSubType_GenericOutput |  kAudioUnitManufacturer_Apple
格式转换 | kAudioUnitType_FormatConverter |  kAudioUnitSubType_AUConverter |  kAudioUnitManufacturer_Apple

## AudioUnit的操作
前面说过了。AudioUnit单独是无法工作的，需要组建一个“Audio Unit Graph”，所以对AudioUnit的操作，基本通过“[Audio Unit Processing Graph Services](https://developer.apple.com/reference/audiotoolbox/1669790-audio_unit_processing_graph_serv)”接口就可以完成了，当如如果需要特殊的对某个Unit的修改，还可以用“[Audio Unit Component Services](https://developer.apple.com/reference/audiounit/1653800-audio_unit_component_services?language=objc)”进行设置。而AudioUnit的创建、打开和关闭则是通过“[Audio Component Services](https://developer.apple.com/reference/audiounit/1653552-audio_component_services?language=objc)”

### 单独创建AudioUnit

### 通过AUGraph创建AudioUnit

## AudioUnit的结构

## AUGraph管理器


## 参考
1. [Audio Unit Hosting Guide for iOS](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/Introduction/Introduction.html)
2. [Audio Unit Programming Guide](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitProgrammingGuide/AudioUnitDevelopmentFundamentals/AudioUnitDevelopmentFundamentals.html#//apple_ref/doc/uid/TP40003278-CH7-SW5)