#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

/*CHDeclareClass(UIPopoverController);

__attribute__((visibility("hidden")))
@interface FullForcePopoverManager : NSObject<UIPopoverControllerDelegate> {
@private
	UIViewController *_viewController;
	UIImagePickerController *_pickerController;
	UIPopoverController *_popoverController;
}

- (id)initWithViewController:(UIViewController *)viewController pickerController:(UIImagePickerController *)pickerController;
- (void)show;
- (void)dismissAnimated:(BOOL)animated;

@end

static FullForcePopoverManager *currentPopoverManager;

@implementation FullForcePopoverManager

- (id)initWithViewController:(UIViewController *)viewController pickerController:(UIImagePickerController *)pickerController
{
	if ((self = [super init])) {
		_viewController = [viewController retain];
		_pickerController = [pickerController retain];
		_popoverController = [CHAlloc(UIPopoverController) initWithContentViewController:pickerController];
		[_popoverController setDelegate:self];
	}
	return self;
}

- (void)dealloc
{
	[_viewController release];
	[_pickerController release];
	[_popoverController setDelegate:nil];
	[_popoverController release];
	[super dealloc];
}

- (void)show
{
	[currentPopoverManager dismissAnimated:YES];
	currentPopoverManager = [self retain];
	UIView *view = [[[_viewController view] window] contentView];
	CGRect bounds = [view bounds];
	bounds.origin.y += bounds.size.height - 1.0f;
	bounds.size.height = 1.0f;
	bounds.origin.x += 10.0f;
	bounds.size.width -= 20.0f;
	[_popoverController presentPopoverFromRect:bounds inView:view permittedArrowDirections:0xf animated:YES];
}

- (void)dismissAnimated:(BOOL)animated
{
	[_popoverController dismissPopoverAnimated:animated];
	[currentPopoverManager release];
	currentPopoverManager = nil;
}

- (BOOL)popoverControllerShouldDismissPopover:(UIPopoverController *)popoverController
{
	id<UIImagePickerControllerDelegate> delegate = [_pickerController delegate];
	if ([delegate respondsToSelector:@selector(imagePickerControllerDidCancel:)])
		[delegate imagePickerControllerDidCancel:_pickerController];
	return NO;
}

- (void)popoverControllerDidDismissPopover:(UIPopoverController *)popoverController
{
	[currentPopoverManager release];
	currentPopoverManager = nil;
}

@end*/

CHDeclareClass(SBApplication);

CHOptimizedMethod(0, self, BOOL, SBApplication, isClassic)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	value &= ![[self tags] containsObject:@"no-fullforce"];
	[pool drain];
	if (value) {
		CHSuper(0, SBApplication, isClassic);
		return NO;
	} else {
		return CHSuper(0, SBApplication, isClassic);
	}
}

CHOptimizedMethod(0, new, BOOL, SBApplication, isActuallyClassic)
{
	return CHSuper(0, SBApplication, isClassic);
}

/*CHDeclareClass(UIViewController);

CHOptimizedMethod(2, self, void, UIViewController, presentModalViewController, UIViewController *, viewController, animated, BOOL, animated)
{
	if ([viewController isKindOfClass:[UIImagePickerController class]]) {
		FullForcePopoverManager *ffpm = [[FullForcePopoverManager alloc] initWithViewController:self pickerController:(UIImagePickerController *)viewController];
		[ffpm show];
		[ffpm release];
	} else {
		CHSuper(2, UIViewController, presentModalViewController, viewController, animated, animated);
	}
}

CHOptimizedMethod(1, self, void, UIViewController, dismissModalViewControllerAnimated, BOOL, animated)
{
	if (currentPopoverManager)
		[currentPopoverManager dismissAnimated:YES];
	else
		CHSuper(1, UIViewController, dismissModalViewControllerAnimated, animated);
}*/

CHDeclareClass(UIDevice);

static NSInteger standardInterfaceIdiom;
static UIBarButtonItem *currentBarButtonItem;

CHOptimizedMethod(0, self, UIUserInterfaceIdiom, UIDevice, userInterfaceIdiom)
{
	return standardInterfaceIdiom ? CHSuper(0, UIDevice, userInterfaceIdiom) : UIUserInterfaceIdiomPhone;
}

CHDeclareClass(UIActionSheet)

