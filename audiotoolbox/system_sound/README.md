# 4.4 系统音播放
有的时候在App的使用中，我们只是想给用户一个提示，比如微信消息来了，滴一下；用户收到好友邀请了，震动一下。拿微信消息这个场景举例子就很直观了。对于这样的场景，Apple提供了更简洁的接口给开发者来使用，而不用那些复杂的播放音乐媒体的操作。

## 一键播放提示音
先看一个例子，在界面上增加一个按钮，并绑定按钮的点击事件到下面的逻辑：

    NSURL *furl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"alert" ofType:@"wav"]];

    OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(furl), &ssfd_);
    VStatus(status, @"AudioServicesCreateSystemSoundID Error");
    AudioServicesPlayAlertSound(ssfd_);


这里VStatus是定义的一个检查OSStatus返回值的宏。这里仅仅是简单判断了`kAudioServicesNoError`
	
	#define VErr(err, msg)  do {\
                            if(kAudioServicesNoError != err) {\
                                NSLog(@"[ERR]:%@--%@", (msg), [err localizedDescription]);\
                                return ;\
                            }\
                        } while(0)

更多的返回值参考[System Sound Services Reference](https://developer.apple.com/library/mac/documentation/AudioToolbox/Reference/SystemSoundServicesReference/index.html#//apple_ref/c/func/AudioServicesPlaySystemSound)

	kAudioServicesNoError
	kAudioServicesUnsupportedPropertyError
	kAudioServicesBadPropertySizeError
	kAudioServicesBadSpecifierSizeError
	kAudioServicesSystemSoundUnspecifiedError
	kAudioServicesSystemSoundClientTimedOutError
	
Demo参考[GitHub]()	
	
##  System Sound Services提供的接口
### 基本使用
在上面的例子中，我们使用了

	void AudioServicesPlayAlertSound ( SystemSoundID inSystemSoundID )
来播放一段告警音。其参数是`SystemSoundID inSystemSoundID`我们可以将他想象成"fwrite"中的"FILE *"。那类似的也应该会有一个“fopen” ，这里是
	
	OSStatus AudioServicesCreateSystemSoundID ( CFURLRef inFileURL, SystemSoundID *outSystemSoundID )
需要给一个“CFURLRef”类型的inFileURL表示文件的路径，输出的文件句柄在“SystemSoundID *”的outSystemSoundID中。返回值参见上面的错误码。

函数参数很容易理解，就是传入一个路径得到一个文件句柄。不过这里需要注意的是

1. 文件路径是"file://"打头的标准文件路径，比如用NSBundle获得的路径，而不是"/var/xxx"这样的绝对路径，比如用Document拼接的路径。
2. 文件格式只能是PCM数据的.caf，.aif或者.wav文件，不能是mp3文件，否则会出现"-1500"错误码
3. 文件中的音频数据只能小于30s，否则可能出现"-1500"错误码


创建了音频数据的文件句柄后，就可以调用上面的“AudioServicesPlayAlertSound”进行播放了，除了这个函数外还可以使用：

	void AudioServicesPlaySystemSound ( SystemSoundID inSystemSoundID );
	
来播放，二者基本没有区别。一个比较直接的区别是，如果用户将手机调成静音，前者会震动，后者不会。

其实到这里，“System Sound Services”的核心功能就没有了。就两个API，一个创建音频文件句柄，一个播放（有两个播放方式可以选择），这也就是为什么开始的时候说Apple为播放提示音提供了简单的接口，你不需要用AVAudioSession去设置播放模式，也不用响应静音中断来控制震动。两个接口就完成了功能。

### 回调和属性
当然强大的“System Sound Services”也提供了一些其他功能，比如要知道什么时候提示音播放完毕了，如果App被强退，声音是否继续播放（有这样的需求么？）。

	OSStatus AudioServicesAddSystemSoundCompletion ( SystemSoundID inSystemSoundID, CFRunLoopRef inRunLoop, CFStringRef inRunLoopMode, AudioServicesSystemSoundCompletionProc inCompletionRoutine, void *inClientData );
	
这个接口，为指定的文件句柄“inSystemSoundID”注册了一个回调函数，当声音播放完后进行回调。“inRunLoop”不用说，就是在哪个RunLoop里面进行回调，inRunLoopMode为对应的RunLoop的模式。回调的格式如下，“inClientData”会透传到回调中，比如传入self。

	typedef void (*AudioServicesSystemSoundCompletionProc) ( SystemSoundID ssID, void *clientData );

说白了就是一个传入音频文件句柄和自定义数据没有返回值的函数。当播放完后通过"ssID"指定句柄，“clientData”指定注册回调时的透传数据。比如：

	// callback defination
	void impAudioServicesSystemSoundCompletionProc ( SystemSoundID ssID, void *clientData )
	{
	    NSLog(@"self is %p", clientData);
	    NSLog(@"ssID is %d", ssID);
	}
	
	//...
	// regist callback
	status = AudioServicesAddSystemSoundCompletion(ssfd_, NULL, NULL, impAudioServicesSystemSoundCompletionProc, (__bridge void * _Nullable)(self));
	VStatus(status, @"AudioServicesAddSystemSoundCompletion");
	
除了回调，还可以通过属性设置控制下播放行为，比如上面的如果App被强退，声音是否继续播放。

	OSStatus AudioServicesSetProperty ( AudioServicesPropertyID inPropertyID, UInt32 inSpecifierSize, const void *inSpecifier, UInt32 inPropertyDataSize, const void *inPropertyData );
	
通过这个接口可以自定义属性，inPropertyID很显然就是指定属性。目前就两个属性可以自定义：

	enum {
	   kAudioServicesPropertyIsUISound                   = 'isui',
	   kAudioServicesPropertyCompletePlaybackIfAppDies   = 'ifdi'
	};

* kAudioServicesPropertyIsUISound表示当用户切换静音的时候跟着切换。这个默认是1.
* kAudioServicesPropertyCompletePlaybackIfAppDies 表示如果App被强退，声音是否继续播放，1为播放

这个接口比较有意思。一般设置是针对音频文件句柄的，给个句柄SystemSoundID就得了。但是他这里却是`
	UInt32 inSpecifierSize, const void *inSpecifier`,一个表示句柄对象长度，一个表示句柄地址，传递buffer的方式传进去。

而属性的值也是这样的方式`UInt32 inPropertyDataSize, const void *inPropertyData`分别是值类型的长度和指针。
连起来就是将inSpecifier这个对象上inPropertyID指定的属性设置成inPropertyData里面的值。如：

    SystemSoundID ssfd_;
    UInt32 isDie = 1;
    status = AudioServicesSetProperty(kAudioServicesPropertyCompletePlaybackIfAppDies,sizeof(ssfd_),&ssfd_,sizeof(isDie), &isDie);
	VStatus(status, @"AudioServicesCreateSystemSoundID Error");
	
## 总结
Apple为播放提示音提供了一套简介的接口，创建文件，然后播放，播放有两个接口，一个可以触发在静音状态下的震动。有了这个就可以完成基本的需求了。

如果还想知道提示音什么时间播放结束，还可以通过回调的方式获得通知，另外也可以设置属性自定义播放行为。

有点需要了解的时，播放都是异步的并且是可多次触发的。什么意思？比如间隔100ms调用Play，你会发现提示音被播了多次，且重叠在一起。蛮好玩的，这也验证了这个是系统的提供的"Services"，play只是提交任务给系统，由他来调度执行。

## 参考
1. [System Sound Services](https://developer.apple.com/reference/audiotoolbox/1657326-system_sound_services)
2. [OSStatus](https://www.osstatus.com/)
