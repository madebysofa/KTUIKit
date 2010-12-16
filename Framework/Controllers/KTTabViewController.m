//
//  KTTabViewController.m
//  KTUIKit
//
//  Created by Cathy on 18/03/2009.
//  Copyright 2009 Sofa. All rights reserved.
//

#import "KTTabViewController.h"
#import "KTTabItem.h"
#import "KTView.h"
#import "KTWindowController.h"

@interface KTTabViewController ()
- (KTView *)view;
@end

@interface KTTabViewController (Private)
- (void)_selectTabItem:(KTTabItem*)theTabItem;
@end

@implementation KTTabViewController
//=========================================================== 
// - synthesize
//===========================================================
@synthesize tabItemArrayController = mTabItemArrayController;
@synthesize releaseViewControllersWhenNotSeletcted = mReleaseViewControllersWhenNotSeletcted;
@synthesize shouldResizeTabViews = mShouldResizeTabViews;
@synthesize delegate = wDelegate;

static void *_KTTVCTabItemArrayControllerSelectionIndexObservationContext = (void *)@"_KTTVCTabItemArrayControllerSelectionIndexObservationContext";
//=========================================================== 
// - initWithNibName:bundle:windowController
//===========================================================
- (id)initWithNibName:(NSString*)theNibName bundle:(NSBundle*)theBundle windowController:(KTWindowController*)theWindowController
{
	if ((self = [super initWithNibName:nil bundle:theBundle windowController:theWindowController])) {
		// create the 'content view' - when we switch controllers
		// we'll be adding/removing their views to and from this 'content' view
		KTView *aContentView = [[[KTView alloc] initWithFrame:NSZeroRect] autorelease];
		[[aContentView viewLayoutManager] setWidthType:KTSizeFill];
		[[aContentView viewLayoutManager] setHeightType:KTSizeFill];
		[self setView:aContentView];
		
		// create an array that will hold our list of KSTabItems - users can bind to the
		// arranged objects and selectionIndex property to control the tab (to a pop up button or a custom tab view, for example)
		// we let this array controller manage selection for us
		mTabItemArrayController = [[NSArrayController alloc] init];
		[mTabItemArrayController setSelectsInsertedObjects:YES];
		[mTabItemArrayController addObserver:self forKeyPath:@"selectionIndex"options:0 context:&_KTTVCTabItemArrayControllerSelectionIndexObservationContext];
		[self setShouldResizeTabViews:YES];
	}
	return self;
}

//=========================================================== 
// - dealloc
//===========================================================
- (void)dealloc
{
	[mTabItemArrayController release];
	[super dealloc];
}

//=========================================================== 
// - removeObservations
//===========================================================
- (void)removeObservations
{
	[mTabItemArrayController removeObserver:self forKeyPath:@"selectionIndex"];
	[super removeObservations];
}

#pragma mark -
#pragma mark Accessors

- (KTView *)view
{
	return (KTView *)[super view];
}

// When showing a tab view controller, calling super will make all sub controllers for all tabs visible, therefore they will be in the responder chain. We need to hide the view controllers for the non-selected tab items and re-patch the responder chain.
- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
{
	[super _setHidden:theHidden patchResponderChain:thePatch];
	
	if (!theHidden) {
		NSMutableArray *aMutableTabItems = [[self tabItems] mutableCopy];
		KTTabItem *aSelectedTab = [self selectedTabItem];
		[aMutableTabItems removeObject:aSelectedTab];
		for (KTTabItem *aTabItem in aMutableTabItems) {
			KTViewController *aViewController = [aTabItem viewController];
			[aViewController _setHidden:YES patchResponderChain:NO];
		}
		[aMutableTabItems release];
		
		[[self windowController] _patchResponderChain];		
	}
}

#pragma mark -
#pragma mark KVO Callbacks

