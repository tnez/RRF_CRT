////////////////////////////////////////////////////////////
//  Mock_AppDelegate.m
//  ComRrfComponentVas
//  --------------------------------------------------------
//  Author: Travis Nesland <tnesland@gmail.com>
//  Created: 9/7/10
//  Copyright 2010 Resedential Research Facility,
//  University of Kentucky. All rights reserved.
/////////////////////////////////////////////////////////////
#import "Mock_AppDelegate.h"
#import "TKComponentConfigurationView.h"
#import "TKComponentOption.h"
#import "TKComponentStringOption.h"
#import "TKComponentNumberOption.h"
#import "TKComponentBooleanOption.h"
#import "TKComponentPathOption.h"
#import "TKComponentEnumOption.h"
#import "RRFCRTController.h"
@class TKSession;

/**
 Macros for logging functions conditional upon debug vs. production
 ELog: informative log that will occur even in production builds
 DLog: informative log that will only occur in debug builds
 */
#define ELog(...) NSLog(@"%s %@",__PRETTY_FUNCTION__,[NSString stringWithFormat:__VA_ARGS__])
#ifdef DEBUG 
  #define DLog(...) NSLog(@"%s %@",__PRETTY_FUNCTION__,[NSString stringWithFormat:__VA_ARGS__])
#else
  #define DLog(...) do { } while(0)
#endif

@implementation Mock_AppDelegate

@synthesize manifest;
@synthesize componentOptions;
@synthesize subject;
@synthesize leftView;
@synthesize topRightView;
@synthesize bottomRightView;
@synthesize componentDefinition;
@synthesize setupWindow;
@synthesize sessionWindow;
@synthesize presentedOptions;
@synthesize errorLog;

#pragma mark Housekeeping
- (void)dealloc {
    // remove notifications
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // release objects
    [manifest release];
    [componentOptions release];
    [componentDefinition release];
    [presentedOptions release];
    [errorLog release];
    [super dealloc];
}
- (void)awakeFromNib {

    // setup loggers and timers
    [NSThread detachNewThreadSelector:@selector(spawnAndBeginTimer:) toTarget:[TKTimer class] withObject:nil];
    NSLog(@"Session timer started");
    [NSThread detachNewThreadSelector:@selector(spawnMainLogger:) toTarget:[TKLogging class] withObject:nil];
    [NSThread detachNewThreadSelector:@selector(spawnCrashRecoveryLogger:) toTarget:[TKLogging class] withObject:nil];
    NSLog(@"Session logs started");

    // clear any old components
    component = nil;

    // register for notifications
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(theComponentWillBegin:)
                                                 name:TKComponentWillBeginNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(theComponentDidBegin:)
                                                 name:TKComponentDidBeginNotification
                                               object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(theComponentDidFinish:)
                                                 name:TKComponentDidFinishNotification
                                               object:nil];

    // reset error log
    errorLog = nil;

    // read manifest
    [self setManifest:MANIFEST];

    // get options
    [self setPresentedOptions:[NSMutableArray array]];
    [self setComponentOptions:[NSArray arrayWithArray:
                               [manifest valueForKey:TKComponentOptionsKey]]];
    [self setComponentDefinition:[[NSMutableDictionary alloc] init]];

    // load component config view
    componentConfigView =
        [[TKComponentConfigurationView alloc] initWithFrame:[leftView frame]];
    [componentConfigView setMargins:10.0];

    // for each option add a subview
    id tmp = nil;
    for(id option in componentOptions) {
        switch([[option valueForKey:TKComponentOptionTypeKey] integerValue]) {
            case TKComponentOptionTypeString:
                tmp = [[TKComponentStringOption alloc]
                          initWithDictionary:option];
                [componentConfigView addSubview:[tmp view]];
                [presentedOptions addObject:tmp];
                [tmp release]; tmp=nil;
                break;
            case TKComponentOptionTypeNumber:
                tmp = [[TKComponentNumberOption alloc]
                          initWithDictionary:option];
                [componentConfigView addSubview:[tmp view]];
                [presentedOptions addObject:tmp];
                [tmp release]; tmp=nil;
                break;
            case TKComponentOptionTypeBoolean:
                tmp = [[TKComponentBooleanOption alloc]
                          initWithDictionary:option];
                [componentConfigView addSubview:[tmp view]];
                [presentedOptions addObject:tmp];
                [tmp release]; tmp=nil;
                break;
            case TKComponentOptionTypePath:
                tmp = [[TKComponentPathOption alloc]
                          initWithDictionary:option];
                [componentConfigView addSubview:[tmp view]];
                [presentedOptions addObject:tmp];
                [tmp release]; tmp=nil;
                break;
            case TKComponentOptionTypeEnum:
                tmp = [[TKComponentEnumOption alloc]
                          initWithDictionary:option];
                [componentConfigView addSubview:[tmp view]];
                [presentedOptions addObject:tmp];
                [tmp release]; tmp=nil;
                break;
            default:
                break;
        }   // end switch
    }       // end for

    // add component view to left view
    [leftView setDocumentView:componentConfigView];

    // display views
    [componentConfigView setNeedsDisplay:YES];
    [leftView setNeedsDisplay:YES];
    [[leftView superview] setNeedsDisplay:YES];

}

