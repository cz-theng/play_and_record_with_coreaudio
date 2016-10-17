# 使用AVAudioSession管理上下文
音频输出作为硬件资源，对于iOS系统来说是唯一的，那么要如何协调和各个App之间对这个稀缺的硬件持有关系呢？

iOS给出的解决方案是"AVAudioSession" ，通过它可以实现对App当前上下文音频资源的控制，比如
插拔耳机、接电话、是否和其他音频数据混音等。当你遇到:

* 是进行录音还是播放？
* 当系统静音键按下时该如何表现？
* 是从扬声器还是从听筒里面播放声音？
* 插拔耳机后如何表现？
* 来电话/闹钟响了后如何表现？
* 其他音频App启动后如何表现？
* ...

这些场景的时候，就可以考虑一下“AVAudioSession”了。

在很久以前（其实也是不是太久--iOS7以前）还有个[AudioSession](https://developer.apple.com/library/ios/documentation/AudioToolbox/Reference/AudioSessionServicesReference/)的存在，其功能与AVAudioSession类似，但是在iOS7以后就已经被标记为
“Not Applicable”,所以如果Google到了说AudioSession的内容而不是用的AVAudioSession，那么就可以直接PASS了，当然如果要兼容iOS6
就另当别论了，不过现在QQ/微信都是要求iOS7的情况下，是否需要兼容iOS6就看老板们的意思吧。

## 1. Hello World

## 2. 激活与关闭

## 3. 申请录音权限

## 2. Category
总共有7种

注意事项：

* VoIP
* Recording 模式

## 选择最好的Category

## Mode
也是有7种

## 获取系统的硬件参数

## 3. Interruption

## 4. Route Changes's Notification

## 5. 默认的表现
如非必要，不要让App处于默认的Audio Session控制的情况下。

* 播放和录音
* 静音键
* 锁屏
* 其他音乐App的影响


## 总结：

## 参考文档
1. [Audio Session Programming Guide](https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/Introduction/Introduction.html#//apple_ref/doc/uid/TP40007875-CH1-SW1)
2. [ Audio Session Services Reference](https://developer.apple.com/library/ios/documentation/AudioToolbox/Reference/AudioSessionServicesReference/)