//=========================================================== 
// - observeValueForKeyPath
//===========================================================
- (void)observeValueForKeyPath:(NSString *)theKeyPath ofObject:(id)theObject change:(NSDictionary *)theChange context:(void *)theContext
{
	if(theContext == &_KTTVCTabItemArrayControllerSelectionIndexObservationContext)
	{
		NSInteger aSelectedIndex = [mTabItemArrayController selectionIndex];
		KTTabItem * aNewTabToSelect = nil;
		if(aSelectedIndex!=NSNotFound)
			aNewTabToSelect = [[mTabItemArrayController arrangedObjects] objectAtIndex:aSelectedIndex];
		[self _selectTabItem:aNewTabToSelect];
	} else {
		[super observeValueForKeyPath:theKeyPath ofObject:theObject change:theChange context:theContext];
	}
}

#pragma mark -
#pragma mark Fast Enumeration

- (NSUInteger)countByEnumeratingWithState:(NSFastEnumerationState *)theState objects:(id *)theStackBuffer count:(NSUInteger)theLength;
{
	return [[self tabItems] countByEnumeratingWithState:theState objects:theStackBuffer count:theLength];
}

#pragma mark -
#pragma mark Managing Tabs
//=========================================================== 
// - addTabItem
//===========================================================
- (void)addTabItem:(KTTabItem*)theTabItem
{
	[self insertTabItem:theTabItem atIndex:[[mTabItemArrayController arrangedObjects] count]];
}

//=========================================================== 
// - addTabItem
//===========================================================
- (void)addTabItem:(KTTabItem *)theTabItem select:(BOOL)theBool
{
	KTTabItem * aCurrentSelection = [self selectedTabItem];
	//[[self tabItemArrayController] setSelectsInsertedObjects:NO];
	[self addTabItem:theTabItem];
	
	if (!theBool)
		[self selectTabItem:aCurrentSelection];
	//[[self tabItemArrayController] setSelectsInsertedObjects:YES];
}

//=========================================================== 
// - removeTabItem
//===========================================================
- (void)removeTabItem:(KTTabItem*)theTabItem
{
	[theTabItem retain];
	
	NSInteger	anIndexOfTabItemToRemove = [[mTabItemArrayController arrangedObjects] indexOfObject:theTabItem];
	BOOL		aTabIsCurrentSelection = [theTabItem isEqualTo:wCurrentSelectedTab];
	KTTabItem * aNewTabToSelect = nil;
	
	if(anIndexOfTabItemToRemove!=NSNotFound)
	{
		NSInteger aTabItemCount = [[mTabItemArrayController arrangedObjects] count];
		// if the tab we're going to remove is selected and it is *not* the last item in the 
		// tab array controller, we need to manually select a new tab - NSArrayController already handles the 
		// case where the item that is removed is the last item and it's selected
		if(		aTabIsCurrentSelection
			&&	anIndexOfTabItemToRemove!=aTabItemCount-1)
		{
			NSInteger aNewSelectionIndex = anIndexOfTabItemToRemove+1;
			// get the tab at this index, after we change the content of the array, we want to select this
			// object at its new index
			aNewTabToSelect = [[mTabItemArrayController arrangedObjects] objectAtIndex:aNewSelectionIndex];
		}
		
		
		// let our delegate know that we will remove this tab item
		if([[self delegate] respondsToSelector:@selector(tabViewController:willRemoveTabItem:)])
			[[self delegate] tabViewController:self willRemoveTabItem:theTabItem];
			
		
		if([theTabItem viewController])
		{
			[[[theTabItem viewController] view] removeFromSuperview];
			[self removeSubcontroller:[theTabItem viewController]];
		}
		
		// clear out any reference to us and remove the tab item from our array controller
		[theTabItem setTabViewController:nil];
		[theTabItem setViewController:nil];
		
		[mTabItemArrayController removeObject:theTabItem];
		if([[self delegate] respondsToSelector:@selector(tabViewController:didRemoveTabItem:)])
			[[self delegate] tabViewController:self didRemoveTabItem:theTabItem];
		
		
		// adjust the selection if we need to 
		if(aNewTabToSelect!=nil)
		{
			[mTabItemArrayController setSelectionIndex:[[mTabItemArrayController arrangedObjects] indexOfObject:aNewTabToSelect]];
		}
	}
	
	[theTabItem release];
}

