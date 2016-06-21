# 4.4 系统音播放
有的时候在App的使用中，我们只是想给用户一个提示，比如微信消息来了，滴一下；用户收到好友邀请了，震动一下。拿微信消息这个场景举例子就很直观了。对于这样的场景，Apple提供了更简洁的接口给开发者来使用，而不用那些复杂的播放音乐媒体的操作。

##一键播放提示音
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
	
##  System Sound Services提供的接口

在上面的例子中，我们使用了`void AudioServicesPlayAlertSound ( SystemSoundID inSystemSoundID );
` 来播放一段告警音。其参数是`SystemSoundID inSystemSoundID`我们可以将他想象成。