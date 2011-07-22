//--------------------------------------------------------
// ORRad7Model
// Created by Mark  A. Howe on Fri Jul 22 2005
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

#import "ORRad7Model.h"
#import "ORSerialPort.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORSerialPortAdditions.h"
#import "ORDataTypeAssigner.h"
#import "ORDataPacket.h"
#import "ORTimeRate.h"

#pragma mark ***External Strings
NSString* ORRad7ModelOperationStateChanged = @"ORRad7ModelOperationStateChanged";
NSString* ORRad7ModelTUnitsChanged		= @"ORRad7ModelTUnitsChanged";
NSString* ORRad7ModelRUnitsChanged		= @"ORRad7ModelRUnitsChanged";
NSString* ORRad7ModelFormatChanged		= @"ORRad7ModelFormatChanged";
NSString* ORRad7ModelToneChanged		= @"ORRad7ModelToneChanged";
NSString* ORRad7ModelPumpModeChanged	= @"ORRad7ModelPumpModeChanged";
NSString* ORRad7ModelThoronChanged		= @"ORRad7ModelThoronChanged";
NSString* ORRad7ModelModeChanged		= @"ORRad7ModelModeChanged";
NSString* ORRad7ModelRecycleChanged		= @"ORRad7ModelRecycleChanged";
NSString* ORRad7ModelCycleTimeChanged	= @"ORRad7ModelCycleTimeChanged";
NSString* ORRad7ModelProtocolChanged	= @"ORRad7ModelProtocolChanged";
NSString* ORRad7ModelShipTemperatureChanged = @"ORRad7ModelShipTemperatureChanged";
NSString* ORRad7ModelPollTimeChanged	= @"ORRad7ModelPollTimeChanged";
NSString* ORRad7ModelSerialPortChanged	= @"ORRad7ModelSerialPortChanged";
NSString* ORRad7ModelPortNameChanged	= @"ORRad7ModelPortNameChanged";
NSString* ORRad7ModelPortStateChanged	= @"ORRad7ModelPortStateChanged";

NSString* ORRad7Lock = @"ORRad7Lock";

@interface ORRad7Model (private)
- (void) timeout;
- (void) processOneCommandFromQueue;
- (void) process_response:(NSString*)theResponse;
- (void) pollHardware;
- (void) goToNextCommand;
- (void) handleSetupReview:(NSString*)aLine lineNumber:(int) lineNumber;
@end

@implementation ORRad7Model

enum {
	kRad7PowerUp,
	kSpecialStatus,
	kSpecialBeep,
	kSetupReview,
	kNumberRad7Cmds //must be last
};

enum {
	kRad7CommandStart
};


static struct {
	NSString* commandName;
	unsigned int cmdId;
	unsigned int commandInitialState;
	unsigned int expectedReturnLines;
} rad7Cmds[kNumberRad7Cmds] = {
	{@"PowerUpSequence", kRad7PowerUp,	 kRad7PowerUp,     17},
	{@"Special Status",  kSpecialStatus, kRad7CommandStart,	6},
	{@"Special Beep",    kSpecialBeep,   kRad7CommandStart,	1},
	{@"Setup Review",    kSetupReview,	 kRad7CommandStart, 13}
};

#define kNumberRad7FormatNames 4
static NSString* rad7FormatNames[kNumberRad7FormatNames] = {
	@"OFF",
	@"SHORT",
	@"MEDIUM",
	@"LONG"
};

#define kNumberRad7ToneNames 3
static NSString* rad7ToneNames[kNumberRad7ToneNames] = {
	@"OFF",
	@"CHIME",
	@"GEIGER"
};

#define kNumberRad7ModeNames 5
static NSString* rad7ModeNames[kNumberRad7ModeNames] = {
	@"SNIFF",
	@"AUTO",
	@"WAT-40",
	@"WAT-250",
	@"NORMAL"
};

#define kNumberRad7PumpModeNames 4
static NSString* rad7PumpModeNames[kNumberRad7PumpModeNames] = {
	@"AUTO",
	@"ON",
	@"OFF",
	@"GRAB"
};

