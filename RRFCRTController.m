////////////////////////////////////////////////////////////////////////////////
//  RRFCRTController.m
//  RRFCRT
//  ----------------------------------------------------------------------------
//  Author: Travis Nesland
//  Created: 3/31/11
//  Copyright 2011, Residential Research Facility,
//  University of Kentucky. All Rights Reserved.
////////////////////////////////////////////////////////////////////////////////
#import "RRFCRTController.h"
#import "CRTResponderImageView.h"
#import "CRTTrial.h"

#define RRFLogToTemp(fmt, ...) [delegate logStringToDefaultTempFile:[NSString stringWithFormat:fmt,##__VA_ARGS__]]
#define RRFLogToFile(filename,fmt, ...) [delegate logString:[NSString stringWithFormat:fmt,##__VA_ARGS__] toDirectory:[delegate tempDirectory] toFile:filename]
#define RRFPathToTempFile(filename) [[delegate tempDirectory] stringByAppendingPathComponent:filename]

@implementation RRFCRTController

@synthesize applicationState;
@synthesize currentTrial;
@synthesize definition;
@synthesize delegate;
@synthesize errorLog;
@synthesize finishedTrials;
@synthesize imageView;
@synthesize storedImages;
@synthesize textField;
@synthesize totalTrialsThisRun;
@synthesize trialBlocksCompleted;
@synthesize trials;
@synthesize view;

#pragma mark HOUSEKEEPING METHODS
/**
 Give back any memory that may have been allocated by this bundle
 */
- (void)dealloc {
  [currentTrial release];currentTrial=nil;
  [errorLog release];errorLog=nil;
  [finishedTrials release];finishedTrials=nil;
  [storedImages release];storedImages=nil;
  [trials release];trials=nil;
  // any additional release calls go here
  // ...
  [super dealloc];
}

- (id)init {
  if(self=[super init]) {
    trialBlocksCompleted = 0;
    totalTrialsThisRun = 0;
    finishedTrials = [[NSMutableArray alloc] init];
    storedImages = [[NSMutableArray alloc] init];
    return self;
  }
  return nil;
}

#pragma mark REQUIRED PROTOCOL METHODS
/**
 Start the component - will receive this message from the component controller
 */
- (void)begin {

}
/**
 Return a string representation of the data directory
 */
- (NSString *)dataDirectory {
  NSString *temp = nil;
  if(temp = [definition valueForKey:RRFCRTDataDirectoryKey]) {
    return [temp stringByStandardizingPath];    // return standardized path if
                                                // we have one
  } else {
    return nil;                                 // otherwise, return nil
  }
}
/**
 Return a string object representing all current errors in log form
 */
- (NSString *)errorLog {
  return errorLog;
}
/**
 Perform any and all error checking required by the component - return YES if 
 passed
 */
- (BOOL)isClearedToBegin {
  return YES; // this is the default; change as needed
}
/**
 Returns the file name containing the raw data that will be appended to the data
 file
 */
- (NSString *)rawDataFile {
  return [delegate defaultTempFile]; // this is the default implementation
}
/**
 Perform actions required to recover from crash using the given raw data passed
 as string
 */
- (void)recover {
  DLog(@"Beginning Recovery Process");
  // get info from previous run
  NSDictionary *ourTaskEntry = [delegate registryForTaskWithOffset:0];
  NSDictionary *previousRun = [delegate registryForRunWithOffset:0 forTaskRegistry:ourTaskEntry];
  NSData *archivedTrials = [previousRun valueForKey:RRFCRTPreviousTrialsKey];
  if(archivedTrials) {
    NSArray *unarchivedTrials = [NSKeyedUnarchiver unarchiveObjectWithData:archivedTrials];
    [finishedTrials addObjectsFromArray:unarchivedTrials];
    totalTrialsThisRun = [finishedTrials count];
  }
  trialBlocksCompleted = [[previousRun valueForKey:RRFCRTBlocksFinishedKey] unsignedIntegerValue];
  // remove secondary temp^2 file, this is the raw data from last run
  [[NSFileManager defaultManager] removeItemAtPath:RRFPathToTempFile(RRFCRTHeapFileKey) error:nil];
  // then perform normal setup
  [self setup];
}
/**
 Accept assignment for the component definition
 */