#pragma mark Actions
- (IBAction)createDefinition: (id)sender {

    // populate universal manifest info
    [componentDefinition setValue:[manifest valueForKey:TKComponentTypeKey] forKey:TKComponentTypeKey];
    [componentDefinition setValue:[manifest valueForKey:TKComponentNameKey] forKey:TKComponentNameKey];
    [componentDefinition setValue:[manifest valueForKey:TKComponentBundleNameKey] forKey:TKComponentBundleNameKey];
    [componentDefinition setValue:[manifest valueForKey:TKComponentBundleIdentifierKey] forKey:TKComponentBundleIdentifierKey];

    // populate options
    for(TKComponentOption *option in presentedOptions) {
        [componentDefinition setValue:[option value]
                               forKey:[option optionKeyName]];
    }
}
- (IBAction)preflight: (id)sender {

    // create definition from options
    [self createDefinition:self];

    // create component
    component = [[TKComponentController loadFromDefinition:componentDefinition] retain];

    // setup component
    [component setSubject:subject];
    [component setSessionWindow:sessionWindow];
    [component setDelegate:(TKSession *)self];

    // test
    [self setErrorLog:[component preflightAndReturnErrorAsString]];

    // give back component
    [component release]; component = nil;
}
- (IBAction) run: (id)sender {

    // create definition
    [self createDefinition:self];
    DLog(@"Comp Def: %@",componentDefinition);

    // create component
    component = [[TKComponentController loadFromDefinition:componentDefinition] retain];
    currentComponentID = [[componentDefinition valueForKey:@"RRFCRTTaskName"] retain];
  
    // setup component
    [component setSubject:subject];
    [component setSessionWindow:sessionWindow];
    [component setDelegate:(TKSession *)self];
    [[NSFileManager defaultManager] createDirectoryAtPath:[component tempDirectory] withIntermediateDirectories:YES attributes:nil error:nil];  
  
    // setup registry file
    if([self initRegistryFile]) {
      // add entry to component history
      [[registry valueForKey:RRFSessionHistoryKey] addObject:currentComponentID];
      // create new run entry for current task
      [[[self registryForTask:currentComponentID] valueForKey:RRFSessionRunKey] 
       addObject:[NSMutableDictionary dictionaryWithCapacity:2]];
      // update start value
      [self setValue:[NSDate date] forRunRegistryKey:@"start"];
    } else { // error creating registry file
      ELog(@"Could not create registry file");
      [component release];component=nil;
      return;
    }
  
    // begin component
    [component begin];

}
- (IBAction) runWithSample: (id)sender {

    // create component definition
    [self setComponentDefinition:[NSDictionary dictionaryWithContentsOfFile:
                                  [[NSBundle mainBundle] pathForResource:@"SampleDefinition" ofType:@"plist"]]];

    // create component
    component = [[TKComponentController loadFromDefinition:componentDefinition] retain];

    // setup component
    [component setSubject:subject];
    [component setSessionWindow:setupWindow];

    // if component is good to go...
    if([component isClearedToBegin]) {
        // ...go
        [component begin];
    } else { // if component is not good...
        // ...
    }
}

