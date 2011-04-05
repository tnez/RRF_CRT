//
//  CRTTrial.m
//  CuedRT
//
//  Created by Scott on 2/25/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CRTTrial.h"


@implementation CRTTrial

@synthesize color,orientation,waitTimeMilliseconds,didHit,responseTimeMicroseconds;

- (void)encodeWithCoder: (NSCoder *)coder {
  [coder encodeObject:color forKey:@"CRTTrialColor"];
  [coder encodeInteger:orientation forKey:@"CRTTrialOrientation"];
  [coder encodeInteger:waitTimeMilliseconds forKey:@"CRTTrialWaitTime"];
  [coder encodeBool:didHit forKey:@"CRTTrialDidHit"];
  [coder encodeInteger:responseTimeMicroseconds forKey:@"CRTTrialResponseTime"];
}

- (id)initWithCoder: (NSCoder *)coder {
  if(self=[super init]) {
    [self setColor:[coder decodeObjectForKey:@"CRTTrialColor"]];
    [self setOrientation:[coder decodeIntegerForKey:@"CRTTrialOrientation"]];
    [self setWaitTimeMilliseconds:[coder decodeIntegerForKey:@"CRTTrialWaitTime"]];
    [self setDidHit:[coder decodeBoolForKey:@"CRTTrialDidHit"]];
    [self setResponseTimeMicroseconds:[coder decodeIntegerForKey:@"CRTTrialResponseTime"]];
    return self;
  }
  ELog(@"Could not initialize archived trial object");
  return nil;
}

@end
