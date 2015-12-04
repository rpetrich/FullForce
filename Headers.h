#import <UIKit/UIKit.h>

typedef void *GSEventRef;

@interface UIWindow ()
+ (UIWindow *)keyWindow;
- (UIView *)contentView;
@end

@interface UIApplication ()
- (NSString *)displayIdentifier;
@end

@interface SBApplication : NSObject
- (NSString *)displayIdentifier;
- (BOOL)isClassic;
- (NSArray *)tags;
@end

@interface SBApplication (iOS8)
- (NSString *)bundleIdentifier;
@end
