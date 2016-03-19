//
//  NvramControl.m
//  ThunderDev
//
//  Created by Rob Baltzer on 5/22/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "NvramControl.h"
#import "AppDelegate.h"

#define STATE_MACHINE_TICK              (0.05F)        
#define TIMEOUT_SECONDS                 (2.0F)

@implementation NvramControl
@synthesize deviceUUID;

- (id)init
{
    self = [super init];
    if (self) {
        sendPacket = [[SendPacket alloc] init];
        nvramState = nvrStateIdle;
        trace = ApplicationDelegate.trace;
        deviceUUID = [[NSString alloc] initWithString: @"00000000-0000-0000-0000-000000000000"];   // default UUID
        [trace trace:@"deviceUUID initted"];
        [trace trace:deviceUUID];
        [NSTimer scheduledTimerWithTimeInterval:STATE_MACHINE_TICK target:self selector:@selector(nvramStateMachine) userInfo:nil repeats:YES];
    }

    return self;
}

- (void) writeUUID : (NSString*) uuidStringWithDashes
{
    // Check on idle since this is a temporary function - I think
    if (nvramState == nvrStateIdle) {
        deviceUUID = [[NSString alloc] initWithString:uuidStringWithDashes];
        nvramState = nvrStateGetNVRAM;
    }
}

- (void) readUUID
{
    nvramState = nvrStateGetMfgData;   
}

- (void)ParmMfgDataReceived:(NSNotification *)notification 
{
    PageData* pageData = [notification object];
    otpShadow = *((Nv_OtpShadow*) [pageData bytes]);
    
//    [trace traceFormat:@"optShadow.mfgdata[0] 0x%x": otpShadow.mfgdata[0]];
//    [trace traceFormat:@"optShadow.mfgdata[1] 0x%x": otpShadow.mfgdata[1]];
//    [trace traceFormat:@"optShadow.mfgdata[2] 0x%x": otpShadow.mfgdata[2]];
//    [trace traceFormat:@"optShadow.mfgdata[3] 0x%x": otpShadow.mfgdata[3]];
//    [trace traceFormat:@"optShadow.mfgdata[23] 0x%x": otpShadow.mfgdata[23]];
//    [trace traceFormat:@"optShadow.uuid[0] 0x%x": otpShadow.uuid[0]];
//    [trace traceFormat:@"optShadow.uuid[1] 0x%x": otpShadow.uuid[1]];
//    [trace traceFormat:@"optShadow.uuid[2] 0x%x": otpShadow.uuid[2]];
//    [trace traceFormat:@"optShadow.uuid[3] 0x%x": otpShadow.uuid[3]];
//    [trace traceFormat:@"optShadow.uuid[15] 0x%x": otpShadow.uuid[15]];
    
    if (nvramState == nvrStateWaitGetMfgData) {
        deviceUUID = [self uuidBits2String:otpShadow.uuid];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MfgDataReceived" 
                                                            object:deviceUUID];

        [trace trace:deviceUUID];
        nvramState = nvrStateComplete;
    }
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ParmMfgDataReceived" object:nil];
    
}

- (void)ParmNVRAMDataRecieved:(NSNotification *)notification 
{
    PageData* pageData = [notification object];
    nvramData = *((NvramData*) [pageData bytes]);
    
//    [trace traceFormat:@"integrity[0] 0x%x": nvramData.integrity[0]];
//    [trace traceFormat:@"integrity[1] 0x%x": nvramData.integrity[1]];
//    [trace traceFormat:@"signature 0x%x": nvramData.signature];
//    [trace traceFormat:@"section_mask 0x%x": nvramData.section_mask];
//    [trace traceFormat:@"crc 0x%x": nvramData.crc];
//    [trace traceFormat:@"hdrcrc 0x%x": nvramData.hdrcrc];
//    [trace traceFormat:@"nvramData.otp.mfgdata[0] 0x%x": nvramData.otp.mfgdata[0]];
//    [trace traceFormat:@"nvramData.otp.mfgdata[1] 0x%x": nvramData.otp.mfgdata[1]];
//    [trace traceFormat:@"nvramData.otp.mfgdata[2] 0x%x": nvramData.otp.mfgdata[2]];
//    [trace traceFormat:@"nvramData.otp.mfgdata[3] 0x%xd": nvramData.otp.mfgdata[3]];
//    [trace traceFormat:@"nvramData.otp.mfgdata[23] 0x%x": nvramData.otp.mfgdata[23]];
//    [trace traceFormat:@"nvramData.otp.uuid[0] 0x%x": nvramData.otp.uuid[0]];
//    [trace traceFormat:@"nvramData.otp.uuid[1] 0x%x": nvramData.otp.uuid[1]];
//    [trace traceFormat:@"nvramData.otp.uuid[2] 0x%x": nvramData.otp.uuid[2]];
//    [trace traceFormat:@"nvramData.otp.uuid[3] 0x%x": nvramData.otp.uuid[3]];
//    [trace traceFormat:@"nvramData.otp.uuid[15] 0x%x": nvramData.otp.uuid[15]];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ParmNVRAMDataRecieved" object:nil];
    
    if (nvramState == nvrStateWaitForNVRAMGet) {
        nvramState = nvrInsertUUID;
    }
}

#define TIMEOUT_TICKS           ((TIMEOUT_SECONDS)/(STATE_MACHINE_TICK)/30) // TODO: Why do I need to scale by 30?
#define MAX_RETRIES             (3)

static u8 nvrRetries;
static int nvrTimeout;

