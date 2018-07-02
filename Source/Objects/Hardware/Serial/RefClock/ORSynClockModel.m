//--------------------------------------------------------
// ORSynClockModel
// Created by Mark  A. Howe on Fri Jul 22 2005 / Julius Hartmann, KIT, November 2017
// Code partially generated by the OrcaCodeWizard. Written by Mark A. Howe.
// Copyright (c) 2005 CENPA, University of Washington. All rights reserved.
//-----------------------------------------------------------
//This program was prepared for the Regents of the University of
//Washington at the Center for Experimental Nuclear Physics and
//Astrophysics (CENPA) sponsored in part by the United States
//Department of Energy (DOE) under Grant #DE-FG02-97ER41020.
//The University has certain rights in the program pursuant to
//the contract and the program should not be copied or distributed
//outside your organization.  The DOE and the University of
//Washington reserve all rights in the program. Neither the authors,
//University of Washington, or U.S. Government make any warranty,
//express or implied, or assume any liability or responsibility
//for the use of this software.
//-------------------------------------------------------------

#pragma mark ***Imported Files

#import "ORSynClockModel.h"
#import "ORRefClockModel.h"

#pragma mark ***External Strings
NSString* ORSynClockModelTrackModeChanged	    = @"ORSynClockModelTrackModeChanged";
NSString* ORSynClockModelSyncChanged	        = @"ORSynClockModelSyncChanged";
NSString* ORSynClockModelAlarmWindowChanged	    = @"ORSynClockModelAlarmWindowChanged";
NSString* ORSynClockModelStatusChanged          = @"ORSynClockModelStatusChanged";
NSString* ORSynClockModelStatusPollChanged      = @"ORSynClockModelStatusPollChanged";
NSString* ORSynClockModelStatusOutputChanged    = @"ORSynClockModelStatusOutputChanged";
NSString* ORSynClockModelResetChanged           = @"ORSynClockModelResetChanged";
NSString* ORSynClockStatusUpdated               = @"ORSynClockStatusUpdated";
NSString* ORSynClockIDChanged                   = @"ORSynClockIDChanged";

//#define maxReTx 3  // above this number, stop trying to
// retransmit and place an Error.

@interface ORSynClockModel (private)
- (void) updatePoll;
- (void) updateStatusHistory:(NSString*)aMessage;
@end

@implementation ORSynClockModel
- (void) dealloc
{
    [previousStatusMessages dealloc];
	[super dealloc];
}

- (void) setRefClock:(ORRefClockModel*)aRefClock
{
    refClock  = aRefClock; //this is a delegate... don't retain or release
}

- (NSString*) helpURL
{
	return @"RS232/SynClock.html";
}

#pragma mark ***Accessors

- (void) reset{
    [self writeData:[self resetCommand]];
    [self writeData:[self errMessgOffCommand]];  // this is written to SynClock flash and needs to be activate only once for a new device (2018-03-28 JH.) (dont use more than 100'000 times to save the synclocks flash memory)
}

- (void) requestID{
    [self writeData:[self iDCommand]];
}

- (BOOL) statusPoll
{
    return statusPoll;
}

- (void) setStatusPoll:(BOOL)aStatusPoll
{
    [[[self undoManager] prepareWithInvocationTarget:self] setStatusPoll:statusPoll];
    statusPoll = aStatusPoll;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockModelStatusPollChanged object:self];
    [self updatePoll];
}

- (void) requestStatus
{
    [self writeData:[self statusCommand]];
}

- (NSString*) statusMessages
{
    NSMutableString* messages = [[[NSMutableString alloc] init] autorelease];
    int i;
    for(i = 0; i < nLastMsgs; ++i){
        if(i == 1){
            [messages appendString:@"***previous messages:*** \n "];
        }
        if(i<[previousStatusMessages count] && [previousStatusMessages objectAtIndex:i])[messages appendString:[previousStatusMessages objectAtIndex:i]];
        [messages appendString:@"\n "];
    }
    if([messages length]==0)return @"";
    else                    return messages;
}
- (NSString*) clockID{
    return clockID;
}