#define kNumberRad7ProtocolNames 10
static NSString* rad7ProtocolNames[kNumberRad7ProtocolNames] = {
	@"NONE",
	@"SNIFF",
	@"1_DAY",
	@"2_DAY",
	@"WEEKS",
	@"USER",
	@"GRAB",
	@"WAT-40",
	@"WAT250",
	@"THORON"
};

#define kNumberRad7ThoronNames 2
static NSString* rad7ThoronNames[kNumberRad7ThoronNames] = {
	@"ON",
	@"OFF"
};
- (id) init
{
	self = [super init];
    [self registerNotificationObservers];
	return self;
}

- (void) dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [buffer release];
	[cmdQueue release];
	[lastRequest release];
    [portName release];
    if([serialPort isOpen]){
        [serialPort close];
    }
    [serialPort release];
	[timeRate release];
	
	[super dealloc];
}

- (void) setUpImage
{
	[self setImage:[NSImage imageNamed:@"Rad7.tif"]];
}

- (void) makeMainController
{
	[self linkToController:@"ORRad7Controller"];
}

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];

    [notifyCenter addObserver : self
                     selector : @selector(dataReceived:)
                         name : ORSerialPortDataReceived
                       object : nil];
}

- (void) dataReceived:(NSNotification*)note
{
    if([[note userInfo] objectForKey:@"serialPort"] == serialPort){
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(timeout) object:nil];
        NSString* theString = [[[[NSString alloc] initWithData:[[note userInfo] objectForKey:@"data"] 
												      encoding:NSASCIIStringEncoding] autorelease] uppercaseString];
		
		//the serial port may break the data up into small chunks, so we have to accumulate the chunks until
		//we get a full piece.
		theString = [[theString componentsSeparatedByString:@"\n"] componentsJoinedByString:@""];
		theString = [[theString componentsSeparatedByString:@">"] componentsJoinedByString:@""];
		
        if(!buffer)buffer = [[NSMutableString string] retain];
        [buffer appendString:theString];	
		
        do {
            NSRange lineRange = [buffer rangeOfString:@"\r"];
            if(lineRange.location!= NSNotFound){
                NSString* theResponse = [[[buffer substringToIndex:lineRange.location+1] copy] autorelease];
                [buffer deleteCharactersInRange:NSMakeRange(0,lineRange.location+1)];      //take the cmd out of the buffer
				theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\r" withString:@""];
				theResponse = [theResponse stringByReplacingOccurrencesOfString:@"\n" withString:@""];

				if([theResponse length] != 0){
					[self process_response:theResponse];
				}
            }
        } while([buffer rangeOfString:@"\r"].location!= NSNotFound);
	}
}


- (void) shipTemps
{
    if([[ORGlobal sharedGlobal] runInProgress]){
		
		unsigned long data[4];
		data[0] = dataId | 4;
		data[1] = ([self uniqueIdNumber]&0x0000fffff);
		
		union {
			float asFloat;
			unsigned long asLong;
		}theData;
		
		int index = 2;
		theData.asFloat = 0; //put in the actual value.....................
		data[index] = theData.asLong;
		index++;
		data[index] = timeMeasured;
		
		[[NSNotificationCenter defaultCenter] postNotificationName:ORQueueRecordForShippingNotification 
															object:[NSData dataWithBytes:data length:sizeof(long)*4]];
	}
}


#pragma mark ***Accessors

- (int) operationState
{
    return operationState;
}

- (void) setOperationState:(int)aOperationState
{
    operationState = aOperationState;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelOperationStateChanged object:self];
}

- (NSString*) operationStateString
{
	switch(operationState){
		case kRad7Idle:				return @"Idle";
		case kRad7UpdatingSettings: return @"Updating Settings";
		default: return @"Idle";
	}
}


- (int) tUnits
{
    return tUnits;
}

- (void) setTUnits:(int)aUnits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTUnits:tUnits];
    
    tUnits = aUnits;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelTUnitsChanged object:self];
}

- (int) rUnits
{
    return rUnits;
}

- (void) setRUnits:(int)aUnits
{
    [[[self undoManager] prepareWithInvocationTarget:self] setRUnits:rUnits];
    
    rUnits = aUnits;
	
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelRUnitsChanged object:self];
}

- (int) formatSetting
{
    return formatSetting;
}

