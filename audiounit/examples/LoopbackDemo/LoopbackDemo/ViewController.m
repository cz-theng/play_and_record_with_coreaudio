//
//  ViewController.m
//  LoopbackDemo
//
//  Created by CZ on 12/23/16.
//  Copyright © 2016 projm. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController {
    AUGraph _processingGraph;
    AUNode _micNode;
    AUNode _speakerNode;
    AudioUnit _micUnit;
    AudioUnit _speakerUnit;
    AudioComponentDescription _micDesc;
    AudioComponentDescription _speakerDesc;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    [self setupAudioSession];
}




- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void) setupAudioSession{
    NSError *error;
    AVAudioSession *session = [AVAudioSession sharedInstance];
    
    [session setActive:YES error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setActive error:%@", error.localizedDescription);
        return;
    }
    
    error = nil;
    NSString *category = AVAudioSessionCategoryPlayAndRecord;
    
    [[AVAudioSession sharedInstance] setCategory:category error:&error];
    if (nil != error) {
        NSLog(@"AudioSession setCategory(AVAudioSessionCategoryPlayAndRecord) error:%@", error.localizedDescription);
        return;
    } else {
        NSLog(@"set category to %@", category);
    }
}


- (void) buildAUGraph {
    NewAUGraph (&_processingGraph);
    _micDesc.componentType = kAudioUnitType_Output;
    _micDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    _micDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _micDesc.componentFlags = _micDesc.componentFlagsMask = 0;
    
    _speakerDesc.componentType = kAudioUnitType_Output;
    _speakerDesc.componentSubType = kAudioUnitSubType_RemoteIO;
    _speakerDesc.componentManufacturer = kAudioUnitManufacturer_Apple;
    _speakerDesc.componentFlags = _speakerDesc.componentFlagsMask = 0;
    
    
    AUGraphAddNode(_processingGraph, &_micDesc, &_micNode);
    AUGraphAddNode(_processingGraph, &_speakerDesc, &_speakerNode);
    
    AUGraphOpen (_processingGraph);
    
    AUGraphNodeInfo (_processingGraph, _micNode, &_micDesc, &_micUnit);
    AUGraphNodeInfo (_processingGraph, _speakerNode, &_speakerDesc, &_speakerUnit);
}




- (IBAction)onRecord:(id)sender {
    
}

- (IBAction)onPlayer:(id)sender {
    
}

@end
