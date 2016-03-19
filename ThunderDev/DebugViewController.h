//
//  DebugViewController.h
//  ThunderDev
//
//  Created by Rob Baltzer on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTraceController.h"
#import "FirmwareUpgrade.h"
#import "nvram.h"
#import "NvramControl.h"
#import "PacketHandler.h"

@interface DebugViewController : UIViewController {
    NvramControl* nvram;
    FirmwareUpgrade* upgrade;
    MKNetworkOperation *userOperation;
    NSString* emailAddress;
    PacketHandler* packetHandler;
}

- (IBAction)buttonExit:(id)sender;
- (IBAction)buttonClear:(id)sender;
- (IBAction)buttonGetLatestFirmwareRevision:(id)sender;
- (IBAction)sendUserRegistration:(id)sender;
- (IBAction)checkUserRegistration:(id)sender;
- (IBAction)sendRejectRegistration:(id)sender;
- (IBAction)buttonSaveInFlash:(id)sender;
- (IBAction)buttonReadFlash:(id)sender;
- (IBAction)buttonDoUpgrade:(id)sender;
- (IBAction)newServerSelected:(id)sender;

@property (nonatomic, strong) MyTraceController* trace;
@property (nonatomic, strong) IBOutlet UITextView *textView;
@property (weak, nonatomic) IBOutlet UITextField *uuidField;
@property (weak, nonatomic) IBOutlet UITextField *emailField;
@property (weak, nonatomic) IBOutlet UILabel *statusLabel;
@property (nonatomic, strong) IBOutlet UISegmentedControl *serverControl;



@end
