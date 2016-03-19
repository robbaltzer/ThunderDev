/*
 * Copyright 2012 by Avnera Corporation, Beaverton, Oregon.
 *
 *
 * All Rights Reserved
 *
 *
 * This file may not be modified, copied, or distributed in part or in whole
 * without prior written consent from Avnera Corporation.
 *
 *
 * AVNERA DISCLAIMS ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING
 * ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT SHALL
 * AVNERA BE LIABLE FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR
 * ANY DAMAGES WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS,
 * WHETHER IN AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,
 * ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS
 * SOFTWARE.
 */

#import "AppDelegate.h"
#import "FirmwareUpgrade.h"
#import "SBJsonParser.h"
#import "protocol_defs.h"

#define STATE_MACHINE_TICK  (0.05F)        // Length of state machine tick in seconds
#define TIMEOUT_SECONDS     (2.0F)

@implementation FirmwareUpgrade
@synthesize revisions, binaries, rootRevision, state;
@synthesize firmwareOperation;

- (id) init {
    self = [super init];
    if (self) {
        trace = ApplicationDelegate.trace;
        nvram = ApplicationDelegate.nvram;
        state = stateIdle;
        fileSystemHeader = [[NSMutableData alloc] init];
        orderOfProgramming = [[NSArray alloc] initWithObjects:
                              @"app8051.bin",
                              @"dspInstr.bin",
                              @"dspInstr1.bin", 
                              @"dspInstr2.bin", 
                              @"dspInstr3.bin", 
                              @"dspInstr4.bin", 
                              @"dspInstr5.bin", 
                              @"dspInstr6.bin", 
                              @"dspInstr7.bin", 
                              @"dspInstr8.bin", 
                              @"dspParm.bin", 
                              @"dspParm1.bin", 
                              @"dspParm2.bin", 
                              @"dspParm3.bin", 
                              @"dspParm4.bin", 
                              @"dspParm5.bin", 
                              @"dspParm6.bin", 
                              @"dspParm7.bin", 
                              @"dspParm8.bin", 
                              nil];
        filenameLookup = [[NSMutableDictionary alloc] init];
        [filenameLookup setObject:@"app8051.bin" forKey:@"app8051_revision"];
        [filenameLookup setObject:@"dspInstr.bin" forKey:@"dspInstr_revision"];
        [filenameLookup setObject:@"dspInstr1.bin" forKey:@"dspInstr1_revision"];
        [filenameLookup setObject:@"dspInstr2.bin" forKey:@"dspInstr2_revision"];
        [filenameLookup setObject:@"dspInstr3.bin" forKey:@"dspInstr3_revision"];
        [filenameLookup setObject:@"dspInstr4.bin" forKey:@"dspInstr4_revision"];
        [filenameLookup setObject:@"dspInstr5.bin" forKey:@"dspInstr5_revision"];
        [filenameLookup setObject:@"dspInstr6.bin" forKey:@"dspInstr6_revision"];        
        [filenameLookup setObject:@"dspInstr7.bin" forKey:@"dspInstr7_revision"];
        [filenameLookup setObject:@"dspInstr8.bin" forKey:@"dspInstr8_revision"];
        [filenameLookup setObject:@"dspParm.bin" forKey:@"dspParm_revision"];
        [filenameLookup setObject:@"dspParm1.bin" forKey:@"dspParm1_revision"];        
        [filenameLookup setObject:@"dspParm2.bin" forKey:@"dspParm2_revision"];   
        [filenameLookup setObject:@"dspParm3.bin" forKey:@"dspParm3_revision"];        
        [filenameLookup setObject:@"dspParm4.bin" forKey:@"dspParm4_revision"];           
        [filenameLookup setObject:@"dspParm5.bin" forKey:@"dspParm5_revision"];        
        [filenameLookup setObject:@"dspParm6.bin" forKey:@"dspParm6_revision"];   
        [filenameLookup setObject:@"dspParm7.bin" forKey:@"dspParm7_revision"];        
        [filenameLookup setObject:@"dspParm8.bin" forKey:@"dspParm8_revision"];                  
        binaries = [[NSMutableDictionary alloc] init];
        
        
        firmwareOperation = nil;
        
        sendPacket = [[SendPacket alloc] init];
        [NSTimer scheduledTimerWithTimeInterval:STATE_MACHINE_TICK target:self selector:@selector(stateMachine) userInfo:nil repeats:YES];
    }
    return self;
}

