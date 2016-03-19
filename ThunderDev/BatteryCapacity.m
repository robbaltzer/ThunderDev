//
//  BatteryCapacity.m
//  ThunderDev
//
//  Created by Rob Baltzer on 7/24/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "BatteryCapacity.h"
#import "AppDelegate.h"
#import "protocol_defs.h"

// NOTE: bcs = (b)attery (c)apacity (s)tate
typedef enum {
    bcsIdle,
    bcsDebounceConnect,
    bcsStartFastFill,
    bcsGetSample,
    bcsWaitForSample,
    bcsGetPowerMode,
    bcsWaitPowerMode,
    bcsComplete,
    bcsError,
} BatteryCapacityState;

#define STATE_MACHINE_TICK      (100)        // Length of state machine tick in ms

#define ZONE_HYSTERESIS_MV      (100)


@implementation BatteryCapacity
- (id) init {
    self = [super init];
    if (self) {
        trace = ApplicationDelegate.trace;        
        packetHandler = ApplicationDelegate.packetHandler;
        sendPacket = [[SendPacket alloc] init];
        sample = [[NSMutableArray alloc] init];
        powerMode = pmodeInvalid;
        [[NSNotificationCenter defaultCenter]   addObserver:self 
                                                   selector:@selector(accessoryDidConnect:) 
                                                       name:EAAccessoryDidConnectNotification 
                                                     object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self 
                                                 selector:@selector(accessoryDidDisconnect:) 
                                                     name:EAAccessoryDidDisconnectNotification 
                                                   object:nil];
        float tmp = (float)STATE_MACHINE_TICK/1000.0F;
        [NSTimer scheduledTimerWithTimeInterval:tmp target:self selector:@selector(stateMachine) userInfo:nil repeats:YES];
        if ([packetHandler sessionOpen]) {
            state = bcsStartFastFill;
        }
        else {
            state = bcsIdle;
        }
    }
    return self;
}

-(void) accessoryDidConnect: (NSNotification*) notif {
    [trace trace:@"accessoryDidConnectaccessoryDidConnect"];
//    if (state == bcsIdle) {
        [trace trace:@"1"];
        timeout = 0;
        state = bcsDebounceConnect;
//    }
}

-(void) accessoryDidDisconnect: (NSNotification*) notif {
    if (state != bcsDebounceConnect) {
        [trace trace:@"2"];
        state = bcsIdle;
        powerMode = pmodeInvalid;
    }
}

/*
 - Listen for connection notifications
 - Start calc'ing battery percentage (maybe getting lots of samples at first)
 - Use rolling average +/- deltas
 - Need state VDC/Battery sent from Thunder (without asking for it)
 - We will poll for battery mv
*/

#define TIMEOUT_MS                  (2000)           
#define DEBOUNCE_CONNECT_MS         (5000)
#define FAST_FILL_SAMPLE_RATE_MS    (100)
#define MONITOR_SAMPLE_RATE_MS      (10000)
#define SAMPLE_ARRAY_SIZE           (30)

#define TIMEOUT_TICKS               ((TIMEOUT_MS)/(STATE_MACHINE_TICK))
#define DEBOUNCE_CONNECT_TICKS      ((DEBOUNCE_CONNECT_MS)/(STATE_MACHINE_TICK))
#define FAST_FILL_SAMPLE_RATE_TICKS ((FAST_FILL_SAMPLE_RATE_MS)/(STATE_MACHINE_TICK))

static int arrayCount;

