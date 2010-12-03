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

NSString *const KTViewControllerViewControllersKey = @"viewControllers";
NSString *const KTViewControllerLayerControllersKey = @"layerControllers";

@interface KTViewController ()
@property (readwrite, nonatomic, assign, setter = _setParentViewController:) KTViewController *parentViewController;

@property (readonly, nonatomic) NSMutableArray *primitiveViewControllers;
@property (readonly, nonatomic) NSMutableArray *primitiveLayerControllers;

@property (readwrite, nonatomic, copy) NSArray *topLevelObjects;

- (void)_setHidden:(BOOL)theHiddenFlag patchResponderChain:(BOOL)thePatchFlag;
@end

@implementation KTViewController

@synthesize windowController = wWindowController;
@synthesize parentViewController = wParentViewController;
@synthesize hidden = mHidden;
@synthesize topLevelObjects = mTopLevelNibObjects;

+ (id)viewControllerWithWindowController:(KTWindowController *)theWindowController
{
	return [[[self alloc] initWithNibName:nil bundle:nil windowController:theWindowController] autorelease];
}

- (id)initWithNibName:(NSString *)theNibName bundle:(NSBundle *)theBundle windowController:(KTWindowController *)theWindowController;
{
	if ((self = [super initWithNibName:theNibName bundle:theBundle])) {
		wWindowController = theWindowController;
	}
	return self;
}

- (id)initWithNibName:(NSString *)theName bundle:(NSBundle *)theBundle;
{
	[NSException raise:@"KTViewControllerException" format:@"An instance of an KTViewController concrete subclass was initialized using the NSViewController method -initWithNibName:bundle: all view controllers in the enusing tree will have no reference to an KTWindowController object and cannot be automatically added to the responder chain"];
	return nil;
}

// On 10.6 NSObject implements -awakeFromNib. It's a very common mistake to call super when compiling for 10.5+, we implement -awakeFromNib here so subclasses can safely call super.
- (void)awakeFromNib;
{}

- (void)dealloc;
{
	[mPrimitiveViewControllers release];
	[mPrimitiveLayerControllers release];

	[mTopLevelNibObjects release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@ hidden:%@", [super description], [self hidden] ? @"YES" : @"NO"];
}

- (void)setWindowController:(KTWindowController *)theWindowController;
{
	if (wWindowController == theWindowController) return;
	wWindowController = theWindowController;
	[[self subcontrollers] makeObjectsPerformSelector:@selector(setWindowController:) withObject:theWindowController];
	[theWindowController _patchResponderChain];
}

- (void)setHidden:(BOOL)theHidden;
{
	[self _setHidden:theHidden patchResponderChain:YES];
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
		[[self windowController] _patchResponderChain];			
	}
}

#pragma mark View Controllers

- (NSMutableArray *)primitiveViewControllers;
{
	if (mPrimitiveViewControllers != nil) return mPrimitiveViewControllers;
	mPrimitiveViewControllers = [[NSMutableArray alloc] init];
	return mPrimitiveViewControllers;
}

- (NSArray *)viewControllers;
{
	return [[[self primitiveViewControllers] copy] autorelease];
}

- (NSUInteger)countOfViewControllers;
{
	return [[self primitiveViewControllers] count];
}

- (id)objectInViewControllersAtIndex:(NSUInteger)theIndex;
{
	return [[self primitiveViewControllers] objectAtIndex:theIndex];
}

// These methods are merely for mutating the |primitiveViewControllers| array. See the public |-add/removeViewController:| methods for places where connections to other view controllers are maintained and |removeObservations| is called.
- (void)insertObject:(KTViewController *)theViewController inViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] insertObject:theViewController atIndex:theIndex];
}

- (void)removeObjectFromViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] removeObjectAtIndex:theIndex];
}

#pragma mark Public View Controller API

- (void)addViewController:(KTViewController *)theViewController;
{
	if (theViewController == nil) return;
	NSParameterAssert(![[self primitiveViewControllers] containsObject:theViewController]);
	[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] addObject:theViewController];
	[theViewController _setParentViewController:self];
	[[self windowController] _patchResponderChain];
}

- (void)removeViewController:(KTViewController *)theViewController;
{
	if (theViewController == nil) return;
	NSParameterAssert([[self primitiveViewControllers] containsObject:theViewController]);
	[theViewController retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] removeObject:theViewController];
		[theViewController removeObservations];
		[theViewController _setParentViewController:nil];		
	}
	[theViewController release];
	[[self windowController] _patchResponderChain];
}

- (void)removeAllViewControllers;
{
	NSArray *aViewControllers = [[self primitiveViewControllers] retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] removeAllObjects];
		[aViewControllers makeObjectsPerformSelector:@selector(removeObservations)];
		[aViewControllers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:nil];		
	}
	[aViewControllers release];
	[[self windowController] _patchResponderChain];
}

#pragma mark Old Subcontroller API
// TODO: These methods should be deprecated in favour of the "viewController" variants
- (NSArray *)subcontrollers;
{
	return [self viewControllers];
}

- (void)setSubcontrollers:(NSArray *)theSubcontrollers;
{
	[theSubcontrollers retain];
	{
		[self removeAllViewControllers];
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] addObjectsFromArray:theSubcontrollers];
		[theSubcontrollers makeObjectsPerformSelector:@selector(_setParentViewController:) withObject:self];		
	}
	[theSubcontrollers release];
	[[self windowController] _patchResponderChain];
}

- (void)addSubcontroller:(KTViewController *)theViewController;
{
	[self addViewController:theViewController];
}

- (void)removeSubcontroller:(KTViewController *)theViewController;
{
	[self removeViewController:theViewController];
}

