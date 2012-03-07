//--------------------------------------------------------
// ORVXMController
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

#import "ORVXMController.h"
#import "ORVXMModel.h"
#import "ORAxis.h"
#import "ORSerialPortList.h"
#import "ORSerialPort.h"
#import "ORVXMMotor.h"

@interface ORVXMController (private)
- (void) populatePortListPopup;
@end

@implementation ORVXMController

#pragma mark ***Initialization

- (id) init
{
	self = [super initWithWindowNibName:@"VXM"];
	return self;
}

- (void) dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[super dealloc];
}

- (void) awakeFromNib
{
    [self populatePortListPopup];
	

	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	[numberFormatter setFormat:@"#0.00"];	
	int i;
	for(i=0;i<kNumVXMMotors;i++){
		[[conversionMatrix cellAtRow:i column:0] setTag:i];
		[[fullScaleMatrix cellAtRow:i column:0] setTag:i];
		[[speedMatrix cellAtRow:i column:0] setTag:i];
		[[motorEnabledMatrix cellAtRow:i column:0] setTag:i];
		[[positionMatrix cellAtRow:i column:0] setTag:i];
		[[targetMatrix cellAtRow:i column:0] setTag:i];
		[[addButtonMatrix cellAtRow:i column:0] setTag:i];
		[[absMotionMatrix cellAtRow:i column:0] setTag:i];
		
		[[conversionMatrix cellAtRow:i column:0]	setFormatter:numberFormatter];
	}
	[self setFormats];
    [super awakeFromNib];
}

- (void) setFormats
{
	int i;
	NSNumberFormatter *numberFormatter = [[[NSNumberFormatter alloc] init] autorelease];
	if([model displayRaw]) [numberFormatter setFormat:@"#0"];
	else				   [numberFormatter setFormat:@"#0.00"];
	for(i=0;i<kNumVXMMotors;i++){
		[[fullScaleMatrix cellAtRow:i column:0]		setFormatter:numberFormatter];
		[[positionMatrix cellAtRow:i column:0]		setFormatter:numberFormatter];
		[[speedMatrix cellAtRow:i column:0]		setFormatter:numberFormatter];
		[[targetMatrix cellAtRow:i column:0]		setFormatter:numberFormatter];
	}
	[fullScaleMatrix setNeedsDisplay];
	[speedMatrix setNeedsDisplay];
	[positionMatrix setNeedsDisplay];
	[targetMatrix setNeedsDisplay];
}

#pragma mark ***Notifications

- (void) registerNotificationObservers
{
	NSNotificationCenter* notifyCenter = [NSNotificationCenter defaultCenter];
    [super registerNotificationObservers];
    [notifyCenter addObserver : self
                     selector : @selector(updateButtons:)
                         name : ORRunStatusChangedNotification
                       object : nil];
    
    [notifyCenter addObserver : self
                     selector : @selector(updateButtons:)
                         name : ORVXMLock
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portNameChanged:)
                         name : ORVXMModelPortNameChanged
                        object: nil];

    [notifyCenter addObserver : self
                     selector : @selector(portStateChanged:)
                         name : ORSerialPortStateChanged
                       object : nil];
	
    [notifyCenter addObserver : self
                     selector : @selector(positionChanged:)
                         name : ORVXMMotorPositionChanged
                       object : model];
                       
   [notifyCenter addObserver : self
                     selector : @selector(motorEnabledChanged:)
                         name : ORVXMMotorEnabledChanged
                       object : model];

	[notifyCenter addObserver : self
                     selector : @selector(absoluteMotionChanged:)
                         name : ORVXMMotorAbsMotionChanged
                       object : model];

   [notifyCenter addObserver : self
                     selector : @selector(conversionChanged:)
                         name : ORVXMMotorConversionChanged
                       object : model];
	
   [notifyCenter addObserver : self
                     selector : @selector(fullScaleChanged:)
                         name : ORVXMMotorFullScaleChanged
                       object : model];
    
    [notifyCenter addObserver : self
                     selector : @selector(speedChanged:)
                         name : ORVXMMotorSpeedChanged
                       object : model];      

	[notifyCenter addObserver : self
                     selector : @selector(targetChanged:)
                         name : ORVXMMotorTargetChanged
                       object : model];      
		
	[notifyCenter addObserver : self
                     selector : @selector(updateCmdTable:)
                         name : ORVXMModelCmdQueueChanged
                       object : model]; 	
	
    [notifyCenter addObserver : self
                     selector : @selector(displayRawChanged:)
                         name : ORVXMModelDisplayRawChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(syncWithRunChanged:)
                         name : ORVXMModelSyncWithRunChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCmdsChanged:)
                         name : ORVXMModelRepeatCmdsChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(repeatCountChanged:)
                         name : ORVXMModelRepeatCountChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(stopRunWhenDoneChanged:)
                         name : ORVXMModelStopRunWhenDoneChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(cmdIndexChanged:)
                         name : ORVXMModelCmdIndexChanged
						object: model];

    [notifyCenter addObserver : self
                     selector : @selector(numTimesToRepeatChanged:)
                         name : ORVXMModelNumTimesToRepeatChanged
						object: model];
	
    [notifyCenter addObserver : self
                     selector : @selector(goingHomeChanged:)
                         name : ORVXMModelAllGoingHomeChanged
						object: model];	
	
    [notifyCenter addObserver : self
                     selector : @selector(shipRecordsChanged:)
                         name : ORVXMModelShipRecordsChanged
						object: model];

}

