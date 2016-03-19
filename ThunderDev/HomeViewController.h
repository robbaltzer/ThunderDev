//
//  HomeViewController.h
//  ThunderDev
//
//  Created by Rob Baltzer on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MyTraceController.h"
#import "SendPacket.h"
#import "ParameterNotificationPair.h"
#import "PacketHandler.h"
#import"NvramControl.h"

@interface HomeViewController : UIViewController {
    SendPacket* sendPacket;
    float timeout;
    NSMutableArray* initParameters;
    PacketHandler* packetHandler;
    float iPadBatteryLevel;
    NvramControl* nvram;
    NSTimer *millivoltUpdateTimer;
}

- (IBAction)radioButtonCharging:(id)sender;
- (IBAction)radioButtonSoundProcessing:(id)sender;
- (IBAction)registrationButton:(id)sender;
- (IBAction)toggleAutoSelect:(id)sender;

@property (weak, nonatomic) IBOutlet UILabel *millivoltLabel;
@property (weak, nonatomic) IBOutlet UILabel *labelUUID;
@property (weak, nonatomic) IBOutlet UITabBarItem *tabHome;
@property (weak, nonatomic) IBOutlet UILabel *labelTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelThunderBatteryTitle;
@property (weak, nonatomic) IBOutlet UILabel *labeliPadBatteryTitle;
@property (weak, nonatomic) IBOutlet UILabel *labelBatteryChargingPreference;
@property (weak, nonatomic) IBOutlet UILabel *labelSoundProcessing;
@property (weak, nonatomic) IBOutlet UILabel *labelAutoSelect;
@property (weak, nonatomic) IBOutlet UISwitch *toggleAutoSelect;
@property (weak, nonatomic) IBOutlet UISegmentedControl *radioButtonsCharging;
@property (weak, nonatomic) IBOutlet UISegmentedControl *radioButtonsSoundProcessing;
@property (weak, nonatomic) IBOutlet UILabel *labelIpadBatteryLevel;
@property (weak, nonatomic) IBOutlet UILabel *labelThunderBatteryLevel;
@property (retain, nonatomic) MyTraceController* trace;
@property (weak, nonatomic) IBOutlet UILabel *labelRevisionText;
@property (weak, nonatomic) IBOutlet UILabel *labelRevisionNumber;

- (IBAction)startMillivoltUpdates:(id)sender;
- (IBAction)stopMillivoltUpdates:(id)sender;

@end
