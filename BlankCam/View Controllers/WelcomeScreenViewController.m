//
//  WelcomeScreenViewController.m
//  BlankCam
//
//  Created by Robert Cash on 11/1/15.
//  Copyright © 2015 Robert Cash. All rights reserved.
//

#import "WelcomeScreenViewController.h"

@interface WelcomeScreenViewController ()

@end

@implementation WelcomeScreenViewController

#pragma mark - View Management Code

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
    [self setUpUI];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Setup Mark

-(void)setUpUI{
    // Edit Got It Button
    self.gotItButton.layer.cornerRadius = 10;
    self.gotItButton.clipsToBounds = YES;
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