- (void) updateWindow
{
    [super updateWindow];
    [self updateButtons:nil];
    [self portStateChanged:nil];
    [self portNameChanged:nil];
    [self positionChanged:nil];
	[self conversionChanged:nil];
    [self fullScaleChanged:nil];
    [self motorEnabledChanged:nil];
    [self speedChanged:nil];
    [self targetChanged:nil];
    [self updateCmdTable:nil];
	[self displayRawChanged:nil];
	[self absoluteMotionChanged:nil];
	[self syncWithRunChanged:nil];
	[self repeatCmdsChanged:nil];
	[self repeatCountChanged:nil];
	[self stopRunWhenDoneChanged:nil];
	[self cmdIndexChanged:nil];
	[self numTimesToRepeatChanged:nil];
	[self goingHomeChanged:nil];
	[self shipRecordsChanged:nil];
}

- (void) shipRecordsChanged:(NSNotification*)aNote
{
	[shipRecordsCB setIntValue: [model shipRecords]];
}

- (void) goingHomeChanged:(NSNotification*)aNote
{
	[self updateButtons:nil];
}

- (void) numTimesToRepeatChanged:(NSNotification*)aNote
{
	[numTimesToRepeatField setIntValue: [model numTimesToRepeat]];
}

- (void) cmdIndexChanged:(NSNotification*)aNote
{
	[cmdIndexField setIntValue: [model cmdIndex]];
}

- (void) stopRunWhenDoneChanged:(NSNotification*)aNote
{
	[stopRunWhenDoneCB setIntValue: [model stopRunWhenDone]];
}

- (void) repeatCountChanged:(NSNotification*)aNote
{
	[repeatCountField setIntValue: [model repeatCount]];
}

- (void) repeatCmdsChanged:(NSNotification*)aNote
{
	[repeatCmdsCB setIntValue: [model repeatCmds]];
	[self updateButtons:nil];
}

- (void) syncWithRunChanged:(NSNotification*)aNote
{
	[syncWithRunCB setIntValue: [model syncWithRun]];
	[self updateButtons:nil];
}

- (void) displayRawChanged:(NSNotification*)aNote
{
	[displayRawMatrix selectCellWithTag: [model displayRaw]];
	[self updateButtons:nil];
	[self setFormats];
	[self speedChanged:nil];
	[self fullScaleChanged:nil];
	[self positionChanged:nil];
	[self targetChanged:nil];
}

- (void) updateCmdTable:(NSNotification*)aNotification
{
	[cmdQueueTable reloadData];
}

- (void) conversionChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		[[conversionMatrix cellWithTag:[aMotor motorId]] setFloatValue: [aMotor conversion]];
	}
	else {
		for(id aMotor in [model motors]){
			[[conversionMatrix cellWithTag:[aMotor motorId]] setFloatValue:[aMotor conversion]];
		}
	}
	[self speedChanged:nil];
}