//=========================================================== 
// - insertTabItem
//===========================================================
- (void)insertTabItem:(KTTabItem*)theTabItem atIndex:(NSInteger)theIndex
{
	if(theTabItem!=nil)
	{
		if([theTabItem viewController]!=nil)
			[self addSubcontroller:[theTabItem viewController]];
//		else
//			NSLog(@"adding a tab item without a view controller");
		[theTabItem setTabViewController:self];
		[mTabItemArrayController insertObject:theTabItem atArrangedObjectIndex:theIndex];
	}
}


//=========================================================== 
// - tabItems
//===========================================================
- (NSArray*)tabItems
{
	return [mTabItemArrayController arrangedObjects];
}

//=========================================================== 
// - tabItemForIdentifier
//===========================================================
- (KTTabItem*)tabItemForIdentifier:(id)theIdentifier
{
	KTTabItem * aTabItemToReturn = nil;
	for(KTTabItem * aTabItem in [mTabItemArrayController arrangedObjects])
	{
		if([[aTabItem identifier] isEqual:theIdentifier])
		{
			aTabItemToReturn = aTabItem;
			break;
		}
	}
	return aTabItemToReturn;
}

//=========================================================== 
// - tabItemForViewController
//===========================================================
- (KTTabItem*)tabItemForViewController:(KTViewController*)theViewController
{
	KTTabItem * aTabItemToReturn = nil;
	for(KTTabItem * aTabItem in [mTabItemArrayController arrangedObjects])
	{
		if([[aTabItem viewController] isEqual:theViewController])
		{
			aTabItemToReturn = aTabItem;
			break;
		}
	}
	return aTabItemToReturn;
}

//=========================================================== 
// - tabItemForIndex
//===========================================================
- (KTTabItem*)tabItemForIndex:(NSInteger)theIndex
{
	KTTabItem * aTabItemToReturn = nil;
	if(		theIndex >= 0
		||	theIndex < [[mTabItemArrayController arrangedObjects] count])
		aTabItemToReturn = [[mTabItemArrayController arrangedObjects] objectAtIndex:theIndex];
	return aTabItemToReturn;
}

#pragma mark -
#pragma mark Selection
//=========================================================== 
// - selectedTabItem
//===========================================================
- (KTTabItem*)selectedTabItem
{
	return wCurrentSelectedTab;
}

//=========================================================== 
// - selectedTabIndex
//===========================================================
- (NSInteger)selectedTabIndex
{
	 KTTabItem * aSelectedTab = [self selectedTabItem];
	 return [[mTabItemArrayController arrangedObjects] indexOfObject:aSelectedTab];
}

//=========================================================== 
// - selectTabAtIndex
//===========================================================
- (void)selectTabItem:(KTTabItem*)theTabItem
{
	if (!theTabItem)
		return;
	
	[mTabItemArrayController setSelectedObjects:[NSArray arrayWithObject:theTabItem]];
}

//=========================================================== 
// - selectTabAtIndex
//===========================================================
- (void)selectTabAtIndex:(NSInteger)theTabIndex
{
	KTTabItem * aTabForIndex = [[mTabItemArrayController arrangedObjects] objectAtIndex:theTabIndex];
	[self selectTabItem:aTabForIndex];
}

