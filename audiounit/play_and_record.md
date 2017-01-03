# 本地回环Demo
前面说了那么多理论知识和接口说明，实在太枯燥了。这里我们来看一个本地回环Demo，效果如下图：

![loopback_demo](./images/loopback_demo.png)

在Demo中点击麦克风按钮，Demo就开始打开麦克风开始采集，而点击扬声器则会打开扬声器开始播放刚刚采集的声音，效果就跟TOM猫类似。

实现步骤如下：

1. 配置AudioSession， 和其他使用功能一样，需要用AudioSession配置录音和播放环境
2. 使用AudioStreamBasicDescription配置AudioComponentDescription
3. 创建AUGraph并添加节点
4. 获取AUGraph中的节点并进行配置。
5. 连接各个节点
6. 控制AUGraph开启和停止


## 构建AUGraph
在使用AudioUnit前，需要根据需求设计好处理的图。也就是AUGraph，这里我们主要需要一个采集节点，一个播放节点，然后串起来，采集节点的输出连接到播放节点的输入节点。如下图：

![loopback_graph](./images/loopback_graph.png)

首先创建AUGraph，然后增加一个RemoteIO节点，输入域的输入从系统麦克风获取数据，而输出域的输出输出到系统的扬声器进行播放:

	- (void) buildAUGraph {
	    OSStatus stts;
	    NewAUGraph (&_processingGraph);
	    VStatus(stts, @"NewAUGraph Error!");
	    _remoteIODesc.componentType = kAudioUnitType_Output;
	    _remoteIODesc.componentSubType = kAudioUnitSubType_RemoteIO;
	    _remoteIODesc.componentManufacturer = kAudioUnitManufacturer_Apple;
	    _remoteIODesc.componentFlags = _remoteIODesc.componentFlagsMask = 0;
	    
	    
	    stts = AUGraphAddNode(_processingGraph, &_remoteIODesc, &_remoteIONode);
	    VStatus(stts, @"Add Node Error!");
	    stts = AUGraphOpen (_processingGraph);
	    VStatus(stts, @"Open Graph Error!");
	    stts = AUGraphNodeInfo (_processingGraph, _remoteIONode, NULL, &_remoteIOUnit);
	    VStatus(stts, @"Get Node Info Error!");
	    
	    UInt32 one = 1;
	    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Input, 1, &one, sizeof(one));
	    VStatus(stts, @"could not enable input on AURemoteIO");
	    stts = AudioUnitSetProperty(_remoteIOUnit, kAudioOutputUnitProperty_EnableIO, kAudioUnitScope_Output, 0, &one, sizeof(one));
	    VStatus(stts, @"could not enable output on AURemoteIO");    
	}
    
这里的函数在签名都有介绍，这里就不在赘述了。这里还要获取每个Node并设置其属性。

在这个例子中我们，主要使用“Remote I/O unit”或者替换成“Voice-Processing I/O Unit”主要可以进行回声消除，防止啸叫产生。

默认情况下“Remote I/O unit”的输入是关闭的，而输出则是打开的。这里我们要采集音频，所以需要把麦克风节点的输入打开。这里RemoteIO Unit有两个Element中，
* “1”：表示麦克风，所以其输入为麦克风，输出为数据
* “0”：表示扬声器，所以其输入为数据，而输出则为扬声器喇叭

所以这里，我们显示的将两个Element的对应的输入和输出，也就是“1”麦克风的输入和“0”扬声器的输出分别都设成正"one"表示的打开状态。

另外每个节点还需要设置输入和输出域的用数据格式。下面再上门的函数中再增加设置输入输出端的数据格式：

	struct AudioStreamBasicDescription inFmt;
	inFmt.mFormatID = kAudioFormatLinearPCM; // pcm data
	inFmt.mBitsPerChannel = 16; // 16bit
	inFmt.mChannelsPerFrame = 2; // double channel
	inFmt.mSampleRate = 44100; // 44.1kbps sample rate
	inFmt.mFramesPerPacket =1 ;
	inFmt.mBytesPerFrame =inFmt.mBitsPerChannel*inFmt.mChannelsPerFrame/8;
	inFmt.mBytesPerPacket = inFmt.mBytesPerFrame * inFmt.mFramesPerPacket;
	stts = AudioUnitSetProperty(_remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 0, &inFmt, sizeof(inFmt));
	VStatus(stts, @"set kAudioUnitProperty_StreamFormat of input error");
	    
	struct AudioStreamBasicDescription outFmt = inFmt;
	stts = AudioUnitSetProperty(_remoteIOUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 0, &outFmt, sizeof(outFmt));
	VStatus(stts, @"set kAudioUnitProperty_StreamFormat of output error");
	
这里接着将Element 1 麦克风的输出数据设置成44.1K的PCM数据而Element 0扬声器的输入设置成同样的格式。	






## 实现回调


## 连接节点


## 总结
这里我们通过构建一个Demo来模拟了如何使用AudioUnit进行采集和播放，在使用之前需要根据场景设计一个使用图，可以参考[Audio Unit Hosting Guide for iOS](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html#//apple_ref/doc/uid/TP40009492-CH16-SW1)中开始的三种模式，一般就是既有采集又有播放的如我们的Demo；或者只有播放的比如一个MP3播放器，后面我们会介绍；又或者可以收集各种乐器的MIDI应用。设计好了数据流图后就可以开始构建图了，并设置好各个节点的属性以及回调函数。

## 参考

1. [Audio Unit Hosting Guide for iOS](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/ConstructingAudioUnitApps/ConstructingAudioUnitApps.html#//apple_ref/doc/uid/TP40009492-CH16-SW1)
2. [Audio Component Services](https://developer.apple.com/reference/audiounit/1653552-audio_component_services)
3. [Audio Unit Component Services](https://developer.apple.com/reference/audiounit/1653800-audio_unit_component_services)
4. [Output Audio Unit Services](https://developer.apple.com/reference/audiounit/1651082-output_audio_unit_services)

	
	


