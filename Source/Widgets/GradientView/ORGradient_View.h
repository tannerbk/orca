//
//  ORGradient_View.h
//  Orca
//
//  Created by Mark Howe on 6/20/07.
//  Copyright 2007 CENPA, University of Washington. All rights reserved.
//
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

#import <Cocoa/Cocoa.h>

@class CTGradient;

@interface ORGradient_View : NSView {
	CTGradient*			gradient;
	NSColor*			endColor;
	NSColor*			startColor;
	IBOutlet NSView*    viewToAdd;
}
- (NSColor*) startColor;
- (void) setStartColor:(NSColor*)aColor;
- (NSColor*) endColor;
- (void) setEndColor:(NSColor*)aColor;
- (void) makeGradient;

#pragma mark ���Archival
- (id)initWithCoder:(NSCoder*)decoder;
- (void)encodeWithCoder:(NSCoder*)encoder;

@end