- (void)upgradeFirmwareToLatest
{
    state = stateGetLatest;     // Start the upgrade process
}


// for all the binaries in the list, retrieve them all and place in our binaries dictionary. 
// We will be programming them later in the process
- (void)getAllBinaries
{    
    [binaries removeAllObjects];
    
    for (NSString* filenameKey in filenameLookup) {
        NSString* filename = [filenameLookup objectForKey:filenameKey];
        for (NSString* revisionKey in revisions) {
            if ([revisionKey isEqualToString: filenameKey]) {
                NSString* revision = [revisions objectForKey: revisionKey];
                // Initialize to "nil". Will get updated once the download is complete:
                [binaries setObject:@"" forKey: filename];
                [self fetchBinaryFileSynchronously:filename :revision];
            }
        }
    }
    
}

// Gets binary from server synchronously and stores in binaries dictionary if MD5s match
- (BOOL)fetchBinaryFileSynchronously: (NSString*) filename : (NSString*) revision
{
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    NSString *uuid = nvram.deviceUUID;
//    NSString *uuid = [ApplicationDelegate getDeviceUUID];
    
    firmwareOperation = [cloudEngine fetchBinaryFile:filename revision:revision
                                                     uuid:uuid
                                             onCompletion:^(NSData *responseData) {
                                                 u8 result[16];
                                                 CC_MD5(responseData.bytes, responseData.length, result ); 
                                                 NSString* calculatedMD5 = [NSString stringWithFormat:
                                                                            @"%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x%02x",
                                                                            result[0], result[1], result[2], result[3], 
                                                                            result[4], result[5], result[6], result[7],
                                                                            result[8], result[9], result[10], result[11],
                                                                            result[12], result[13], result[14], result[15]
                                                                            ];         
                                                 [trace traceString:@"Calculated MD5 %@": calculatedMD5];
                                                 [self getMD5FromServer: filename revision:revision calculatedMD5:calculatedMD5 responseData:responseData];
                                                 
                                             }
                                                  onError:^(NSError* error) {
                                                      [trace trace:@"Got error when requesting firmware file from DB"];
                                                  }
                              ];
    return FALSE;
}

- (void) getMD5FromServer: (NSString*) filename 
                 revision: (NSString*) revision 
            calculatedMD5: (NSString*) calculatedMD5
             responseData: (NSData *) responseData
{
    
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    NSString *uuid = nvram.deviceUUID;
    
    firmwareOperation = [cloudEngine getMD5:filename 
                                        revision:revision
                                            uuid:uuid
                                    onCompletion:^(NSString *response) {
                                        
                                        if ([response length] == 32) {
                                            NSString *serverMD5 = response;
                                            
                                            [trace trace:@"MongoDB calc'd MD5:"];
                                            [trace trace:serverMD5];  
                                            
                                            if ([calculatedMD5 isEqualToString:serverMD5]) {
                                                [binaries setObject:responseData forKey: filename];   // Store binary in dictionary
                                                [trace traceFormat:@"Binary size %d" : [responseData length]];
                                            }
                                            else {
                                                [trace trace:@"Error: MD5s didn't match"];
                                            }
                                        }
                                        else {
                                            [trace traceFormat:@"MD5 length from DB should be 32, got %d": [response length]];
                                            
                                        }
                                    }
                                         onError:^(NSError* error) {
                                             [trace trace:@"Got error when requesting MD5 from DB"];
                                         }
                              ];
    
}

- (void)getLatestFirmwareRev
{
    [trace trace:@"Requesting latest firmware revision..."];
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    NSString *uuid = nvram.deviceUUID;
    
    firmwareOperation = [cloudEngine getLatestFirmwareRev:1
                                                          uuid:uuid
                                                  onCompletion:^(NSString *version) {
                                                      NSString *msg = [[NSString alloc] initWithFormat:@"Latest (root) Firmware Rev is: %@", version];
                                                      [trace trace:msg];
                                                      
                                                      rootRevision = version;
                                                      
                                                      if( state == stateWaitForLatest )
                                                          state = stateGetFileList;
                                                      else if( state == stateWaitForLatestOneShot )
                                                          state = stateIdle;
                                                      
                                                  }
                                                       onError:^(NSError* error) {
                                                           [trace trace:@"Got error when requesting latest firmware revision from DB"];
                                                       }
                              ];
    
    
}