- (void)setDefinition: (NSDictionary *)aDictionary {
  definition = aDictionary;
}
/**
 Accept assignment for the component delegate - The component controller will 
 assign itself as the delegate
 Note: The new delegate must adopt the TKComponentBundleDelegate protocol
 */
- (void)setDelegate: (id <TKComponentBundleDelegate> )aDelegate {
  delegate = aDelegate;
}
/**
 Perform any and all initialization required by component - load any nib files 
 and perform all required initialization
 */
- (void)setup {
  [self setErrorLog:@""]; // clear the error log
  // WHAT NEEDS TO BE INITIALIZED BEFORE THIS COMPONENT CAN OPERATE?
  // ...
  applicationState = CRTWaitingForUserToBegin;
  prepTimeMilliseconds = [[definition valueForKey:RRFCRTPrepTimeMSKey] unsignedIntegerValue];
  blankScreenMilliseconds = [[definition valueForKey:RRFCRTBlankScreenTimeMSKey] unsignedIntegerValue];
  numberOfVerticalGreenRectangles = [[definition valueForKey:RRFCRTVertGreenRectCountKey] unsignedIntegerValue];
  numberOfHorizontalGreenRectangles = [[definition valueForKey:RRFCRTHorizGreenRectCountKey] unsignedIntegerValue];
  numberOfVerticalBlueRectangles = [[definition valueForKey:RRFCRTVertBlueRectCountKey] unsignedIntegerValue];
  numberOfHorizontalBlueRectangles = [[definition valueForKey:RRFCRTHorizBlueRectCountKey] unsignedIntegerValue];
  numberOf100msTrials = [[definition valueForKey:RRFCRT100TrialCountKey] unsignedIntegerValue];
  numberOf200msTrials = [[definition valueForKey:RRFCRT200TrialCountKey] unsignedIntegerValue];
  numberOf300msTrials = [[definition valueForKey:RRFCRT300TrialCountKey] unsignedIntegerValue];
  numberOf400msTrials = [[definition valueForKey:RRFCRT400TrialCountKey] unsignedIntegerValue];
  numberOf500msTrials = [[definition valueForKey:RRFCRT500TrialCountKey] unsignedIntegerValue];
  maxTrialWaitTime = [[definition valueForKey:RRFCRTMaxTrialWaitTimeMSKey] unsignedIntegerValue];
  resultDisplayTime = [[definition valueForKey:RRFCRTResultDisplayTimeMSKey] unsignedIntegerValue];
  numberOfTrialBlocks = [[definition valueForKey:RRFCRTTrialBlockCountKey] unsignedIntegerValue];
  blockSize = [[definition valueForKey:RRFCRTBlockSizeKey] unsignedIntegerValue];
  breakTime = [[definition valueForKey:RRFCRTBreakTimeKey] unsignedIntegerValue];
  breakWarning = [[definition valueForKey:RRFCRTBreakWarningKey] unsignedIntegerValue];
  responseTimeFilter = [[definition valueForKey:RRFCRTResponseTimeFilterMSKey] unsignedIntegerValue];
	NSNotificationCenter * noteCenter=[NSNotificationCenter defaultCenter];
	[noteCenter addObserver:self selector:@selector(displayBlankScreenBeforeEmptyRectangle:) name:@"displayBlankScreenBeforeEmptyRectangle" object:nil];
	[noteCenter addObserver:self selector:@selector(displayBlankRectangle:) name:@"displayBlankRectangle" object:nil];
	[noteCenter addObserver:self selector:@selector(displayFullRectangle:) name:@"displayFullRectangle" object:nil];
	[noteCenter addObserver:self selector:@selector(userTimeOut:) name:@"userTimeOut" object:nil];
	[noteCenter addObserver:self selector:@selector(beginNextTrial:) name:@"beginNextTrial" object:nil];
  [noteCenter addObserver:self selector:@selector(giveBreakWarning:) name:@"giveBreakWarning" object:nil];
  [self cacheImages];
  [self layoutTrials];
  DLog(@"Trials Array: %@",trials);
  // LOAD NIB
  // ...
  if([NSBundle loadNibNamed:RRFCRTMainNibNameKey owner:self]) {
    // SETUP THE INTERFACE VALUES
    // ...
		[textField setFont:[NSFont fontWithName:[[textField font] fontName] size:48]];	
		[textField sizeToFit];
		NSRect windowFrame = [view frame];
		float textFieldWidth = ([textField frame]).size.width*4;
		float textFieldHeight = ([textField frame]).size.height*4;	    
		[textField setFrame:NSMakeRect(((windowFrame.size.width/2) - (textFieldWidth/2)),((windowFrame.size.height/2)-(textFieldHeight/2)),textFieldWidth,textFieldHeight)];
		[textField setNeedsDisplay];
		[[delegate sessionWindow] makeFirstResponder:imageView];    
  } else {
    // nib did not load, so throw error
    [self registerError:@"Could not load Nib file"];
  }
}
/**
 Return YES if component should perform recovery actions
 */