- (void)removeAllSubcontrollers
{
	[self removeAllViewControllers];
}

#pragma mark Layer Controllers

- (NSMutableArray *)primitiveLayerControllers;
{
	if (mPrimitiveLayerControllers != nil) return mPrimitiveLayerControllers;
	mPrimitiveLayerControllers = [[NSMutableArray alloc] init];
	return mPrimitiveLayerControllers;
}

- (NSArray *)layerControllers;
{
	return [[[self primitiveLayerControllers] copy] autorelease];
}

- (NSUInteger)countOfLayerControllers;
{
	return [[self primitiveLayerControllers] count];
}

- (id)objectInLayerControllersAtIndex:(NSUInteger)theIndex;
{
	return [[self primitiveLayerControllers] objectAtIndex:theIndex];
}

- (void)insertObject:(KTLayerController *)theLayerController inLayerControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveLayerControllers] insertObject:theLayerController atIndex:theIndex];
}

- (void)removeObjectFromLayerControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveLayerControllers] removeObjectAtIndex:theIndex];
}

- (void)addLayerController:(KTLayerController *)theLayerController;
{
	if (theLayerController == nil) return;
	NSParameterAssert(![[self primitiveLayerControllers] containsObject:theLayerController]);
	[[self mutableArrayValueForKey:KTViewControllerLayerControllersKey] addObject:theLayerController];
	[[self windowController] _patchResponderChain];
}

- (void)removeLayerController:(KTLayerController *)theLayerController;
{
	if (theLayerController == nil) return;
	NSParameterAssert([[self primitiveLayerControllers] containsObject:theLayerController]);
	[theLayerController retain];
	{
		[[self mutableArrayValueForKey:KTViewControllerLayerControllersKey] addObject:theLayerController];
		[theLayerController removeObservations];
	}
	[theLayerController release];
	[[self windowController] _patchResponderChain];
}

#pragma mark -
#pragma mark Descedants

- (NSArray *)descendants
{
	CFMutableArrayRef aMutableDescendants = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);

	NSArray *aViewControllers = [self viewControllers];
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	for (KTViewController *aSubViewController in aViewControllers) {
		CFArrayAppendValue(aMutableDescendants, aSubViewController);
		NSArray *aSubDescendants = [aSubViewController descendants];
		if (aSubDescendants != nil) {
			CFIndex aDescendantsCount = CFArrayGetCount((CFArrayRef)aSubDescendants);
			if (aDescendantsCount > 0) {
				CFArrayAppendArray(aMutableDescendants, (CFArrayRef)aSubDescendants, CFRangeMake(0, aDescendantsCount));
			}
		}
		[aPool drain];
		aPool = [[NSAutoreleasePool alloc] init];
	}
	[aPool drain];
	
	NSArray *aLayerControllers = [self layerControllers];
	aPool = [[NSAutoreleasePool alloc] init];	
	for (KTLayerController *aLayerController in aLayerControllers) {
		CFArrayAppendValue(aMutableDescendants, aLayerController);
		NSArray *aSubDescendants = [aLayerController descendants];
		if (aSubDescendants != nil) {
			CFIndex aDescendantsCount = CFArrayGetCount((CFArrayRef)aSubDescendants);
			if (aDescendantsCount > 0) {
				CFArrayAppendArray(aMutableDescendants, (CFArrayRef)aSubDescendants, CFRangeMake(0, aDescendantsCount));
			}
		}
		[aPool drain];
		aPool = [[NSAutoreleasePool alloc] init];
	}
	[aPool drain];
	
	CFArrayRef aDescendants = CFArrayCreateCopy(kCFAllocatorDefault, aMutableDescendants);
	CFRelease(aMutableDescendants);
	return [NSMakeCollectable(aDescendants) autorelease];
}

void _KTViewControllerEnumerateSubControllers(KTViewController *theViewController, _KTControllerEnumeratorCallBack theCallBackFunction, void *theContext)
{
	theCallBackFunction(theViewController, theContext);
	for (KTViewController *aViewController in [theViewController viewControllers]) {
		_KTViewControllerEnumerateSubControllers(aViewController, theCallBackFunction, theContext);
	}	
	for (KTLayerController *aLayerController in [theViewController layerControllers]) {
		_KTLayerControllerEnumerateSubControllers(aLayerController, theCallBackFunction, theContext);
	}
}

- (void)_enumerateSubControllers:(_KTControllerEnumeratorCallBack)theCallBackFunction context:(void *)theContext;
{
	theCallBackFunction(self, theContext);
	for (KTViewController *aViewController in [self viewControllers]) {
		[aViewController _enumerateSubControllers:theCallBackFunction context:theContext];
	}
	for (KTLayerController *aLayerController in [self layerControllers]) {
		[aLayerController _enumerateSubControllers:theCallBackFunction context:theContext];
	}
}

#pragma mark -
#pragma mark KVO Teardown

- (void)removeObservations
{
	[[self viewControllers] makeObjectsPerformSelector:@selector(removeObservations)];
	[[self layerControllers] makeObjectsPerformSelector:@selector(removeObservations)];
}

#pragma mark -
#pragma mark Nib Management

- (BOOL)loadNibNamed:(NSString*)theNibName bundle:(NSBundle*)theBundle
{
	NSNib *aNib = [[NSNib alloc] initWithNibNamed:theNibName bundle:theBundle];
	NSArray *aTopLevelObjects = nil;
	BOOL aSuccess = NO;
	if ((aSuccess = [aNib instantiateNibWithOwner:self topLevelObjects:&aTopLevelObjects])) {
		[self setTopLevelObjects:aTopLevelObjects];
	}
	[aNib release];
	return aSuccess;
}

@end
