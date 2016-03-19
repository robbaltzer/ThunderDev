//
//  PacketHandler.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "PacketHandler.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "EASessionController.h"
#import "AppDelegate.h"
#import "nvram.h"   // Shared with Thunder's 8051

@implementation PacketHandler
@synthesize myPacket, sessionOpen;

- (id)init {
    self = [super init];
    if (self) {
        sessionOpen = NO;
        trace = ApplicationDelegate.trace;
        sendPacket = [[SendPacket alloc] init];
        myPacket = [[MyPacket alloc] init];
        pageData = [[PageData alloc] init];
        [[NSNotificationCenter defaultCenter]   addObserver:self 
                                                   selector:@selector(accessoryDidConnect:) 
                                                       name:EAAccessoryDidConnectNotification 
                                                     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(accessoryDidDisconnect:) 
                                                     name:EAAccessoryDidDisconnectNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(accessoryDataReceived:) 
                                                     name:EASessionDataReceivedNotification 
                                                   object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(packetReceived:)
                                                     name:@"packetReceived"
                                                   object:nil];
        [[EAAccessoryManager sharedAccessoryManager] registerForLocalNotifications]; 
        eaSessionController = [EASessionController sharedController];
        [eaSessionController setMyTraceController:trace];
        [self accessoryDidConnect:nil];         
        [trace trace:@"PacketHandler alive"];
    }
    return self;
}

// TODO: move all this packet RX code into it's owQuitn object. Shouldn't clutter app_delegate
- (void)packetReceived:(NSNotification *)notification
{
    SoundcasePacket* scPacket;
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ss.SSSSS"];
    
    if (myPacket) {
        scPacket = (SoundcasePacket*) [myPacket.theData bytes];
        switch(scPacket->parameter) {   
            
            case ParmBatteryVoltagePercent:
                if (scPacket->command == cmdSet) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmBatteryVoltagePercentReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]];
                }
                else {
                    [trace trace:@"(err) Bad ParmBatteryVoltagePercent command"];
                }
                break;
            
            case ParmChargeMode:
                if (scPacket->command == cmdSet) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmChargeModeReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]];
                }
                break;
            
            case ParmDspIndex:
                if (scPacket->command == cmdSet) {               
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmDspIndexReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]];
                }
                break;
            
            case ParmDspAutoSelect:
                if (scPacket->command == cmdSet) {               
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmDspAutoSelectReceived" 
                                                                        object:[NSNumber numberWithBool:(bool) scPacket->value]];
                }
                break;

            case ParmFirmwareVersion:
                if (scPacket->command == cmdSet) {
                    memcpy([pageData bytes], scPacket->bulk_data, 3);   // 3 bytes for firmware version Major, Minor, & ID
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmFirmwareVersionReceived" 
                                                                        object:pageData];
                }
                break;  
            
            case ParmNVRAM:
                if (scPacket->command == cmdSend) {
                    memcpy([pageData bytes], scPacket->bulk_data, sizeof(NvramData));                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmNVRAMDataRecieved" 
                                                                        object:pageData]; 
                }
                break;

            case ParmMfgData:
                if (scPacket->command == cmdSend) {
                    memcpy([pageData bytes], scPacket->bulk_data, sizeof(Nv_OtpShadow));                    
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ParmMfgDataReceived" 
                                                                        object:pageData]; 
                }                
                break;
            case ParmUpgradeStartPage:
                if (scPacket->command == cmdSet) {                  
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UpgradeStartPageReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }
                break;
            case ParmFlash:
                if (scPacket->command == cmdACK) {                  
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"FlashModeAckReceived" 
                                                                        object:nil];                    
                }
                break; 
            case ParmResetDevice:
                if (scPacket->command == cmdACK) {                  
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ResetThunderAckReceived" 
                                                                        object:nil];                    
                }
                break; 
            case ParmBatteryMillivolts:
                if (scPacket->command == cmdSet) {                  
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"BatteryMillivoltsReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }                
                break;

            case ParmChargeBoost:
                if (scPacket->command == cmdSet) {                  
                    [trace traceFormat:@"Charge boost state: %d": scPacket->value];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ChargeBoostReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }                
                break;
                
            case ParmThermistorVoltage:
                if (scPacket->command == cmdSet) {    
                    [trace traceFormat:@"Thermistor voltage: %d": scPacket->value];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"ThermistorVoltageReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }                
                break;
                
            case ParmTempFault:
                if (scPacket->command == cmdSet) {    
                    [trace trace:@"TEMP FAULT"];
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"TempFaultReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }                
                break;

            case ParmPowerMode:
                if (scPacket->command == cmdSet) {    
                    if (scPacket->value == PmodeVdc) {
                        [trace trace:@"Running on VDC"];
                    }
                    if (scPacket->value == PmodeBattery) {
                        [trace trace:@"Running on Battery"];
                    }
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"PowerModeReceived" 
                                                                        object:[NSNumber numberWithInt:scPacket->value]]; 
                }                
                break;
/*          case ParmAccessoryVolume:
                break;
            case ParmNormalizedAccessoryVolume:
                break;

 

            case ParmBulkData:
                if (scPacket->command == cmdSet) {
                    [trace traceBulkData: 256 : scPacket->bulk_data];
                }
                break;
//            case ParmSettingsPage:
//                if (scPacket->command == cmdSend) {
//                    //                    [trace traceFormat:@"Got ParmSettingsPage %d": scPacket->value];
//                    //                    [trace traceBulkData: 256 : scPacket->bulk_data];
//                    memcpy([pageData bytes], scPacket->bulk_data, sizeof(SettingsValues));
//                    [trace traceFormat:@"sizeof(SettingsValues) = %d": sizeof(SettingsValues)];
//                    [[NSNotificationCenter defaultCenter] postNotificationName:@"SettingsReceived" 
//                                                                        object:pageData];
//                }
//                break;            
            case ParmEventReadStart:
                if (scPacket->command == cmdACK) {
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"EventStartRecievedAck" 
                                                                        object:nil];
                }
                break;
            case ParmEventPage:
                if (scPacket->command == cmdWrite) {
                    //                    [trace traceFormat:@"Got ParmEventPage %d": scPacket->value];
                    //                    [trace traceBulkData: 256 : scPacket->bulk_data];
                    memcpy([pageData bytes], scPacket->bulk_data, FLASH_PAGE_SIZE);   
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"EventPageRecieved" 
                                                                        object:pageData];                    
                }
                break;


                
 
*/   
            default:
                break;
        }
    }
 }