- (void) fullScaleChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		float conversion = 1.0;
		if(![model displayRaw]) conversion = [aMotor conversion];
		[[conversionMatrix cellWithTag:[aMotor motorId]] setFloatValue: [aMotor fullScale]/conversion];
	}
	else {
		for(id aMotor in [model motors]){
			float conversion = 1.0;
			if(![model displayRaw]) conversion = [aMotor conversion];
			[[fullScaleMatrix cellWithTag:[aMotor motorId]] setFloatValue:[aMotor fullScale]/conversion];
		}
	}
}

- (void) speedChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		float conversion = 1.0;
		if(![model displayRaw]) conversion = [aMotor conversion];
		[[speedMatrix cellWithTag:[aMotor motorId]] setFloatValue: [aMotor motorSpeed]/conversion];

	}
	else {
		for(id aMotor in [model motors]){
			float conversion = 1.0;
			if(![model displayRaw]) conversion = [aMotor conversion];
			[[speedMatrix cellWithTag:[aMotor motorId]] setFloatValue:[aMotor motorSpeed]/conversion];
		}
	}
}

- (void) positionChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		float conversion = 1.0;
		if(![model displayRaw]) conversion = [aMotor conversion];
		[[positionMatrix cellWithTag:[aMotor motorId]] setFloatValue: [aMotor motorPosition]/conversion];
	}
	else {
		for(id aMotor in [model motors]){
			float conversion = 1.0;
			if(![model displayRaw]) conversion = [aMotor conversion];
			[[positionMatrix cellWithTag:[aMotor motorId]] setFloatValue:[aMotor motorPosition]/conversion];
		}
	}
}

- (void) targetChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		float conversion = 1.0;
		if(![model displayRaw]) conversion = [aMotor conversion];
		[[targetMatrix cellWithTag:[aMotor motorId]] setFloatValue: [aMotor targetPosition]/conversion];
	}
	else {
		for(id aMotor in [model motors]){
			float conversion = 1.0;
			if(![model displayRaw]) conversion = [aMotor conversion];
			[[targetMatrix cellWithTag:[aMotor motorId]] setFloatValue:[aMotor targetPosition]/conversion];
		}
	}
}

- (void) checkGlobalSecurity
{
    BOOL secure = [[[NSUserDefaults standardUserDefaults] objectForKey:OROrcaSecurityEnabled] boolValue];
    [gSecurity setLock:ORVXMLock to:secure];
    [lockButton setEnabled:secure];
}

- (void) updateButtons:(NSNotification*)aNotification
{

    BOOL runInProgress = [gOrcaGlobals runInProgress];
    BOOL lockedOrRunningMaintenance = [gSecurity runInProgressButNotType:eMaintenanceRunType orIsLocked:ORVXMLock];
    BOOL locked = [gSecurity isLocked:ORVXMLock];
	BOOL displayRaw = [model displayRaw];
	BOOL goingHome = [model allGoingHome];
	BOOL syncWithRun = [model syncWithRun];
	
    [lockButton setState: locked];

    [portListPopup setEnabled:!locked];
    [openPortButton setEnabled:!locked];
    [getPositionButton setEnabled:!locked];
	[stopGoNextCmdButton setEnabled:!locked & !goingHome];
	[manualStartButton setEnabled:!locked & !goingHome & !syncWithRun];
	[syncWithRunCB setEnabled:!locked & !goingHome];
	[stopWithRunButton setEnabled:!locked & !goingHome];
	[repeatCmdsCB setEnabled:!locked & !goingHome];
	[numTimesToRepeatField setEnabled:!locked & !goingHome & [model repeatCmds]];
	 
	for(id aMotor in [model motors]){
		int i = [aMotor motorId];
		BOOL motorEnabled = [aMotor motorEnabled];
        BOOL absMotion = [aMotor absoluteMotion];
		[[conversionMatrix cellWithTag:i] setEnabled:!locked & motorEnabled && !displayRaw];
		[[motorEnabledMatrix cellWithTag:i] setEnabled:!locked & !goingHome];
		[[fullScaleMatrix cellWithTag:i] setEnabled:!locked & motorEnabled];
		[[speedMatrix cellWithTag:i] setEnabled:!locked & motorEnabled & !goingHome];
		[[absMotionMatrix cellWithTag:i] setEnabled:!locked & motorEnabled & !goingHome];
		[[addButtonMatrix cellWithTag:i] setEnabled:!locked & motorEnabled & !goingHome];
		[[addButtonMatrix cellWithTag:i] setTitle:absMotion?@"Add Abs Cmd":@"Add Rel Cmd"];
	}

	if([model displayRaw]){
		[fullScaleLabelField setStringValue:@"(steps)"];
		[speedLabelField setStringValue:@"(stps/sec)"];
		[currentPositionLabelField setStringValue:@"(steps)"];
		[targetLabelField setStringValue:@"(steps)"];
	}
	else {
		[fullScaleLabelField setStringValue:@"(mm)"];
		[speedLabelField setStringValue:@"(mm/sec)"];
		[currentPositionLabelField setStringValue:@"(mm)"];
		[targetLabelField setStringValue:@"(mm)"];
	}	

    NSString* s = @"";
    if(lockedOrRunningMaintenance){
        if(runInProgress && ![gSecurity isLocked:ORVXMLock])s = @"Not in Maintenance Run.";
    }
    [lockDocField setStringValue:s];

}

