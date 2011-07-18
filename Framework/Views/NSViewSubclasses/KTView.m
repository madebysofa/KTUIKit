//
//  KTView.m
//  KTUIKit
//
//  Created by Cathy Shive on 05/20/2008.
//
// Copyright (c) Cathy Shive
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
// For example, "Contains "KTUIKit" by Cathy Shive" will do.

#import "KTView.h"

NSString *const KTViewViewLayoutManagerKey = @"layoutManager";
NSString *const KTViewStyleManagerKey = @"styleManager";
NSString *const KTViewLabelKey = @"label";

@interface KTView ()
- (void)_drawDebuggingRect;
@end

@implementation KTView

@synthesize mouseDownCanMoveWindow = mMouseDownCanMoveWindow;
@synthesize opaque = mOpaque;
@synthesize canBecomeKeyView = mCanBecomeKeyView;
@synthesize canBecomeFirstResponder = mCanBecomeFirstResponder;
@synthesize acceptsFirstMouse = mAcceptsFirstMouse;
@synthesize drawAsImage = mDrawAsImage;
@synthesize cachedImage = mCachedImage;
@synthesize drawDebuggingRect = mDrawDebuggingRect;

@synthesize viewLayoutManager = mLayoutManager;
@synthesize styleManager = mStyleManager;
@synthesize label = mLabel;
@dynamic frame;

- (id)initWithFrame:(NSRect)theFrame
{
	if ((self = [super initWithFrame:theFrame])) {
		KTLayoutManager *aLayoutManger = [[[KTLayoutManager alloc] initWithView:self] autorelease];
		[self setViewLayoutManager:aLayoutManger];
		[self setAutoresizesSubviews:NO];
		mStyleManager = [[KTStyleManager alloc] initWithView:self];		
		mLabel = [@"KTView" copy];
		[self setOpaque:NO];
	}
	return self;
}
 
- (void)encodeWithCoder:(NSCoder*)theCoder
{	
	[super encodeWithCoder:theCoder];
	[theCoder encodeObject:[self viewLayoutManager] forKey:KTViewViewLayoutManagerKey];
	[theCoder encodeObject:[self styleManager] forKey:KTViewStyleManagerKey];
	[theCoder encodeObject:[self label] forKey:KTViewLabelKey];
}
 
- (id)initWithCoder:(NSCoder*)theCoder
{
	if ((self = [super initWithCoder:theCoder])) {
		KTLayoutManager * aLayoutManager = [theCoder decodeObjectForKey:KTViewViewLayoutManagerKey];
		if(aLayoutManager == nil)
			aLayoutManager = [[[KTLayoutManager alloc] initWithView:self] autorelease];
		else
			[aLayoutManager setView:self];
		[self setViewLayoutManager:aLayoutManager];
		[self setAutoresizesSubviews:NO];
		[self setAutoresizingMask:NSViewNotSizable];
		
		KTStyleManager * aStyleManager = [theCoder decodeObjectForKey:KTViewStyleManagerKey];
		if(aStyleManager == nil)
			aStyleManager = [[[KTStyleManager alloc] initWithView:self] autorelease];
		else
			[aStyleManager setView:self];
		[self setStyleManager:aStyleManager];
		[self setOpaque:NO];
		
		NSString * aLabel = [theCoder decodeObjectForKey:KTViewLabelKey];
		if(aLabel == nil)
			aLabel = [self description];
		[self setLabel:aLabel];
	}
	return self;
}
 
- (void)dealloc
{	
	[mLayoutManager release];
	[mStyleManager release];
	[mLabel release];
	[mCachedImage release];
	[super dealloc];
}

- (NSString *)description;
{
	return [NSString stringWithFormat:@"%@ %@ frame:%@ numberOfSubviews:%i", [super description], [self label], NSStringFromRect([self frame]), [[self subviews] count]];
}
 
- (BOOL)isOpaque
{
	return mOpaque;
}
 
