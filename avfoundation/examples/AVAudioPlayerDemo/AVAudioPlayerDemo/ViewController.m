//
//  ViewController.m
//  AVAudioPlayerDemo
//
//  Created by apollo on 26/10/2016.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"
#import "MusicBarView.h"

@interface ViewController ()
@property (strong, nonatomic) MPMediaPickerController *mpPickerVC;
@property (weak, nonatomic) IBOutlet UIProgressView *progressBar;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UITextView *infoTV;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSURL *furl;
@property (strong, nonatomic) NSTimer *secondTimer;
@property (strong, nonatomic) NSTimer *millTimer;
@property BOOL isInitSound;
@property (weak, nonatomic) IBOutlet UILabel *startTimeLbl;
@property (weak, nonatomic) IBOutlet UILabel *totalTimeLbl;
@property (weak, nonatomic) IBOutlet MusicBarView *musicBarView;
@property float rate;
@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    _mpPickerVC = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    _mpPickerVC.allowsPickingMultipleItems = NO;
    _mpPickerVC.delegate = self;
    _player = [[AVAudioPlayer alloc] init];
    //_player.delegate = self;
    _secondTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(timerAction:) userInfo:nil repeats:YES];
    _millTimer =[NSTimer scheduledTimerWithTimeInterval:1.0/10 target:self selector:@selector(millTimerAction:) userInfo:nil repeats:YES];
    _isInitSound = NO;
    _rate = 1.0;
}

- (IBAction)onForward:(id)sender {
    static float step = 0.05;
    NSTimeInterval newCur = _player.currentTime + _player.duration*step;
    _player.currentTime = newCur;
}

- (IBAction)onBackward:(id)sender {
    static float step = 0.05;
    NSTimeInterval newCur = _player.currentTime - _player.duration*step;
    if (newCur<0) {
        newCur = 0;
    }
    _player.currentTime = newCur;
}

- (void) millTimerAction: (id) sender {
    if (nil != _player &&  _isInitSound) {
        if(_player.playing) {
            [_player updateMeters];
            [_musicBarView addValue: ([_player averagePowerForChannel:0]+160)/160/2];
            [_musicBarView updateUI];
        }
    }
}

- (void) timerAction: (id) sender {
    if (nil != _player &&  _isInitSound) {
        float rate = _player.currentTime/_player.duration;
        [_progressBar setProgress:rate];
        [_startTimeLbl setText: [NSString stringWithFormat:@"%02ld:%02ld",(long)_player.currentTime/60, ((long)_player.currentTime)%60 ]];
        NSLog(@"duration:%f, curr: %f, device: %f", _player.duration, _player.currentTime, _player.deviceCurrentTime);
        if(_player.playing) {
            [_player updateMeters];
            NSLog(@"volume %f", _player.volume);
            NSLog(@"pan %f", _player.pan);
            NSLog(@"channel 0 power:%f", ([_player averagePowerForChannel:0]+160)/160);
        }
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onDrawer:(id)sender {
    NSLog(@"onDrawer");
    [self presentViewController: _mpPickerVC animated:YES completion:^{
        NSLog(@"Show Music Picker!");
    }];
}

- (IBAction)onPlay:(id)sender {
    NSLog(@"onPlay");
    static BOOL once = NO;
    if (!once) {
        [_playBtn setImage:[UIImage imageNamed:@"btn_pause.png"] forState:UIControlStateNormal];
        once = YES;
        
        if (nil != _player && _isInitSound) {
            [_player play];
        }
    } else {
        [_playBtn setImage:[UIImage imageNamed:@"btn_play.png"] forState:UIControlStateNormal];
        once = NO;
        
        if (nil != _player && _isInitSound) {
            [_player pause];
        }
        [_musicBarView clear];
    }
}

#pragma mark MPMediaPickerControllerDelegate
- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    NSString *title;
    NSString *artist;
    NSString *content;


    for (MPMediaItem * item in [mediaItemCollection items]) {
        title =  [item valueForKey:MPMediaItemPropertyTitle];
        artist = [item valueForKey:MPMediaItemPropertyArtist];
        _furl = [item valueForKey:MPMediaItemPropertyAssetURL];
    }
    
    content = title;
    content = [content stringByAppendingFormat:@"\n %@", artist];
    NSError *error;
    if (nil != _furl) {
        _player = [_player initWithContentsOfURL:_furl error:&error];
        [_player play];
        [_player pause];
        _player = [_player initWithContentsOfURL:_furl error:&error];
        if (nil != error) {
            NSLog(@"initWithContentsOfURL with error %@", error.localizedDescription);
            return ;
        }
        _isInitSound = YES;
        [_totalTimeLbl setText:[NSString stringWithFormat:@"%02ld:%02ld", (long)_player.duration/60, ((long)_player.duration)%60]];
        _player.delegate = self;
        _player.enableRate = YES;
        _player.meteringEnabled = YES;

    }    
    
    [_infoTV setText:content];
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"Successful pick and return ");
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    
    [mediaPicker dismissViewControllerAnimated:YES completion:^{
        NSLog(@"User cancel pick and return ");
    }];
}

#pragma mark  AVAudioPlayerDelegate
/* audioPlayerDidFinishPlaying:successfully: is called when a sound has finished playing. This method is NOT called if the player is stopped due to an interruption. */
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {

}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {

}
@end
