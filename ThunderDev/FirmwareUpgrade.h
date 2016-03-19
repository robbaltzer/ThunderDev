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

#import <Foundation/Foundation.h>
#import <CommonCrypto/CommonDigest.h> // Need to import for CC_MD5 access
#import "MyTraceController.h"
#import "SendPacket.h"
#import "NvramControl.h"

typedef enum {
    stateIdle,
    stateGetLatest,
    stateGetLatestOneShot,
    stateWaitForLatest,
    stateWaitForLatestOneShot,    
    stateGetFileList,
    stateWaitForList,
    stateStartFlashMode,
    stateWaitStartFlashMode,
    stateGetBinaries,
    stateWaitForBinaries,
    stateGetUpgradeStartPage,
    stateWaitUpgradeStartPage,
    stateProgram,
    stateWaitForProgram,
    stateEndFlashMode,
    stateWaitEndFlashMode,
    stateResetThunder,
    stateComplete,
    stateError,
} FirmwareUpgradeState;

@interface FirmwareUpgrade : NSObject {
// Private data  
    NSString *rootRevision;
    NSDictionary *revisions;
    NSMutableDictionary *binaries;
    NSArray* orderOfProgramming;   
    SendPacket* sendPacket;
    NSString *requestType;
    FirmwareUpgradeState state;
    NSMutableDictionary* filenameLookup;
    int nFiles;     // As defined in SFS File System Header
    int nPages;     // "
    NSMutableData* fileSystemHeader;
    NSString *md5;
    NSNumber *upgradeStartPage;
    float timeout;
    MKNetworkOperation *firmwareOperation;
    MyTraceController* trace;
    NvramControl* nvram;
}

//
// Public Data
//
// This is the root FW revision number
@property NSString *rootRevision;
// Dictionary of all binary revisions that go into a FW revision
@property (nonatomic, strong) NSDictionary *revisions; 
// Dictionary of NSData objects that hold binaries keyed by filename for a FW rev
@property (nonatomic, strong) NSMutableDictionary *binaries; 
@property (nonatomic) FirmwareUpgradeState state;
@property (strong, nonatomic) MKNetworkOperation *firmwareOperation;


// Public methods
- (void)upgradeFirmwareToLatest;
- (void)getLatestFirmwareRevOneShot;

// "Private" methods
- (BOOL)fetchBinaryFileSynchronously: (NSString*) filename : (NSString*) revision;
- (void) getMD5FromServer: (NSString*) filename revision: (NSString*) revision calculatedMD5: (NSString*) calculatedMD5 responseData: (NSData *) responseData;
- (void)getLatestFirmwareRev;
- (void)getUpgradeFilesList;
- (void)getAllBinaries;
- (void)stateMachine;
@end
