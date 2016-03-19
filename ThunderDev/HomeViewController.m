//
//  HomeViewController.m
//  ThunderDev
//
//  Created by Rob Baltzer on 4/13/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "HomeViewController.h"
#import "AppDelegate.h"
#import "VersionInfo.h"


@implementation HomeViewController
@synthesize millivoltLabel;
@synthesize labelUUID;
@synthesize tabHome;
@synthesize labelTitle;
@synthesize labelThunderBatteryTitle;
@synthesize labeliPadBatteryTitle;
@synthesize labelBatteryChargingPreference;
@synthesize labelSoundProcessing;
@synthesize labelAutoSelect;
@synthesize toggleAutoSelect;
@synthesize radioButtonsCharging;
@synthesize radioButtonsSoundProcessing;
@synthesize labelIpadBatteryLevel;
@synthesize labelThunderBatteryLevel;
@synthesize trace;
@synthesize labelRevisionText;
@synthesize labelRevisionNumber;

#define INVALID_SEGMENTED_CONTROL_VALUE (-1)
#define STATE_MACHINE_TICK              (0.05F)        
#define TIMEOUT_SECONDS                 (2.0F)

typedef enum {
    stateMainIdle,
    stateMainStart,
    stateMainSendParameter,
    stateMainWaitForNotification,
    stateMainGetUuid,
    stateMainWaitUuid,
    stateMainEnd,
    stateMainTimeout,
    stateMainError,
} MAIN_STATES;
// This state machine inits all the parameters on a connect
static MAIN_STATES state;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    NSNumber *revisionNumber = [NSNumber numberWithFloat:THUNDER_DEV_APP_VERSION];
    [labelRevisionNumber setText:[NSNumberFormatter 
                                  localizedStringFromNumber:revisionNumber
                                  numberStyle:kCFNumberFormatterDecimalStyle]];  
    self.labelTitle.text = NSLocalizedString(@"THUNDER", @"Thunder");
    self.labelRevisionText.text = NSLocalizedString(@"REVISION", @"Revision");
    self.labelThunderBatteryTitle.text = NSLocalizedString(@"THUNDER", @"Thunder");
    self.labeliPadBatteryTitle.text = NSLocalizedString(@"IPAD", @"iPad");   
    [radioButtonsCharging setTitle:NSLocalizedString(@"THUNDER", @"Thunder") forSegmentAtIndex:0];
    [radioButtonsCharging setTitle:NSLocalizedString(@"AUTO", @"Auto") forSegmentAtIndex:1];
    [radioButtonsCharging setTitle:NSLocalizedString(@"IPAD", @"iPad") forSegmentAtIndex:2];
    self.labelBatteryChargingPreference.text = NSLocalizedString(@"BATTERY_CHARGING_PREFERENCE", @"Battery Charging Preference");
    self.labelSoundProcessing.text = NSLocalizedString(@"SOUND_PROCESSING", @"Sound Processing");    
    self.labelAutoSelect.text = NSLocalizedString(@"AUTO_SELECT", @"Auto Select");
    [radioButtonsSoundProcessing setTitle:NSLocalizedString(@"MOVIE_MODE", @"Movie Mode") forSegmentAtIndex:0];
    [radioButtonsSoundProcessing setTitle:NSLocalizedString(@"GAMING_MODE", @"Gaming Mode") forSegmentAtIndex:1];
    [radioButtonsSoundProcessing setTitle:NSLocalizedString(@"MUSIC_MODE", @"Music Mode") forSegmentAtIndex:2];
    
    initParameters = [[NSMutableArray alloc] init];
    
    // NOTE: ParmDspAutoSelect needs to be updated before ParmDspIndex
    [initParameters addObject:[[ParameterNotificationPair alloc] initWithPair:ParmDspAutoSelect         :@"ParmDspAutoSelectReceived"]];
    [initParameters addObject:[[ParameterNotificationPair alloc] initWithPair:ParmBatteryVoltagePercent :@"ParmBatteryVoltagePercentReceived"]];
    [initParameters addObject:[[ParameterNotificationPair alloc] initWithPair:ParmChargeMode            :@"ParmChargeModeReceived"]];
    [initParameters addObject:[[ParameterNotificationPair alloc] initWithPair:ParmDspIndex              :@"ParmDspIndexReceived"]];
    [initParameters addObject:[[ParameterNotificationPair alloc] initWithPair:ParmFirmwareVersion       :@"ParmFirmwareVersionReceived"]];
    
    nvram = ApplicationDelegate.nvram;
    packetHandler = ApplicationDelegate.packetHandler;
    [self loadModalRegistrationViewController];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChange:)
                                                 name:@"ipadBatteryLevelChanged"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleDisconnect:)
                                                 name:EAAccessoryDidDisconnectNotification
                                               object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(handleConnect:)
                                                 name:@"EASessionOpenedSuccess" 
                                               object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(batteryLevelDidChange:)
                                                 name:UIDeviceBatteryLevelDidChangeNotification 
                                               object:nil];
    [UIDevice currentDevice].batteryMonitoringEnabled = YES;
    [self batteryLevelDidChange:nil];
    [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(batteryLevelDidChange:) userInfo:nil repeats:YES]; 
    [self updateThunderBatteryLevelLabel:-1];
    sendPacket = [[SendPacket alloc] init];
    self.radioButtonsCharging.selectedSegmentIndex = INVALID_SEGMENTED_CONTROL_VALUE;
    self.radioButtonsSoundProcessing.selectedSegmentIndex = INVALID_SEGMENTED_CONTROL_VALUE;

    state = stateMainIdle;
    [NSTimer scheduledTimerWithTimeInterval:STATE_MACHINE_TICK target:self selector:@selector(stateMachine) userInfo:nil repeats:YES];
    if ([packetHandler sessionOpen] == YES) {
        [self handleConnect:nil];
    }
    [millivoltLabel setText:@""];
    // Do any additional setup after loading the view, typically from a nib.
}