- (int) trackMode
{
    return trackMode;
}

- (void) setTrackMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTrackMode:trackMode];
    trackMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockModelTrackModeChanged object:self];
    [self updatePoll];
    [self writeData:[self trackModeCommand:[self trackMode]]];
}

- (int) syncMode
{
    return syncMode;
}

- (void) setSyncMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setSyncMode:syncMode];
    syncMode = aMode;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockModelSyncChanged object:self];
    [self updatePoll];
    [self writeData:[self syncModeCommand:[self syncMode]]];
}

- (unsigned long) alarmWindow
{
    int err = alarmWindow % 50;  // make the alarm windown divisible by 50 according to datasheet..
    if (err > 25){
        err = 50 - err;
        alarmWindow += err;
    }
    else alarmWindow -= err;
    if(alarmWindow==0)          alarmWindow = 2000; //special case on start-up
    else if(alarmWindow<50)     alarmWindow = 50;
    else if(alarmWindow>12750)  alarmWindow = 12750;
    
    return alarmWindow;
}

- (void) setAlarmWindow:(unsigned long)aValue
{
    if(aValue<50)          aValue = 50;
    else if(aValue>12750)  aValue = 12750;
    
    [[[self undoManager] prepareWithInvocationTarget:self] setAlarmWindow:alarmWindow];
    alarmWindow = aValue;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockModelAlarmWindowChanged object:self];
    [self writeData:[self alarmWindowCommand:[self alarmWindow]]];//todo: alarmWindowCommand here?
}

- (ORRefClockModel*) refClockModel{
    return refClock;
}

//put our parameters into any run header
- (NSMutableDictionary*) addParametersToDictionary:(NSMutableDictionary*)dictionary
{
    NSMutableDictionary* objDictionary = [NSMutableDictionary dictionary];
    [objDictionary setObject:NSStringFromClass([self class]) forKey:@"Class Name"];

	return objDictionary;
}

- (BOOL) portIsOpen
{
    return [refClock portIsOpen];
}
#pragma mark *** Commands

- (void) writeData:(NSDictionary*)aDictionary
{
    [refClock addCmdToQueue:aDictionary];
}

- (void) processResponse:(NSData*)receivedData forRequest:(NSDictionary*)lastRequest;
{
    //receivedData should have been processed by refClockModel to be the full response.
    //Here is where the data is decoded into something meaningful for this object
    
    //use [refClock lastRequest] to get the orginal command
    
    //if([refClock verbose]) NSLog(@"received synClock response\n");
    //NSLog(@"received synClock response\n");
    
    ///MAH -- I didn't attempt to do anything to the old processing code below since I don't know the format
    //\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/\/
    //BOOL done = NO;
 
    unsigned short nBytes = [receivedData length];
    unsigned char * bytes = (unsigned char *)[receivedData bytes];
    //if([inComingData length] >= 7) {
    if(bytes[nBytes - 1] == '\n') { // check for trailing \n (LF)
        
        
        if([refClock verbose]){
            //NSLog(@"last command: %s (synClock dataAvailable) \n", lastCmd);
            NSLog(@"SynClock data received: %s ; size: %d \n", bytes, nBytes);
        }
        if([lastRequest isEqualToDictionary:[self statusCommand]]){
            NSString* statusMessage = nil;
            switch(bytes[0]){
                case '0': statusMessage = @"0: warming up"; break;
                case '1': statusMessage = @"1: tracking set-up"; break;
                case '2': statusMessage = @"2: track to PPSREF"; break;
                case '3': statusMessage = @"3: sync to PPSREF"; break;
                case '4': statusMessage = @"4: Free Run. Track OFF"; break;
                case '5': statusMessage = @"5: PSREF unstable (Hold over)"; break;
                case '6': statusMessage = @"6: No PSREF (Hold over)"; break;
                case '7': statusMessage = @"7: factory used"; break;
                case '8': statusMessage = @"8: factory used"; break;
                case '9': statusMessage = @"9: Fault"; break;
                default: statusMessage = @"warning: SynClock default message"; break;
            }
            [self updateStatusHistory:statusMessage];
            if([refClock verbose]){
                NSLog(@"statusMessage: notifying... \n");
            }
        //displayStatus(bytes[0]);
        }
        else if([lastRequest isEqualToDictionary:[self iDCommand]]){
            clockID = [[NSString alloc]initWithBytes:bytes length:nBytes - 2 encoding:NSASCIIStringEncoding];
            [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockIDChanged object:self];
            if([refClock verbose]){
                NSLog(@"clockID: notifying... \n");
            }
        }
        else if([lastRequest isEqualToDictionary:[self alarmWindowCommand:alarmWindow]]){ // alarmWindow is assumed the same from issuing to receiving
            if([refClock verbose]){
                NSLog(@"alarm Window %u was set. \n", alarmWindow);
            }
        }
        else if([lastRequest isEqualToDictionary:[self resetCommand]]){
            if([refClock verbose]){
                NSLog(@"SynClock reset. \n");
            }
        }
        else if([lastRequest isEqualToDictionary:[self errMessgOffCommand]]){
            if([refClock verbose]){
                NSLog(@"SynClock Error Message switched off \n");
            }
        }
        else if([lastRequest isEqualToDictionary:[self trackModeCommand:trackMode]]){
            if([refClock verbose]){
                NSLog(@"SynClock track mode set \n");
            }
        }
        else if([lastRequest isEqualToDictionary:[self syncModeCommand:syncMode]]){
            if([refClock verbose]){
                NSLog(@"SynClock  sync mode set \n");
            }
        }
        
        else{
            NSLog(@"Warning (SynClockModel::dataAvailable): unsupported command \n");
        }
    }
   
}