- (IBAction)saveDefinitionToDisk: (id)sender
{
  // run a panel to select save location
  NSSavePanel *panel = [NSSavePanel savePanel];
  NSArray *fileTypes = [NSArray arrayWithObject:@"plist"];
  [panel setAllowedFileTypes:fileTypes];
  if([panel runModal])
  {
    DLog(@"We will save generated plist to disk");
    [self createDefinition:self];
    NSURL *_fileURL = [panel URL];
    if(![componentDefinition writeToURL:_fileURL atomically:YES])
    {
      ELog(@"Could not write plist to disk");
      [self setErrorLog:@"There was a problem writing the plist to disk"];
    }
  }
  else
  {
    DLog(@"User did cancel save operation");
  }
}

#pragma mark Notifications
- (void)theComponentWillBegin: (NSNotification *)aNote {

    DLog(@"The component will begin");
    // bring up the session window
    [sessionWindow makeKeyAndOrderFront:self];
}
- (void)theComponentDidBegin: (NSNotification *)aNote {
    DLog(@"The component did begin");
}
- (void)theComponentDidFinish: (NSNotification *)aNote {
    DLog(@"The component did finish");
    // log the end time of the component in registry
    [self setValue:[NSDate date] forRunRegistryKey:@"end"];
    // move registry file to data directory
    NSString *destPath = [[component dataDirectory] stringByAppendingPathComponent:@"regfile.plist"];
    [[NSFileManager defaultManager] moveItemAtPath:[pathToRegistryFile stringByStandardizingPath] toPath:destPath error:nil];
    // close component and release component
    [[TKLibrary sharedLibrary] exitFullScreenWithWindow:sessionWindow];
    [component release]; component = nil;
}

