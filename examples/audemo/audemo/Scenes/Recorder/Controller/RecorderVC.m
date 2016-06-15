/*******************************************************************************\
** audemo:RecorderVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/5/28
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import "RecorderVC.h"

#include <time.h>

#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>
#import <AVFoundation/AVFoundation.h>

#define VErr(err, msg)  do {\
                            if(nil != err) {\
                                    NSLog(@"[ERR]:%@--%@", (msg), [err localizedDescription]);\
                                    return ;\
                            }\
                         } while(0)

#define VStatus(err, msg) do {\
                             if(noErr != err) {\
                               NSLog(@"[ERR]:%@", (msg));\
                               return ;\
                             }\
                          } while(0)

@interface RecorderVC () {
    AudioUnit *covertUnit_;
    AudioUnit *ioUnit_;
    AUNode *coverNode_;
    AUNode *ioNode_;
    AUGraph auGraph_;
}

@end

@implementation RecorderVC

- (void) initAUGraph {
    NewAUGraph(&auGraph_);
    
    AudioComponentDescription ioDesc;
    AudioComponentDescription covertDesc;
    
    ioDesc.componentType = kAudioUnitType_Output;
    ioDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    ioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDesc.componentFlags = ioDesc.componentFlagsMask = 0;
    
    covertDesc.componentType = kAudioUnitType_FormatConverter;
    covertDesc.componentSubType = kAudioUnitSubType_AUConverter;
    ioDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    ioDesc.componentFlags = ioDesc.componentFlagsMask = 0;
    
    OSStatus status;
    status = AUGraphAddNode(auGraph_, &covertDesc, coverNode_);
    VStatus(status, @"AUGraphAddNode covertDesc");
    status = AUGraphAddNode(auGraph_, &ioDesc, ioNode_);
    VStatus(status, @"AUGraphAddNode ioDesc");
    
    status = AUGraphOpen(auGraph_);
    VStatus(status, @"AUGraphOpen");
}

- (void) initAVAudioSession {
    NSError *asError = nil;
    AVAudioSession *as = [AVAudioSession sharedInstance];
    [as setPreferredSampleRate:44100 error:&asError];
    VErr(asError, @"setPreferredSampleRate");
    
    [as setCategory:AVAudioSessionCategoryPlayback error: &asError];
    VErr(asError, @"setCategory:AVAudioSessionCategoryPlayback");
    
    [as setActive:YES error:&asError];
    VErr(asError, @"setActive:YES");
}

- (void)viewDidLoad {
    [super viewDidLoad];

}

- (instancetype)initWithCoder:(NSCoder *)aDecoder  {
    if ( self = [super initWithCoder:aDecoder]) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"录音笔" image:[UIImage imageNamed:@"offline_tab_message"] selectedImage:[UIImage imageNamed:@"offline_tab_message"]];
    }
    return  self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPlay:(id)sender {
    struct timespec now;
    clock_gettime(CLOCK_MONOTONIC, &now);
    
}

- (IBAction)onStop:(id)sender {

}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
