////////////////////////////////////////////////////////////////////////////////
//  RRFCRTController.h
//  RRFCRT
//  ----------------------------------------------------------------------------
//  Author: Travis Nesland
//  Created: 3/31/11
//  Copyright 2011, Residential Research Facility,
//  University of Kentucky. All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
#import <Cocoa/Cocoa.h>
#import <TKUtility/TKUtility.h>
@class CRTTrial;
@class CRTResponderImageView;

@interface RRFCRTController : NSObject <TKComponentBundleLoading> {

  // PROTOCOL MEMBERS //////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////    
  NSDictionary                                                *definition;
  id                                                          delegate;
  NSString                                                    *errorLog;
  IBOutlet NSView                                             *view;

  // ADDITIONAL MEMBERS ////////////////////////////////////////////////////////
  //////////////////////////////////////////////////////////////////////////////
	NSMutableArray * trials;
	NSMutableArray * finishedTrials;
	NSView * theWindow;
	NSTextField * textField;
	CRTResponderImageView * imageView;
	NSInteger applicationState;
	CRTTrial * currentTrial;
  TKTime startMarker;
  TKTime lastMarker;
	NSUInteger trialBlocksCompleted;
	NSUInteger totalTrialsThisRun;
  /* defined parameters */
  NSUInteger prepTimeMilliseconds;
  NSUInteger blankScreenMilliseconds;
  NSUInteger numberOfVerticalGreenRectangles;
  NSUInteger numberOfHorizontalGreenRectangles;
  NSUInteger numberOfVerticalBlueRectangles;
  NSUInteger numberOfHorizontalBlueRectangles;
  NSUInteger numberOf100msTrials;
  NSUInteger numberOf200msTrials;
  NSUInteger numberOf300msTrials;
  NSUInteger numberOf400msTrials;
  NSUInteger numberOf500msTrials;
  NSUInteger maxTrialWaitTime;
  NSUInteger resultDisplayTime;
  NSUInteger numberOfTrialBlocks;
  NSUInteger blockSize;
  NSUInteger breakTime;
  NSUInteger breakWarning;
  NSUInteger responseTimeFilter;
}

// PROTOCOL PROPERTIES /////////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@property (assign)              NSDictionary                    *definition;
@property (assign)              id <TKComponentBundleLoading>   delegate;
@property (nonatomic, retain)   NSString                        *errorLog;
@property (assign)              IBOutlet NSView                 *view;

// ADDITIONAL PROPERTIES ///////////////////////////////////////////////////////
////////////////////////////////////////////////////////////////////////////////
@property(nonatomic,retain) NSMutableArray * finishedTrials;
@property(nonatomic,retain) CRTTrial * currentTrial;
@property(nonatomic,retain) IBOutlet CRTResponderImageView * imageView;
@property(nonatomic,retain) IBOutlet NSTextField * textField;
@property(nonatomic,retain) IBOutlet NSView * theWindow;
@property(nonatomic,retain) NSMutableArray * trials;
@property(readwrite) NSUInteger trialBlocksCompleted;
@property(readwrite) NSInteger applicationState;
@property(readwrite) NSUInteger totalTrialsThisRun;

#pragma mark REQUIRED PROTOCOL METHODS
/**
 Start the component - will receive this message from the component controller
 */
- (void)begin;
/**
 Return a string representation of the data directory
 */
- (NSString *)dataDirectory;
/**
 Return a string object representing all current errors in log form
 */
- (NSString *)errorLog;
/**
 Perform any and all error checking required by the component - return YES if
 passed
 */
- (BOOL)isClearedToBegin;
/**
 Returns the file name containing the raw data that will be appended to the 
 data file
 */
- (NSString *)rawDataFile;
/**
 Perform actions required to recover from crash using the given raw data passed
 as string
 */
- (void)recover;
/**
 Accept assignment for the component definition
 */
- (void)setDefinition: (NSDictionary *)aDictionary;
/**
 Accept assignment for the component delegate - The component controller will 
 assign itself as the delegate
 Note: The new delegate must adopt the TKComponentBundleDelegate protocol
 */
- (void)setDelegate: (id <TKComponentBundleDelegate> )aDelegate;
/**
 Perform any and all initialization required by component - load any nib files
 and perform all required initialization
 */
- (void)setup;
/**
 Return YES if component should perform recovery actions
 */
- (BOOL)shouldRecover;
/**
 Return the name for the current task
 */
- (NSString *)taskName;
/**
 Perform any and all finalization required by component
 */