- (BOOL)shouldRecover {
  // need to recover if we still have raw data sitting out there
  NSFileManager *fm = [NSFileManager defaultManager];
  return [fm fileExistsAtPath:RRFPathToTempFile([delegate defaultTempFile])];
}
/**
 Perform any and all finalization required by component
 */
- (void)tearDown {
  // any finalization should be done here:
  // ...
  [self clearImagesFromCache];
  [delegate setValue:nil forRunRegistryKey:RRFCRTPreviousTrialsKey];  // clear out previous trials data
  // remove any temporary data files (uncomment below to use default)
  NSError *tFileMoveError = nil;
  [[NSFileManager defaultManager] removeItemAtPath:RRFPathToTempFile([delegate defaultTempFile]) error:&tFileMoveError];
  [[NSFileManager defaultManager] removeItemAtPath:RRFPathToTempFile(RRFCRTHeapFileKey) error:&tFileMoveError];
  if(tFileMoveError) {
    ELog(@"%@",[tFileMoveError localizedDescription]);
    [tFileMoveError release]; tFileMoveError=nil;
  }
  // de-register any possible notifications
  [[NSNotificationCenter defaultCenter] removeObserver:self];
}
/**
 Return the name of the current task
 */
- (NSString *)taskName {
  return [definition valueForKey:RRFCRTTaskNameKey];
}
/**
 Return the main view that should be presented to the subject
 */
- (NSView *)mainView {
  return view;
}

#pragma mark OPTIONAL PROTOCOL METHODS
/** Uncomment and implement the following methods if desired */
/**
 Run header if something other than default is required
 */
- (NSString *)runHeader {
  NSString *_header;
  _header = [NSString stringWithFormat:@"\nRun:%d Time:%@\n",[delegate runCount],[NSDate date]];
  _header = [_header stringByAppendingString:@"Trial\tHit\tMiss\tCorrectMiss\tIncorrectHit\tTarget\tResponseTime\tSOA\n"];
  return _header;
}
/**
 Session header if something other than default is required
 */
//- (NSString *)sessionHeader {
//
//}
/**
 Summary data if desired
 */
