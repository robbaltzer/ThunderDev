//
//  NvramControl.h
//  ThunderDev
//
//  Created by Rob Baltzer on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "protocol_defs.h"
#import "PageData.h"
#import "nvram.h"
#import "MyTraceController.h"
#import "SendPacket.h"

typedef enum {
    nvrStateIdle,
    nvrStateGetNVRAM,
    nvrStateWaitForNVRAMGet,
    nvrInsertUUID,
    nvrStateWriteNVRAM,
    nvrStateWaitNVRAMWrite,
    
    nvrStateGetMfgData,
    nvrStateWaitGetMfgData,
    
    nvrStateComplete,
    nvrStateTimeout,
    nvrStateError,
} NvramState;

#define BITS_PER_BYTE   (8)
#define UUID_BITS       (128)
#define UUID_BYTES      (UUID_BITS/BITS_PER_BYTE)

@interface NvramControl : NSObject {
    SendPacket* sendPacket;
    MyTraceController* trace;
    NvramData nvramData;
    Nv_OtpShadow otpShadow;
    NvramState nvramState;
    NSString* deviceUUID;
    u8 uuidBits[UUID_BYTES];    // 128 bit representation of the UUID
}

@property (strong, nonatomic) NSString* deviceUUID;

// Read/Write from flash
- (void) writeUUID : (NSString*) uuidStringWithDashes;  // This should be temporary as the UUIDs should be programmed in before this app is run.
- (void) readUUID;
@end
