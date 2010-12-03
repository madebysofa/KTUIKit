
#import <Cocoa/Cocoa.h>
#import "KTMacros.h"

@protocol KTController;

typedef void (*_KTControllerEnumeratorCallBack)(NSResponder <KTController> * /* controller */, void * /* context */);

@protocol KTController <NSObject>
- (NSArray *)descendants;
- (void)removeObservations;
@property (readwrite, nonatomic, assign) BOOL hidden;

- (void)_enumerateSubControllers:(_KTControllerEnumeratorCallBack)theCallBackFunction context:(void *)theContext;
@end