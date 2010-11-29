//
//  KTOpenGLLayerController.m
//  KTUIKit
//
//  Created by Cathy on 27/02/2009.
//  Copyright 2009 Sofa. All rights reserved.
//

#import "KTLayerController.h"
#import "KTViewController.h"
#import "KTWindowController.h"

@implementation KTLayerController

//=========================================================== 
// synthesized properties
//===========================================================
@synthesize viewController = wViewController;
@synthesize subcontrollers = mSubcontrollers;
@synthesize representedObject = wRepresentedObject;
@synthesize layer = mLayer;
@synthesize hidden = mHidden;

//=========================================================== 
// - layerControllerWithViewController
//===========================================================
+ (id)layerControllerWithViewController:(KTViewController*)theViewController
{
	return [[[self alloc] initWithViewController:theViewController] autorelease];
}


//=========================================================== 
// - initWithViewController
//===========================================================
- (id)initWithViewController:(KTViewController*)theViewController
{
	if ((self = [super init])) {
		wViewController = theViewController;
		mSubcontrollers = [[NSMutableArray alloc] init];
	}
	return self;
}

//=========================================================== 
// - dealloc
//===========================================================
- (void)dealloc
{
	[mSubcontrollers release];
	[mLayer release];
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (void)setHidden:(BOOL)theHidden;
{
	[self _setHidden:theHidden patchResponderChain:YES];
}

- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
{
	if (mHidden == theHidden) return;
	mHidden = theHidden;	
	
	for (KTLayerController *aLayerController in [self subcontrollers]) {
		[aLayerController _setHidden:theHidden patchResponderChain:NO];
	}
	
	if (thePatch) {
		[[[self viewController] windowController] patchResponderChain];			
	}
}

//=========================================================== 
// - setRepresentedObject
//===========================================================
- (void)setRepresentedObject:(id)theRepresentedObject
{
	wRepresentedObject = theRepresentedObject;
}


//=========================================================== 
// - removeObservations
//===========================================================
- (void)removeObservations
{
	[mSubcontrollers makeObjectsPerformSelector:@selector(removeObservations)];
}


//=========================================================== 
// - addSubcontroller
//===========================================================
- (void)addSubcontroller:(KTLayerController*)theSubcontroller
{
	if(theSubcontroller)
	{
		[mSubcontrollers addObject:theSubcontroller];
		[[[self viewController] windowController] patchResponderChain];
	}
}

//=========================================================== 
// - removeSubcontroller
//===========================================================
- (void)removeSubcontroller:(KTLayerController*)theSubcontroller
{
	if(theSubcontroller)
	{
		[mSubcontrollers removeObject:theSubcontroller];
		[[[self viewController] windowController] patchResponderChain];
	}
}


#pragma mark Controller Responder Chain Protocol

- (NSArray *)descendants
{
	CFMutableArrayRef aMutableDescendants = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	for (KTLayerController *aLayerController in [self subcontrollers]) {
		CFArrayAppendValue(aMutableDescendants, aLayerController);
		NSArray *aDescendants = [aLayerController descendants];
		if (aDescendants != nil) {
			CFIndex aDescendantsCount = CFArrayGetCount((CFArrayRef)aDescendants);
			if (aDescendantsCount > 0) {
				CFArrayAppendArray(aMutableDescendants, (CFArrayRef)aDescendants, CFRangeMake(0, aDescendantsCount));
			}
		}
	}
	CFArrayRef aDescendants = CFArrayCreateCopy(kCFAllocatorDefault, aMutableDescendants);
	CFRelease(aMutableDescendants);
	return [NSMakeCollectable(aDescendants) autorelease];
}

@end


