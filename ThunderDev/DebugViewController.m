//
//  DebugViewController.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
#import "DebugViewController.h"
#import "AppDelegate.h"

@implementation DebugViewController
@synthesize uuidField;
@synthesize emailField;
@synthesize statusLabel;
@synthesize textView, trace, serverControl;

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

    upgrade = ApplicationDelegate.upgrade;
    nvram = ApplicationDelegate.nvram;
    packetHandler = ApplicationDelegate.packetHandler;
    
    [trace setTextView: self.textView];
    [trace update];
    if ([[NSUserDefaults standardUserDefaults] stringForKey:@"emailAddress"] == nil) {
        emailAddress = @"?";
    }
    else {
        emailAddress =  [[NSUserDefaults standardUserDefaults] stringForKey:@"emailAddress"];        
    }
    [emailField setText:emailAddress];
    [statusLabel setText:@""];
    
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(EASessionOpenedSuccess:) 
                                                 name:@"EASessionOpenedSuccess" 
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(EAAccessoryDidDisconnectNotification:) 
                                                 name:EAAccessoryDidDisconnectNotification
                                               object:nil];    
    
    if (packetHandler.sessionOpen) {
        [self buttonReadFlash:nil];
    }
    else {
        [uuidField setText:@"?"];
    }
}

- (void)EASessionOpenedSuccess:(NSNotification *)notification 
{
    [self buttonReadFlash:nil];    
}

- (void)EAAccessoryDidDisconnectNotification:(NSNotification *)notification 
{
    [uuidField setText:@"?"];
}


- (void)viewDidUnload
{
    [self setUuidField:nil];
    [self setEmailField:nil];
    [self setStatusLabel:nil];
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

- (IBAction)buttonExit:(id)sender {
    [self dismissModalViewControllerAnimated:YES];
}

- (IBAction)buttonClear:(id)sender {
    [trace clear];
}

- (IBAction)buttonGetLatestFirmwareRevision:(id)sender {
    [upgrade getLatestFirmwareRevOneShot];
}

- (IBAction)sendUserRegistration:(id)sender {
    
    NSString *uuid = [uuidField text];
    NSString *email = [emailField text];
    
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    userOperation = [cloudEngine sendRegisterDevice:uuid 
                                                     email:email 
                                              onCompletion:^(NSString *response) {
                                                  NSString *status = @"OK";
                                                  NSRange textRange = [response rangeOfString: @"Entry already exists"];
                                                  if( textRange.location != NSNotFound ) {
                                                      status = @"ALREADY REGISTERED";
                                                  }
                                                  // The server simply returns "ERROR" if the UUID is not valid
                                                  textRange = [response rangeOfString: @"ERROR"];
                                                  if( textRange.location != NSNotFound ) {
                                                      status = @"INVALID UUID";
                                                  }
                                                  [statusLabel setText:status];
                                              } 
                                                   onError:^(NSError* error) {
                                                       [statusLabel setText:@"ERROR"];
                                                   }
                          ];
    [statusLabel setText:@"Working..."];
}

- (IBAction)checkUserRegistration:(id)sender {
    NSString *uuid = [uuidField text];
    NSString *email = [emailField text];
    
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    userOperation = [cloudEngine checkDeviceRegistration:uuid email: email 
                                               onCompletion:^(NSString *response) {
                                                   NSString *status = @"UNRECOGNIZED";
                                                   if( [response isEqualToString:@"YES"] )
                                                       status = @"Registered";
                                                   else if( [response isEqualToString:@"NO"] )
                                                       status = @"NOT registered";
                                                   [statusLabel setText:status];
                                               } 
                                                    onError:^(NSError* error) {
                                                        [statusLabel setText:@"ERROR"];
                                                    }
                          ];
    [statusLabel setText:@"Working..."];
}

- (IBAction)sendRejectRegistration:(id)sender {
    
    NSString *uuid = [uuidField text];
    
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    userOperation = [cloudEngine sendRegistrationRejected:uuid 
                                                  onCompletion:^(NSString *response) {
                                                      NSString *status = @"OK";
                                                      // The server simply returns "ERROR" if the UUID is not valid
                                                      NSRange textRange = [response rangeOfString: @"ERROR"];
                                                      if( textRange.location != NSNotFound ) {
                                                          status = @"INVALID UUID";
                                                      }
                                                      [statusLabel setText:status];
                                                  } 
                                                       onError:^(NSError* error) {
                                                           [statusLabel setText:@"ERROR"];
                                                       }
                          ];
    [statusLabel setText:@"Working..."];
}

- (IBAction)buttonSaveInFlash:(id)sender 
{
    NSString *email = [emailField text];
    [[NSUserDefaults standardUserDefaults] setObject:email forKey:@"emailAddress"];
    [nvram writeUUID:[uuidField text]];
    
    
}

- (IBAction)buttonReadFlash:(id)sender 
{
    [[NSNotificationCenter defaultCenter] addObserver:self 
                                             selector:@selector(MfgDataReceived:) 
                                                 name:@"MfgDataReceived" 
                                               object:nil];
    [nvram readUUID];
}

- (IBAction)buttonDoUpgrade:(id)sender 
{
    [upgrade upgradeFirmwareToLatest];
}

- (IBAction)newServerSelected:(id)sender {
    //[_trace trace:@"NEW SERVER"];
    int index = [serverControl selectedSegmentIndex];
    int server_num = 1;
    
    if(index == 1) {
        server_num = 1;
        [trace trace:@"Selected server 1"];
    } else if(index == 2) {
        server_num = 2;    
        [trace trace:@"Selected server 2"];
    } else if(index == 3) {
        server_num = 3;    
        [trace trace:@"Selected server 3"];
    } else { // Fallback (auto tab)
        server_num = 0; // Auto
        [trace trace:@"Selected server AUTO"];
    }
    [ApplicationDelegate setServer:server_num];
}

- (void)MfgDataReceived:(NSNotification *)notification 
{
    [uuidField setText:(NSString*) [notification object]];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"MfgDataReceived" object:nil];
}
@end