/*******************************************************************************\
** ssdemo:PlayerVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/6/20
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import "PlayerVC.h"

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



void impAudioServicesSystemSoundCompletionProc ( SystemSoundID ssID, void *clientData )
{
    NSLog(@"self is %p", clientData);
    NSLog(@"ssID is %d", ssID);
}

@interface PlayerVC () {
    SystemSoundID ssfd_;
}
@property (strong, nonatomic) MPMediaPickerController * mpPickerVC;
@property (strong, nonatomic) NSURL *musicURL;
@end

@implementation PlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    
    _mpPickerVC = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    _mpPickerVC.prompt = @"请选择要读取的歌曲";
    _mpPickerVC.allowsPickingMultipleItems = NO;
    _mpPickerVC.showsCloudItems = NO;
    _mpPickerVC.delegate  = self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (IBAction)onPicker:(id)sender {
    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

- (IBAction)onPlay:(id)sender {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *path = [paths objectAtIndex:0];
    NSString *fpath = [NSString stringWithFormat:@"%@/%s", path, "13.wav"];
    NSURL *furl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"13" ofType:@"wav"]];
    //NSURL *furl = [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"e" ofType:@"mp3"]];
    //NSURL *furl = _musicURL;
    
    OSStatus status = AudioServicesCreateSystemSoundID((__bridge CFURLRef _Nonnull)(furl), &ssfd_);
    VStatus(status, @"AudioServicesCreateSystemSoundID Error");
    
    UInt32 isDie = 1;
    status = AudioServicesSetProperty(kAudioServicesPropertyCompletePlaybackIfAppDies,sizeof(ssfd_),&ssfd_,sizeof(isDie), &isDie);
    VStatus(status, @"AudioServicesSetProperty");
    NSLog(@"start play and self is %@", self);
    status = AudioServicesAddSystemSoundCompletion(ssfd_, NULL, NULL, impAudioServicesSystemSoundCompletionProc, (__bridge void * _Nullable)(self));
    VStatus(status, @"AudioServicesAddSystemSoundCompletion");
    AudioServicesPlayAlertSound(ssfd_);
    NSLog(@"after paly");
}

#pragma mark  MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    if (NULL == mediaItemCollection) {
        NSLog(@"mediaItemCollection is null");
        return ;
    }
    for (MPMediaItem *item in [mediaItemCollection items]) {
        if (NULL == item) {
            NSLog(@"item is null");
            continue;
        }
        NSString *title = [item valueForKey:MPMediaItemPropertyTitle];
        _musicURL = [item valueForKey:MPMediaItemPropertyAssetURL];
        NSLog(@"select with sound: %@ with url %@ artist is %@", title, _musicURL, [item valueForKey:MPMediaItemPropertyArtist]);
        break ;
    }
    [_mpPickerVC dismissViewControllerAnimated:YES completion:^{
        //
    }];
}

- (void)mediaPickerDidCancel:(MPMediaPickerController *)mediaPicker {
    NSLog(@"Cancel");
    [_mpPickerVC dismissViewControllerAnimated:YES completion:^{
        //
    }];
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