- (void)accessoryDidDisconnect:(NSNotification *)notification {
    [trace trace:@"Accessory disconnected"];
    [self closeTheSession];
}

- (void) closeTheSession {
    sessionOpen = NO;
    [eaSessionController closeSession];
}

- (void) accessoryDataReceived:(NSNotification*) notification {
    NSData* tmpData = [eaSessionController readData:[eaSessionController readBytesAvailable]];
    [myPacket updateWithNSData:tmpData];
    [[NSNotificationCenter defaultCenter]
     postNotificationName:@"packetReceived" object:self];
}


// All remote events are updated within 500ms except for volume which is 100ms
#define REMOTE_EVENT_UPDATE_INTERVAL    (0.500)
#define VERY_SMALL_BRIGHTNESS_CHANGE    (0.005)
#define BRIGHTNESS_MIDPOINT             (0.5)

- (void)accessoryDidConnect:(NSNotification *)notification {
    tmpBrightness = [[UIScreen mainScreen] brightness];
    NSString* tmp = [[NSString alloc] initWithFormat:@"Brightness %f", tmpBrightness];
    [trace trace: tmp];
    // Sneaky trick to get iOS to send us a "wake up" packet so we wake on UART activity. It is OK for us to
    // miss this packet.
    if (tmpBrightness < BRIGHTNESS_MIDPOINT) {
        [[UIScreen mainScreen] setBrightness: tmpBrightness + VERY_SMALL_BRIGHTNESS_CHANGE];
    }
    else {
        [[UIScreen mainScreen] setBrightness: tmpBrightness - VERY_SMALL_BRIGHTNESS_CHANGE];    
    }
    [NSTimer scheduledTimerWithTimeInterval:REMOTE_EVENT_UPDATE_INTERVAL target:self selector:@selector(doOpenSessionDelay) userInfo:nil repeats:NO];
}

#define TIME_DELAY_100MS    (0.100)
- (void) doOpenSessionDelay
{
    // It appears Thunder takes about 30ms to wake out of snooze, so setting 100ms should be safe.
    [NSTimer scheduledTimerWithTimeInterval:TIME_DELAY_100MS target:self selector:@selector(doOpenSession) userInfo:nil repeats:NO];    
}

- (void) doOpenSession
{
    // Close any previously opened sessions
    [self closeTheSession];
    
    // Set brightness back to original setting
    [[UIScreen mainScreen] setBrightness:tmpBrightness];
    
    // Do the open session
    [trace trace:@"Accessory connected"];
    NSArray *accessories = [[EAAccessoryManager sharedAccessoryManager]
                            connectedAccessories];
    
    EAAccessory *accessory = nil;
    session = nil;
    for (EAAccessory *obj in accessories)
    {
        if ([[obj protocolStrings] containsObject:@"com.avnera.sc"])
        {
            accessory = obj;
            [trace trace:@"Found com.avnera.sc"];
            [eaSessionController setupControllerForAccessory:accessory withProtocolString:@"com.avnera.sc"];
            
            if (YES == [eaSessionController openSession]) {
                [[NSNotificationCenter defaultCenter] postNotificationName:@"EASessionOpenedSuccess" 
                                                                    object:nil]; 
                [trace trace:@"Open EASession Successful"];
                sessionOpen = YES;   
            }
            else {
                [trace trace:@"Open EASession Unsuccessful"];
                [[NSNotificationCenter defaultCenter] postNotificationName:@"EASessionOpenedFail" 
                                                                    object:nil]; 
                sessionOpen = NO;
            }
            break;
        }
    }    
}
@end
