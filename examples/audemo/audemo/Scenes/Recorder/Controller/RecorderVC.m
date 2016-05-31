/*******************************************************************************\
** audemo:RecorderVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/5/28
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import "RecorderVC.h"

@interface RecorderVC ()
@property (strong, nonatomic) MPMediaPickerController * mpPickerVC;
@property (weak, nonatomic) IBOutlet UISearchBar *artistSearchBar;
@property (weak, nonatomic) IBOutlet UITextView *soundsTV;
@property (weak, nonatomic) IBOutlet UIButton *playBtn;
@property (weak, nonatomic) IBOutlet UIButton *previousBtn;
@property (weak, nonatomic) IBOutlet UIButton *nextBtn;
@property (strong, nonatomic) MPMediaItemCollection *slctItems;
@property (strong, nonatomic) MPMusicPlayerController* appMusicPlayer;
@end

@implementation RecorderVC

- (void)viewDidLoad {
    [super viewDidLoad];
    _mpPickerVC = [[MPMediaPickerController alloc] initWithMediaTypes: MPMediaTypeAnyAudio];
    _mpPickerVC.prompt = @"请选择背景音乐";
    _mpPickerVC.allowsPickingMultipleItems = YES;
    _mpPickerVC.showsCloudItems = YES;
    _mpPickerVC.delegate  = self;
    _artistSearchBar.delegate = self;
    _appMusicPlayer = [MPMusicPlayerController applicationMusicPlayer];
    
    
    NSNotificationCenter *notificationCenter = [NSNotificationCenter defaultCenter];
    
    [notificationCenter  addObserver: self
                            selector: @selector (onVolumeChange:)
                                name: MPMusicPlayerControllerVolumeDidChangeNotification
                              object: _appMusicPlayer];
    [notificationCenter  addObserver: self
                            selector: @selector (onStateChange:)
                                name: MPMusicPlayerControllerPlaybackStateDidChangeNotification
                              object: _appMusicPlayer];
    [notificationCenter  addObserver: self
                            selector: @selector (onNowPlaying:)
                                name: MPMusicPlayerControllerNowPlayingItemDidChangeNotification
                              object: _appMusicPlayer];
    // take of this
    [_appMusicPlayer beginGeneratingPlaybackNotifications];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)onPick:(id)sender {

    [self presentViewController:_mpPickerVC animated:YES completion:^{
        //
    }];
}

- (void) updateList: (MPMediaItemCollection *) collection {
    NSString *txt=@"";
    NSString *tag = @"";
    for (MPMediaItem *item in [collection items]) {
        if (NULL == item) {
            NSLog(@"item is null");
            continue;
        }
        NSString *title = [item valueForKey:MPMediaItemPropertyTitle];
        NSString *artist = [item valueForKey:MPMediaItemPropertyArtist];
        txt = [NSString stringWithFormat:@"%@%@%@-%@", txt, tag, title, artist];
        tag = @"\n";
    }
    _soundsTV.text = txt;

}

- (void) queryArtist: (NSString *)artist {
    MPMediaQuery *artistQry = [[MPMediaQuery alloc] init];
    MPMediaPropertyPredicate *artistNamePredicate =
    [MPMediaPropertyPredicate predicateWithValue: artist
                                     forProperty: MPMediaItemPropertyArtist];
    [artistQry addFilterPredicate: artistNamePredicate];
    for (MPMediaItem *item in [artistQry items]) {
        if (NULL == item) {
            NSLog(@"item is null");
            continue;
        }
        NSString *title = [item valueForKey:MPMediaItemPropertyTitle];
        NSLog(@"After search with sound: %@ with url %@ artist is %@", title, [item valueForKey:MPMediaItemPropertyAssetURL], [item valueForKey:MPMediaItemPropertyArtist]);
    }
    _slctItems  = [MPMediaItemCollection collectionWithItems:artistQry.items];
    [_previousBtn setEnabled:NO];
    [self updateList:_slctItems];
    [_appMusicPlayer setQueueWithItemCollection:_slctItems];
}

- (IBAction)onQuery:(id)sender {
    if (NULL == _artistSearchBar.text || 0== _artistSearchBar.text.length ) {
        return;
    }
    
    
    [self queryArtist: _artistSearchBar.text];
}
- (IBAction)onPrevious:(id)sender {
    if (NULL == _appMusicPlayer) {
        return;
    }
    
    if (_appMusicPlayer.indexOfNowPlayingItem <=1) {
        [_previousBtn setEnabled:NO];
    }
    [_appMusicPlayer skipToPreviousItem];

        [_nextBtn setEnabled:YES];

}
- (IBAction)onPlay:(id)sender {
    static BOOL isPlay = NO;
    if (NULL == _appMusicPlayer) {
        return;
    }
    if (!isPlay) {
        isPlay = YES;
        [_playBtn setTitle:@"Stop" forState:UIControlStateNormal];
        [_appMusicPlayer play];
    } else {
        isPlay = NO;
        [_playBtn setTitle:@"Play" forState:UIControlStateNormal];
        [_appMusicPlayer pause];
    }
}
- (IBAction)onNext:(id)sender {
    if (NULL == _appMusicPlayer) {
        return;
    }
    
    if (_appMusicPlayer.indexOfNowPlayingItem >= (_slctItems.count -2)) {
        [_nextBtn setEnabled:NO];
    }
    
    [_appMusicPlayer skipToNextItem];

    [_previousBtn setEnabled:YES];

}

#pragma mark Notifaction
- (void) onStateChange: (NSNotification*) notification {
    NSLog(@"onStateChange");
}

- (void) onNowPlaying: (NSNotification*) notification {
    NSLog(@"onNowPlaying");
    MPMusicPlayerController *player = notification.object;
    MPMediaItem *item = [player nowPlayingItem];
    NSLog(@"now playing %@", [item valueForKey:MPMediaItemPropertyTitle]);
}

- (void) onVolumeChange: (NSNotification*) notification {
    NSLog(@"onVolumeChange");
}

#pragma mark  MPMediaPickerControllerDelegate

- (void)mediaPicker:(MPMediaPickerController *)mediaPicker didPickMediaItems:(MPMediaItemCollection *)mediaItemCollection {
    NSLog(@"picked");
    //NSLog(@"picked with %d itmes", [mediaItemCollection count]);
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
        NSLog(@"select with sound: %@ with url %@ artist is %@", title, [item valueForKey:MPMediaItemPropertyAssetURL], [item valueForKey:MPMediaItemPropertyArtist]);
    }
    _slctItems  = mediaItemCollection;
    [_appMusicPlayer setQueueWithItemCollection: _slctItems];
    [self updateList: _slctItems];
    [_previousBtn setEnabled:NO];
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

#pragma mark  UISearchBarDelegate
- (void)searchBarSearchButtonClicked:(UISearchBar *)searchBar {
    NSLog(@"search for %@", searchBar.text);
    if (NULL == searchBar.text || 0==searchBar.text.length ) {
        return;
    }
    
    [self queryArtist:searchBar.text];
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
