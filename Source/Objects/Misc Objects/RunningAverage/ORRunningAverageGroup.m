//
//  ORRunningAverageGroup
//  Orca
//
//  Created by Wenqin on 5/16/16.
//
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


#import "ORRunningAverageGroup.h"
NSString* ORRunningAverageSpikeNotification  = @"ORRunningAverageSpikeNotification";
NSString* ORRunningAverageChangedNotification = @"ORRunningAverageChangedNotification";

@implementation ORRunningAverageGroup

- (id) initGroup:(int)numberInGroup groupTag:(int) aGroupTag withLength:(int)wl
{
    self = [super init];
    verbose = NO;

    [self setTag:aGroupTag];
    [self setWindowLength:wl];
    [self setGroupSize:numberInGroup];
    
    [self setRunningAverages:[NSMutableArray array]];
    
    triggerType = kRASpikeOnRatio;
    triggerValue=0.1;
    
    int i;
    for(i=0;i<numberInGroup;i++){
        ORRunningAverage* aRAObj = [[ORRunningAverage alloc] initWithTag:i andLength:wl];
        [aRAObj setGroupTag:aGroupTag];
        [runningAverages addObject:aRAObj];
        [aRAObj release];
    }
    return self;
}

- (void) dealloc
{
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
    [runningAverages release];
    [super dealloc];
}

#pragma mark •••Accessors
-(void) setGroupSize:(int)a
{
    groupSize=a;
}

-(int)groupSize
{
    return groupSize;
}

-(void) setVerbose:(BOOL)b
{
    verbose=b;
}


- (void) setTriggerType: (int)aType;
{
    triggerType = aType;
}
- (int)  triggerType
{
    return triggerType;
}

- (void) setTriggerValue:(float)aValue
{
    triggerValue =aValue;
}

- (float) triggerValue
{
    return triggerValue;
}

- (NSArray*) runningAverages
{
    if(verbose)NSLog(@"ORRunningAverageGroup, - runningAverages\n");
    return runningAverages;
}

- (void) setRunningAverages:(NSMutableArray *)newRAs
{
    if(verbose)NSLog(@"ORRunningAverageGroup, - setRunningAverages\n");
    [newRAs retain]; //in case the newRAs is itself.
    [runningAverages release];
    runningAverages = newRAs;
}

- (id) runningAverageObject:(short)index
{
    if(index<[runningAverages count]){
        return [runningAverages objectAtIndex:index];
    }
    else return nil;
}

- (float) getRunningAverageValue:(short)idx{
    if(idx<[runningAverages count]){
        return [[self runningAverageObject:idx] runningAverage];
    }
    else return 0;
} //this is no new caculation in the getAverage method, just returns a value

- (NSArray*) getRunningAverageValues {
    if(verbose)NSLog(@"ORRunningAverageGroup, - (NSArray*)getRunningAverage\n");

    NSMutableArray * newrunningAverages = [[NSMutableArray alloc] init];
    int idx;
    for(idx=0; idx<[runningAverages count];idx++){
        [newrunningAverages addObject:[NSNumber numberWithFloat:[self getRunningAverageValue: idx]]];
    }
    return [newrunningAverages autorelease];
} //return the copy of running averages that this object keeps

- (void) updateWindowLength:(int) newWindowLength
{
    if(verbose)NSLog(@"ORRunningAverageGroup, - setWindowLength\n");
    int idx;
    for(idx=0; idx<[runningAverages count];idx++){
        [[self runningAverageObject:idx] setWindowLength:newWindowLength];
    }
}

-(void) setWindowLength:(int)newWindowLength
{
    windowLength=newWindowLength;
}

-(int) windowLength
{
    return windowLength;
}

- (void) resetCounters:(float) rate
{
    int idx;
    for(idx=0; idx<[runningAverages count];idx++){
        [[self runningAverageObject:idx] resetCounter:rate];
    }
}

- (int) tag
{
    return tag;
}
- (void) setTag:(int)newTag
{
    tag=newTag;
}

- (void) addNewValue:(float)aValue toIndex:(int)i
{
    ORRunningAverage* ra         = [runningAverages objectAtIndex:i];
    ORRunningAveSpike* aSpikeObj = [ra averageRate:aValue minSamples:windowLength triggerValue:triggerValue spikeType:triggerType];
    if(aSpikeObj){
        NSDictionary* userInfo = [NSDictionary dictionaryWithObject:aSpikeObj forKey:@"SpikeObject"];
        [[NSNotificationCenter defaultCenter] postNotificationName:ORRunningAverageSpikeNotification object:self userInfo:userInfo];
    }
}


- (void) resetRates
{
    if(verbose)NSLog(@"ORRunningAverageGroup, - resetRates\n");

    [runningAverages makeObjectsPerformSelector:@selector(reset)];//what does this mean?
    //[self setTotalRate:0];
}


@end

