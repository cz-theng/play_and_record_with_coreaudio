//
//  ViewController.m
//  AVAudioRecoderDemo
//
//  Created by apollo on 08/11/2016.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"
#import "MessageView.h"

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (strong, nonatomic) NSMutableArray *messages;
@property (strong, nonatomic) AVAudioRecorder *recorder;
@property (strong, nonatomic) AVAudioPlayer *player;
@property float msgHeight;
@end

@implementation ViewController

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

- (BOOL) preparePlayer: (NSURL *) fileName {
    NSError *error = nil;
//    NSString *docDir = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) firstObject];
//    NSString *localFile = [NSString stringWithFormat:@"%@/%@", docDir, fileName];
//    NSURL *fileURL = [NSURL URLWithString:localFile];
    _player = [[AVAudioPlayer alloc] initWithContentsOfURL:fileName error:&error];
    if (nil != error) {
        NSLog(@"create player[%@] error:%@", fileName, error.localizedDescription);
        return NO;
    }
    return YES;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    [self setAudioSession];
    // Do any additional setup after loading the view, typically from a nib.
    _messages = [[NSMutableArray alloc] init];
    _msgHeight = 30;
    
    [self updateMessages];
    
    
}

- (void) messageTouched:(id) sender {
    for (int i=0; i<_messages.count; i++) {
        if ([self preparePlayer:[_messages objectAtIndex:i]]) {
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
}

- (void) updateMessages {
    
    [self.scrollView layoutIfNeeded];
    [_scrollView setContentSize: CGSizeMake( _scrollView.frame.size.width, 1.5*_msgHeight * _messages.count)];
    _scrollView.scrollEnabled = YES;
    _scrollView.userInteractionEnabled = YES;
    _scrollView.bounces = YES;
    if (1.5*_msgHeight * _messages.count > _scrollView.frame.size.height) {
        [_scrollView setContentOffset:CGPointMake(0, 1.5*_msgHeight * _messages.count - _scrollView.frame.size.height)];
    }
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setAudioSession {
    AVAudioSessionCategoryOptionAllowBluetooth
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    

}

- (IBAction)onRecord:(id)sender {
    static BOOL clicked = NO;
    if (! clicked) {
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_open"] forState:UIControlStateNormal];
        NSString *fileName = [NSString stringWithFormat:@"voice_%ld.aac", time(NULL)];
        if ([self prepareRecorder:fileName]) {
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
            MessageView *v = [[MessageView alloc] initWithFrame:CGRectMake(20, _messages.count *1.5*_msgHeight, 100, _msgHeight)];
            v.duration = [_recorder currentTime] ;
            [_recorder stop];
            [_messages addObject:_recorder.url];

            [_scrollView addSubview:v];
            UITapGestureRecognizer * tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(messageTouched:)];
            [v addGestureRecognizer:tapGesture];
            v.userInteractionEnabled = YES;
            [tapGesture setNumberOfTapsRequired:1];
            
            [self updateMessages];
        }
        clicked = NO;
    }

}

#pragma mark AVAudioRecorderDelegate

- (void)audioRecorderDidFinishRecording:(AVAudioRecorder *)recorder successfully:(BOOL)flag {
    NSLog(@"audioRecorderDidFinishRecording");
}


- (void)audioRecorderEncodeErrorDidOccur:(AVAudioRecorder *)recorder error:(NSError * __nullable)error {
    NSLog(@"audioRecorderEncodeErrorDidOccur error:%@", error.localizedDescription);
}

@end
