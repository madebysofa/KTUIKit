//
//  KTViewController.m
//  View Controllers
//
//  Created by Jonathan Dann and Cathy Shive on 14/04/2008.
//
// Copyright (c) 2008 Jonathan Dann and Cathy Shive
//
// Permission is hereby granted, free of charge, to any person
// obtaining a copy of this software and associated documentation
// files (the "Software"), to deal in the Software without
// restriction, including without limitation the rights to use,
// copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the
// Software is furnished to do so, subject to the following
// conditions:
//
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
//
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
// OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
// HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
// WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
// FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
// OTHER DEALINGS IN THE SOFTWARE.
//
// If you use it, acknowledgement in an About Page or other appropriate place would be nice.
// For example, "Contains "View Controllers" by Jonathan Dann and Cathy Shive" will do.


/*
	(Cathy 11/10/08) NOTE:
	I've made the following changes that need to be documented:
	• When a child is removed, its view is removed from its superview and it is sent a "removeObservations" message
	• Added 'removeChild:(KTViewController*)theChild' method to remove specific subcontrollers
	• Added 'loadNibNamed' and 'releaseNibObjects' to support loading more than one nib per view controller.  These take care
	of releasing the top level nib objects for those nib files. Users have to unbind any bindings in those nibs in the view
	controller's removeObservations method.
	• Added class method, 'viewControllerWithWindowController'
	• I'm considering overriding 'view' and 'setView:' so that the view controller only deals with KTViews.
*/


#import "KTViewController.h"
#import "KTWindowController.h"
#import "KTLayerController.h"

@interface KTViewController ()
@property (nonatomic, readwrite, assign) KTViewController * parentViewController;
@end


@interface KTViewController (Private)
- (void)releaseNibObjects;
- (void)_setHidden:(BOOL)theHiddenFlag patchResponderChain:(BOOL)thePatchFlag;
@end

@implementation KTViewController
//=========================================================== 
// - @synthesize
//=========================================================== 
@synthesize windowController = wWindowController;
@synthesize parentViewController = wParentViewController;
@synthesize hidden = mHidden;


//=========================================================== 
// - viewControllerWithWindowController
//=========================================================== 
+ (id)viewControllerWithWindowController:(KTWindowController*)theWindowController
{
	return [[[self alloc] initWithNibName:nil bundle:nil windowController:theWindowController] autorelease];
}


//=========================================================== 
// - initWithNibName
//=========================================================== 
- (id)initWithNibName:(NSString *)theNibName bundle:(NSBundle *)theBundle windowController:(KTWindowController *)theWindowController;
{
	if (![super initWithNibName:theNibName bundle:theBundle])
		return nil;
	wWindowController = theWindowController;
	mSubcontrollers = [[NSMutableArray alloc] init];
	mTopLevelNibObjects = [[NSMutableArray alloc] init];
	mLayerControllers = [[NSMutableArray alloc] init];
	return self;
}

//=========================================================== 
// - initWithNibName
//=========================================================== 
- (id)initWithNibName:(NSString *)name bundle:(NSBundle *)bundle
{
	[NSException raise:@"KTViewControllerException" format:@"An instance of an KTViewController concrete subclass was initialized using the NSViewController method -initWithNibName:bundle: all view controllers in the enusing tree will have no reference to an KTWindowController object and cannot be automatically added to the responder chain"];
	return nil;
}

//=========================================================== 
// - awakeFromNib
//=========================================================== 
- (void)awakeFromNib
{}

//=========================================================== 
// - dealloc
//=========================================================== 
- (void)dealloc
{
	//NSLog(@"%@ dealloc", self);
	[self releaseNibObjects];
//	[mSubcontrollers makeObjectsPerformSelector:@selector(removeObservations)];
	for(KTViewController * aViewController in mSubcontrollers)
		[aViewController setParentViewController:nil];
	[mSubcontrollers release];
//	[mLayerControllers makeObjectsPerformSelector:@selector(removeObservations)];
	[mLayerControllers release];
	[super dealloc];
}

//=========================================================== 
// - releaseNibObjects
//=========================================================== 
- (void)releaseNibObjects
{
	for(NSInteger i = 0; i < [mTopLevelNibObjects count]; i++)
	{
		[[mTopLevelNibObjects objectAtIndex:i] release];
	}
	[mTopLevelNibObjects release];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@ hidden:%@", [super description], [self hidden] ? @"YES" : @"NO"];
}

// CS: I wonder about this situation
// if the window controller changes, say a view controller is moved from one window to another
// it is important that the view controller has been removed from the old window controller
// and that that window controller has re-patched its responder chain
// otherwise it is possible that actions from the other window will get handled by a view controller
// that is no longer a part of that window
//=========================================================== 
// - setWindowController
//=========================================================== 
- (void)setWindowController:(KTWindowController*)theWindowController
{
	wWindowController = theWindowController;
	[[self subcontrollers] makeObjectsPerformSelector:@selector(setWindowController:) withObject:theWindowController];
	[[self windowController] patchResponderChain];
}

- (void)setHidden:(BOOL)theBool
{
	[self _setHidden:theBool patchResponderChain:YES];
}

- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
{
	if (mHidden == theHidden) return;
	mHidden = theHidden;	
	
	for (KTViewController *aViewController in [self subcontrollers]) {
		[aViewController _setHidden:theHidden patchResponderChain:NO];
	}
	
	for (KTLayerController *aLayerController in [self layerControllers]) {
		[aLayerController _setHidden:theHidden patchResponderChain:NO];
	}
	
	if (thePatch) {
		[[self windowController] patchResponderChain];			
	}
}

#pragma mark Subcontrollers
//=========================================================== 
// - setSubcontrollers
//=========================================================== 
- (void)setSubcontrollers:(NSArray *)theSubcontrollers;
{
	if(mSubcontrollers != theSubcontrollers)
	{
		NSMutableArray * aNewSubcontrollers = [theSubcontrollers mutableCopy];
		[mSubcontrollers release];
		mSubcontrollers = aNewSubcontrollers;
		[[self windowController] patchResponderChain];
		for(KTViewController*aSubcontroller in mSubcontrollers)
			[aSubcontroller setParentViewController:self];
	}
}

//=========================================================== 
// - subcontrollers
//=========================================================== 
- (NSArray *)subcontrollers
{
	return mSubcontrollers;
}

//=========================================================== 
// - addSubcontroller
//=========================================================== 
- (void)addSubcontroller:(KTViewController *)theViewController;
{
	if(theViewController)
	{
		[mSubcontrollers addObject:theViewController];
		[[self windowController] patchResponderChain];
		[theViewController setParentViewController:self];
	}
}



//=========================================================== 
// - removeSubcontroller
//=========================================================== 
- (void)removeSubcontroller:(KTViewController *)theViewController;
{
	if(theViewController)
	{
		[theViewController setParentViewController:nil];	
		[theViewController removeObservations];
		[mSubcontrollers removeObject:theViewController];
		[[self windowController] patchResponderChain];
	}
}



//=========================================================== 
// - removeAllSubcontrollers
//=========================================================== 
- (void)removeAllSubcontrollers
{
	for(KTViewController*aSubcontroller in mSubcontrollers)
		[aSubcontroller setParentViewController:nil];
	[self setSubcontrollers:[NSArray array]];
	[[self windowController] patchResponderChain];
}


#pragma mark Layer Controllers
//=========================================================== 
// - addLayerController
//=========================================================== 
- (void)addLayerController:(KTLayerController*)theLayerController
{
	if(theLayerController)
	{
		[mLayerControllers addObject:theLayerController];
		[[self windowController] patchResponderChain];
	}
}



//=========================================================== 
// - removeLayerController
//=========================================================== 
- (void)removeLayerController:(KTLayerController*)theLayerController
{
	if(theLayerController)
	{
		[mLayerControllers removeObject:theLayerController];
		[[self windowController] patchResponderChain];
	}
}

//=========================================================== 
// - layerControllers
//=========================================================== 
- (NSArray*)layerControllers
{
	return mLayerControllers;
}

- (NSArray *)descendants
{
	CFMutableArrayRef aMutableDescendants = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	for (KTViewController *aSubViewController in mSubcontrollers) {
		CFArrayAppendValue(aMutableDescendants, aSubViewController);
		NSArray *aSubDescendants = [aSubViewController descendants];
		if (aSubDescendants != nil) {
			CFIndex aDescendantsCount = CFArrayGetCount((CFArrayRef)aSubDescendants);
			if (aDescendantsCount > 0) {
				CFArrayAppendArray(aMutableDescendants, (CFArrayRef)aSubDescendants, CFRangeMake(0, aDescendantsCount));
			}
		}
	}
	for (KTLayerController *aLayerController in mLayerControllers) {
		CFArrayAppendValue(aMutableDescendants, aLayerController);
		NSArray *aSubDescendants = [aLayerController descendants];
		if (aSubDescendants != nil) {
			CFIndex aDescendantsCount = CFArrayGetCount((CFArrayRef)aSubDescendants);
			if (aDescendantsCount > 0) {
				CFArrayAppendArray(aMutableDescendants, (CFArrayRef)aSubDescendants, CFRangeMake(0, aDescendantsCount));
			}
		}
	}
	
	CFArrayRef aDescendants = CFArrayCreateCopy(kCFAllocatorDefault, aMutableDescendants);
	CFRelease(aMutableDescendants);
	return [NSMakeCollectable(aDescendants) autorelease];
}


//=========================================================== 
// - removeAllViewControllers
//=========================================================== 
- (void)removeObservations
{
	// subcontrollers
	[mSubcontrollers makeObjectsPerformSelector:@selector(removeObservations)];
	// layer controllers
	[mLayerControllers makeObjectsPerformSelector:@selector(removeObservations)];
}


//=========================================================== 
// - loadNibNamed:
//=========================================================== 
- (BOOL)loadNibNamed:(NSString*)theNibName bundle:(NSBundle*)theBundle
{
	BOOL		aSuccess;
	NSArray *	anObjectList = nil;
	NSNib *		aNib = [[[NSNib alloc] initWithNibNamed:theNibName bundle:theBundle] autorelease];
	aSuccess = [aNib instantiateNibWithOwner:self topLevelObjects:&anObjectList];
	if(aSuccess)
	{
		int i;
		for(i = 0; i < [anObjectList count]; i++)
			[mTopLevelNibObjects addObject:[anObjectList objectAtIndex:i]];
	}
	return aSuccess;
}

@end
