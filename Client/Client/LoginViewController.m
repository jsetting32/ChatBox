//
//  LoginViewController.m
//  Client
//
//  Created by John Setting on 12/14/13.
//  Copyright (c) 2013 John Setting. All rights reserved.
//

#import "LoginViewController.h"
#import <QuartzCore/QuartzCore.h>
@interface LoginViewController ()

@end

@implementation LoginViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Initialization code here.
    }
    return self;
}

- (void)viewWillLoad
{
}

- (void)viewDidLoad
{
    CALayer *viewLayer = [CALayer layer];
    [viewLayer setBackgroundColor:CGColorCreateGenericRGB(0.0, 0.0, 0.0, 0.5)]; //RGB plus Alpha Channel
    [[self view] setWantsLayer:YES]; // view's backing store is using a Core Animation Layer
    [[self view] setLayer:viewLayer];
}

- (void)loadView
{
    [self viewWillLoad];
    [super loadView];
    [self viewDidLoad];
}

- (NSString *)getHostField {
    return [hostField stringValue];
}
- (void)hideHostField:(BOOL)hide {
    [hostField setHidden:hide];
}

- (NSInteger)getPortField {
    return [portField integerValue];
}

- (void)hidePortField:(BOOL)hide {
    [portField setHidden:hide];
}

- (NSString *)getDisplayNameField {
    return [displayNameField stringValue];
}

- (void)hideDisplayNameField:(BOOL)hide{
    [displayNameField setHidden:hide];
}

@end