- (void) batteryLevelDidChange: (NSNotification*) notification
{
    float batteryLevel = [UIDevice currentDevice].batteryLevel;
    NSNumber *levelObj = [NSNumber numberWithFloat:batteryLevel];
    
    if (batteryLevel < 0) {
        [labelIpadBatteryLevel setText:NSLocalizedString(@"UNKNOWN", @"Unknown")];
    }
    else {     
        [labelIpadBatteryLevel setText:[NSNumberFormatter 
                                        localizedStringFromNumber:levelObj
                                        numberStyle:NSNumberFormatterPercentStyle]];
    }
}

- (void) handleConnect : (NSNotification *) notif
{
    [trace trace:@"handleConnect"];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ParmBatteryVoltagePercentReceived:)
                                                 name:@"ParmBatteryVoltagePercentReceived"
                                               object:nil];    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ParmChargeModeReceived:)
                                                 name:@"ParmChargeModeReceived"
                                               object:nil];   
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ParmDspIndexReceived:)
                                                 name:@"ParmDspIndexReceived"
                                               object:nil];  
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ParmDspAutoSelectReceived:)
                                                 name:@"ParmDspAutoSelectReceived"
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(ParmFirmwareVersionReceived:)
                                                 name:@"ParmFirmwareVersionReceived" 
                                               object:nil];


    // Wait a bit before we start updating parameters. There is a lot going on during authentication.
    [NSTimer scheduledTimerWithTimeInterval:.25 target:self selector:@selector(initParameters) userInfo:nil repeats:NO];
}

- (void) initParameters
{
    state = stateMainStart;    
}

- (void) handleDisconnect : (NSNotification *) notif
{
    state = stateMainIdle;
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"BatteryVoltagePercent"
                                                  object:nil];

    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"ParmChargeModeReceived"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"ParmDspIndexReceived"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"ParmDspAutoSelectReceived"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"ParmFirmwareVersionReceived"
                                                  object:nil];
    [[NSNotificationCenter defaultCenter] removeObserver:self
                                                    name:@"MfgDataReceived"
                                                  object:nil];
    [self updateThunderBatteryLevelLabel: -1];
    self.radioButtonsCharging.selectedSegmentIndex = INVALID_SEGMENTED_CONTROL_VALUE;
    self.radioButtonsCharging.enabled = NO;
    self.radioButtonsSoundProcessing.selectedSegmentIndex = INVALID_SEGMENTED_CONTROL_VALUE;
    self.radioButtonsSoundProcessing.enabled = NO;
    self.toggleAutoSelect.hidden = YES;
    self.labelAutoSelect.hidden = YES;
    self.labelUUID.hidden = YES;
}



- (void) ParmFirmwareVersionReceived: (NSNotification*) notification {
    u8* bytes;
    
    PageData* pageData = [notification object];
    bytes = [pageData bytes];
    
    u8 firmwareMajorVersion = *bytes++;
    u8 firmwareMinorVersion = *bytes++;
    u8 firmwareID = *bytes;
    
    NSString* tmp1 = [[NSString alloc] initWithFormat:@"Version: %d.%d %d",firmwareMajorVersion,firmwareMinorVersion,firmwareID];
    [trace trace:tmp1];    
    NSString *tmp = [[NSMutableString alloc] initWithFormat:@"%d.%d", firmwareMajorVersion, firmwareMinorVersion];
    [ApplicationDelegate setCurrentRevision:tmp];
}

