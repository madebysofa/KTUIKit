//
//  KTStyleManager.m
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


/*
 (CS 11/12/08) This is a very basic implementation of the style manager
 you can configure it and it will draw. The plan is to eventually
 create a 'style sheet' object that can be used with bindings
 so that users can bind specific elements to the style sheet in IB. 
 Also the style manager should deal with color changes for different key states of views and their windows All for the future...
*/


#import "KTStyleManager.h"
#import "KTView.h"

NSString *const KTStyleManagerBackgroundColorKey = @"backgroundColor";
NSString *const KTStyleManagerBackgroundGradientKey = @"backgroundGradient";
NSString *const KTStyleManagerBackgroundGradientAngleKey = @"gradientAngle";
NSString *const KTStyleManagerBorderWidthTopKey = @"borderWidthTop";
NSString *const KTStyleManagerBorderWidthRightKey = @"borderWidthRight";
NSString *const KTStyleManagerBorderWidthBottomKey = @"borderWidthBottom";
NSString *const KTStyleManagerBorderWidthLeftKey = @"borderWidthLeft";
NSString *const KTStyleManagerBorderColorTopKey = @"borderColorTop";
NSString *const KTStyleManagerBorderColorRightKey = @"borderColorRight";
NSString *const KTStyleManagerBorderColorBottomKey = @"borderColorBottom";
NSString *const KTStyleManagerBorderColorLeftKey = @"borderColorLeft";

@interface KTStyleManager (Private)
- (NSArray*)keysForCoding;
@end


@implementation KTStyleManager

@synthesize backgroundColor = mBackgroundColor;
@synthesize borderColorTop = mBorderColorTop;
@synthesize borderColorRight = mBorderColorRight;
@synthesize borderColorBottom = mBorderColorBottom;
@synthesize borderColorLeft = mBorderColorLeft;
@synthesize	borderWidthTop = mBorderWidthTop;
@synthesize borderWidthRight = mBorderWidthRight;
@synthesize borderWidthBottom = mBorderWidthBottom;
@synthesize borderWidthLeft = mBorderWidthLeft;
@synthesize backgroundGradient = mBackgroundGradient;
@synthesize gradientAngle = mGradientAngle;

@synthesize view = wView;

- (id)initWithView:(id <KTStyle>)theView;
{
	if ((self = [self init])) {
		wView = theView;
	}
	return self;
}
 
- (void)dealloc
{
	[mBackgroundColor release];
	[mBorderColorTop release];
	[mBorderColorRight release];
	[mBorderColorBottom release];
	[mBorderColorLeft release];
	[mBackgroundGradient release];
	[mBackgroundImage release];
	CGImageRelease(mBackgroundImageRef);

	[super dealloc];
}

 
- (id)initWithCoder:(NSCoder*)theCoder
{
	if ((self = [self init])) {
		for (NSString *key in [self keysForCoding]) {
			[self setValue:[theCoder decodeObjectForKey:key] forKey:key];			
		}
	}
	return self;
}
 
- (void)encodeWithCoder:(NSCoder*)theCoder
{
	for (NSString *key in [self keysForCoding]) {
		[theCoder encodeObject:[self valueForKey:key] forKey:key];		
	}
}
 
- (NSArray *)keysForCoding
{
	return [NSArray arrayWithObjects:KTStyleManagerBackgroundColorKey,
									 KTStyleManagerBackgroundGradientKey, 
									 KTStyleManagerBackgroundGradientAngleKey, 
									 KTStyleManagerBorderWidthTopKey, 
									 KTStyleManagerBorderWidthRightKey, 
									 KTStyleManagerBorderWidthBottomKey, 
									 KTStyleManagerBorderWidthLeftKey, 
									 KTStyleManagerBorderColorTopKey, 
									 KTStyleManagerBorderColorRightKey, 
									 KTStyleManagerBorderColorBottomKey, 
									 KTStyleManagerBorderColorLeftKey, nil];
}

- (void)setNilValueForKey:(NSString *)key;
{
	if([key isEqualToString:KTStyleManagerBackgroundGradientAngleKey])
		[self setGradientAngle:0.0];
	else if([key isEqualToString:KTStyleManagerBorderWidthTopKey])
		[self setBorderWidthTop:0.0];
	else if([key isEqualToString:KTStyleManagerBorderWidthRightKey])
		[self setBorderWidthRight:0.0];
	else if([key isEqualToString:KTStyleManagerBorderWidthBottomKey])
		[self setBorderWidthBottom:0.0];
	else if([key isEqualToString:KTStyleManagerBorderWidthLeftKey])
		[self setBorderWidthLeft:0.0];

	else
		[super setNilValueForKey:key];
}

- (void)_drawBackgroundGradientInRect:(NSRect)theRect context:(CGContextRef)theContext controlView:(KTView <KTStyle> *)theView;
{
	CGContextSaveGState(theContext);
	{
		CGContextClipToRect(theContext, theRect);
		[mBackgroundGradient drawInRect:[theView bounds] angle:mGradientAngle];
	}
	CGContextRestoreGState(theContext);
}

