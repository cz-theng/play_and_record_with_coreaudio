/*******************************************************************************\
** AVAudioSessionDemo:RecorderViewController.m
** Created by CZ(cz.devnet@gmail.com) on 29/11/2016
**
**  Copyright © 2016 projm. All rights reserved.
\*******************************************************************************/


#import "RecorderViewController.h"

@interface RecorderViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;
@property (strong, nonatomic) NSString *fileName;
@end

@implementation RecorderViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    self.tabBarItem.title = @"Recorder";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}
- (IBAction)onPlay:(id)sender {
    if ([self preparePlayer: _fileName]) {
        NSLog(@"total length %g", [_player duration]);
        NSError *error = nil;
        [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&error];
        if (nil != error) {
            NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayback) error:%@", error.localizedDescription);
            return;
        }
        [_player play];
    }
}

- (IBAction)onRecord:(id)sender {
    [[AVAudioSession sharedInstance] requestRecordPermission:^(BOOL granted) {
        if (granted) {
            NSLog(@"Microphone is available!");
        } else {
            NSLog(@"Microphone is not  available!");
            return ;
        }
    }];
    
    static BOOL clicked = NO;
    if (! clicked) {
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_open"] forState:UIControlStateNormal];
        _fileName = [NSString stringWithFormat:@"voice_%ld.aac", time(NULL)];
        if ([self prepareRecorder:_fileName]) {
            if (nil!=_recorder) {
                NSError *error = nil;
                [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayAndRecord error:&error];
                if (nil != error) {
                    NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
                    return;
                }
                if ([_recorder record]) {
                    NSLog(@"start recording...");
                } else {
                    NSLog(@"record error!");
                }
            }
        }
        clicked = YES;
    } else {
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_closed"] forState:UIControlStateNormal];
        if (nil != _recorder) {
            [_recorder stop];
        }
        clicked = NO;
    }

}

- (void) setAudioSession {
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    
}

- (BOOL) prepareRecorder:(NSString *) fileName {
    NSError *error = nil;
    NSDictionary *setting = @{  AVFormatIDKey:[NSNumber numberWithInt: kAudioFormatMPEG4AAC] // aac format
                                ,AVSampleRateKey:[NSNumber numberWithInt:44100] // 44.k sample rate
                                ,AVNumberOfChannelsKey:[NSNumber numberWithInt:2] // double channel
                                ,AVLinearPCMBitDepthKey:[NSNumber numberWithInt:16] // bit depth
                                };
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *localFile = [NSString stringWithFormat:@"%@/%@", docDir, fileName];
    NSURL *fileURL = [NSURL URLWithString:localFile];
    _recorder = [[AVAudioRecorder alloc] initWithURL:fileURL settings:setting error:&error];
    if (nil != error) {
        NSLog(@"create recorder for[%@] error: %@", fileName, error.localizedDescription);
        return NO;
    }
    
    _recorder.delegate = self;
    return YES;
    
}

- (BOOL) preparePlayer: (NSString *) fileName {
    NSError *error = nil;
    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
    NSString *localFile = [NSString stringWithFormat:@"%@/%@", docDir, fileName];
    NSURL *fileURL = [NSURL URLWithString:localFile];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileURL error:&error];
    if (nil != error) {
        NSLog(@"create player[%@] error:%@", fileName, error.localizedDescription);
        return NO;
    }
    return YES;
}

#pragma mark AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"audioRecorderDidFinishRecording");
}


- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    NSLog(@"audioRecorderEncodeErrorDidOccur error:%@", error.localizedDescription);
}


@end
