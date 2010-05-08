#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(SBApplication);

CHMethod(0, BOOL, SBApplication, isClassic)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	[pool drain];
	if (value) {
		CHSuper(0, SBApplication, isClassic);
		return NO;
	} else {
		return CHSuper(0, SBApplication, isClassic);
	}
}

CHMethod(0, BOOL, SBApplication, isActuallyClassic)
{
	return CHSuper(0, SBApplication, isClassic);
}

CHDeclareClass(UIApplication);

CHMethod(0, void, UIApplication, _reportAppLaunchFinished)
{
	CHSuper(0, UIApplication, _reportAppLaunchFinished);
	UIWindow *keyWindow = [UIWindow keyWindow];
	CGRect windowFrame = [keyWindow frame];
	UIView *contentView = [keyWindow contentView];
	CGRect contentFrame = [contentView frame];
	if (contentFrame.size.width > windowFrame.size.width || contentFrame.size.height > windowFrame.size.height) {
		windowFrame.size = contentFrame.size;
		[keyWindow setFrame:windowFrame];
		[contentView setFrame:contentFrame];
	}
}

CHConstructor
{
	CHLoadLateClass(SBApplication);
	CHHook(0, SBApplication, isClassic);
	CHHook(0, SBApplication, isActuallyClassic);
	CHLoadClass(UIApplication);
	CHHook(0, UIApplication, _reportAppLaunchFinished);
}