#pragma mark Session Posing
- (NSDictionary *)registryForTask: (NSString *)taskID {
  NSDictionary * retValue = nil;
  @try {
    retValue = [[NSDictionary dictionaryWithDictionary:
                 [[registry valueForKey:RRFSessionComponentsKey]
                  valueForKey:taskID]] retain];
  }
  @catch (NSException * e) {
    ELog(@"Could not find task with ID: %@",taskID);
  }
  @finally {
    return [retValue autorelease];
  }
}
- (NSDictionary *)registryForLastTask {
  // get the ID of the last completed task from the history
  // in the registry... the history is an array of number objects
  // representing succession of task ID's through time
  return [self registryForTaskWithOffset:-1];
}
- (NSDictionary *)registryForTaskWithOffset: (NSInteger)offset {
  NSDictionary *retValue = nil;
  @try {
    // determine ID of the task using offset
    NSInteger targetIdx;
    NSArray *history = [NSArray arrayWithArray:
                        [registry valueForKey:RRFSessionHistoryKey]];
    // if offset is positive... implication is that we are offsetting
    // from the begginging...
    if(offset>0) {
      // ...this will be index in the array minus 1
      targetIdx = offset - 1;
    } else {
      // we were given a non-positive offset which implies
      // that we should offset from our current point
      // this is equivalent to the index of the last item in history
      // minus our offset (which may be zero representing the current task)
      targetIdx = [history count] - 1 + offset;
    }
    // we then need the registry for the task with id equal to the
    // value we find in our target index
    NSString *targetID = [history objectAtIndex:targetIdx];
    retValue = [self registryForTask:targetID];
  }
  @catch (NSException * e) {
    ELog(@"Could not find task with offset: %d Exception: %@",offset,e);
  }
  @finally {
    return [retValue autorelease];
  }
}
- (void)setValue: (id)newValue forRegistryKey: (NSString *)key {
  @try {
    DLog(@"value: %@ forKey: %@",newValue,key);
    // get reference to current task...
    NSMutableDictionary *currentTask = 
    [[registry objectForKey:RRFSessionComponentsKey]
     objectForKey:currentComponentID];
    // set value for said dictionary
    [currentTask setValue:newValue forKey:key];
    // we did change
    [self registryDidChange];
  }
  @catch (NSException * e) {
    ELog(@"Could not set value for run registry key: %@ due to exception: %@",
         key,e);
  }
}
- (void)setValue: (id)newValue forRunRegistryKey: (NSString *)key {
  @try {
    DLog(@"value: %@ forKey: %@",newValue,key);
    // get reference to current run of current task...
    NSMutableDictionary* currentRun = 
    [[registry valueForKeyPath:
      [NSString stringWithFormat:
       @"%@.%@.%@",RRFSessionComponentsKey,currentComponentID,
       RRFSessionRunKey]] lastObject];
    // set value for said dictionary
    [currentRun setValue:newValue forKey:key];
    // we did change
    [self registryDidChange];
  }
  @catch (NSException * e) {
    ELog(@"Could not set value for run registry key: %@ due to exception: %@",
         key,e);
  }
}
- (BOOL)initRegistryFile {
  @try {
    // latch path to registry file
    pathToRegistryFile = [[[[NSBundle mainBundle] bundlePath]
                           stringByAppendingPathComponent:
                           RRFSessionPathToRegistryFileKey] retain];
    // create empty file at path
    if(![[NSFileManager defaultManager]
         createFileAtPath:[self pathToRegistryFile]
         contents:nil attributes:nil]) {
      ELog(@"Could not create empty registry file on disk: %@",
           [self pathToRegistryFile]);
      return NO;
    }
    // create registry in memory
    registry = [[NSMutableDictionary alloc] init];
    // load global session info
    [registry setValue:[subject study] forKey:RRFSessionProtocolKey];
    [registry setValue:[subject subject_id] forKey:RRFSessionSubjectKey];
    [registry setValue:[subject session] forKey:RRFSessionSessionKey];
    [registry setValue:[NSDate date] forKey:RRFSessionStartKey];
    DLog(@"Loaded global values in registry");
    // create empty history
    [registry setValue:[NSMutableArray array] forKey:RRFSessionHistoryKey];
    DLog(@"Created empty history in registry");
    // create empty components dictionary
    [registry setValue:[NSMutableDictionary dictionary]
                forKey:RRFSessionComponentsKey];
    DLog(@"Created empty component block in registry");
    
    // for our task, create a mutable dictionary with the key of task ID and
    // a nested runs mutable dictionary
    NSMutableDictionary *compSection =
    [registry valueForKey:RRFSessionComponentsKey];
    // task ID and a nested runs mutable dictionary
    [compSection setValue:[NSMutableDictionary dictionary]
                   forKey:[[component definition] valueForKey:@"RRFCRTTaskName"]];
    // create an empty run registry inside
    NSMutableDictionary *curSection=
    [compSection valueForKey:[[component definition] valueForKey:@"RRFCRTTaskName"]];
    [curSection setValue:[NSMutableArray array] forKey:RRFSessionRunKey];
    
    DLog(@"Created entries for all components in registry");
    // we have succeeded (presumably) :}
    [self registryDidChange];    
    return YES;
  } // end of try block
  @catch (NSException * e) {
    // we have failed :{
    ELog(@"Encountered exception when trying to create registry file: %@",
         e);
    return NO;
  }
  return NO; // bleh
}
- (BOOL)bounceRegistryToDisk {
  return [registry writeToFile:[self pathToRegistryFile] atomically:YES];
}
- (NSString *)pathToRegistryFile {
  return pathToRegistryFile;
}
- (void)registryDidChange {
  DLog(@"Writing registry to disk");
  if(![self bounceRegistryToDisk]) {
    ELog(@"Unable to write the registry to disk");
  }
}

#pragma mark Parameters
NSString * const RRFSessionProtocolKey = @"protocol";
NSString * const RRFSessionSubjectKey = @"subject";
NSString * const RRFSessionSessionKey = @"session";
NSString * const RRFSessionMachineKey = @"machine";
NSString * const RRFSessionStartKey = @"start";
NSString * const RRFSessionStartTaskKey = @"startTask";
NSString * const RRFSessionEndKey = @"end";
NSString * const RRFSessionDescriptionKey  = @"description";
NSString * const RRFSessionDataDirectoryKey = @"dataDirectory";
NSString * const RRFSessionCreationDateKey = @"creationDate";
NSString * const RRFSessionModifiedDateKey = @"modifiedDate";
NSString * const RRFSessionStatusKey = @"status";
NSString * const RRFSessionLastRunDateKey = @"lastRunDate";
NSString * const RRFSessionComponentsKey = @"components";
NSString * const RRFSessionComponentsDefinitionKey = @"definition";
NSString * const RRFSessionComponentsJumpsKey = @"jumps";
NSString * const RRFSessionComponentsOffsetKey = @"jumpOffset";
NSString * const RRFSessionHistoryKey = @"history"; 
NSString * const RRFSessionRunKey = @"runs";
NSString * const RRFSessionPathToRegistryFileKey = @"_TEMP/regfile.plist";

@end
