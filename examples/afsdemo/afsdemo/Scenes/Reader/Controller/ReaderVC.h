/*******************************************************************************\
** afsdemo:ReaderVC.h
** Created by CZ(cz.devnet@gmail.com) on 16/6/15
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import <UIKit/UIKit.h>
#import <AudioToolBox/AudioFile.h>
#import <AudioToolBox/CAFFile.h>
#import <MediaPlayer/MediaPlayer.h>
@import CoreAudio;
@import AudioToolbox;

@interface ReaderVC : UIViewController <MPMediaPickerControllerDelegate, UISearchBarDelegate>


@end
