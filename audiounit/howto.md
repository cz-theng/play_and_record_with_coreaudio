# Audio Unit模式

## 创建AuidoUnit
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

这里主要分成四类Unit
* 均衡器： 和iPod内置App一样的均衡器效果调节
* 混音： 支持3D混音和多路混音，比如混合一路背景音
* 输入输出： 输入输出包括了同时支持录音和播放的输入输出、用于VoIP模式的输入输出以及普通是输出（播放）
* 格式转换： iOS提供了一些内置格式的支持，可以进行互相转换，

Unit的类型通过[Identifier Key](https://developer.apple.com/library/ios/documentation/MusicAudio/Conceptual/AudioUnitHostingGuide_iOS/UsingSpecificAudioUnits/UsingSpecificAudioUnits.html#//apple_ref/doc/uid/TP40009492-CH17-SW14)来指定。
