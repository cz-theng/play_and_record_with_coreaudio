//
//  ViewController.m
//  AudioQueueRecorderDemo
//
//  Created by apollo on 14/12/2016.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"


#define VErr(err, msg)  do {\
    if(nil != err) {\
        NSLog(@"[ERR]:%@--%@", (msg), [err localizedDescription]);\
        return ;\
    }\
} while(0)

#define VStatus(err, msg) do {\
    if(noErr != err) {\
        NSLog(@"[ERR-%d]:%@", err, (msg));\
        return ;\
    }\
} while(0)

#define VStatusBOOL(err, msg) do {\
    if(noErr != err) {\
        NSLog(@"[ERR-%d]:%@", err, (msg));\
        return NO;\
    }\
} while(0)

@interface ViewController ()
@property (weak, nonatomic) IBOutlet UIButton *recordBtn;
@property (weak, nonatomic) IBOutlet UIButton *prepareBtn;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) setAudioSession: (int) mode {
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    
    error = nil;
    NSString *category;
    if (1 == mode) {
        category = AVAudioSessionCategoryRecord;
    } else {
        category = AVAudioSessionCategoryAmbient;
    }
    
    [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryRecord error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    }
}


- (BOOL) prepareAudioRecorder {

    return YES;
}

- (BOOL) disposeAudioRecorder {
    return YES;
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPrepare:(id)sender {
    static BOOL once = NO;
    if (! once ) {
        if (![self prepareAudioRecorder]) {
            NSLog(@"prepare Audio Recorder Error");
            return ;
        }
        
        [_prepareBtn setTitle:@"Dispose" forState:UIControlStateNormal];
        once = YES;
    } else {
        if(![self disposeAudioRecorder]) {
            NSLog(@"dispose Audio Recoder Error");
            return ;
        }
        
        [_prepareBtn setTitle:@"Prepare" forState:UIControlStateNormal];
        once = NO;
    }
}

- (void) startRecord {
    [self setAudioSession:1];
}

- (void) stopRecord {
    [self setAudioSession:2];
}

- (IBAction)onPlay:(id)sender {
    [self setAudioSession:2];
}

- (IBAction)onRecord:(id)sender {
    static BOOL once = NO;
    if (! once ) {
        [self startRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_closed"] forState:UIControlStateNormal];
        once = YES;
    } else {
        [self stopRecord];
        [_recordBtn setImage:[UIImage imageNamed:@"btn_microphone_open"] forState:UIControlStateNormal];
        once = NO;
    }
}

@end