- (void) portStateChanged:(NSNotification*)aNotification
{
    if(aNotification == nil || [aNotification object] == [model serialPort]){
        if([model serialPort]){
            [openPortButton setEnabled:YES];

            if([[model serialPort] isOpen]){
                [openPortButton setTitle:@"Close"];
                [portStateField setTextColor:[NSColor colorWithCalibratedRed:0.0 green:.8 blue:0.0 alpha:1.0]];
                [portStateField setStringValue:@"Open"];
            }
            else {
                [openPortButton setTitle:@"Open"];
                [portStateField setStringValue:@"Closed"];
                [portStateField setTextColor:[NSColor redColor]];
            }
        }
        else {
            [openPortButton setEnabled:NO];
            [portStateField setTextColor:[NSColor blackColor]];
            [portStateField setStringValue:@"---"];
            [openPortButton setTitle:@"---"];
        }
    }
}

- (void) portNameChanged:(NSNotification*)aNotification
{
    NSString* portName = [model portName];
    
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;

    [portListPopup selectItemAtIndex:0]; //the default
    while (aPort = [enumerator nextObject]) {
        if([portName isEqualToString:[aPort name]]){
            [portListPopup selectItemWithTitle:portName];
            break;
        }
	}  
    [self portStateChanged:nil];
}

- (void) absoluteMotionChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		[[absMotionMatrix cellWithTag:[aMotor motorId]] setIntValue: [aMotor absoluteMotion]];
	}
	else {
		for(id aMotor in [model motors]){
			[[absMotionMatrix cellWithTag:[aMotor motorId]] setIntValue:[aMotor absoluteMotion]];
		}
	}
    [self updateButtons:nil];
}

- (void) motorEnabledChanged:(NSNotification*)aNotification
{
	if(aNotification){
		ORVXMMotor* aMotor = [[aNotification userInfo] objectForKey:@"VMXMotor"];
		[[motorEnabledMatrix cellWithTag:[aMotor motorId]] setIntValue: [aMotor motorEnabled]];
	}
	else {
		for(id aMotor in [model motors]){
			[[motorEnabledMatrix cellWithTag:[aMotor motorId]] setIntValue:[aMotor motorEnabled]];
		}
	}
	[self updateButtons:nil];
}


#pragma mark ***Actions

- (void) shipRecordsAction:(id)sender
{
	[model setShipRecords:[sender intValue]];	
}

- (IBAction) manualStateAction:(id)sender
{
	[model manualStart];
}

- (IBAction) removeAllAction:(id)sender
{
	[model removeAllCmds];
}

- (IBAction) numTimesToRepeatAction:(id)sender
{
	[model setNumTimesToRepeat:[sender intValue]];	
}

- (IBAction) stopRunWhenDoneAction:(id)sender
{
	[model setStopRunWhenDone:[sender intValue]];	
}