- (NSDictionary*) resetCommand
{
    unsigned char cmdData[7];
    cmdData[0] = 'R';
    cmdData[1] = 'E';
    cmdData[2] = 'S';
    cmdData[3] = 'E';
    cmdData[4] = 'T';
    cmdData[5] = '\r';
    cmdData[6] = '\n';
    
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:7],
                                   @"device"    : ORSynClock,
                                   @"replySize" : @20
                                   };
    //NSLog(@"SynClockModel::resetCommand! \n");
    
    return commandDict;
}
- (NSDictionary*) errMessgOffCommand
{
    unsigned char cmdData[9];
    cmdData[0] = 'M';
    cmdData[1] = 'C';
    cmdData[2] = 'S';
    cmdData[3] = '0';
    cmdData[4] = '7';
    cmdData[5] = '0';  // switch off '?' reply for unknown command
    cmdData[6] = '0';
    cmdData[7] = '\r';
    cmdData[8] = '\n';
    
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:9],
                                   @"device"    : ORSynClock,
                                   @"replySize" : @2 // todo
                                   };
    //NSLog(@"SynClockModel::errMessgOffCommand! (!'?') \n");
    
    return commandDict;
}

- (NSDictionary*) alarmWindowCommand:(unsigned int)nanoseconds
{
    char cmdData[9];
    cmdData[0] = 'A';
    cmdData[1] = 'W';
    sprintf(&cmdData[2], "%.5u", nanoseconds);
    cmdData[7] = '\r';
    cmdData[8] = '\n';
    //NSLog(@"alarmWindowCommand: %9s \n", cmdData);
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:9],
                                   @"device"    : @"SynClock",
                                   @"replySize" : @7
                                   };
    return commandDict;
}

- (NSDictionary*) statusCommand
{
    unsigned char cmdData[4];
    cmdData[0] = 'S';
    cmdData[1] = 'T';
    cmdData[2] = '\r';
    cmdData[3] = '\n';
    
    NSDictionary * commandDict = @{
        @"data"      : [NSData dataWithBytes:cmdData length:4],
        @"device"    : ORSynClock,
        @"replySize" : @3
    };
    //NSLog(@"SynClockModel::statusCommand! \n");
    
    return commandDict;
}

