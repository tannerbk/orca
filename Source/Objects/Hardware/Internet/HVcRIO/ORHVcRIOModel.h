//--------------------------------------------------------
// ORHVcRIOModel
// Created by Mark  A. Howe on Oct 17, 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2017, University of North Carolina. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//North Carolina sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//North Carolina reserve all rights in the program. Neither the authors,
//University of North Carolina, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

@class ORTimeRate;
@class ORSafeQueue;
@class NetSocket;

@interface ORHVcRIOModel : OrcaObject
{
    @private
        NSString*           ipAddress;
        BOOL                isConnected;
        NetSocket*          socket;
        BOOL                wasConnected;
  
		NSString*			lastRequest;
		ORSafeQueue*		cmdQueue;
		NSMutableString*    buffer;

		unsigned long		readCount;
		NSString*			setPointFile;
        BOOL                readOnce;
        NSMutableArray*     measuredValues;
        NSMutableArray*     setPoints;
    
        BOOL                expertPCControlOnly;
        BOOL                zeusHasControl;
        BOOL                orcaHasControl;
        BOOL                isBusy;
        BOOL                verbose;
        NSMutableString*    stringBuffer;
        BOOL                showFormattedDates;
}

#pragma mark ***Initialization
- (void) dealloc;
- (NSString*) commonScriptMethods;

#pragma mark ***Accessors
- (id) setPointItem:(int)i forKey:(NSString*)aKey;
- (id) measuredValueItem:(int)i forKey:(NSString*)aKey;
- (void) setSetPoint: (int)aIndex withValue: (double)value;
- (void) setSetPointReadback: (int)aIndex withValue: (double)value;
- (id) setPointAtIndex:(int)i;
- (id) setPointReadBackAtIndex:(int)i;
- (id) measuredValueAtIndex:(int)i;
- (void) setMeasuredValue: (int)aIndex withValue: (double)value;
- (NetSocket*) socket;
- (void) setSocket:(NetSocket*)aSocket;
- (NSString*) ipAddress;
- (void) setIpAddress:(NSString*)aIpAddress;
- (BOOL) isConnected;
- (void) setIsConnected:(BOOL)aFlag;
- (void) writeCmdString:(NSString*)aCommand;
- (void) parseString:(NSString*)theString;
- (void) connect;
- (void) setVerbose:(BOOL)aState;
- (BOOL) verbose;
- (void) setShowFormattedDates:(BOOL)aState;
- (BOOL) showFormattedDates;

- (NSString*) title;

- (NSString*) setPointFile;
- (void) setSetPointFile:(NSString*)aPath;
- (NSString*) lastRequest;
- (void) setLastRequest:(NSString*)aRequest;
- (int) queCount;
- (BOOL) isBusy;
- (void) flushQueue;
- (void) createSetPointArray;
- (NSInteger) numSetPoints;
- (void) createMeasuredValueArray;
- (NSInteger) numMeasuredValues;
- (BOOL) expertPCControlOnly ;
- (BOOL) zeusHasControl;
- (BOOL) orcaHasControl;

#pragma mark ***Commands
- (void) writeSetpoints;
- (void) readBackSetpoints;
- (void) readMeasuredValues;

- (id)   initWithCoder:(NSCoder*)decoder;
- (void) encodeWithCoder:(NSCoder*)encoder;
- (void) readSetPointsFile:(NSString*) aPath;
- (void) saveSetPointsFile:(NSString*) aPath;
- (void) pushReadBacksToSetPoints;

@end

@interface NSObject (ORHistModel)
- (void) removeFrom:(NSMutableArray*)anArray;
@end

extern NSString* ORHVcRIOLock;
extern NSString* ORHVcRIOModelSetPointChanged;
extern NSString* ORHVcRIOModelQueCountChanged;
extern NSString* ORHVcRIOModelReadBackChanged;
extern NSString* ORHVcRIOModelIsConnectedChanged;
extern NSString* ORHVcRIOModelIpAddressChanged;
extern NSString* ORHVcRIOModelSetPointsChanged;
extern NSString* ORHVcRIOModelMeasuredValuesChanged;
extern NSString* ORHVcRIOModelSetPointFileChanged;
extern NSString* ORHVcRIOModelVerboseChanged;
extern NSString* ORHVcRIOModelShowFormattedDatesChanged;

