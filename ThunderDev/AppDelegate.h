//
//  AppDelegate.h
//  ThunderDev
//
//  Created by Rob Baltzer on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "PacketHandler.h"
#import "MyTraceController.h"
#import "HomeViewController.h"
#import "CloudEngine.h"
#import "FirmwareUpgrade.h"
#import "NvramControl.h"
#import "BatteryCapacity.h"

#define ApplicationDelegate ((AppDelegate *)[UIApplication sharedApplication].delegate)

@interface AppDelegate : UIResponder <UIApplicationDelegate> {
    PacketHandler* packetHandler;
    MyTraceController* trace;
    CloudEngine *cloudEngine;
    FirmwareUpgrade* upgrade;
    NSString *current_revision;
    NvramControl* nvram;
    BatteryCapacity* batteryCapacity;
}

@property (nonatomic, strong) HomeViewController *rootViewController;
@property (strong, nonatomic) UIWindow *window;
@property (strong, nonatomic) MyTraceController* trace;
@property (strong, nonatomic) PacketHandler* packetHandler;
@property (strong, nonatomic) CloudEngine *cloudEngine;
@property (strong, nonatomic) FirmwareUpgrade* upgrade;
@property (strong, nonatomic) NvramControl* nvram;

- (NSString*)getCurrentRevision;
- (void)setCurrentRevision:(NSString*)revision;
- (void)setServer:(int)server_num;
@end