- (NSString *)summary {
	NSString * headerString = [NSString stringWithString:@"SOA\tGo Correct\tGo Corr Rt\tGo Err\tNoGo Correct\tNoGo Err\tNoGo Err RT\tVert Go Correct\tVert Go Corr RT\tVert Go Err\tVert NoGo Correct\tVert NoGo Ert\tVert NoGo Err Rt\tHorz Go Correct\tHorz Go Corr RT\tHorz Go Err\tHorz NoGo Correct\tHorz NoGo Err\tHorz NoGo Err RT\n"];
	int i=0;
	int j=0;
	for(i=1;i<=5;i++){
		NSUInteger soa = (i * 100);
		NSUInteger goCorrect = 0;
		float	   totalGoCorrectRT =0;
		NSUInteger goErr =0;
		NSUInteger noGoCorrect =0;
		NSUInteger noGoErr=0;
		float totalNoGoErrRT=0;
		NSUInteger vertGoCorrect=0;
		float totalVertGoCorrRT=0;
		NSUInteger vertGoErr=0;
		NSUInteger vertNoGoCorrect=0;
		NSUInteger vertNoGoErr=0;
		float	totalVertNoGoErrRT =0;
		NSUInteger horzGoCorrect =0;
		float totalHorzGoCorrRT = 0;
		NSUInteger horzGoErr = 0;
		NSUInteger horzNoGoCorrect = 0;
		NSUInteger horzNoGoErr =0;
		float totalHorzNoGoErrRT = 0;
		for(j=0;j<[finishedTrials count];j++){
			CRTTrial * trial = [finishedTrials objectAtIndex:j];
			float millisecondResponseTime = (float) [trial responseTimeMicroseconds] / (float) 1000;
			if(([trial waitTimeMilliseconds] == (i*100))&&(![trial didHit] || millisecondResponseTime > responseTimeFilter)){
				if ( [trial color] == [NSColor greenColor] ){
					if( [trial orientation] == CRTVerticalOrientation ){
						if([trial didHit]){
							goCorrect++;
							vertGoCorrect++;
							totalGoCorrectRT += millisecondResponseTime;
							totalVertGoCorrRT += millisecondResponseTime;
						}else{
							goErr ++;
							vertGoErr ++;
						}
					}else{
						if([trial didHit]){
							goCorrect++;
							horzGoCorrect++;
							totalGoCorrectRT += millisecondResponseTime;
							totalHorzGoCorrRT += millisecondResponseTime;
						}else{
							goErr ++;
							horzGoErr ++;
						}						
					}					
				}else{
					if( [trial orientation] == CRTVerticalOrientation ){
						if([trial didHit]){
							noGoErr++;
							totalNoGoErrRT += millisecondResponseTime;
							vertNoGoErr++;
							totalVertNoGoErrRT +=millisecondResponseTime;
						}else{
							noGoCorrect++;
							vertNoGoCorrect++;
						}
					}else{
						if([trial didHit]){
							noGoErr++;
							totalNoGoErrRT += millisecondResponseTime;
							horzNoGoErr++;
							totalHorzNoGoErrRT +=millisecondResponseTime;
						}else{
							noGoCorrect++;
							horzNoGoCorrect++;
						}
					}					
				} // end if blue
				
			} // end if we don't through it out
		} // end for every trial
		
		NSNumber * goCorrectRT = [NSNumber numberWithFloat:(goCorrect == 0 ? 0.0 : (totalGoCorrectRT/goCorrect))];
		NSNumber * noGoErrRT = [NSNumber numberWithFloat:(noGoErr == 0 ? 0.0 :(totalNoGoErrRT/noGoErr))];
		NSNumber * vertGoCorrectRT = [NSNumber numberWithFloat:(vertGoCorrect == 0 ? 0.0 : (totalVertGoCorrRT/vertGoCorrect))];
		NSNumber * vertNoGoErrRT = [NSNumber numberWithFloat:(vertNoGoErr == 0 ? 0.0 : (totalVertNoGoErrRT/vertNoGoErr))];
		NSNumber * horzGoCorrectRT = [NSNumber numberWithFloat:(horzGoCorrect == 0 ? 0.0 : (totalHorzGoCorrRT/horzGoCorrect))];
		NSNumber * horzNoGoErrRT = [NSNumber numberWithFloat:(horzNoGoErr == 0 ? 0.0 : (totalHorzNoGoErrRT/horzNoGoErr))];
		NSNumberFormatter * formatter = [[NSNumberFormatter alloc] init];
		[formatter setFormat:@"000.00"];
		headerString = [headerString stringByAppendingString:[NSString stringWithFormat:@"%03d\t%03d\t%@\t%03d\t%03d\t%03d\t%@\t%03d\t%@\t%03d\t%03d\t%03d\t%@\t%03d\t%@\t%03d\t%03d\t%03d\t%@\n",
                                                          soa, 
                                                          goCorrect, 
                                                          [formatter stringFromNumber:goCorrectRT], 
                                                          goErr,
                                                          noGoCorrect,
                                                          noGoErr,
                                                          [formatter stringFromNumber:noGoErrRT],
                                                          vertGoCorrect,
                                                          [formatter stringFromNumber:vertGoCorrectRT],
                                                          vertGoErr,
                                                          vertNoGoCorrect,
                                                          vertNoGoErr,
                                                          [formatter stringFromNumber:vertNoGoErrRT],
                                                          horzGoCorrect,
                                                          [formatter stringFromNumber:horzGoCorrectRT], 
                                                          horzGoErr,
                                                          horzNoGoCorrect,
                                                          horzNoGoErr,
                                                          [formatter stringFromNumber:horzNoGoErrRT]]];
		
	}
	
	return headerString;
}

