//
//  KTViewControl.m
//  KTUIKit
//
//  Created by Cathy Shive on 11/3/08.
//  Copyright 2008 Cathy Shive. All rights reserved.
//

#import "KTViewControl.h"

@interface KTViewControl (Private)

@end

@implementation KTViewControl

@synthesize isEnabled = mIsEnabled;
@synthesize target = wTarget;
@synthesize action = wAction;

//=========================================================== 
// - initWithFrame:
//=========================================================== 
- (id)initWithFrame:(NSRect)theFrame
{
	if((self = [super initWithFrame:theFrame])) {
		mIsEnabled = YES;
	}
	return self;
}

//=========================================================== 
// - initWithCoder:
//=========================================================== 
- (id)initWithCoder:(NSCoder*)theCoder
{
	if ((self = [super initWithCoder:theCoder])) {
		mIsEnabled = YES;
	}	
	return self;
}

//=========================================================== 
// - encodeWithCoder:
//=========================================================== 
- (void)encodeWithCoder:(NSCoder*)theCoder
{	
	[super encodeWithCoder:theCoder];
}


//=========================================================== 
// - performAction:
//=========================================================== 
- (void)performAction
{
	if([wTarget respondsToSelector:wAction])
		[wTarget performSelector:wAction withObject:self];
}

//=========================================================== 
// - setIsEnabled:
//=========================================================== 
- (void)setIsEnabled:(BOOL)theBool
{
	mIsEnabled = theBool;
	if(theBool==NO && [[self window] firstResponder]==self)
		[[self window] makeFirstResponder:nil];
	[self setNeedsDisplay:YES];
}
@end
