# 使用AVAudioPlayer播放音频
AVAudioPlayer可以对音频文件或者音频NSData数据进行播放，通常适用于IO延时较低的场景，比如来自网络上的音频流数据。并可以对播放进度进行控制，同时还可以
获得音频数据播放时的音量/能量大小等信息，从而可以绘制波形图进行展示。
##1. Hello World
先看一个例子，点击"Play"播放[Jason Chen](https://www.youtube.com/channel/UCoLmFHomrdplbGMj22ixdkA)翻唱的小幸运。“Play”变成“Stop”，点击“Stop”，停止播放。

	@interface ViewController ()
	@property (weak, nonatomic) IBOutlet UIButton *playBtn;
	@property (nonatomic, strong) AVAudioPlayer *player;
	@end
	
	@implementation ViewController
	
	- (void)viewDidLoad {
	    [super viewDidLoad];
	    // Do any additional setup after loading the view, typically from a nib.
	    
	    [self initPlayer];
	}
	
	- (void) initPlayer {
	    NSError *error;
	    NSString *soundPath = [[NSBundle mainBundle] pathForResource:@"xiao_xing_yun" ofType:@"mp3"];
	    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:[NSURL URLWithString:soundPath] error:&error];
	    if (error != nil ) {
	        NSLog(@"init avaudioplayer error!");
	        return;
	    }
	}
	
	- (void)didReceiveMemoryWarning {
	    [super didReceiveMemoryWarning];
	    // Dispose of any resources that can be recreated.
	}
	- (IBAction)onPlayClick:(id)sender {
	    static BOOL clicked = NO;
	    if (!clicked) {
	        clicked = YES;
	        [_playBtn setTitle:@"Stop" forState:UIControlStateNormal];
	        [_player play];
	    } else {
	        clicked = NO;
	        [_playBtn setTitle:@"Play" forState:UIControlStateNormal];
	        [_player stop];
	    }
	}
	
	@end


##2. 获取播放信息
如果运行上面的程序，会发现，当点击"Play"的时候能正常播放音乐，当点击"Stop"的时候也能正常停止。但是当再次点击“Play”的时候，会发现它不是从头开始播放
，而是接着上次停止的位置。这里Stop虽然会接触player的perepare to play的状态，但是他并不会将`currentTime`清零。`currentTime`是什么呢？就是
音频数据到现在播放了的播放时间，比如一般MP3播放上面显示的总时间和当前播放时间，这个就是后者的当前播放时间。与之对应的还有个`deviceCurrentTime`
，这个时间指的是从_player 创建之后的时间，不论是否调用了`stop`或者`pause`其都会增长。这个时间主要用来做多个player之间的时间同步。这个后面会介绍到。这里说到了`pause`,上面的例子中也可以吧`stop`替换成`pause`,只是`pause`不会接触prepare to play的状态，同样也会记录当前的播放时间位置，不会从头开始播放。

处理启停控制之外，还有音量、通道、时间等常用属性


属性|类型|作用
---|---|---
playing| BOOL| 是否在播放音频
volume|float| 音量大小，范围[0.0, 1.0]是一个比例范围0表示静音
pan| float| 立体音位置，-1.0表示完全的左声道，0.0表示正中间，1.0表示完全的右声道
enableRate|BOOL| 是否允许调整播放速率
rate| float| 播放速率，1.0表示正常速度，0.5表示减半速度播放，2.0表示加速一倍播放，需要打开enalbeRate开关
numberOfLoops|NSInteger|播放的循环次数，0（默认）表示不循还，只播放一次，负数表示无限循环，正数表示循环几次，比1会播放两次（一次原本的，一次循环的）

numberOfChannels|NSUInteger(readonly)| 通道数
channelAssignments |NSArray<NSNumber *>*| 一个数组，每个成员表示每个通道的描述 AVAudioSessionChannelDescription
duration|NSTimeInterval(readonly)| 音频文件持续的时长（单位是秒）
currentTime|NSTimeInterval| 当前播放时长，比如MP3上显示的进度
meteringEnabled| BOOL | 是否开启能量统计的开关

另外还有几个Get函数


函数原型|作用
---|---
(float)averagePowerForChannel:(NSUInteger)channelNumber|所指通道上的平均能量值，需要配合meteringEnabled使用
(float)peakPowerForChannel:(NSUInteger)channelNumber| 所指通道上当前的能量峰值， 需要配合meteringEnabled使用