- (void) nvramStateMachine
{
    nvrTimeout += STATE_MACHINE_TICK;
    switch(nvramState) {
        case nvrStateIdle:
            // do nothing
            break;
            
/************* Get MfgData States ****************/            
        case nvrStateGetMfgData:
            nvrRetries = 0;
            nvrTimeout = 0;
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(ParmMfgDataReceived:) 
                                                         name:@"ParmMfgDataReceived" 
                                                       object:nil];
            [sendPacket sendSimplePacket:ParmMfgData :cmdRequest :0];  
            nvramState = nvrStateWaitGetMfgData;
            break;
            
        case nvrStateWaitGetMfgData:
            if (nvrTimeout >= TIMEOUT_TICKS) {
                if (nvrRetries < MAX_RETRIES) {
                    nvrRetries += 1;
                    nvramState = nvrStateGetMfgData;
                }
                else {
                    nvramState = nvrStateTimeout;
                }
            }
            break;
/************************************************/  
            
        case nvrStateGetNVRAM:
            nvrRetries = 0;
            nvrTimeout = 0;
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(ParmNVRAMDataRecieved:) 
                                                         name:@"ParmNVRAMDataRecieved" 
                                                       object:nil];
            nvrTimeout = 0;
            [sendPacket sendSimplePacket:ParmNVRAM :cmdRequest :0];
            nvramState = nvrStateWaitForNVRAMGet;
            break;
            
        case nvrStateWaitForNVRAMGet:
            if (nvrTimeout >= TIMEOUT_TICKS) {
                if (nvrRetries < MAX_RETRIES) {
                    nvrRetries += 1;
                    nvramState = nvrStateGetNVRAM;
                }
                else {
                    nvramState = nvrStateTimeout;
                }
            }
            break;
            
        case nvrInsertUUID:
            if ([self uuidString2Bits:deviceUUID : uuidBits]) {
                memcpy(nvramData.otp.uuid, uuidBits, UUID_BYTES);
                nvramState = nvrStateWriteNVRAM;
            }
            else {
                [trace trace:@"Error parsing uuid"];
                nvramState = nvrStateError;
            }
            break;
            
        case nvrStateWriteNVRAM:
            [sendPacket sendDataPacket:ParmNVRAM :cmdSend :0 : sizeof(NvramData) :(u8*) &nvramData];
            nvramState = nvrStateComplete;
            break;            
            
        case nvrStateComplete:
            [trace trace:@"nvrStateComplete - going idle"];
            nvramState = nvrStateIdle;
            break;     
            
        case nvrStateTimeout:
            [trace trace:@"nvrStateTimeout - going idle"];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            nvramState = nvrStateIdle;
            break;            
            
        case nvrStateError:
            [trace trace:@"nvrStateError - going idle"];
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            nvramState = nvrStateIdle;                 
            break;
            
        default:
            [trace trace:@"nvrState Undefined!!! - going idle"];
            nvramState = nvrStateIdle;     
            break;
    }
}

#define CORRECT_UUID_STRING_LENGTH              (36)
#define CORRECT_UUID_STRING_LENGTH_NO_DASHES    (32)

// Convert UUID string into 16 chars for a total of 128 bits
// Note: This assumes the UUID string is in 8-4-4-4-12 format
- (bool) uuidString2Bits : (NSString*) uuidString :(u8*) myUUIDBits 
{
    NSString* tmpString = [[NSString alloc] initWithString:uuidString];
    
    // Make sure string is correct length
    if ([tmpString length] != CORRECT_UUID_STRING_LENGTH) {
        [trace traceFormat:@"Wrong length. Got %d. Should be 36": [tmpString length]];
        return false;
    }
    
    // Remove dashes
    NSString* tmp2 = [tmpString stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    // Convert to uppercase
    NSString* hexString = [[NSString alloc] initWithString:[tmp2 uppercaseString]];
    
    // Convert to bits
    [trace traceFormat: @"hexString length %d": [hexString length]];
    for(int i = 0; i < [hexString length]; i += 2) {
        NSRange range = { i, 2 };
        NSString *subString = [hexString substringWithRange:range];
        unsigned value;
        [[NSScanner scannerWithString:subString] scanHexInt:&value];
        myUUIDBits[i / 2] = (u8)value;
    }
    return true;   
}

// UUID is displayed in 8-4-4-4-12 format
#define FIRST_DASH_OFFSET       (8)
#define SECOND_DASH_OFFSET      (4)
#define THIRD_DASH_OFFSET       (4)
#define FOURTH_DASH_OFFSET      (4)

#define TOTAL_OFFSETS           (4)
// Convert UUID 128 bits (16 bytes) into string with dashs in format: 8-4-4-4-12
- (NSString*) uuidBits2String :(u8*) myUUIDBits
{
    int offsetTotal = 0;
    u8 dash_offset[TOTAL_OFFSETS] = { 
        FIRST_DASH_OFFSET,
        SECOND_DASH_OFFSET,
        THIRD_DASH_OFFSET,
        FOURTH_DASH_OFFSET
    };
    
    // Create hex string
    NSMutableString* returnString = [[NSMutableString alloc] init];
    for (int i = 0 ; i < UUID_BYTES ; i++) {
        [returnString appendFormat:@"%02x", myUUIDBits[i]];
    }
    
    // Insert dashes
    int j = 0;
    for (int i = 0 ; i < TOTAL_OFFSETS ; i++) {
        offsetTotal += dash_offset[j++];        
        [returnString insertString:@"-" atIndex:offsetTotal];
        offsetTotal++;  // Add one to account for the dash
    }
    
    return (NSString*) returnString;
}

@end