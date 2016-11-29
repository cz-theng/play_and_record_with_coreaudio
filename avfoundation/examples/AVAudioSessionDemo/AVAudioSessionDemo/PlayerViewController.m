/*******************************************************************************\
** AVAudioSessionDemo:PlayerViewController.m
** Created by CZ(cz.devnet@gmail.com) on 29/11/2016
**
**  Copyright © 2016 projm. All rights reserved.
\*******************************************************************************/


#import "PlayerViewController.h"

@interface PlayerViewController ()
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (strong, nonatomic) MPMediaPickerController *mpPickerVC;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSURL *furl;
@end

@implementation PlayerViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tabBarItem.title = @"Player";
    _mpPickerVC = [[MPMediaPickerController alloc] initWithMediaTypes:MPMediaTypeMusic];
    _mpPickerVC.allowsPickingMultipleItems = NO;
    _mpPickerVC.delegate = self;
    _player = [[AVAudioPlayer alloc] init];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPickMusic:(id)sender {
    NSLog(@"onPickMusic");
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
        
        NSLog(@"Current Category:%@", [AVAudioSession sharedInstance].category);
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (nil != error) {
            NSLog(@"set Category error %@", error.localizedDescription);
        }
        NSLog(@"Current Category:%@", [AVAudioSession sharedInstance].category);
        AVAudioSessionCategoryOptions options = [[AVAudioSession sharedInstance] categoryOptions];
        NSLog(@"Category[%@] has %lu options",  [AVAudioSession sharedInstance].category, options);
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback withOptions:AVAudioSessionCategoryOptionMixWithOthers error:&error];
        if (nil != error) {
            NSLog(@"set Option error %@", error.localizedDescription);
        }
        options = [[AVAudioSession sharedInstance] categoryOptions];
        NSLog(@"Category[%@] has %lu options",  [AVAudioSession sharedInstance].category, options);
        AVAudioSessionModeDefault
        if (nil != _player ) {
            [_player play];
        }
    } else {
        [_playBtn setImage:[UIImage imageNamed:@"btn_play.png"] forState:UIControlStateNormal];
        once = NO;
        
        if (nil != _player ) {
            [_player stop];
        }
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
        _player.delegate = self;
        _player.enableRate = YES;
        _player.meteringEnabled = YES;
        
    }
    
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
- (void)audioPlayerDidFinishPlaying:(AVAudioPlayer *)player successfully:(BOOL)flag {
    
}

/* if an error occurs while decoding it will be reported to the delegate. */
- (void)audioPlayerDecodeErrorDidOccur:(AVAudioPlayer *)player error:(NSError * __nullable)error {
    
}


@end
