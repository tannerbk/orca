//--------------------------------------------------------
// ORXYScannerController
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

@class ORPlotter2D;

@interface ORXYScannerController : OrcaObjectController
{
    IBOutlet ORPlotter2D*   xyPlot;
    IBOutlet NSTextField*   lockDocField;
    IBOutlet NSTextField*   portStateField;
    IBOutlet NSButton*      lockButton;
    IBOutlet NSPopUpButton* portListPopup;
    IBOutlet NSButton*      openPortButton;
    IBOutlet NSButton*      getPositionButton;
    IBOutlet NSButton*      getHomeButton;
    IBOutlet NSTextField*   xPositionField;
    IBOutlet NSTextField*   yPositionField;
    IBOutlet NSTextField*   cmdXValueField;
    IBOutlet NSTextField*   cmdYValueField;
    IBOutlet NSMatrix*      absMatrix;
    IBOutlet NSButton*      goButton;
    IBOutlet NSButton*      stopButton;
    IBOutlet NSTextField*   goingHomeField;
    IBOutlet NSTextField*   moveLabelField;
    IBOutlet NSTextField*   cmdFileField;
    IBOutlet NSTextField*   cmdFileField1;
    IBOutlet NSButton*      selectCmdFileButton;
    IBOutlet NSButton*      selectCmdFileButton1;
    IBOutlet NSButton*      runCmdFileButton;
    IBOutlet NSMatrix*      patternTypeMatrix;
    IBOutlet NSMatrix*      patternMatrix;
    IBOutlet NSMatrix*      optionMatrix;
    IBOutlet NSTextField*   dwellTimeField;
}

#pragma mark ***Initialization
- (id) init;
- (void) dealloc;
- (void) awakeFromNib;

#pragma mark ***Notifications
- (void) registerNotificationObservers;
- (void) updateWindow;
- (void) lockChanged:(NSNotification*)aNotification;
- (void) portNameChanged:(NSNotification*)aNotification;
- (void) portStateChanged:(NSNotification*)aNotification;
- (void) positionChanged:(NSNotification*)aNotification;
- (void) cmdPositionChanged:(NSNotification*)aNotification;
- (void) absMotionChanged:(NSNotification*)aNotification;
- (void) goingHomeChanged:(NSNotification*)aNotification;
- (void) cmdFileChanged:(NSNotification*)aNotification;
- (void) patternTypeChanged:(NSNotification*)aNotification;
- (void) patternChanged:(NSNotification*)aNotification;
- (void) dwellTimeChanged:(NSNotification*)aNotification;
- (void) optionsChanged:(NSNotification*)aNotification;

#pragma mark ***Accessors


#pragma mark ***Actions
- (IBAction) lockAction:(id) sender;
- (IBAction) portListAction:(id) sender;
- (IBAction) openPortAction:(id)sender;
- (IBAction) getPositionAction:(id)sender;
- (IBAction) goHomeAction:(id)sender;
- (IBAction) cmdPositionAction:(id)sender;
- (IBAction) absMotionAction:(id)sender;
- (IBAction) goAction:(id)sender;
- (IBAction) stopAction:(id)sender;
- (IBAction) runCmdFileAction:(id)sender;
- (IBAction) selectCmdFileAction:(id)sender;
- (IBAction) patternTypeAction:(id)sender;
- (IBAction) patternAction:(id)sender;
- (IBAction) dwellTimeAction:(id)sender;
- (IBAction) optionsAction:(id)sender;

@end