- (void)_selectTabItem:(KTTabItem *)theTabItem
{
	if (wCurrentSelectedTab == theTabItem)
		return;
	/*
		When switching tabs we are doing two different things:
		1.  Switching views
		2.  Switching view controllers
		
		Switching view controllers means that we only want the selected view
		controller to be in the responder chain and listening for updates from bindings/KVO
		
		Since our tabItems retain the view controller and their represented object, we can safely
		remove the view controller as a subcontroller - which will take it out of the responder chain
		and then tell it to remove observations, which will unhook it from any KVO/bindings it has set up
		
		When we select a new view controller, we can re-set its represented object for bindings/kvo and also
		add it as a subcontroller to put it in the responder chain.
	*/

		if([[self delegate] respondsToSelector:@selector(tabViewController:willSelectTabItem:)])
			[[self delegate] tabViewController:self willSelectTabItem:theTabItem];

		// deal with the current selection first
		KTViewController * aCurrentViewController = [wCurrentSelectedTab viewController];
//		if(aCurrentViewController == nil)
//			NSLog(@"de-selecting a tab with no view controller");
//			
		// remove the current view controller's view from the view hierarchy
		[[aCurrentViewController view] removeFromSuperview];
		[aCurrentViewController setHidden:YES];
		
		
		// remove the view controller from our list of subcontrollers to take it out of the responder chain
		// this automatcally calls 'removeObservations'
//		[self removeSubcontroller:aCurrentViewController];
		
		
		
		// now select the new view controller
		KTViewController * aViewControllerToSelect = [theTabItem viewController];
		KTView * aViewForTab = (KTView*)[aViewControllerToSelect view];
		[[self view] addSubview:aViewForTab];
		[aViewControllerToSelect setHidden:NO];
		
		// layout
		if([self shouldResizeTabViews])
		{
			[[aViewForTab viewLayoutManager] setWidthType:KTSizeFill];
			[[aViewForTab viewLayoutManager] setHeightType:KTSizeFill];
			[[[self view] viewLayoutManager] refreshLayout];	
		}
		else
		{
			NSRect aFrameForTab = [aViewForTab frame];
			aFrameForTab.origin.x = 0;
			aFrameForTab.origin.y = 0;
			[aViewForTab setFrame:aFrameForTab];
		}

		// add the new view controller as a subcontroller
//		[self addSubcontroller:aViewControllerToSelect];
//		// reestablish its KVO/bindings with its represented object
//		id aRepresentedObjectForViewController = [aViewControllerToSelect representedObject];
//		[aViewControllerToSelect setRepresentedObject:aRepresentedObjectForViewController];
		
		
		wCurrentSelectedTab = theTabItem;
		
		// finally send our delegate a message that we've selected a new tab item
		if([wDelegate respondsToSelector:@selector(tabViewController:didSelectTabItem:)])
			[wDelegate tabViewController:self didSelectTabItem:[self selectedTabItem]];

}

- (BOOL)canSelectNextTabItem
{
	BOOL aBoolToReturn = YES;
	NSInteger aCurrentIndex = [self selectedTabIndex];
	if(		aCurrentIndex >= [[mTabItemArrayController arrangedObjects] count]-1
		||	aCurrentIndex == NSNotFound)
		aBoolToReturn = NO;
	return aBoolToReturn;
}

- (BOOL)canSelectPreviousTabItem
{
	BOOL aBoolToReturn = YES;
	NSInteger aCurrentIndex = [self selectedTabIndex];
	if(		aCurrentIndex <= 0
		||	aCurrentIndex == NSNotFound)
		aBoolToReturn = NO;
	return aBoolToReturn;
}

- (void)selectNextTabItem
{
	if([self canSelectNextTabItem] == NO)
		return;
		
	NSInteger aCurrentIndex = [self selectedTabIndex];
	if(		aCurrentIndex < [[mTabItemArrayController arrangedObjects] count]-1
		&&	aCurrentIndex != NSNotFound)
		[self selectTabAtIndex:aCurrentIndex+1];
}

- (void)selectPreviousTabItem
{
	if([self canSelectPreviousTabItem] == NO)
		return;
		
	NSInteger aCurrentIndex = [self selectedTabIndex];
	if(		aCurrentIndex > 0
		&&	aCurrentIndex != NSNotFound)
		[self selectTabAtIndex:aCurrentIndex-1];
}

@end