- (NSDictionary*) iDCommand{
    unsigned char cmdData[4];
    cmdData[0] = 'I';
    cmdData[1] = 'D';
    cmdData[2] = '\r';
    cmdData[3] = '\n';
    
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:4],
                                   @"device"    : ORSynClock,
                                   @"replySize" : @20
                                   };
    //NSLog(@"SynClockModel::iDCommand! \n");
    
    return commandDict;
}


- (NSDictionary*) trackModeCommand:(unsigned int)mode{
    unsigned char cmdData[5];
    cmdData[0] = 'T';
    cmdData[1] = 'R';
    cmdData[2] = 0x30 + mode;  // generate char digit
    cmdData[3] = '\r';
    cmdData[4] = '\n';
    
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:5],
                                   @"device"    : ORSynClock,
                                   @"replySize" : @3
                                   };
    
    return commandDict;
}
- (NSDictionary*) syncModeCommand:(unsigned int)mode{
    unsigned char cmdData[5];
    cmdData[0] = 'S';
    cmdData[1] = 'Y';
    cmdData[2] = 0x30 + mode;  // generate char digit
    cmdData[3] = '\r';
    cmdData[4] = '\n';
    
    NSDictionary * commandDict = @{
                                   @"data"      : [NSData dataWithBytes:cmdData length:5],
                                   @"device"    : ORSynClock,
                                   @"replySize" : @3
                                   };
    
    return commandDict;
}

- (NSUndoManager*) undoManager
{
    return [refClock undoManager];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
    self = [super init];
    [[self undoManager] disableUndoRegistration];
    [self setTrackMode:  [decoder decodeIntForKey:  @"trackMode"]];
    [self setSyncMode:   [decoder decodeIntForKey:  @"syncMode"]];
    
    unsigned long aValue = [decoder decodeInt32ForKey:@"alarmWindow"];
    if(aValue == 0)aValue = 2000; //0 is illegal and means first start, so set to default value
    [self setAlarmWindow:aValue];
    
    previousStatusMessages = [[decoder decodeObjectForKey:@"previousStatusMessages"] retain];
    if(!previousStatusMessages){
        previousStatusMessages = [[NSMutableArray array] retain];
        int i;
        for (i = 0; i < nLastMsgs; ++i){
            [previousStatusMessages addObject:@"\n"];
        }
    }

    [[self undoManager] enableUndoRegistration];

    return self;
}

- (void) encodeWithCoder:(NSCoder*)encoder
{
    [encoder encodeInt:   trackMode   forKey:@"trackMode"];
    [encoder encodeInt:   syncMode    forKey:@"syncMode"];
    [encoder encodeInt32: alarmWindow forKey:@"alarmWindow"];
    [encoder encodeObject:previousStatusMessages forKey:@"previousStatusMessages"];
}

@end

@implementation ORSynClockModel (private)

- (void) updateStatusHistory:(NSString*)aMessage
{
    if(!aMessage) return;
    if(!previousStatusMessages){
        previousStatusMessages = [[NSMutableArray array] retain];
        int i;
        for (i = 0; i < nLastMsgs; ++i){
            [previousStatusMessages addObject:@"\n"];
        }
    }
    for(int i = nLastMsgs; i > 1 ; i--){  // insert new statusMessage at top; last message in array drops out
        int j = i-2;
        int k = i-1;
        if(k<[previousStatusMessages count] && j<[previousStatusMessages count]){
            [previousStatusMessages exchangeObjectAtIndex:k withObjectAtIndex:j]; //withObject:[previousStatusMessages objectAtIndex:i-2]];
        }
    }
    if([previousStatusMessages count])[previousStatusMessages replaceObjectAtIndex:0 withObject:aMessage];
    if([refClock verbose]){
        NSLog(@"%@\n",previousStatusMessages);
    }
    [[NSNotificationCenter defaultCenter] postNotificationName:ORSynClockStatusUpdated object:self];
}
- (void) updatePoll
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(updatePoll) object:nil];
    float delay = 4.0; // Seconds
    if(statusPoll && [refClock portIsOpen]) {
        [self requestStatus];
        [self performSelector:@selector(updatePoll) withObject:nil afterDelay:delay];
    }
}



@end