//
//  KTOpenGLLayerController.h
//  KTUIKit
//
//  Created by Cathy on 27/02/2009.
//  Copyright 2009 Sofa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KTController.h"

@class KTViewController;

@interface KTLayerController : NSResponder <KTController> {
	@private
	KTViewController	*wViewController;
	NSMutableArray		*mSubcontrollers;
	id					mLayer;
	id					wRepresentedObject;
	BOOL				mHidden;
}

@property (nonatomic, readwrite, assign) KTViewController * viewController;
@property (nonatomic, readwrite, retain) NSMutableArray * subcontrollers;
@property (nonatomic, readwrite, retain) id layer;
@property (nonatomic, readwrite, assign) id representedObject;
@property (nonatomic, readwrite, assign) BOOL hidden;

+ (id)layerControllerWithViewController:(KTViewController*)theViewController;
- (id)initWithViewController:(KTViewController*)theViewController;

- (void)addSubcontroller:(KTLayerController *)theSubcontroller;
- (void)removeSubcontroller:(KTLayerController *)theSubcontroller;

@end

@interface KTLayerController (KTPrivate)
- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
@end