##3. 还保留的Delegate

对于异步执行的API，Apple一般都会提供一个Delegate来做消息通知。比如这里的AVAudioPlayer，播放的过程是异步的，因此播放结束的时候就会通过Delegate（AVAudioPlayerDelegate）给一个事件通知。

在最原始的版本中，AVAudioPlayerDelegate总共有6个回调，在iOS6.0中废弃掉两个，然后在iOS8.0又废掉两个。马上iOS 10就要出来，距离不用兼容iOS7的日子估计也不远了（LinkedIn现在(20160501)就要求iOS8.0以上了），因此只需要关注这最后存活下来的回调即可

### 成功播放完成后
`- audioPlayerDidFinishPlaying:successfully:` 当音频数据被完完整整播放完时回调，这里注意是播放完，类似中断触发、Pause都不算是播放完音频数据。其主要有两个参数提示状态：

* player： 播放的AVAudioPlayer，表示是哪个播放器触发的
* flat: 一个BOOL值，如果系统正常播放完成，则为YES，如果是系统错误导致的停止，比如解码出错，则为NO.

通过这个回调，我们可以处理，播放器结束时的动作，比如一个MP3播放器，当播放完一首歌的时候，就会触发这个回调，然后再操作其去播放下一首歌。

### 当播放过程中出错时
`- audioPlayerDecodeErrorDidOccur:error:` 当在播放音频数据的过程中，出现错误时被回调。同样也有两个参数：

* player： 播放的AVAudioPlayer，表示是哪个播放器触发的
* error : 错误内容，主要是解码错误

通过这个回调，我们可以对解码错误做一些处理，比如停止播放或者提示用户。

在以前的版本中被抛弃的回调接口，主要是控制播放器在播放的过程中收到中断（比如Home键、锁屏键、静音键）以及输入、输出设备的改变（插入耳机）。现在没有了这些回调，则通过AVSession来捕获控制。

##4. 配合AVSession进行播放控制
正常使用AVAudioPlayer的时候，对于系统的响应是符合正常使用场景的：

* 当按下Home键切换App或者来电话甚至锁屏的时候，会暂停音乐的播放，当切换回来的时候，会自动继续播放。
* 当切换静音键到静音状态时，播放也会被静音。
* 当插入耳机的时候，播放的声音会自动从耳机中播放出来

但如果不希望其按照默认的方式表现的话，改怎么办呢？比如锁屏后还希望音乐继续播放！

此时就需要通过AVSession来控制收到中断以及改变输入/输出时的表现了。通过订阅AVSession的`AVAudioSessionInterruptionNotification`来判断中断了还是恢复了，通过订阅`AVAudioSessionRouteChangeNotification`来监控是否有耳机插入等

*AVAudioSessionInterruptionNotification： 
	当中断时，userInfo中会有“ AVAudioSessionInterruptionTypeBegan” 这个成员，如果是恢复回来，则是"AVAudioSessionInterruptionTypeEnded"

* AVAudioSessionRouteChangeNotification ：
	userInfo中包括了“ AVAudioSessionRouteChangeReasonKey”改变原因和 “AVAudioSessionSilenceSecondaryAudioHintTypeKey”表示改变的目标。



##5. 总结
总的来说，使用AVAudioPlayer播放声音是App中首要的选择方案，比如背景音、试听等场景。其使用简单，基本功能都有，既可以播放本地文件，也可以播放从网络上下载到内存中的音频内容。当实际使用过程中AVAudioPlayer满足不了的时候（比如VoIP、流媒体），再去考虑其他解决方案。

##参考文档
1. [AVAudioPlayer Class Reference](https://developer.apple.com/library/ios/documentation/AVFoundation/Reference/AVAudioPlayerClassReference/#//apple_ref/occ/instm/AVAudioPlayer/updateMeters)
2. [Audio Session Programming Guide](https://developer.apple.com/library/ios/documentation/Audio/Conceptual/AudioSessionProgrammingGuide/HandlingAudioInterruptions/HandlingAudioInterruptions.html#//apple_ref/doc/uid/TP40007875-CH4-SW1)
3. [AVAudioSession Class Reference]()