- (void) setFormatSetting:(int)aFormat
{
    [[[self undoManager] prepareWithInvocationTarget:self] setFormatSetting:formatSetting];
    
    formatSetting = aFormat;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelFormatChanged object:self];
}

- (int) tone
{
    return tone;
}

- (void) setTone:(int)aTone
{
    [[[self undoManager] prepareWithInvocationTarget:self] setTone:tone];
    
    tone = aTone;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelToneChanged object:self];
}

- (int) pumpMode
{
    return pumpMode;
}

- (void) setPumpMode:(int)aPumpMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPumpMode:pumpMode];
    
    pumpMode = aPumpMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelPumpModeChanged object:self];
}

- (void) convertUnitsString:(NSString*)aUnitsString
{
	//should be in format like "PCI/L  `C"
	NSArray* parts = [aUnitsString componentsSeparatedByString:@" "];
	if([parts count]==2){
		NSString* rU = [parts objectAtIndex:0];
		NSString* tU = [parts objectAtIndex:1];
		
		if([rU isEqualToString:@"PCI/L"])		[self setRUnits:kRad7PciL];
		else if([rU isEqualToString:@"BQ/M3"])	[self setRUnits:kRad7bqm3];
		else if([rU isEqualToString:@"CPM"])    [self setRUnits:kRad7cpm];
		else if([rU isEqualToString:@"#CNTS"])	[self setRUnits:kRad7ncnts];
		else [self setRUnits:kRad7Unknown];

		if([tU isEqualToString:@"`C"])		[self setTUnits:kRad7Centigrade];
		else if([tU isEqualToString:@"`F"])	[self setTUnits:kRad7Fahrenheit];
		else [self setTUnits:kRad7Unknown];
		
	}
}

- (int) convertFormatStringToIndex:(NSString*)aMode
{
	int i;
	for(i=0;i<kNumberRad7FormatNames;i++){
		if([aMode isEqualToString:rad7FormatNames[i]])return i+1;
	}
	return kRad7Unknown;
}


- (int) convertToneStringToIndex:(NSString*)aMode
{
	int i;
	for(i=0;i<kNumberRad7ToneNames;i++){
		if([aMode isEqualToString:rad7ToneNames[i]])return i+1;
	}
	return kRad7Unknown;
}

- (int) convertModeStringToIndex:(NSString*)aMode
{
	int i;
	for(i=0;i<kNumberRad7ModeNames;i++){
		if([aMode isEqualToString:rad7ModeNames[i]])return i+1;
	}
	return kRad7Unknown;
}

- (int) convertPumpModeStringToIndex:(NSString*)aPumpMode
{
	int i;
	for(i=0;i<kNumberRad7PumpModeNames;i++){
		if([aPumpMode isEqualToString:rad7PumpModeNames[i]])return i+1;
	}
	return kRad7Unknown;
}

- (int) convertProtocolStringToIndex:(NSString*)aProtocol
{
	int i;
	for(i=0;i<kNumberRad7ProtocolNames;i++){
		if([aProtocol isEqualToString:rad7ProtocolNames[i]])return i+1;
	}
	return kRad7Unknown;
	
}

- (int) convertThoronStringToIndex:(NSString*)aMode
{
	int i;
	for(i=0;i<kNumberRad7ThoronNames;i++){
		if([aMode isEqualToString:rad7ThoronNames[i]])return i+1;
	}
	return kRad7Unknown;
}

- (int) convertCycleHours:(NSString*)hourString minutes:(NSString*)minutesString
{
	return [hourString intValue]*60 + [minutesString intValue];
}

- (BOOL) thoron
{
    return thoron;
}

- (void) setThoron:(BOOL)aThoron
{
    [[[self undoManager] prepareWithInvocationTarget:self] setThoron:thoron];
    
    thoron = aThoron;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelThoronChanged object:self];
}

- (int) mode
{
    return mode;
}

- (void) setMode:(int)aMode
{
    [[[self undoManager] prepareWithInvocationTarget:self] setMode:mode];
    
    mode = aMode;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelModeChanged object:self];
}

- (int) recycle
{
    return recycle;
}

- (void) setRecycle:(int)aRecycle
{
	if(aRecycle < 0) aRecycle = 0;
	if(aRecycle > 99)aRecycle = 99;
	
    [[[self undoManager] prepareWithInvocationTarget:self] setRecycle:recycle];
    
    recycle = aRecycle;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelRecycleChanged object:self];
}

