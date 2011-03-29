
#import <Cocoa/Cocoa.h>
#import "KTMacros.h"

@protocol KTController;

typedef void (*_KTControllerEnumeratorCallBack)(NSResponder <KTController> * /* controller */, BOOL * /*theStopFlag*/, void * /* context */);

enum {
	_KTControllerEnumerationOptionsNone = 0,

	// TODO: These declarations are here to show where the API will be going in the future. The search style (breadth or depth-first) should be a mask so you can set both the style and ignore flags.

	_KTControllerEnumerationOptionsIgnoreViewControllers = 1,
	_KTControllerEnumerationOptionsIgnoreLayerControllers = 2,
	
	_KTControllerEnumerationOptionsDepthFirst = 3,
	_KTControllerEnumerationOptionsBreadthFirst = 4
};
typedef NSUInteger _KTControllerEnumerationOptions;


@protocol KTController <NSObject>
- (NSArray *)descendants;
- (void)removeObservations;
@property (readwrite, nonatomic, assign) BOOL hidden;

- (void)_enumerateSubControllers:(_KTControllerEnumeratorCallBack)theCallBackFunction context:(void *)theContext;
@end