- (void)_drawBackgroundFillInRect:(NSRect)theRect context:(CGContextRef)theContext controlView:(KTView <KTStyle> *)theView;
{
	CGFloat r, g, b, a;
	[[mBackgroundColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
	CGContextSetRGBFillColor(theContext, r, g, b, a);
	CGContextFillRect(theContext, NSRectToCGRect(theRect));	
}

// TODO: stop using the bounds of the view here.
- (void)_drawBackgroundImageInRect:(NSRect)theBounds context:(CGContextRef)theContext controlView:(KTView <KTStyle> *)theView;
{
	NSPoint anImagePoint = theBounds.origin;
	NSSize anImageSize = [mBackgroundImage size];
	
//	NSData * anImageData = [NSBitmapImageRep TIFFRepresentationOfImageRepsInArray: [mBackgroundImage representations]];
//	CGImageSourceRef aCGImageSourceRef = CGImageSourceCreateWithData((CFDataRef)anImageData, NULL);
//	CGImageRef aCGBackgroundImage = CGImageSourceCreateImageAtIndex(aCGImageSourceRef, 0, NULL);
	
	if(mTileImage)
		CGContextDrawTiledImage(theContext, CGRectMake(anImagePoint.x,anImagePoint.y, anImageSize.width, anImageSize.height), mBackgroundImageRef);
	else 
	{
		// draw from the center
		anImagePoint.x = floor(theBounds.origin.x+theBounds.size.width*.5-anImageSize.width*.5);
		anImagePoint.y = floor(theBounds.origin.y+theBounds.size.height*.5-anImageSize.height*.5);
		CGContextDrawImage(theContext, CGRectMake(anImagePoint.x,anImagePoint.y, anImageSize.width, anImageSize.height), mBackgroundImageRef);	
	}
//	CFRelease(aCGImageSourceRef);
//	CGImageRelease(aCGBackgroundImage);	
}

static void _KTStyleManagerAddPathFromPoint(CGContextRef theContext, CGPoint theStartPoint, CGPoint theEndPoint) {
	CGMutablePathRef aPath = CGPathCreateMutable();
	CGPathMoveToPoint(aPath, NULL, theStartPoint.x,  theStartPoint.y);
	CGPathAddLineToPoint(aPath, NULL, theEndPoint.x,  theEndPoint.y);
	CGContextAddPath(theContext, aPath);
	CGPathRelease(aPath);
}

static void _KTStyleManagerStrokePathWithColor(CGContextRef theContext, NSColor *theColor, CGFloat theLineWidth) {
	CGContextSetLineWidth(theContext, theLineWidth);
	CGFloat r, g, b, a;
	[[theColor colorUsingColorSpaceName:NSCalibratedRGBColorSpace] getRed:&r green:&g blue:&b alpha:&a];
	CGContextSetRGBStrokeColor(theContext, r, g, b, a);
	CGContextStrokePath(theContext);
}

static BOOL _KTStyleManagerShouldDrawBorder(NSColor *theColor, CGFloat theBorderWidth) {
	if (theColor == nil) return NO;
	return (theBorderWidth > 0 && ![theColor isEqual:[NSColor clearColor]]);
}

// TODO: none of this properly supports flipped views. The nomenclature doesn't work, should use rect edges instead.
// As we support different colors for each edge, we arbitraily draw the top and bottom borders over left and right.
- (void)_drawBordersInRect:(NSRect)theRect context:(CGContextRef)theContext controlView:(KTView <KTStyle> *)theView;
{
	CGContextSaveGState(theContext);
	{
		CGContextClipToRect(theContext, theRect);
		
		CGRect aBounds = NSRectToCGRect([theView bounds]);
		
		if (_KTStyleManagerShouldDrawBorder(mBorderColorLeft, mBorderWidthLeft)) {
			CGPoint aStartPoint = CGPointMake(NSMinX(aBounds) + 0.5,  NSMinY(aBounds));
			CGPoint anEndPoint = CGPointMake(NSMinX(aBounds) + 0.5,  NSMaxY(aBounds));
			_KTStyleManagerAddPathFromPoint(theContext, aStartPoint, anEndPoint);
			_KTStyleManagerStrokePathWithColor(theContext, mBorderColorLeft, mBorderWidthLeft);			
		}
		
		if (_KTStyleManagerShouldDrawBorder(mBorderColorRight, mBorderWidthRight)) {
			CGPoint aStartPoint = CGPointMake(NSMaxX(aBounds) - 0.5,  NSMinY(aBounds));
			CGPoint anEndPoint = CGPointMake(NSMaxX(aBounds) - 0.5,  NSMaxY(aBounds));
			_KTStyleManagerAddPathFromPoint(theContext, aStartPoint, anEndPoint);
			_KTStyleManagerStrokePathWithColor(theContext, mBorderColorRight, mBorderWidthRight);			
		}
		
		if (_KTStyleManagerShouldDrawBorder(mBorderColorTop, mBorderWidthTop)) {
			CGPoint aStartPoint = CGPointMake(NSMinX(aBounds),  NSMaxY(aBounds) - 0.5);
			CGPoint anEndPoint = CGPointMake(NSMaxX(aBounds),  NSMaxY(aBounds) - 0.5);
			_KTStyleManagerAddPathFromPoint(theContext, aStartPoint, anEndPoint);
			_KTStyleManagerStrokePathWithColor(theContext, mBorderColorTop, mBorderWidthTop);			
		}
		
		if (_KTStyleManagerShouldDrawBorder(mBorderColorBottom, mBorderWidthBottom)) {
			CGPoint aStartPoint = CGPointMake(NSMinX(aBounds),  NSMinY(aBounds) + 0.5);
			CGPoint anEndPoint = CGPointMake(NSMaxX(aBounds),  NSMinY(aBounds) + 0.5);
			_KTStyleManagerAddPathFromPoint(theContext, aStartPoint, anEndPoint);
			_KTStyleManagerStrokePathWithColor(theContext, mBorderColorBottom, mBorderWidthBottom);			
		}
	}
	CGContextRestoreGState(theContext);
}

- (void)drawStylesInRect:(NSRect)theRect context:(CGContextRef)theContext view:(KTView <KTStyle> *)theView;
{
	NSRect aViewBounds = [(NSView*)theView bounds];

	// Either draw a background gradient of solid color fill.
	if(mBackgroundGradient != nil) {
		[self _drawBackgroundGradientInRect:theRect context:theContext controlView:theView];
	} else if(mBackgroundColor != [NSColor clearColor]) {
		[self _drawBackgroundFillInRect:theRect context:theContext controlView:theView];
	}
	
	// also need to figure out a way to optimize image drawing so it only draws in the dirty rect of the view
	if (mBackgroundImage != nil && mBackgroundImageRef != nil) {
		[self _drawBackgroundImageInRect:aViewBounds context:theContext controlView:theView];
	}
	
	[self _drawBordersInRect:theRect context:theContext controlView:theView];
}
 
- (void)setBorderWidth:(CGFloat)theWidth
{
	[self setBorderWidthTop:theWidth right:theWidth bottom:theWidth left:theWidth];
}
 
- (void)setBorderWidthTop:(CGFloat)theTopWidth right:(CGFloat)theRightWidth bottom:(CGFloat)theBottomWidth left:(CGFloat)theLeftWidth
{
	[self setBorderWidthTop:theTopWidth];
	[self setBorderWidthRight:theRightWidth];
	[self setBorderWidthBottom:theBottomWidth];
	[self setBorderWidthLeft:theLeftWidth];
}
 
- (void)setBackgroundImage:(NSImage*)theBackgroundImage tile:(BOOL)theBool
{
	if(mBackgroundImage != theBackgroundImage)
	{
		[theBackgroundImage retain];
		[mBackgroundImage release];
		CGImageRelease(mBackgroundImageRef);
		mBackgroundImage = theBackgroundImage;

		NSData * anImageData = [NSBitmapImageRep TIFFRepresentationOfImageRepsInArray: [mBackgroundImage representations]];
		if(anImageData==nil)
			anImageData = [mBackgroundImage TIFFRepresentation];

		CGImageSourceRef aCGImageSourceRef = CGImageSourceCreateWithData((CFDataRef)anImageData, NULL);
		mBackgroundImageRef = CGImageSourceCreateImageAtIndex(aCGImageSourceRef, 0, NULL);
		CFRelease(aCGImageSourceRef);		
	}
	mTileImage = theBool;
	if(mTileImage)
	{
		if([wView isKindOfClass:[KTView class]])
			[(KTView*)wView setOpaque:YES];	
	}
}

// either save a gradient or a fill color 
- (void)setBackgroundColor:(NSColor*)theColor
{
	if(mBackgroundColor!=theColor) {
		[mBackgroundColor release];
		mBackgroundColor = [theColor retain];
		if(mBackgroundColor!=nil)
			[self setBackgroundGradient:nil];
			
		if([mBackgroundColor alphaComponent] >= 1)
			[(KTView*)wView setOpaque:YES];
	}
}
 
- (void)setBackgroundGradient:(NSGradient*)theGradient
{
	if(mBackgroundGradient!=theGradient) {
		[mBackgroundGradient release];
		mBackgroundGradient = [theGradient retain];
		if(mBackgroundGradient!=nil)
			[self setBackgroundColor:nil];
		[(KTView*)wView setOpaque:YES];
	}
}
 
- (void)setBackgroundGradient:(NSGradient*)theGradient angle:(CGFloat)theAngle
{
	[self setBackgroundGradient:theGradient];
	[self setGradientAngle:theAngle];
}
 
- (void)setBorderColor:(NSColor*)theColor
{
	[self setBorderColorTop:theColor right:theColor bottom:theColor left:theColor];
}
 
- (void)setBorderColorTop:(NSColor*)theTopColor right:(NSColor*)theRightColor bottom:(NSColor*)theBottomColor left:(NSColor*)theLeftColor
{
	[self setBorderColorTop:theTopColor];
	[self setBorderColorRight:theRightColor];
	[self setBorderColorBottom:theBottomColor];
	[self setBorderColorLeft:theLeftColor];
}

@end
