////////////////////////////////////////////////////////////
//  Mock_AppDelegate.h
//  ComRrfComponentVas
//  --------------------------------------------------------
//  Author: Travis Nesland <tnesland@gmail.com>
//  Created: 9/7/10
//  Copyright 2010 Resedential Research Facility,
//  University of Kentucky. All rights reserved.
/////////////////////////////////////////////////////////////
#import <Cocoa/Cocoa.h>
#import <TKUtility/TKUtility.h>
@class TKComponentConfigurationView;

#define MANIFEST [NSDictionary dictionaryWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"RRFCRTManifest" ofType:@"plist"]]

@interface Mock_AppDelegate : NSObject {
  
  /** setup material */
  NSDictionary                                *manifest;
  NSArray                                     *componentOptions;
  IBOutlet TKSubject                          *subject;
  TKComponentController                       *component;
  NSMutableDictionary                         *registry;
  NSString                                    *currentComponentID;
  NSString                                    *pathToRegistryFile;
  
  /** view boxes */
  IBOutlet NSScrollView                       *leftView;
  IBOutlet NSView                             *topRightView;
  IBOutlet NSView                             *bottomRightView;
  IBOutlet NSWindow                           *setupWindow;
  IBOutlet NSWindow                           *sessionWindow;
  TKComponentConfigurationView                *componentConfigView;

  /** run products */
  NSMutableDictionary                         *componentDefinition;
  NSMutableArray                              *presentedOptions;
  NSString                                    *errorLog;

}

@property (nonatomic, retain) NSDictionary          *manifest;
@property (nonatomic, retain) NSArray               *componentOptions;
@property (assign) IBOutlet TKSubject               *subject;
@property (assign) IBOutlet NSScrollView            *leftView;
@property (assign) IBOutlet NSView                  *topRightView;
@property (assign) IBOutlet NSView                  *bottomRightView;
@property (assign) IBOutlet NSWindow                *setupWindow;
@property (assign) IBOutlet NSWindow                *sessionWindow;
@property (nonatomic, retain) NSMutableDictionary   *componentDefinition;
@property (nonatomic, retain) NSMutableArray        *presentedOptions;
@property (nonatomic, retain) NSString              *errorLog;

#pragma mark ACTIONS
- (IBAction)createDefinition: (id)sender;
- (IBAction)run: (id)sender;
- (IBAction)runWithSample: (id)sender;
- (IBAction)preflight: (id)sender;

#pragma mark SESSION POSING
/**
 Return copy of entire dictionary belonging to the task w/ the given ID
 Should return nil if ID is invalid
 */
- (NSDictionary *)registryForTask: (NSString *)taskID;

/**
 Return copy of entire dictionary belonging to the last completed task
 Should return nil if last task cannot be found
 */
- (NSDictionary *)registryForLastTask;

/**
 Return copy of entire dictionary belonging to the task referenced by the
 given offset. Should return nil if offset is invalid.
 Positive offsets are interpreted as from the first run task forward.
 Zero offset is the current task.
 Negative offsets are interpreted as the last run task backward.
 */
- (NSDictionary *)registryForTaskWithOffset: (NSInteger)offset;

/** 
 Sets a value for key pertaining to the whole current task (not to an 
 individual run of said task).
 */
- (void)setValue: (id)newValue forRegistryKey: (NSString *)key;

/**
 Sets a value for key pertaining to the current run of the current task
 */
- (void)setValue: (id)newValue forRunRegistryKey: (NSString *)key;

/**
 Initialize an empty registrer file. Return YES if successful.
 */
- (BOOL)initRegistryFile;

/**
 Write the registry file to disk. Returns YES if successful.
 */
- (BOOL)bounceRegistryToDisk;

/**
 Returns the path to where the registry file will be stored
 */
- (NSString *)pathToRegistryFile;

/**
 This method should be called whenever we have made a change to the registry
 in memory
 */
- (void)registryDidChange;

/**
 PREFERENCE KEYS
 */
NSString * const RRFSessionProtocolKey;
NSString * const RRFSessionSubjectKey;
NSString * const RRFSessionSessionKey;
NSString * const RRFSessionMachineKey;
NSString * const RRFSessionStartKey;
NSString * const RRFSessionStartTaskKey;
NSString * const RRFSessionEndKey;
NSString * const RRFSessionDescriptionKey;
NSString * const RRFSessionDataDirectoryKey;
NSString * const RRFSessionCreationDateKey;
NSString * const RRFSessionModifiedDateKey;
NSString * const RRFSessionStatusKey;
NSString * const RRFSessionLastRunDateKey;
NSString * const RRFSessionComponentsKey;
NSString * const RRFSessionComponentsDefinitionKey;
NSString * const RRFSessionComponentsJumpsKey;
NSString * const RRFSessionComponentsOffsetKey;
NSString * const RRFSessionHistoryKey;
NSString * const RRFSessionRunKey;
NSString * const RRFSessionPathToRegistryFileKey;

@end