- (int) cycleTime
{
    return cycleTime;
}

- (void) setCycleTime:(int)aCycleTime
{
	if(aCycleTime<0)aCycleTime=1;
	else if(aCycleTime> 24*60)aCycleTime=24*60;
    [[[self undoManager] prepareWithInvocationTarget:self] setCycleTime:cycleTime];
    
    cycleTime = aCycleTime;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelCycleTimeChanged object:self];
}

- (int) protocol
{
    return protocol;
}

- (void) setProtocol:(int)aProtocol
{
    [[[self undoManager] prepareWithInvocationTarget:self] setProtocol:protocol];
    
    protocol = aProtocol;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelProtocolChanged object:self];
}
- (ORTimeRate*)timeRate
{
	return timeRate;
}

- (BOOL) shipTemperature
{
    return shipTemperature;
}

- (void) setShipTemperature:(BOOL)aShipTemperature
{
    [[[self undoManager] prepareWithInvocationTarget:self] setShipTemperature:shipTemperature];
    
    shipTemperature = aShipTemperature;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelShipTemperatureChanged object:self];
}

- (int) pollTime
{
    return pollTime;
}

- (void) setPollTime:(int)aPollTime
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPollTime:pollTime];
    pollTime = aPollTime;
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelPollTimeChanged object:self];

	if(pollTime){
		[self performSelector:@selector(pollHardware) withObject:nil afterDelay:2];
	}
	else {
		[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	}
}




- (unsigned long) timeMeasured
{
	return timeMeasured;
}

- (NSString*) lastRequest
{
	return lastRequest;
}

- (void) setLastRequest:(NSString*)aRequest
{
	if(aRequest){
		int i;
		for(i=0;i<kNumberRad7Cmds;i++){
			if([aRequest isEqualToString:rad7Cmds[i].commandName]){
				
				currentRequest = rad7Cmds[i].cmdId;
				requestState   = rad7Cmds[i].commandInitialState;
				expectedCount  = rad7Cmds[i].expectedReturnLines;
				
				requestCount = 0;
				[lastRequest autorelease];
				lastRequest  = [aRequest copy];  
			}
		}
	}
	else {
		[lastRequest autorelease];
		lastRequest  = [aRequest copy];  
	}
}

- (BOOL) portWasOpen
{
    return portWasOpen;
}

- (void) setPortWasOpen:(BOOL)aPortWasOpen
{
    portWasOpen = aPortWasOpen;
}

- (NSString*) portName
{
    return portName;
}

- (void) setPortName:(NSString*)aPortName
{
    [[[self undoManager] prepareWithInvocationTarget:self] setPortName:portName];
    
    if(![aPortName isEqualToString:portName]){
        [portName autorelease];
        portName = [aPortName copy];    

        BOOL valid = NO;
        NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
        ORSerialPort *aPort;
        while (aPort = [enumerator nextObject]) {
            if([portName isEqualToString:[aPort name]]){
                [self setSerialPort:aPort];
                if(portWasOpen){
                    [self openPort:YES];
				}
                valid = YES;
                break;
            }
        } 
        if(!valid){
            [self setSerialPort:nil];
        }       
    }

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelPortNameChanged object:self];
}

- (ORSerialPort*) serialPort
{
    return serialPort;
}

- (void) setSerialPort:(ORSerialPort*)aSerialPort
{
    [aSerialPort retain];
    [serialPort release];
    serialPort = aSerialPort;

    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelSerialPortChanged object:self];
}

- (void) openPort:(BOOL)state
{
    if(state) {
		[serialPort setSpeed:9600];
		[serialPort setParityNone];
		[serialPort setStopBits2:NO];
		[serialPort setDataBits:8];
        [serialPort open];
    }
    else [serialPort close];
    portWasOpen = [serialPort isOpen];
    [[NSNotificationCenter defaultCenter] postNotificationName:ORRad7ModelPortStateChanged object:self];
}

