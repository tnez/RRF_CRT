//
//  CRTResponderImageView.m
//  CuedRT
//
//  Created by Scott on 3/22/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "CRTResponderImageView.h"
#import "RRFCRTController.h"

@implementation CRTResponderImageView

@synthesize controller;

-(void)keyDown:(NSEvent *)event{
	if(![[event characters] isEqualToString:@""]&&![event isARepeat]){
		[controller userDidInputCharacters:[event characters]] ;
	}	
}


@end