- (void) ParmBatteryVoltagePercentReceived: (NSNotification*) notification
{
    NSNumber* number = [notification object];
    
    [self updateThunderBatteryLevelLabel: [number intValue]];    
}

- (void) ParmChargeModeReceived: (NSNotification*) notification
{
    NSNumber* number = [notification object];
    self.radioButtonsCharging.enabled = YES;
    [self updateRadioButtonCharging: (ChargeControl_t) [number intValue]];    
}

- (void) ParmDspIndexReceived: (NSNotification*) notification
{
    NSNumber* number = [notification object];
    
    self.radioButtonsSoundProcessing.enabled = YES;
    self.radioButtonsSoundProcessing.selectedSegmentIndex = (DspIndex_t) [number intValue];   
}

- (void) ParmDspAutoSelectReceived: (NSNotification*) notification
{
    NSNumber* number = [notification object];
    
    self.toggleAutoSelect.hidden = false;
    self.labelAutoSelect.hidden = false;
    self.toggleAutoSelect.on = [number boolValue];
    self.radioButtonsSoundProcessing.enabled = !self.toggleAutoSelect.isOn;
}

- (void) updateThunderBatteryLevelLabel: (int) percentage
{
    float floatPercentage = (float) percentage / 100.0;
    NSNumber *levelObj = [NSNumber numberWithFloat:floatPercentage];
    
    if (percentage == -1) {
        [labelThunderBatteryLevel setText:NSLocalizedString(@"UNKNOWN", @"Unknown")];
    }
    else {       
        [labelThunderBatteryLevel setText:[NSNumberFormatter 
                                           localizedStringFromNumber:levelObj
                                           numberStyle:NSNumberFormatterPercentStyle]];        
    }
}

- (void) updateRadioButtonCharging: (ChargeControl_t) mode
{
    self.radioButtonsCharging.selectedSegmentIndex = mode;
}

- (void)viewDidUnload
{
    [UIDevice currentDevice].batteryMonitoringEnabled = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self setLabelIpadBatteryLevel:nil];
    [self setLabelThunderBatteryLevel:nil];
    [self setRadioButtonsCharging:nil];
    [self setRadioButtonsSoundProcessing:nil];
    [self setLabelTitle:nil];
    [self setLabelThunderBatteryTitle:nil];
    [self setLabeliPadBatteryTitle:nil];
    [self setLabelBatteryChargingPreference:nil];
    [self setLabelSoundProcessing:nil];
    [self setTabHome:nil];
    [self setLabelAutoSelect:nil];
    [self setToggleAutoSelect:nil];

    [self setLabelRevisionText:nil];
    [self setLabelRevisionNumber:nil];
    [self setLabelUUID:nil];
    [self setMillivoltLabel:nil];
    [super viewDidUnload];
    // Release any retained subviews of the main view.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    if (interfaceOrientation == UIInterfaceOrientationPortraitUpsideDown) {
        return NO;
    }
    if (interfaceOrientation == UIInterfaceOrientationPortrait) {
        return NO;
    }
    return YES;
}

- (IBAction)radioButtonCharging:(id)sender {
    ChargeControl_t chargeMode = (ChargeControl_t) self.radioButtonsCharging.selectedSegmentIndex;
    [sendPacket sendSimplePacket:ParmChargeMode :cmdSet :chargeMode];
}

- (IBAction)radioButtonSoundProcessing:(id)sender {
    [sendPacket sendSimplePacket:ParmDspIndex :cmdSet : self.radioButtonsSoundProcessing.selectedSegmentIndex];

}

- (IBAction)registrationButton:(id)sender {

    [self loadModalRegistrationViewController];
}

- (IBAction)toggleAutoSelect:(id)sender {
    self.radioButtonsSoundProcessing.enabled = !self.toggleAutoSelect.isOn;
    if (toggleAutoSelect.isOn) {
        [sendPacket sendSimplePacket:ParmDspAutoSelect: cmdSet: YES];    
    }
    else {
        [sendPacket sendSimplePacket:ParmDspAutoSelect: cmdSet: NO];            
    }
}

