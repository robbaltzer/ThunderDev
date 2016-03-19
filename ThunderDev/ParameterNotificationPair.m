//
//  ParameterNotificationPair.m
//  ThunderDev
//
//  Created by Rob Baltzer on 5/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "ParameterNotificationPair.h"

@implementation ParameterNotificationPair
@synthesize notificationString, parameter;

- (id) initWithPair : (SoundSkinParameter_t) myParameter : (NSString*) myNotificationString
{
    self = [super init];
    if (self) {
        self.parameter = myParameter;
        self.notificationString = myNotificationString;
    }
    return self;
}
@end
