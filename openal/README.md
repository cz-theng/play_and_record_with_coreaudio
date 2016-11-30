# 跨平台的OpenAL

Open Audio Library (OpenAL) 是既有的跨平台的音频API标准。通过他可以在游戏或者App实现高性能、高质量的音频输出。iOS按照OpenAL1.1标准基于“CoreAudio”的“3D Mixer audio unit”实现了一套提供了标准的OpenAL接口。通过这套标准接口，可以实现播放声音、混音、声源移动等诸多功能。最常见的就是通过这套接口实现游戏中的声音播放模块，这样同样的逻辑代码便可以在多个平台上使用了。

与MacOS上实现完整的OpenAL1.1标准（[OpenAL 1.1 Specification and Reference](https://www.openal.org/documentation/openal-1.1-specification.pdf)）不同，目前在iOS上，Apple提供的OpenAL1.1的实现仅支持播放音频([Playback with Positioning Using OpenAL](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/CoreAudioOverview/CoreAudioEssentials/CoreAudioEssentials.html))，暂不支持音频的采集。一般情况下，使用OpenAL主要还是使用期提供的音频特效，比如3D音、声源远近音等。所以最常见的场景还是游戏中，比如FPS中玩家远近的脚步声。

通过在Xcode中引入“OpenAL.framework”便可以集成OpenAL了，iOS的除了实现了OpenAL1.1，还提供了两个有用的扩展：

* alBufferDataStaticProcPtr ： 当使用alBufferData时，避免每次拷贝
* alcMacOSXMixerOutputRateProcPtr ：  控制混音器的采样率

所以，通过这两个辅助的扩展以及标准的[OpenAL1.1 API](https://www.openal.org/documentation/openal-1.1-specification.pdf) 按照[OpenAL 编程指引](https://www.openal.org/documentation/OpenAL_Programmers_Guide.pdf)中的使用，就可以实现对音频播放的特效操作了。

## 参考
1. [Core Audio Overview](https://developer.apple.com/library/content/documentation/MusicAudio/Conceptual/CoreAudioOverview/CoreAudioEssentials/CoreAudioEssentials.html)
2. [OpenAL_Programmers_Guide](https://www.openal.org/documentation/OpenAL_Programmers_Guide.pdf) 
3. [OpenAL 1.1 Specification and Reference](https://www.openal.org/documentation/openal-1.1-specification.pdf)