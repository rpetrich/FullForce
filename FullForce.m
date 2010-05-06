#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

CHDeclareClass(SBApplication);

CHDeclareMethod(0, BOOL, SBApplication, isClassic)
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