// Note: All timing is done in milliseconds (timeout)
- (void) stateMachine
{
    timeout += 1;  
    switch(state) {
        case bcsIdle:
            break;
            
        // We need this state since we seem to get consecutive connects and we need to ignore the first one    
        case bcsDebounceConnect:
            if (timeout > DEBOUNCE_CONNECT_TICKS) {
                if ([packetHandler sessionOpen]) {            
                    state = bcsGetPowerMode;   
                }
                else {
                    state = bcsIdle;                     
                }
            }
            break;
            
        case bcsGetPowerMode:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(PowerModeReceived:)
                                                         name:@"PowerModeReceived"
                                                       object:nil];
            [sendPacket sendSimplePacket:ParmPowerMode :cmdRequest : 0];
            timeout = 0;
            state = bcsWaitPowerMode;
            break;
            
        case bcsWaitPowerMode:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"BatteryCapacity.m: Timeout bcsWaitPowerMode"];
                state = bcsIdle;
                return;
            }
            break;
            
        case bcsStartFastFill:
            state = bcsGetSample;
            arrayCount = 0;
            [sample removeAllObjects];
            [trace trace:@"10"];
            timeout = 0;
            [trace trace:@"bcsGetSample"];
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(BatteryMillivoltsReceived:)
                                                         name:@"BatteryMillivoltsReceived"
                                                       object:nil];
            break;
            
        case bcsGetSample:
            if (timeout > FAST_FILL_SAMPLE_RATE_TICKS) {
                [sendPacket sendSimplePacket:ParmBatteryMillivolts :cmdGet :0];
                timeout = 0;
                state = bcsWaitForSample;
            }
            break;
            
        case bcsWaitForSample:
            if (timeout >= TIMEOUT_TICKS) {
                [trace trace:@"BatteryCapacity.m: Timeout bcsWaitForSample"];
                state = bcsIdle;
                return;
            }
            // Add to array
            // if full, go to MONITOR STATE
            break;
            
        case bcsComplete:
            [[NSNotificationCenter defaultCenter] removeObserver:self];
            [trace trace:@"Battery capacity statemachine complete. Going idle."];
            state = stateIdle;     
            break;
        
        default:
            break;
    }
}

-(void) BatteryMillivoltsReceived: (NSNotification*) notif {
    if (state == bcsWaitForSample) {
        NSString* tmp = [[NSString alloc] initWithFormat:@"sample %d value %d", arrayCount, [[notif object] intValue]];
        [trace trace:tmp];
        [sample addObject: [notif object]];
        
        arrayCount++;
        if (arrayCount >= SAMPLE_ARRAY_SIZE) {
            [[NSNotificationCenter defaultCenter] removeObserver:self
                                                            name:@"BatteryMillivoltsReceived"
                                                          object:nil];
            [self calcBatteryCapacity:true];
            state = bcsComplete; 
            // TODO: Go to monitor state
        }
        else {
            timeout = 0;
            state = bcsGetSample;
        }
    }
}

-(void) PowerModeReceived: (NSNotification*) notif {
    if (state == bcsWaitPowerMode) {
        [[NSNotificationCenter defaultCenter] removeObserver:self
                                                        name:@"PowerModeReceived"
                                                      object:nil];
        powerMode = (PowerMode_t) [[notif object] intValue];
        state = bcsStartFastFill;
    }
}

- (u8) calcBatteryCapacity: (bool) initialCalc {
    // Calc mean
    int tmp, capacity = 0;   // a value from 0 - 10
    int mean = [self calcSampleMean];
    [trace traceFormat:@"Mean: %d" : mean];
    int range = [self calcRange];
    [trace traceFormat:@"Range: %d" : range];
    
    if (powerMode == PmodeVdc) {
        mean = mean - 15;
    }
    
    
    if (initialCalc) {
        if (mean >= 4100) {
            capacity = 10;
            goto exit;
        }
        else {
            tmp = (mean - 3500) / 60;
            goto exit;
        }
    }
    
    //    int range = 
    // take into account range, power mode, hysteresis
    // adjust mean
    
exit:
    [[NSNotificationCenter defaultCenter] postNotificationName:@"BatteryVoltagePercent" 
                                                        object:[NSNumber numberWithInt:capacity*10]];
    [trace traceFormat:@"Capacity: %d" : capacity];
    return capacity;
}

- (int) calcSampleMean {
    int i, tmp = 0;
    
    i = SAMPLE_ARRAY_SIZE;
    while(i--) {
        tmp += [[sample objectAtIndex:i] intValue];
    }
    tmp = tmp / SAMPLE_ARRAY_SIZE;
    return tmp;
}

- (int) calcRange {
    int lo = 0, hi = 0, sampleVal, i;
    
    i = SAMPLE_ARRAY_SIZE;
    
    hi = [[sample objectAtIndex:0] intValue];
    lo = [[sample objectAtIndex:0] intValue];
    while(i--) {
        sampleVal = [[sample objectAtIndex:i] intValue];
        if (lo > sampleVal) {
            lo = sampleVal;
        }
        if (hi < sampleVal) {
            hi = sampleVal;
        }
    }

    return hi-lo;
}

@end








