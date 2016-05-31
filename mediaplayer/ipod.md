# 获取iPod资源信息
要想获取手机中已经存在的歌曲或者其他如录音音频数据，可以通过MediaPlayer工具。MediaPalyer不仅可以获取音频还可以获取视频信息。不过这里的音视频只能是iPod中可以访问的数据，也就是系统应用“音乐”中的数据。

MediaPlayer提供了两种获取音乐数据文件的方式：

![ipod_two_methods](./images/ipod_two_methods.png)

如图，应用App通过MediaPlayer接口可以走左边的线路（Media Picker）提供的一个音乐选择文件界面选择需要的音乐；也可以通过右边线路（Media Query）罗列并查询具体文件列表的方式获取需要的文件信息。

在获得语音文件后就可以交由其他播放工具比如MediaPlayer进行播放了。