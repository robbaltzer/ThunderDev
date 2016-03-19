//
//  PromoViewController.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PromoViewController.h"

//@interface SecondViewController ()
//
//@end

@implementation PromoViewController
@synthesize thunderWebView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    NSURL *url = [NSURL URLWithString:@"http://www.avnera.com"];
    NSURLRequest* urlRequest = [[NSURLRequest alloc] initWithURL:url];
    [thunderWebView loadRequest:urlRequest];
	// Do any additional setup after loading the view, typically from a nib.
}

- (void)viewDidUnload
{
    [self setThunderWebView:nil];
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

@end