#pragma mark ***Archival
- (id) initWithCoder:(NSCoder*)decoder
{
	self = [super initWithCoder:decoder];
	[[self undoManager] disableUndoRegistration];
	[self setTUnits:			[decoder decodeIntForKey: @"tUnits"]];
	[self setRUnits:			[decoder decodeIntForKey: @"rUnits"]];
	[self setFormatSetting:		[decoder decodeIntForKey:	 @"formatSetting"]];
	[self setTone:				[decoder decodeIntForKey:	 @"tone"]];
	[self setPumpMode:			[decoder decodeIntForKey:	 @"pumpMode"]];
	[self setThoron:			[decoder decodeBoolForKey:	 @"thoron"]];
	[self setMode:				[decoder decodeIntForKey:	 @"mode"]];
	[self setRecycle:			[decoder decodeIntForKey:	 @"recycle"]];
	[self setCycleTime:			[decoder decodeIntForKey:	 @"cycleTime"]];
	//[self setProtocol:			[decoder decodeIntForKey:	@"protocol"]];
	[self setShipTemperature:	[decoder decodeBoolForKey:	 @"ORRad7ModelShipTemperature"]];
	[self setPollTime:			[decoder decodeIntForKey:	 @"ORRad7ModelPollTime"]];
	[self setPortWasOpen:		[decoder decodeBoolForKey:	 @"ORRad7ModelPortWasOpen"]];
    [self setPortName:			[decoder decodeObjectForKey: @"portName"]];
	[[self undoManager] enableUndoRegistration];
	
	timeRate = [[ORTimeRate alloc] init];
    [self registerNotificationObservers];

	return self;
}
- (void) encodeWithCoder:(NSCoder*)encoder
{
    [super encodeWithCoder:encoder];
    [encoder encodeInt:		rUnits			forKey: @"rUnits"];
    [encoder encodeInt:		tUnits			forKey: @"tUnits"];
    [encoder encodeInt:		formatSetting	forKey: @"formatSetting"];
    [encoder encodeInt:		tone			forKey: @"tone"];
    [encoder encodeInt:		pumpMode		forKey: @"pumpMode"];
    [encoder encodeBool:    thoron			forKey: @"thoron"];
    [encoder encodeInt:     mode			forKey: @"mode"];
    [encoder encodeInt:     recycle			forKey: @"recycle"];
    [encoder encodeInt:     cycleTime		forKey: @"cycleTime"];
    [encoder encodeInt:		protocol		forKey: @"protocol"];
    [encoder encodeBool:	shipTemperature forKey:	@"ORRad7ModelShipTemperature"];
    [encoder encodeInt:		pollTime		forKey:	@"ORRad7ModelPollTime"];
    [encoder encodeBool:	portWasOpen		forKey:	@"ORRad7ModelPortWasOpen"];
    [encoder encodeObject:	portName		forKey: @"portName"];
}

#pragma mark *** Commands
- (void) addCmdToQueue:(NSString*)aCmd
{
    if([serialPort isOpen]){ 
		if(!cmdQueue)cmdQueue = [[NSMutableArray array] retain];
		[cmdQueue addObject:aCmd];
		NSLog(@"queue count: %d\n",[cmdQueue count]);
		if(!lastRequest){
			[self processOneCommandFromQueue];
		}
	}
}

- (void) systemTest
{
	[self addCmdToQueue:@"System Test"];
}

- (void) testStatus
{
	[self addCmdToQueue:@"Test Status"];
}

- (void) testStart
{
	[self addCmdToQueue:@"Test Start"];
}

- (void) testStop
{
	[self addCmdToQueue:@"Test Stop"];
}

- (void) testSave
{
	[self addCmdToQueue:@"Test Save"];
}

- (void) testClear
{
	[self addCmdToQueue:@"Test Clear"];
}

- (void) testPurge
{
	[self addCmdToQueue:@"Test Purge"];
}

- (void) sendYes
{
	[self addCmdToQueue:@"YES"];
}

- (void) sendNo
{
	[self addCmdToQueue:@"NO"];
}

- (void) testPrint
{
	[self addCmdToQueue:@"Test Print"];
}

- (void) testCom
{
	[self addCmdToQueue:@"Test Com"];
}

- (void) dataFree
{
	[self addCmdToQueue:@"Data Free"];
}

- (void) dataRenumber
{
	[self addCmdToQueue:@"Data Renumber"];
}

- (void) specialBeep
{
	[self addCmdToQueue:@"Special Beep"];
}

