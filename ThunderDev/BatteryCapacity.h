//
//  BatteryCapacity.h
//  ThunderDev
//
//  Created by Rob Baltzer on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MyTraceController.h"
#import "SendPacket.h"
#import "PacketHandler.h"

@interface BatteryCapacity : NSObject {
    MyTraceController* trace;
    SendPacket* sendPacket;
    float timeout;
    int state;
    NSMutableArray* sample;         // Battery voltage samples (in millivolts)
    PacketHandler* packetHandler;
    PowerMode_t powerMode;
    int batteryCapacity;            // 0 - 10, 0 = empty, 1 = full
}

@end
