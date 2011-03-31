//
//  CRTTrial.h
//  CuedRT
//
//  Created by Scott on 2/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>

#define CRTOrientation NSInteger
#define CRTVerticalOrientation 0
#define CRTHorizontalOrientation 1

@interface CRTTrial : NSObject {
	NSColor * color;
	CRTOrientation orientation;
	NSInteger waitTimeMilliseconds;
	BOOL didHit;
	NSUInteger responseTimeMicroseconds;
}
@property(nonatomic,retain) NSColor * color;
@property(readwrite) CRTOrientation orientation;
@property(readwrite) NSInteger waitTimeMilliseconds;
@property(readwrite) NSUInteger responseTimeMicroseconds;
@property(readwrite) BOOL didHit;

@end