- (BOOL)canBecomeKeyView
{
	if(mCanBecomeKeyView == NO)
		return mCanBecomeKeyView;
		
	return [super canBecomeKeyView];
}
 
- (BOOL)canBecomeFirstResponder
{
	return mCanBecomeFirstResponder;
}

- (BOOL)mouseDownCanMoveWindow
{
	return mMouseDownCanMoveWindow;
}
 
- (void)setMouseDownCanMoveWindow:(BOOL)theBool
{
	mMouseDownCanMoveWindow = theBool;
	if(mMouseDownCanMoveWindow == YES)
	{
		if([[self superview] isKindOfClass:[KTView class]])
			[(KTView*)[self superview] setMouseDownCanMoveWindow:YES];
	}
}
 
- (BOOL)acceptsFirstMouse
{
	return mAcceptsFirstMouse;
}
 
- (void)drawAsImage:(BOOL)theBool
{
//	mDrawAsImage = theBool;
//	if(mDrawAsImage)
//	{
//		[self lockFocus];
//		NSBitmapImageRep * aBitmap = [[[NSBitmapImageRep alloc] initWithFocusedViewRect:[self bounds]] autorelease];
//		[self unlockFocus];
//		NSImage * anImage = [[[NSImage alloc] initWithData:[aBitmap TIFFRepresentation]] autorelease];
//		if(mCachedImage!=nil)
//			[mCachedImage release];
//		mCachedImage = [anImage retain];
//	}
//	else
//	{
//		[mCachedImage release];
//		mCachedImage = nil;
//	}
}


#pragma mark -
#pragma mark Drawing
 
- (void)drawRect:(NSRect)theRect
{	
	CGContextRef aContext = [[NSGraphicsContext currentContext] graphicsPort];

	if ([self drawDebuggingRect])
		[self _drawDebuggingRect];
		
	[[self styleManager] drawStylesInRect:theRect context:aContext view:self];
	[self drawInContext:aContext];
}
 
- (void)drawInContext:(CGContextRef)theContext
{
	// subclasses can override this to do custom drawing over the styles
}
 
- (void)_drawDebuggingRect
{
	[[NSColor colorWithCalibratedRed:0 green:1 blue:0 alpha:.5] set];
	NSRect anInsetBounds = NSInsetRect([self bounds], 10, 10);
	[NSBezierPath fillRect:anInsetBounds];
	
	NSRect anOriginSquare = NSMakeRect(0, 0, 10, 10);
	[[NSColor colorWithCalibratedRed:1 green:0 blue:0 alpha:.5] set];
	[NSBezierPath fillRect:anOriginSquare];
}


#pragma mark -
#pragma mark Layout protocol

- (void)setFrameSize:(NSSize)theSize
{
	[super setFrameSize:theSize];
	NSArray * aSubviewList = [self children];
	NSUInteger aSubviewCount = [aSubviewList count];
	for(NSUInteger i = 0; i < aSubviewCount; ++i) {
		NSView * aSubview = [aSubviewList objectAtIndex:i];
		if ([aSubview conformsToProtocol:@protocol(KTViewLayout)]) {
			[[(KTView *)aSubview viewLayoutManager] refreshLayout];
		}
	}
}

- (id <KTViewLayout>)parent
{
	if([[self superview] conformsToProtocol:@protocol(KTViewLayout)])
		return (id<KTViewLayout>)[self superview];
	else
		return nil;
}

- (NSArray*)children
{
	return [super subviews];
}

- (void)addSubview:(NSView *)theView
{
	[super addSubview:theView];
	if(		[theView conformsToProtocol:@protocol(KTViewLayout)] == NO
		&&	[theView autoresizingMask] != NSViewNotSizable)
		[self setAutoresizesSubviews:YES];
	if([theView isKindOfClass:[KTView class]]) {
		if([theView mouseDownCanMoveWindow])
			[self setMouseDownCanMoveWindow:YES];
	}
}

- (NSWindow *)window
{
	return [super window];
}

@end