- (NSUInteger)summaryOffset {
  // for an overwritting summary, un-comment the following line
  // return [[[delegate registryForTaskWithOffset:0] valueForKey:TKComponentSummaryStartKey] unsignedIntegerValue];
  // ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
  // for an appending summary, un-comment the following line
  return [[[delegate registryForTaskWithOffset:0] valueForKey:TKComponentSummaryEndKey] unsignedIntegerValue];
}

#pragma mark ADDITIONAL METHODS
- (void)cacheImages
{
  // get my bundle instance
  NSBundle *thisBundle = [NSBundle bundleForClass:[self class]];
  DLog(@"This is my bundle: %@",thisBundle);
  // get all image resources in our bundle
  NSArray *myImagePaths = [thisBundle pathsForResourcesOfType:@"PNG" inDirectory:nil];
  DLog(@"I found paths to these images: %@",myImagePaths);
  // for every found image path
  for(NSString *imgPath in myImagePaths)
  {
    // get the image file name
    NSString *_filename = [imgPath lastPathComponent];
    // create and cache the image
    NSImage *_img = [[NSImage alloc] initWithContentsOfFile:imgPath];
    [_img setName:_filename];
    DLog(@"Setting name: %@ for image: %@",_filename,_img);
    [storedImages addObject:_img];
  }
  DLog(@"I've done stored all these images: %@",storedImages);
}

- (void)clearImagesFromCache
{
  for(NSImage *_img in storedImages)
  {
    [_img setName:nil]; // explicitly remove from named cache
    [storedImages removeObject:_img];
    [_img release];_img=nil;
  }
}
  
/** Add additional methods required for operation */
- (void)registerError: (NSString *)theError {
  // append the new error to the error log
  [self setErrorLog:[[errorLog stringByAppendingString:theError] 
                     stringByAppendingString:@"\n"]];
}

- (void)writeMilestoneDataToRegistry {
  // write heap file to default temp
  NSString *heapContents = [NSString stringWithContentsOfFile:RRFPathToTempFile(RRFCRTHeapFileKey)];
  [[TKLogging mainLogger] queueLogMessage:[delegate tempDirectory] file:[delegate defaultTempFile] contentsOfString:heapContents overWriteOnFirstWrite:NO];
  // remove heap file
  [[NSFileManager defaultManager] removeItemAtPath:RRFPathToTempFile(RRFCRTHeapFileKey) error:nil];
  // write recovery data to regfile
  [delegate setValue:[NSKeyedArchiver archivedDataWithRootObject:finishedTrials] forRunRegistryKey:RRFCRTPreviousTrialsKey];
  [delegate setValue:[NSNumber numberWithUnsignedInteger:trialBlocksCompleted] forRunRegistryKey:RRFCRTBlocksFinishedKey];
}