- (void)getLatestFirmwareRevOneShot
{
    state = stateWaitForLatestOneShot;
    [self getLatestFirmwareRev];
}



- (void)getUpgradeFilesList
{
    [trace trace:@"Requesting latest firmware revision..."];
    CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
    NSString *uuid = nvram.deviceUUID;
    
    firmwareOperation = [cloudEngine getUpgradeFileList:rootRevision
                                                        uuid:uuid
                                                onCompletion:^(NSData *responseData) {
                                                    
                                                    if( state == stateWaitForList ) {
                                                        //[trace trace:responseString];
                                                        
                                                        SBJsonParser *jsonParser = [[SBJsonParser alloc] init];
                                                        revisions = [jsonParser objectWithData:responseData];
                                                        jsonParser = nil;
                                                        
                                                        state = stateGetBinaries;
                                                    }
                                                    
                                                }
                                                     onError:^(NSError* error) {
                                                         [trace trace:@"Got error when requesting latest firmware revision from DB"];
                                                     }
                              ];
}

// Concatenate all the binaries into a single NSMutable data in the correct order of programming,
// Then send it all to the EAAccessory transmit pipe
- (void) programBinaries
{
    bool validUpgrade = NO;
    NSMutableData* allBinaries = [[NSMutableData alloc] init];
    u8 nullPadding[16] = 
    {
        0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff,
        0xff, 0xff, 0xff, 0xff,
    };
    NSData * nullPaddingData = [[NSData alloc] initWithBytes:nullPadding length:16];
    
    for (NSString* filenameOrder in orderOfProgramming) {
        for (NSString* filenameBinary in binaries) {
            if ([filenameOrder isEqualToString:filenameBinary]) {
                [allBinaries appendData:[binaries objectForKey: filenameBinary]];
                if ([filenameBinary isEqualToString:@"app8051.bin"]) {
                    validUpgrade = YES;
                }
                [trace traceString:@"allbinarys += %@": filenameBinary];
            }
        }
    }
    [allBinaries appendData:nullPaddingData];
    if (!validUpgrade) {
        [trace trace:@"No app8051.bin file present. Not a valid upgrade"];
        state = stateError;
        return;
    }
    [trace traceFormat:@"allBinary length %d": [allBinaries length]]; 
    [sendPacket sendBinFile: [upgradeStartPage intValue] : (void*) [allBinaries bytes] : [allBinaries length]];
    state = stateEndFlashMode;
}

- (void) UpgradeStartPageReceived: (NSNotification*) notification
{
    upgradeStartPage = (NSNumber*) [notification object];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"UpgradeStartPageReceived" object:nil];    
    state = stateStartFlashMode;
}

- (void) ResetThunderAckReceived: (NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"ResetThunderAckReceived" object:nil];
    state = stateComplete;
}

- (void) FlashModeAckReceived: (NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"FlashModeAckReceived" object:nil];

    if (state == stateWaitStartFlashMode) {
        state = stateProgram;    
    }
    else if (state == stateWaitEndFlashMode) {
        state = stateResetThunder;    
    }
    else {
        state = stateError;
    }
}

- (void) accessoryDidDisconnect: (NSNotification*) notification
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:EAAccessoryDidDisconnectNotification object:nil];
    state = stateError;
}

#define TIMEOUT_TICKS           ((TIMEOUT_SECONDS)/(STATE_MACHINE_TICK))
#define INVALID_REVISION        @"INVALID REVISION";