- (void)loadModalRegistrationViewController {
    UIViewController *ivc = [[UIViewController alloc] init];
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:ivc];
    nc.modalPresentationStyle = UIModalPresentationFormSheet;
    
    [self presentModalViewController:nc animated:YES];
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender
{
    if ([segue.identifier isEqualToString:@"ShowDebugScene"])
    {
        [segue.destinationViewController setTrace:trace];
    }
}

#define TIMEOUT_TICKS           ((TIMEOUT_SECONDS)/(STATE_MACHINE_TICK)/30)
static u8 parameterIndex;
static u8 retries;

- (void) stateMachine
{
    timeout += STATE_MACHINE_TICK;
    switch(state) {
        case stateMainIdle:
            // do nothing
            break;
        case stateMainStart:
            parameterIndex = 0;
            retries = 0;
            state = stateMainSendParameter;
            break;
        case stateMainSendParameter:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(handleStateNotification:)
                                                         name:[[initParameters objectAtIndex:parameterIndex] notificationString]
                                                       object:nil];
            [sendPacket sendSimplePacket:[[initParameters objectAtIndex:parameterIndex] parameter] :cmdGet : 0];
            timeout = 0;
            state = stateMainWaitForNotification;            
            break;
        case stateMainWaitForNotification:
            if (timeout >= TIMEOUT_TICKS) {
                if (retries < 3) {
                    retries += 1;
                    state = stateMainSendParameter;
                }
                else {
                    state = stateMainTimeout;
                }
            }
            break;
        case stateMainGetUuid:
            [[NSNotificationCenter defaultCenter] addObserver:self
                                                     selector:@selector(MfgDataReceived:)
                                                         name:@"MfgDataReceived" 
                                                       object:nil];
            [nvram readUUID];
            state = stateMainWaitUuid;
            timeout = 0;
            break;
        case stateMainWaitUuid:
            if (timeout >= TIMEOUT_TICKS) {
                if (retries < 3) {
                    retries += 1;
                    state = stateMainGetUuid;
                }
                else {
                    state = stateMainTimeout;
                }
            }
            break;
        case stateMainEnd:
            [trace trace:@"stateMainEnd - Successfull - going idle"];
            state = stateMainIdle;
            break;
        case stateMainTimeout:
            [trace trace:@"stateMainTimeout - going idle"];
            state = stateMainIdle;
            break;
        case stateMainError:
            [trace trace:@"stateMainError. Quitting. - going idle"];
            state = stateMainIdle;
            break;
        default:
            break;
    }
}

- (void) handleStateNotification: (NSNotification*) notification
{
    if (state == stateMainWaitForNotification) {
        [trace trace:[notification name]];
        if ([[[initParameters objectAtIndex:parameterIndex] notificationString] isEqualToString: [notification name]]) {
            parameterIndex += 1;
            retries = 0;
            if (parameterIndex >= [initParameters count]) {
                state = stateMainGetUuid;
                retries = 0;
            }
            else {
                state = stateMainSendParameter;
            }
        }
    }
}

- (void) MfgDataReceived: (NSNotification*) notification {
    [labelUUID setText:(NSString*) [notification object]];
    self.labelUUID.hidden = NO;
    [[NSNotificationCenter defaultCenter] removeObserver:self 
                                                    name:@"MfgDataReceived" 
                                                  object:nil];
    state = stateMainEnd;
}

- (IBAction)startMillivoltUpdates:(id)sender {
    millivoltUpdateTimer = [NSTimer scheduledTimerWithTimeInterval:1
                                                            target:self 
                                                          selector:@selector(millivoltUpdateMethod)
                                                          userInfo:nil 
                                                           repeats:YES]; 
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(BatteryMillivoltsReceived:)
                                                 name:@"BatteryMillivoltsReceived" 
                                               object:nil];
    // TODO: register for notifications
}

- (IBAction)stopMillivoltUpdates:(id)sender {
    [millivoltUpdateTimer invalidate];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:@"BatteryMillivoltsReceived" object:nil];
    [millivoltLabel setText:@""];
    //
    // TODO: unregister for notifications, hide millivolts
}

- (void) millivoltUpdateMethod {
        [sendPacket sendSimplePacket:ParmBatteryMillivolts :cmdGet :0];
}

- (void) BatteryMillivoltsReceived: (NSNotification*) notif {
//    [millivoltLabel setText:[NSNumberFormatter 
//                                  localizedStringFromNumber:[notif object]
//                                  numberStyle:kCFNumberFormatterDefaultFormat]]; 

    
    NSString* tmp = [[NSString alloc] initWithFormat:@"%d", [[notif object] intValue]];
    [millivoltLabel setText:tmp];
}
@end