/*******************************************************************************
 BEGIN ORIGINAL METHODS
*******************************************************************************/
-(void)userDidInputCharacters:(NSString*)characters{
	if([self applicationState]==CRTWaitingForUserToBegin&&[characters isEqualToString:@" "]){
		[self beginNextTrial:nil];
	}else if([self applicationState] == CRTDuringTrial && lastMarker.seconds == 0 && lastMarker.microseconds == 0){
    lastMarker = time_since(startMarker);
		[self showResults:nil];
	}
}
-(void)beginNextTrial:(NSNotification *) notification{
	[[delegate sessionWindow] makeFirstResponder:imageView];
	if([trials count] > 0){
		currentTrial = [trials objectAtIndex:0];
		[trials removeObjectAtIndex:0];
		[self setApplicationState:CRTPrepTime];
		[textField setEnabled:NO];
		[textField setHidden:YES];
		NSImage * image=[NSImage imageNamed:@"CRTCrossHair.PNG"];
		if(image==nil){
			ELog(@"Its null");
		}
		[imageView setImage:image];
		[imageView setEnabled:YES];
		[imageView setHidden:NO];
		NSNotification * notification=[NSNotification notificationWithName:@"displayBlankScreenBeforeEmptyRectangle" object:self];
		[[TKTimer appTimer] registerEventWithNotification:notification inSeconds:0 microSeconds:(prepTimeMilliseconds *1000)];
	}else{
		trialBlocksCompleted++;
		if(trialBlocksCompleted<numberOfTrialBlocks){
			[self beginBreak];
		}else{
			[delegate componentDidFinish:self];
		}
	}
}
-(void)layoutTrials{
	NSMutableArray * temporaryArray = [[NSMutableArray alloc] init];
	int i=0;
	int counter=0;
	for(i=0;i<numberOfVerticalGreenRectangles;i++){
		CRTTrial * trial = [[CRTTrial alloc] init];
		[trial setColor:[NSColor greenColor]];
		[trial setOrientation:CRTVerticalOrientation];
		[temporaryArray addObject:trial];
		counter++;
	}
	for(i=0;i<numberOfHorizontalGreenRectangles;i++){
		CRTTrial * trial = [[CRTTrial alloc] init];
		[trial setColor:[NSColor greenColor]];
		[trial setOrientation:CRTHorizontalOrientation];
		[temporaryArray addObject:trial];
		counter++;
	}
	for(i=0;i<numberOfVerticalBlueRectangles;i++){
		CRTTrial * trial = [[CRTTrial alloc] init];
		[trial setColor:[NSColor blueColor]];
		[trial setOrientation:CRTVerticalOrientation];
		[temporaryArray addObject:trial];
		counter++;
	}
	for(i=0;i<numberOfHorizontalBlueRectangles;i++){
		CRTTrial * trial = [[CRTTrial alloc] init];
		[trial setColor:[NSColor blueColor]];
		[trial setOrientation:CRTHorizontalOrientation];
		[temporaryArray addObject:trial];
		counter++;
	}
	trials = [[NSMutableArray alloc] init];
	for(i=0;i<counter;i++){
		int rand=arc4random()%[temporaryArray count];
		CRTTrial * trial = [temporaryArray objectAtIndex:rand];
		[temporaryArray removeObjectAtIndex:rand];
		[trials addObject:trial];
	}
	
	counter=0;
	for(i=0;i<numberOf100msTrials;i++){
		[temporaryArray addObject:[NSNumber numberWithInt:100]];
		counter++;
	}
	for(i=0;i<numberOf200msTrials;i++){
		[temporaryArray addObject:[NSNumber numberWithInt:200]];
		counter++;
	}
	for(i=0;i<numberOf300msTrials;i++){
		[temporaryArray addObject:[NSNumber numberWithInt:300]];
		counter++;
	}
	for(i=0;i<numberOf400msTrials;i++){
		[temporaryArray addObject:[NSNumber numberWithInt:400]];
		counter++;
	}
	for(i=0;i<numberOf500msTrials;i++){
		[temporaryArray addObject:[NSNumber numberWithInt:500]];
		counter++;
	}
	
	for(i=0;i<counter;i++){
		int rand=arc4random()%[temporaryArray count];
		CRTTrial * trial =[trials objectAtIndex:i];
		NSNumber * number= [temporaryArray objectAtIndex:rand];
		[temporaryArray removeObjectAtIndex:rand];
		[trial setWaitTimeMilliseconds:[number intValue]];
	}


}
-(void)userTimeOut:(NSNotification *) notification{
	if(lastMarker.seconds == 0 && lastMarker.microseconds ==0 ){
		[self showResults:notification];
	}
}
-(void)displayBlankScreenBeforeEmptyRectangle:(NSNotification *) notification{
	[[delegate sessionWindow] makeFirstResponder:imageView];
	[self setApplicationState:CRTTransitionToEmptyRectangle];
	[imageView setHidden:YES];
	[textField setHidden:YES];
	NSNotification * notificationToPost = [NSNotification notificationWithName:@"displayBlankRectangle" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:0 microSeconds:(blankScreenMilliseconds *1000)];
}
-(void)displayBlankRectangle:(NSNotification *)notification{
	[[delegate sessionWindow] makeFirstResponder:imageView];
	[self setApplicationState:CRTEmptyRectangle];
	if([currentTrial orientation] == CRTVerticalOrientation){
		[imageView setImage:[NSImage imageNamed:@"verticalClear.PNG"]];
	}else{
		[imageView setImage:[NSImage imageNamed:@"horizontalClear.PNG"]];
	}
	[imageView setEnabled:YES];
	[imageView setHidden:NO];
	
	NSNotification * notificationToPost = [NSNotification notificationWithName:@"displayFullRectangle" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:0 microSeconds:(1000*[currentTrial waitTimeMilliseconds])];
}
-(void)displayFullRectangle:(NSNotification *)notification{
	[[delegate sessionWindow] makeFirstResponder:imageView];
	[self setApplicationState:CRTDuringTrial];
  lastMarker = new_time_marker(0,0);
  startMarker = current_time_marker();
	if([currentTrial orientation] == CRTVerticalOrientation && [currentTrial color] == [NSColor greenColor]){
		[imageView setImage:[NSImage imageNamed:@"verticalGreen.PNG"]];
	}else if([currentTrial orientation] == CRTVerticalOrientation && [currentTrial color] == [NSColor blueColor]){
		[imageView setImage:[NSImage imageNamed:@"verticalBlue.PNG"]];
	}else if([currentTrial orientation] == CRTHorizontalOrientation && [currentTrial color] == [NSColor greenColor]){
		[imageView setImage:[NSImage imageNamed:@"horizontalGreen.PNG"]];
	}else if([currentTrial orientation] == CRTHorizontalOrientation && [currentTrial color] == [NSColor blueColor]){
		[imageView setImage:[NSImage imageNamed:@"horizontalBlue.PNG"]];
	}
	NSNotification * notificationToPost = [NSNotification notificationWithName:@"userTimeOut" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:0 microSeconds:(1000*maxTrialWaitTime)];
}
-(void)showResults:(NSNotification *) notification{
	[[delegate sessionWindow] makeFirstResponder:imageView];
	[self setApplicationState:CRTDisplayingResults];
	totalTrialsThisRun++;
	NSInteger hit = 0;
	NSInteger miss = 0;
	NSInteger correctMiss = 0;
	NSInteger incorrectHit = 0;
	NSString * target = nil;
	if([currentTrial color] == [NSColor greenColor]){
		if([currentTrial orientation] == CRTVerticalOrientation){
			target = [[NSString alloc] initWithString:@"GV"];
		}else{
			target = [[NSString alloc] initWithString:@"GH"];
		}		
	}else{
		if([currentTrial orientation] == CRTVerticalOrientation){
			target = [[NSString alloc] initWithString:@"BV"];
		}else{
			target = [[NSString alloc] initWithString:@"BH"];
		}		
	}
	float responseTime =( (float) lastMarker.microseconds / (float) 1000);
	NSInteger delay = [currentTrial waitTimeMilliseconds];
	[currentTrial setResponseTimeMicroseconds:lastMarker.microseconds];
	if(lastMarker.seconds==0 && lastMarker.microseconds ==0){
		[currentTrial setDidHit:NO];		
		if([currentTrial color] == [NSColor greenColor]){
			[imageView setHidden:YES];
			[textField setEnabled:NO];
			[textField setHidden:YES];
			miss = 1;
		}else{
			NSString * textFieldString = [NSString stringWithFormat:@"%d milliseconds",(lastMarker.microseconds / 1000)];
			[textField setStringValue:textFieldString];
			[textField setHidden:NO];
			[textField setEnabled:YES];
			[imageView setHidden:YES];
			correctMiss = 1;
		}
	}else{
		[currentTrial setDidHit:YES];
		if([currentTrial color] == [NSColor greenColor]){
			NSString * textFieldString = [NSString stringWithFormat:@"%d milliseconds",(lastMarker.microseconds / 1000)];
			[textField setStringValue:textFieldString];
			[textField setHidden:NO];
			[textField setEnabled:YES];
			[imageView setHidden:YES];
			hit = 1;
		}else{
			NSString * textFieldString = [NSString stringWithString:@"Incorrect Response"];
			[textField setStringValue:textFieldString];
			[textField setHidden:NO];
			[textField setEnabled:YES];
			[imageView setHidden:YES];
			incorrectHit  = 1;
		}
	}
	[finishedTrials addObject:currentTrial];
  RRFLogToFile(RRFCRTHeapFileKey,@"%d\t%d\t%d\t%d\t%d\t%@\t%03.2f\t%d\n",
                totalTrialsThisRun,
                hit,
                miss,
                correctMiss,
                incorrectHit,
                target,
                responseTime,
                delay);
	NSNotification * notificationToPost = [NSNotification notificationWithName:@"beginNextTrial" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:0 microSeconds:(resultDisplayTime * 1000)];
	
}
-(void)beginBreak{
	[textField setStringValue:[NSString stringWithFormat:@"Take a %d second break",breakTime]];
	[textField setEnabled:YES];
	[textField setHidden:NO];
	[imageView setHidden:YES];
	
	NSNotification * notificationToPost = [NSNotification  notificationWithName:@"giveBreakWarning" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:breakWarning microSeconds:0];

	[self writeMilestoneDataToRegistry];  // record point for recovery
	[self layoutTrials];                  // layout next set of trials
}
-(void)giveBreakWarning:(NSNotification *)notification{
	[textField setStringValue:[NSString stringWithFormat:@"%d seconds remaining, get ready.",(breakTime-breakWarning)]];
	
	NSNotification * notificationToPost = [NSNotification  notificationWithName:@"beginNextTrial" object:self];
	[[TKTimer appTimer] registerEventWithNotification:notificationToPost inSeconds:(breakTime-breakWarning) microSeconds:0];
}