CHOptimizedMethod(1, self, void, UIActionSheet, showInView, UIView *, view)
{
	if (currentBarButtonItem)
		[self showFromBarButtonItem:currentBarButtonItem animated:YES];
	else {
		if (!view) {
			UIWindow *keyWindow = [UIWindow keyWindow];
			if ([UIWindow respondsToSelector:@selector(rootViewController)])
				view = [[keyWindow rootViewController] view];
			if (!view)
				view = [keyWindow.subviews lastObject];
		}
		CHSuper(1, UIActionSheet, showInView, view);
	}
}

CHDeclareClass(UIPopoverController);

CHOptimizedMethod(1, self, id, UIPopoverController, initWithContentViewController, UIViewController *, contentViewController)
{
	standardInterfaceIdiom++;
	self = CHSuper(1, UIPopoverController, initWithContentViewController, contentViewController);
	standardInterfaceIdiom--;
	return self;
}

CHDeclareClass(UIBarButtonItem);

CHOptimizedMethod(2, self, void, UIBarButtonItem, _sendAction, id, action, withEvent, UIEvent *, event)
{
	currentBarButtonItem = self;
	CHSuper(2, UIBarButtonItem, _sendAction, action, withEvent, event);
	currentBarButtonItem = nil;
}

CHDeclareClass(UIApplication);

CHOptimizedMethod(0, self, void, UIApplication, _reportAppLaunchFinished)
{
	CHSuper(0, UIApplication, _reportAppLaunchFinished);
	UIWindow *keyWindow = [UIWindow keyWindow];
	UIView *contentView = [keyWindow contentView];
	if (contentView) {
		CGRect windowFrame = [keyWindow frame];
		CGRect contentFrame = [contentView frame];
		if (contentFrame.size.width > windowFrame.size.width || contentFrame.size.height > windowFrame.size.height) {
			windowFrame.size.width = contentFrame.origin.x + contentFrame.size.width;
			windowFrame.size.height = contentFrame.origin.y + contentFrame.size.height;
			[keyWindow setFrame:windowFrame];
			[contentView setFrame:contentFrame];
		} else if ((windowFrame.size.width == 320.0f) && (windowFrame.size.height == 480.0f)) {
			CGRect screenBounds = [[UIScreen mainScreen] bounds];
			windowFrame.size = screenBounds.size;
			[keyWindow setFrame:windowFrame];
			if ((contentFrame.size.width == 320.0f) && (contentFrame.size.height == 480.0f))
				contentFrame.size = screenBounds.size;
			[contentView setFrame:contentFrame];
		}
	}
}

CHOptimizedMethod(5, self, void, UIApplication, _runWithURL, NSURL *, url, payload, id, payload, launchOrientation, UIInterfaceOrientation, orientation, statusBarStyle, int, style, statusBarHidden, BOOL, hidden)
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	if (value) {
		NSBundle *bundle = [NSBundle mainBundle];
		if (![bundle.bundleIdentifier isEqualToString:@"com.facebook.Facebook"] || ([[bundle objectForInfoDictionaryKey:@"CFBundleVersion"] integerValue] < 3440)) {
			/*CHLoadLateClass(UIPopoverController);
			CHLoadClass(UIViewController);
			CHHook(2, UIViewController, presentModalViewController, animated);
			CHHook(1, UIViewController, dismissModalViewControllerAnimated);*/
			CHLoadClass(UIDevice);
			CHHook(0, UIDevice, userInterfaceIdiom);
			CHLoadClass(UIActionSheet);
			CHHook(1, UIActionSheet, showInView);
			CHLoadClass(UIPopoverController);
			CHHook(1, UIPopoverController, initWithContentViewController);
			CHLoadClass(UIBarButtonItem);
			CHHook(2, UIBarButtonItem, _sendAction, withEvent);
			CHHook(0, UIApplication, _reportAppLaunchFinished);
		}
	}
	CHSuper(5, UIApplication, _runWithURL, url, payload, payload, launchOrientation, orientation, statusBarStyle, style, statusBarHidden, hidden);
}

CHConstructor
{
	CHLoadLateClass(SBApplication);
	CHHook(0, SBApplication, isClassic);
	CHHook(0, SBApplication, isActuallyClassic);
	CHLoadClass(UIApplication);
	CHHook(5, UIApplication, _runWithURL, payload, launchOrientation, statusBarStyle, statusBarHidden);
}
