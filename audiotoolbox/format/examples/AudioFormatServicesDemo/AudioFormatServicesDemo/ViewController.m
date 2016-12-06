//
//  ViewController.m
//  AudioFormatServicesDemo
//
//  Created by apollo on 06/12/2016.
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
        NSLog(@"[ERR:%d]:%@", err, (msg));\
        return ;\
    }\
} while(0)

@interface ViewController ()
@property (strong, nonatomic) MPMediaPickerController * mpPickerVC;
@property (strong, nonatomic) NSURL *musicURL;
@end

@implementation ViewController {
    AudioFileID musicFD_;
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
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

- (IBAction)onPickerMusic:(id)sender {
    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

- (IBAction)onOpenMusic:(id)sender {
    CFURLRef url = (__bridge CFURLRef) _musicURL;
    if (nil == url) {
        url = (__bridge CFURLRef) [NSURL fileURLWithPath:[[NSBundle mainBundle] pathForResource:@"01" ofType:@"caf"]];
    }
    OSStatus stts = AudioFileOpenURL(url, kAudioFileReadPermission, 0, &musicFD_);
    VStatus(stts, @"AudioFileOpenURL");
    NSLog(@"open file %@ success!", _musicURL);
}

- (IBAction)onFormatInfo:(id)sender {
    OSStatus stts;
    
    UInt32 prprtySize = 0;
    UInt32 prprtyWriteable = 0;
    AudioStreamBasicDescription desc;
    UInt32 descSize = sizeof(desc);
    // kAudioFormatProperty_FormatInfo
#if 0
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, &prprtyWriteable);
    VStatus(stts, @"AudioFileGetPropertyInfo: kAudioFilePropertyMagicCookieData");
    void * magic = malloc(prprtySize);
    if (NULL == magic) {
        NSLog(@"malloc magic is NULL");
        return ;
    }
    memset(magic, 0, prprtySize);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, magic);
    VStatus(stts, @"AudioFileGetProperty: kAudioFilePropertyMagicCookieData");
    NSLog(@"get magic with length %d", prprtySize);
    
    stts = AudioFormatGetProperty(kAudioFormatProperty_FormatInfo, prprtySize, magic, &descSize, &desc);
    VStatus(stts, @"kAudioFormatProperty_FormatInfo");
    NSLog(@"mFormat is %d", desc.mFormatID);
#endif
    
    // kAudioFormatProperty_FormatName
    
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyDataFormat, &descSize, &desc);
    VStatus(stts, @"AudioFileGetProperty: kAudioFilePropertyDataFormat");
    NSLog(@"get data with length %d", descSize);
    CFStringRef formatName;
    UInt32 formatNameSize = sizeof(formatName);
    stts = AudioFormatGetProperty(kAudioFormatProperty_FormatName, descSize, &desc, &formatNameSize, &formatName);
    VStatus(stts, @"kAudioFormatProperty_FormatInfo");
    NSLog(@"Format is %@", formatName);
    
    // kAudioFormatProperty_FormatList
    
    AudioFormatInfo finfo;
    stts = AudioFileGetPropertyInfo(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, &prprtyWriteable);
    VStatus(stts, @"AudioFileGetPropertyInfo: kAudioFilePropertyMagicCookieData");
    void * magic = malloc(prprtySize);
    if (NULL == magic) {
        NSLog(@"malloc magic is NULL");
        return ;
    }
    memset(magic, 0, prprtySize);
    stts = AudioFileGetProperty(musicFD_, kAudioFilePropertyMagicCookieData, &prprtySize, magic);
    VStatus(stts, @"AudioFileGetProperty: kAudioFilePropertyMagicCookieData");
    NSLog(@"get magic with length %d", prprtySize);
    finfo.mASBD = desc;
    finfo.mMagicCookie = magic;
    finfo.mMagicCookieSize = prprtySize;
    
    UInt32 finfoSize = sizeof(finfo);
    UInt32 finfosSize  = 0;
    stts = AudioFormatGetPropertyInfo(kAudioFormatProperty_FormatList, sizeof(finfo), &finfo, &finfosSize);
    VStatus(stts, @"AudioFormatGetPropertyInfo:kAudioFormatProperty_FormatList");
    size_t itemCount = finfosSize / sizeof(AudioFormatListItem);
    AudioFormatListItem *finfos = (AudioFormatListItem *) malloc(finfosSize);
    
    stts = AudioFormatGetProperty(kAudioFormatProperty_FormatList, finfoSize, &finfo, &finfosSize, finfos);
    VStatus(stts, @"AudioFormatGetProperty: kAudioFormatProperty_FormatList");
    for (int i=0; i< itemCount; i++) {
        AudioFormatListItem *item = finfos + i ;
        NSLog(@"channel layout tag is %d", item->mChannelLayoutTag);
    }
}

- (IBAction)onFormatListItems:(id)sender {

}

- (IBAction)onBalanceFade:(id)sender {
    
}

- (IBAction)onPanningInfo:(id)sender {

}

- (IBAction)onFormatExtInfo:(id)sender {

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


@end
