//
//  Battery.m
//  ThunderDev
//
//  Created by Rob Baltzer on 5/3/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//
//*********** CURRENTLY UNUSED ********

/*
#import "Battery.h"
#import "AppDelegate.h"

@implementation Battery
@synthesize ipadBatteryLevel;

- (id)init {
    self = [super init];
    if (self) {
        trace = ApplicationDelegate.trace; 

        // Register for battery level and state change notifications.
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(batteryLevelDidChange:)
                                                     name:UIDeviceBatteryLevelDidChangeNotification 
                                                   object:nil];
        [UIDevice currentDevice].batteryMonitoringEnabled = YES;
        [self batteryLevelDidChange:nil];
        [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(batteryLevelDidChange:) userInfo:nil repeats:YES];    
        [trace trace:@"Battery initted"];
    }
    return self;
}

- (void) batteryLevelDidChange: (NSNotification*) notification
{
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    if (batteryLevel < 0.0)
    {
        ipadBatteryLevel = -1;

    }
    else {
        ipadBatteryLevel = batteryLevel * 100;
    }    
    [[NSNotificationCenter defaultCenter] postNotificationName:@"iPadBatteryLevelChanged" 
                                                        object:[NSNumber numberWithFloat:batteryLevel]];  
}

- (void) dealloc {
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:UIDeviceBatteryLevelDidChangeNotification
                                                  object:nil];
}
@end
 */
