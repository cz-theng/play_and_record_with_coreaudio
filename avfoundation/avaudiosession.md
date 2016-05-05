# 使用AVAudioSession管理上下文
虽然标题中说是控制音频表现，其实并不是说控制音频的混响、均衡器等影响声音的属性，而是说在使用CoreAudio进行音频播放和录制时表现的控制，比如
插拔耳机、接电话、是否和其他音频数据混音等。其实Audio Session的主要功能也就是这些控制:

* 是进行录音还是播放？
* 当系统静音键按下时该如何表现？
* 是从扬声器还是从听筒里面播放声音？
* 插拔耳机后如何表现？
* 来电话/闹钟响了后如何表现？
* 其他音频App启动后如何表现？
* ...

## 1.Hello World


## 2. Category

## 3. Interruption

## 4. Route Changes

## 总结：

## 参考文档
1. [Audio Session Programming Guide](https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007875-CH1-SW1)