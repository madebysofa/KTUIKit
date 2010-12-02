//
//  KTWindowController.m
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

#import "KTWindowController.h"
#import "KTViewController.h"
#import "KTLayerController.h"

NSString *const KTWindowControllerViewControllersKey = @"viewControllers";

@interface KTWindowController ()
@property (readonly, nonatomic) NSMutableArray *primitiveViewControllers;
@end

@implementation KTWindowController

- (void)dealloc;
{
	[mPrimitiveViewControllers release];
	
	[super dealloc];
}

#pragma mark -
#pragma mark Accessors

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

- (void)insertObject:(KTViewController *)theViewController inViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] insertObject:theViewController atIndex:theIndex];
}

- (void)removeObjectFromViewControllersAtIndex:(NSUInteger)theIndex;
{
	[[self primitiveViewControllers] removeObjectAtIndex:theIndex];
}

#pragma mark Public View Controller API

- (void)addViewController:(KTViewController *)theViewController
{
	if (theViewController == nil) return;
	NSParameterAssert(![[self primitiveViewControllers] containsObject:theViewController]);
	[[self mutableArrayValueForKey:KTWindowControllerViewControllersKey] addObject:theViewController];
	[self patchResponderChain];
}

- (void)removeViewController:(KTViewController *)theViewController
{
	if(theViewController == nil) return;
	[theViewController retain];
	{
		[[self mutableArrayValueForKey:KTWindowControllerViewControllersKey] removeObject:theViewController];
		[theViewController removeObservations];
	}
	[theViewController release];
	[self patchResponderChain];
}

- (void)removeAllViewControllers
{
	NSArray *aViewControllers = [[self viewControllers] retain];
	{
		[[self mutableArrayValueForKey:KTWindowControllerViewControllersKey] removeAllObjects];
		[aViewControllers makeObjectsPerformSelector:@selector(removeObservations)];
	}
	[aViewControllers release];
	[self patchResponderChain];
}

#pragma mark Deprecated API

- (void)setViewControllers:(NSArray *)theViewControllers
{
	[theViewControllers retain];
	{
		[self removeAllViewControllers];
		[[self mutableArrayValueForKey:KTViewControllerViewControllersKey] addObjectsFromArray:theViewControllers];
	}
	[theViewControllers release];
	[self patchResponderChain];
}

#pragma mark Descendants

- (NSArray *)_descendants;
{	
	CFMutableArrayRef aMutableDescendants = CFArrayCreateMutable(kCFAllocatorDefault, 0, &kCFTypeArrayCallBacks);
	for (KTViewController *aSubViewController in [self viewControllers]) {
		CFArrayAppendValue(aMutableDescendants, aSubViewController);
		NSArray *aSubDescendants = [aSubViewController descendants];
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

#pragma mark -
#pragma mark KVO Teardown

- (void)removeObservations
{
	[[self viewControllers] makeObjectsPerformSelector:@selector(removeObservations)];
}

#pragma mark -
#pragma mark Responder Chain

- (void)patchResponderChain
{
	NSAutoreleasePool *aPool = [[NSAutoreleasePool alloc] init];
	
	NSArray *aControllersList = [self _descendants];
		
	if ([aControllersList count] > 0) {
		[self setNextResponder:[aControllersList objectAtIndex:0]];
		NSResponder <KTController> *aPreviousContoller = nil;
		for (NSResponder <KTController> *aController in aControllersList) {
			if ([aController hidden]) continue;
			[aPreviousContoller setNextResponder:aController]; // This is a no-op on first pass.
			aPreviousContoller = aController;
		}
		[aPreviousContoller setNextResponder:nil];
	}
	
	[aPool drain];
}

@end