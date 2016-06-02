/*******************************************************************************\
** audemo:PlayerVC.m
** Created by CZ(cz.devnet@gmail.com) on 16/6/2
**
**  Copyright © 2016年 projm. All rights reserved.
\*******************************************************************************/


#import "PlayerVC.h"

@interface PlayerVC ()

@end

@implementation PlayerVC

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (instancetype)initWithCoder:(NSCoder *)aDecoder  {
    if ( self = [super initWithCoder:aDecoder]) {
        self.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"播放器" image:[UIImage imageNamed:@"offline_tab_message"] selectedImage:[UIImage imageNamed:@"offline_tab_message"]];
    }
    return  self;
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
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