- (void)tearDown;
/**
 Return the main view that should be presented to the subject
 */
- (NSView *)mainView;

#pragma mark OPTIONAL PROTOCOL METHODS
// UNCOMMENT ANY OF THE FOLLOWING METHODS IF THEIR BEHAVIOR IS DESIRED
////////////////////////////////////////////////////////////////////////////////
/**
 Run header if something other than default is required
 */
- (NSString *)runHeader;
/**
 Session header if something other than default is required
 */
//- (NSString *)sessionHeader;
/**
 Summary data if desired
 */
- (NSString *)summary;
/**
 Summary offset -- required if custom summary is used
 */
- (NSUInteger)summaryOffset;

#pragma mark ADDITIONAL METHODS
// PLACE ANY NON-PROTOCOL METHODS HERE
//////////////////////////////////////
/**
 Add the error to an ongoing error log
 */
- (void)registerError: (NSString *)theError;
/**
 BEGIN: Scott's original methods
 */
//-(void) applicationDidFinishLaunching:(NSNotification *)aNotifications;
//-(void) applicationWillFinishLaunching:(NSNotification *)aNotifications;
//+(CRTAppController*) sharedAppController;
-(void)userDidInputCharacters:(NSString*)characters;
-(void)beginNextTrial:(NSNotification *)notification;
-(void)layoutTrials;
-(void)userTimeOut:(NSNotification *) notification;
-(void)displayBlankScreenBeforeEmptyRectangle:(NSNotification *) notification;
-(void)displayBlankRectangle:(NSNotification *) notification;
-(void)displayFullRectangle:(NSNotification *) notification;
-(void)showResults:(NSNotification *) notification;
//-(void) terminate;
-(void)beginBreak;
-(void)giveBreakWarning:(NSNotification *)notification;
//-(void)readStartupInfo;
//-(BOOL)attemptCrashRecovery;
//-(BOOL)setupNewRun;
//-(void)logRunRawDataHeader;
//-(void)logCurrentRunHeader;
//-(NSString *) getCurrentRunHeader;
//-(NSString *) mainHeaderString;

#pragma mark Preference Keys
// HERE YOU DEFINE KEY REFERENCES FOR ANY PREFERENCE VALUES
// ex: NSString * const RRFCRTNameOfPreferenceKey;
////////////////////////////////////////////////////////////////////////////////
NSString * const RRFCRTTaskNameKey;
NSString * const RRFCRTDataDirectoryKey;
NSString * const RRFCRTPrepTimeMSKey;
NSString * const RRFCRTBlankScreenTimeMSKey;
NSString * const RRFCRTVertGreenRectCountKey;
NSString * const RRFCRTVertBlueRectCountKey;
NSString * const RRFCRTHorizGreenRectCountKey;
NSString * const RRFCRTHorizBlueRectCountKey;
NSString * const RRFCRT100TrialCountKey;
NSString * const RRFCRT200TrialCountKey;
NSString * const RRFCRT300TrialCountKey;
NSString * const RRFCRT400TrialCountKey;
NSString * const RRFCRT500TrialCountKey;
NSString * const RRFCRTMaxTrialWaitTimeMSKey;
NSString * const RRFCRTResultDisplayTimeMSKey;
NSString * const RRFCRTTrialBlockCountKey;
NSString * const RRFCRTBlockSizeKey;
NSString * const RRFCRTBreakTimeKey;
NSString * const RRFCRTBreakWarningKey;
NSString * const RRFCRTResponseTimeFilterMSKey;

#pragma mark Internal Strings
// HERE YOU DEFINE KEYS FOR CONSTANT STRINGS
////////////////////////////////////////////////////////////////////////////////
NSString * const RRFCRTMainNibNameKey;

#pragma mark Enumerated Values
// HERE YOU CAN DEFINE ENUMERATED VALUES
// ex:
// enum {
//  RRFCRTSomeDescriptor          = 0,
//  RRFCRTSomeOtherDescriptor     = 1,
//  RRFCRTAnotherDescriptor       = 2
// }; typedef NSInteger RRFCRTBlanketDescriptor;
////////////////////////////////////////////////////////////////////////////////
enum appState {
  CRTWaitingForUserToBegin=0,
  CRTBreak=1,
  CRTBreakTimeWarning=2,
  CRTPrepTime=3,
  CRTTransitionToEmptyRectangle=4,
  CRTEmptyRectangle=5,
  CRTDuringTrial=6,
  CRTDisplayingResults=7
};

@end
