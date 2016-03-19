//
//  ParameterNotificationPair.h
//  ThunderDev
//
//  Created by Rob Baltzer on 5/9/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocol_defs.h"

@interface ParameterNotificationPair : NSObject
@property SoundSkinParameter_t parameter;
@property (nonatomic, retain) NSString* notificationString;

- (id) initWithPair : (SoundSkinParameter_t) myParameter : (NSString*) myNotificationString;
@end

