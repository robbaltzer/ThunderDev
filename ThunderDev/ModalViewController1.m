//
//  ModalViewController1.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/16/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ModalViewController1.h"

@interface ModalViewController1 ()

@end

@implementation ModalViewController1

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view.
}

- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    }
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return NO;
    }
    return YES;
}

- (IBAction)buttonYesRegisterMe:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)buttonNoThanks:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}
@end