- (IBAction) repeatCmdsAction:(id)sender
{
	[model setRepeatCmds:[sender intValue]];	
}

- (IBAction) repeatCountAction:(id)sender
{
	[model setRepeatCount:[sender intValue]];	
}

- (IBAction) syncWithRunAction:(id)sender
{
	[model setSyncWithRun:[sender intValue]];	
}

- (IBAction) displayRawAction:(id)sender
{
	int tag = [[displayRawMatrix selectedCell] tag];
	[model setDisplayRaw:tag];	
}

- (IBAction) lockAction:(id) sender
{
    [gSecurity tryToSetLock:ORVXMLock to:[sender intValue] forWindow:[self window]];
}

- (IBAction) portListAction:(id) sender
{
    [model setPortName: [portListPopup titleOfSelectedItem]];
}

- (IBAction) openPortAction:(id)sender
{
    [model openPort:![[model serialPort] isOpen]];
}

- (IBAction) getPositionAction:(id)sender
{
	[model queryPosition];
}

- (IBAction) goAllHomeAction:(id)sender
{
	[self endEditing];
	[model goHomeAll];
}

- (IBAction) goHomeAction:(id)sender
{
	[self endEditing];
	[model goHomeAll];
}

- (IBAction) stopAllAction:(id)sender
{
    [model stopAllMotion];
}

- (IBAction) goToNextCommandAction:(id)sender
{
    [model goToNexCommand];
}

- (IBAction) conversionAction:(id)sender
{
    [[model motor:[[sender selectedCell]tag]] setConversion:[[sender selectedCell] floatValue]];
}

- (IBAction) fullScaleAction:(id)sender
{
	ORVXMMotor* aMotor = [model motor:[[sender selectedCell]tag]];
	float conversion = 1.0;
	if(![model displayRaw]) conversion = [aMotor conversion];
	[aMotor setFullScale:(int)[[sender selectedCell] floatValue]*conversion];
}

- (IBAction) speedAction:(id)sender
{
	ORVXMMotor* aMotor = [model motor:[[sender selectedCell]tag]];
	float conversion = 1.0;
	if(![model displayRaw]) conversion = [aMotor conversion];
	[aMotor setMotorSpeed:(int)[[sender selectedCell] floatValue]*conversion];
}

- (IBAction) targetPositionAction:(id)sender
{
	ORVXMMotor* aMotor = [model motor:[[sender selectedCell]tag]];
	float conversion = 1.0;
	if(![model displayRaw]) conversion = [aMotor conversion];
	[aMotor setTargetPosition:(int)[[sender selectedCell] floatValue]*conversion];
}

- (IBAction) motorEnabledAction:(id)sender
{
	[[model motor:[[sender selectedCell]tag]] setMotorEnabled:[[sender selectedCell] intValue]];
}

- (IBAction) absoluteMotionAction:(id)sender
{
	[[model motor:[[sender selectedCell]tag]] setAbsoluteMotion:[[sender selectedCell] intValue]];
}

- (IBAction) addButtonAction:(id)sender
{
	[self endEditing];
	[model addCmdFromTableFor:[[sender selectedCell]tag]];
}

#pragma mark •••Table Data Source
- (int) numberOfRowsInTableView:(NSTableView *)aTableView
{
	return [model cmdQueueCount];
}

- (id) tableView:(NSTableView *) aTableView objectValueForTableColumn:(NSTableColumn *) aTableColumn row:(int) rowIndex
{
	if([[aTableColumn identifier] isEqualToString:@"Command"]) return [model cmdQueueCommand:rowIndex];
	else if([[aTableColumn identifier] isEqualToString:@"CmdIndex"]) {
		if(rowIndex == [model cmdIndex])return @"√";
		else return @"";
	}
	else return  [model cmdQueueDescription:rowIndex];
}
@end

@implementation ORVXMController (private)
- (void) populatePortListPopup
{
	NSEnumerator *enumerator = [ORSerialPortList portEnumerator];
	ORSerialPort *aPort;
    [portListPopup removeAllItems];
    [portListPopup addItemWithTitle:@"--"];

	while (aPort = [enumerator nextObject]) {
        [portListPopup addItemWithTitle:[aPort name]];
	}    
}
@end


