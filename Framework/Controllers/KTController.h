
#import <Cocoa/Cocoa.h>

@protocol KTController <NSObject>
- (NSArray *)descendants;
- (void)removeObservations;
@property (readwrite, nonatomic, assign) BOOL hidden;
@end