- (void) specialStatus
{
	[self addCmdToQueue:@"Special Status"];
}

- (void) dataErase
{
	[self addCmdToQueue:@"Data Erase"];
}

- (void) dataDelete:(int) runNumber
{
	if(runNumber>0 && runNumber < 99){
		[self addCmdToQueue:[NSString stringWithFormat: @"Data Delete %02d",runNumber]];
		[self addCmdToQueue:@"Yes"];
	}
	else NSLog(@"Rad7: runNumber for dataDelete must be between 0 and 99 inclusive\n");
}

- (void) dataRead:(int) runNumber
{
	if(runNumber>0 && runNumber < 99){
		[self addCmdToQueue:[NSString stringWithFormat: @"Data Read %02d",runNumber]];
	}
	else NSLog(@"Rad7: runNumber for dataRead must be between 0 and 99 inclusive\n");
}

- (void) dataPrint: (int)runNumber
{
	if(runNumber>0 && runNumber < 99){
		[self addCmdToQueue:[NSString stringWithFormat: @"Data Print %02d",runNumber]];
	}
	else NSLog(@"Rad7: runNumber for dataPrint must be between 0 and 99 inclusive\n");
}

- (void) dataCom:(int) runNumber
{
	if(runNumber>0 && runNumber < 99){
		[self addCmdToQueue:[NSString stringWithFormat: @"Data Com %02d",runNumber]];
	}
	else NSLog(@"Rad7: runNumber for dataCom must be between 0 and 99 inclusive\n");
}

- (void) dataSummary:(int) runNumber
{
	if(runNumber>0 && runNumber < 99){
		[self addCmdToQueue:[NSString stringWithFormat: @"Data Summary %02d",runNumber]];
	}
	else NSLog(@"Rad7: runNumber for dataSummary must be between 0 and 99 inclusive\n");
}

- (void) setupCycle
{
	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Cycle"]];
	[self addCmdToQueue:[NSString stringWithFormat: @"00:30"]];
}

- (void) setupRecycle
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Recycle %02d",recycle]];
}

- (void) setupMode
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Mode %02d",mode]];
}

- (void) setupThoron
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Thoron %02d",thoronMode]];
}

- (void) setupPumpMode
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Pump %02d",pumpMode]];
}

- (void) setupTone
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Tone %02d",tone]];
}

- (void) setupFormat
{
//	[self addCmdToQueue:[NSString stringWithFormat: @"Setup Format %@",[self formatString]];
}

- (void) updateSettings
{
	if(operationState == kRad7Idle){
		[self addCmdToQueue:@"Setup Review"];
		[self setOperationState:kRad7UpdatingSettings];
	}
	else NSLog(@"Can not load Rad7 Dialog from HW -- some other operation is in progress\n");
}

- (void) readData
{
	//[self addCmdToQueue:@"++ShipRecords"];
}

#pragma mark ***Data Records
- (unsigned long) dataId { return dataId; }
- (void) setDataId: (unsigned long) DataId
{
    dataId = DataId;
}
- (void) setDataIds:(id)assigner
{
    dataId       = [assigner assignDataIds:kLongForm];
}

- (void) syncDataIdsWith:(id)anotherRad7
{
    [self setDataId:[anotherRad7 dataId]];
}

- (void) appendDataDescription:(ORDataPacket*)aDataPacket userInfo:(id)userInfo
{
    //----------------------------------------------------------------------------------------
    // first add our description to the data description
    [aDataPacket addDataDescriptionItem:[self dataRecordDescription] forKey:@"Rad7Model"];
}

- (NSDictionary*) dataRecordDescription
{
    NSMutableDictionary* dataDictionary = [NSMutableDictionary dictionary];
    NSDictionary* aDictionary = [NSDictionary dictionaryWithObjectsAndKeys:
        @"ORRad7DecoderForTemperature",     @"decoder",
        [NSNumber numberWithLong:dataId],   @"dataId",
        [NSNumber numberWithBool:NO],       @"variable",
        [NSNumber numberWithLong:4],        @"length",
        nil];
    [dataDictionary setObject:aDictionary forKey:@"Temperatures"];
    
    return dataDictionary;
}

@end

