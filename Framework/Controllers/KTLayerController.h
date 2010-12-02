//
//  KTOpenGLLayerController.h
//  KTUIKit
//
//  Created by Cathy on 27/02/2009.
//  Copyright 2009 Sofa. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import "KTMacros.h"
#import "KTController.h"

KT_EXPORT NSString *const KTLayerControllerLayerControllersKey;

@class KTViewController;

@interface KTLayerController : NSResponder <KTController> {
	@private
	KTViewController	*wViewController;
	KTLayerController	*wParentLayerController;

	NSMutableArray		*mPrimitiveLayerControllers;
	
	id					mLayer;
	id					mRepresentedObject;
	
	BOOL				mHidden;
}

@property (readwrite, nonatomic, assign) KTViewController *viewController;
@property (readonly, nonatomic, assign) KTLayerController *parentLayerController;

@property (readwrite, nonatomic, retain) id layer;
@property (readwrite, nonatomic, retain) id representedObject;

@property (readwrite, nonatomic, assign) BOOL hidden;

+ (id)layerControllerWithViewController:(KTViewController*)theViewController;
- (id)initWithViewController:(KTViewController*)theViewController;

#pragma mark Layer Controllers
@property (readonly, nonatomic, copy) NSArray *layerControllers;
- (void)addLayerController:(KTLayerController *)theLayerController;
- (void)removeLayerController:(KTLayerController *)theLayerController;
- (void)removeAllLayerControllers;

// This API will be deprecated in the near-future, use the "layerController" variants instead
#pragma mark Subcontrollers
@property (readonly, nonatomic, retain) NSArray *subcontrollers;
- (void)addSubcontroller:(KTLayerController *)theSubcontroller;
- (void)removeSubcontroller:(KTLayerController *)theSubcontroller;

@end

@interface KTLayerController (KTPrivate)
- (void)_setHidden:(BOOL)theHidden patchResponderChain:(BOOL)thePatch;
@end
