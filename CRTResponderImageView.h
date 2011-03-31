//
//  CRTResponderImageView.h
//  CuedRT
//
//  Created by Scott on 3/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import <Cocoa/Cocoa.h>
@class RRFCRTController;

@interface CRTResponderImageView : NSImageView {
  IBOutlet RRFCRTController *controller;
}
@property (assign) IBOutlet RRFCRTController *controller;
@end