#pragma mark Preference Keys
// HERE YOU DEFINE KEY REFERENCES FOR ANY PREFERENCE VALUES
// ex: NSString * const RRFCRTNameOfPreferenceKey = @"RRFCRTNameOfPreference"
NSString * const RRFCRTTaskNameKey = @"RRFCRTTaskName";
NSString * const RRFCRTDataDirectoryKey = @"RRFCRTDataDirectory";
NSString * const RRFCRTPrepTimeMSKey = @"RRFCRTPrepTimeMS";
NSString * const RRFCRTBlankScreenTimeMSKey = @"RRFCRTBlankScreenTimeMS";
NSString * const RRFCRTVertGreenRectCountKey = @"RRFCRTVertGreenRectCount";
NSString * const RRFCRTVertBlueRectCountKey = @"RRFCRTVertBlueRectCount";
NSString * const RRFCRTHorizGreenRectCountKey = @"RRFCRTHorizGreenRectCount";
NSString * const RRFCRTHorizBlueRectCountKey = @"RRFCRTHorizBlueRectCount";
NSString * const RRFCRT100TrialCountKey = @"RRFCRT100TrialCount";
NSString * const RRFCRT200TrialCountKey = @"RRFCRT200TrialCount";
NSString * const RRFCRT300TrialCountKey = @"RRFCRT300TrialCount";
NSString * const RRFCRT400TrialCountKey = @"RRFCRT400TrialCount";
NSString * const RRFCRT500TrialCountKey = @"RRFCRT500TrialCount";
NSString * const RRFCRTMaxTrialWaitTimeMSKey = @"RRFCRTMaxTrialWaitTimeMS";
NSString * const RRFCRTResultDisplayTimeMSKey = @"RRFCRTResultDisplayTimeMS";
NSString * const RRFCRTTrialBlockCountKey = @"RRFCRTTrialBlockCount";
NSString * const RRFCRTBlockSizeKey = @"RRFCRTBlockSize";
NSString * const RRFCRTBreakTimeKey = @"RRFCRTBreakTime";
NSString * const RRFCRTBreakWarningKey = @"RRFCRTBreakWarning";
NSString * const RRFCRTResponseTimeFilterMSKey = @"RRFCRTResponseTimeFilterMS";

#pragma mark Regfile Keys
NSString * const RRFCRTPreviousTrialsKey = @"RRFCRTPreviousTrials";
NSString * const RRFCRTBlocksFinishedKey = @"RRFCRTBlocksFinished";

#pragma mark Internal Strings
// HERE YOU DEFINE KEYS FOR CONSTANT STRINGS //
///////////////////////////////////////////////
NSString * const RRFCRTMainNibNameKey = @"RRFCRTMainNib";
NSString * const RRFCRTHeapFileKey = @"RRFCRTHeapFile";
        
@end
