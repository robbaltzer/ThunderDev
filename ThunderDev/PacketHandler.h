//
//  PacketHandler.h
//  ThunderDev
//
//  Created by Rob Baltzer on 4/27/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "SendPacket.h"
#import <ExternalAccessory/ExternalAccessory.h>
#import "MyTraceController.h"
#import "MyPacket.h"
#import "PageData.h"

@class EASessionController;



@interface PacketHandler : NSObject {
    SendPacket* sendPacket;
    EASessionController *eaSessionController;
    EASession *session;
    MyTraceController* trace;
    MyPacket *myPacket;
    PageData *pageData;
    NSMutableArray* initParameters;
    BOOL sessionOpen;
    float tmpBrightness;
}

@property (nonatomic, strong) MyPacket *myPacket;
@property (nonatomic) BOOL sessionOpen;


@end