@implementation ORRad7Model (private)
- (void) timeout
{
	NSLogError(@"Rad7",@"command timeout",nil);
	[self goToNextCommand];
}

- (void) goToNextCommand
{
	[self setLastRequest:nil];			 //clear the last request
	[self processOneCommandFromQueue];	 //do the next command in the queue
}

- (void) processOneCommandFromQueue
{
	if([cmdQueue count] == 0) return;
	NSString* aCmd = [[[cmdQueue objectAtIndex:0] retain] autorelease];
	[cmdQueue removeObjectAtIndex:0];
	if([aCmd isEqualToString:@"++ShipRecords"]){
		if(shipTemperature) [self shipTemps];
	}
	else {
		[self setLastRequest:aCmd];
		[self performSelector:@selector(timeout) withObject:nil afterDelay:3];
		aCmd = [aCmd stringByReplacingOccurrencesOfString:@"\n" withString:@""];
		aCmd = [aCmd stringByReplacingOccurrencesOfString:@"\r" withString:@""];
		aCmd = [aCmd stringByAppendingString:@"\r\n"];
		NSLog(@"writing: %@\n",aCmd);
		[serialPort writeString:aCmd];
		if(!lastRequest){
			[self performSelector:@selector(processOneCommandFromQueue) withObject:nil afterDelay:1];
		}
	}
}

- (void) process_response:(NSString*)theResponse
{	
	theResponse = [theResponse removeExtraSpaces];

	if([theResponse rangeOfString:@"DURRIDGE"].location != NSNotFound){
		//special unsolidated response after power up
		NSLog(@"Rad7 going thru power up -- all queued commands cleared\n");
		[cmdQueue removeAllObjects];
		[self setLastRequest:@"PowerUpSequence"]; //fake a command
	}
	else {
		NSLog(@"(%d) %@ \n",requestCount,theResponse);
		
		switch(currentRequest){
				
			case kRad7PowerUp:
			case kSetupReview:
				[self handleSetupReview:theResponse lineNumber:requestCount];
			break;
				
		}
		
		requestCount++;
		
		if(requestCount == expectedCount){
			[self setOperationState:kRad7Idle];
			NSLog(@"set up next command %d\n",[cmdQueue count]);
			if(requestState == kRad7PowerUp || requestState == kSetupReview){
				[self performSelector:@selector(goToNextCommand) withObject:nil afterDelay:5];
			}
			else {
				[self goToNextCommand];
			}
		}
	}
}


- (void) pollHardware
{
	[NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(pollHardware) object:nil];
	[self readData];
	[self performSelector:@selector(pollHardware) withObject:nil afterDelay:pollTime];
}

- (void) handleSetupReview:(NSString*)aLine lineNumber:(int) lineNumber
{
	if(lineNumber < 4)return; //don't care about these
	if([aLine rangeOfString:@":"].location != NSNotFound){
		NSArray* parts = [aLine componentsSeparatedByString:@":"];
		if([parts count]>=2){
			NSString* tag   = [[parts objectAtIndex:0] trimSpacesFromEnds];
			NSString* value = [[parts objectAtIndex:1] trimSpacesFromEnds];
			NSString* value1 = @"";
			if([parts count]>=3)value1 = [[parts objectAtIndex:2] trimSpacesFromEnds];

			if([tag isEqualToString:@"PUMP"])[self setPumpMode:[self convertPumpModeStringToIndex:value]];
			else if([tag isEqualToString:@"MODE"])[self setMode:[self convertModeStringToIndex:value]];
			else if([tag isEqualToString:@"THORON"])[self setThoron:[self convertThoronStringToIndex:value]];
			else if([tag isEqualToString:@"RECYCLE"])[self setRecycle:[value intValue]];
			else if([tag isEqualToString:@"CYCLE"])[self setCycleTime:[self convertCycleHours:value minutes:value1]];
			else if([tag isEqualToString:@"TONE"])[self setTone:[self convertToneStringToIndex:value]];
			else if([tag isEqualToString:@"FORMAT"])[self setFormatSetting:[self convertFormatStringToIndex:value]];
			else if([tag isEqualToString:@"PROTOCOL"])[self setProtocol:[self convertProtocolStringToIndex:value]];
			else if([tag isEqualToString:@"UNITS"])[self convertUnitsString:value];
		}
	}
}
@end