- (void) stateMachine
{
    bool all_downloaded = TRUE;
    timeout += STATE_MACHINE_TICK;
    switch(state) {
        case stateIdle:
            break;
        case stateGetLatest:
            
            if ([ApplicationDelegate.nvram.deviceUUID length] < 36) {
                [trace trace:@"Please use User Menu to enter a valid UUID"];
                state = stateError;
                break;
            }
            
            rootRevision = INVALID_REVISION;  
            [[NSNotificationCenter defaultCenter] addObserver:self 
                                                     selector:@selector(accessoryDidDisconnect:) 
                                                         name:EAAccessoryDidDisconnectNotification 
                                                       object:nil];
            state = stateWaitForLatest;
            [self getLatestFirmwareRev];
            timeout = 0;
            break;
        case stateWaitForLatest:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitForLatest"];
                state = stateError;
            }
            break;
        case stateGetFileList:
            state = stateWaitForList;
            [self getUpgradeFilesList];
            timeout = 0;
        case stateWaitForList:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitForList"];
                state = stateError;
            }
            break;
        case stateGetBinaries:
            [self getAllBinaries];
            state = stateWaitForBinaries;
            timeout = 0;
            break;
        case stateWaitForBinaries:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitForBinaries"];
                state = stateError;
            }
            
            // Check whether all binary files have downloded:
            //bool all_downloaded = TRUE;
            for( NSString *aKey in binaries )
            {
                if( [binaries objectForKey:aKey] == @"" ) {
                    all_downloaded = FALSE;
                    break;
                }
            }
            if( all_downloaded == TRUE) {
                state = stateGetUpgradeStartPage;
                //[trace trace:@"Waiting for binaries; ALL DOWNLOADED!"];
            } else
                //[trace trace:@"Waiting for binaries"];
                break;
        case stateGetUpgradeStartPage:
            [sendPacket sendSimplePacket:ParmUpgradeStartPage :cmdGet :0];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(UpgradeStartPageReceived:)
                                                         name:@"UpgradeStartPageReceived"
                                                       object:nil];   
            state = stateWaitUpgradeStartPage;
            timeout = 0;
            break;
        case stateWaitUpgradeStartPage:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitUpgradeStartPage"];
                state = stateError;
            }
            break;
        case stateStartFlashMode:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(FlashModeAckReceived:)
                                                         name:@"FlashModeAckReceived"
                                                       object:nil];   
            [sendPacket sendSimplePacket:ParmFlash :cmdStart :0];
            state = stateWaitStartFlashMode;
            timeout = 0;
            break;
        case stateWaitStartFlashMode:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitStartFlashMode"];
                state = stateError;
            }
            break;
            
        case stateProgram:
            [self programBinaries];
            [trace trace:@"All binary data put into TX pipe. Accessory is being programmed"];
            timeout = 0;
            break;
        case stateWaitForProgram:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitForProgram"];
                state = stateError;
            }
            break;
        case stateEndFlashMode:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(FlashModeAckReceived:)
                                                         name:@"FlashModeAckReceived"
                                                       object:nil];   
            [sendPacket sendSimplePacket :ParmFlash :cmdEnd :0];
            state = stateWaitEndFlashMode;
            timeout = 0;
            break;
        case stateWaitEndFlashMode:
            if (timeout >= 20*TIMEOUT_TICKS) {
                [trace trace:@"FirmwareUpgrade.m: Timeout stateWaitEndFlashMode"];
                state = stateError;
            }
            break;
        case stateResetThunder:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(ResetThunderAckReceived:)
                                                         name:@"ResetThunderAckReceived"
                                                       object:nil];  
            [sendPacket sendSimplePacket :ParmResetDevice :cmdRequest :0];
            state = stateComplete;
            break;
        case stateComplete:
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [trace trace:@"Firmware upgrade successful. Quitting"];
            state = stateIdle;
        { 
            NSString *uuid = nvram.deviceUUID;
            
            // Send data to the server:
            CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
            firmwareOperation = [cloudEngine sendFirmwareUpdateStatus:uuid
                                                                 status:@"firmware_updated"
                                                               revision:rootRevision
                                                           onCompletion:^(NSString *response) {
                                                               [trace trace:@"firmware_updated POST Succeeded"];
                                                           } 
                                                                onError:^(NSError* error) {
                                                                    [trace trace:@"  POST FAILED"];
                                                                }
                                   ];
        }

            break;
        case stateError:
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [trace trace:@"An error occurred during upgrade process. Quitting"];
            state = stateIdle;
        {
            NSString *uuid = nvram.deviceUUID;
            
            // Send data to the server:
            CloudEngine *cloudEngine = ApplicationDelegate.cloudEngine;
            firmwareOperation = [cloudEngine sendFirmwareUpdateStatus:uuid
                                                                 status:@"firmware_update_failed"
                                                               revision:rootRevision
                                                           onCompletion:^(NSString *response) {
                                                               [trace trace:@"firmware_update_failed POST Succeeded "];
                                                           } 
                                                                onError:^(NSError* error) {
                                                                    [trace trace:@"  POST FAILED"];
                                                                }
                                   ];
        }
            break;
        default:
            break;
    }
}


@end
