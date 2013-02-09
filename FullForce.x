#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <UIKit/UIKit2.h>
#import <SpringBoard/SpringBoard.h>
#import <CaptainHook/CaptainHook.h>

/*
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

%hook SBApplication

static NSInteger inActuallyClassic;

- (BOOL)isClassic
{
	if (inActuallyClassic)
		return %orig();
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	value &= ![[self tags] containsObject:@"no-fullforce"];
	[pool drain];
	if (value) {
		%orig();
		return NO;
	} else {
		return %orig();
	}
}

%new
- (BOOL)isActuallyClassic
{
	inActuallyClassic++;
	BOOL result = [self isClassic];
	inActuallyClassic--;
	return result;
}

%end

%group AppHooks

/*
%hook UIViewController

- (void)presentModalViewController:(UIViewController *)viewController animated:(BOOL)animated
{
	if ([viewController isKindOfClass:[UIImagePickerController class]]) {
		FullForcePopoverManager *ffpm = [[FullForcePopoverManager alloc] initWithViewController:self pickerController:(UIImagePickerController *)viewController];
		[ffpm show];
		[ffpm release];
	} else {
		%orig();
	}
}

- (void)dismissModalViewControllerAnimated:(BOOL)animated
{
	if (currentPopoverManager)
		[currentPopoverManager dismissAnimated:YES];
	else
		%orig();
}

%end
*/
%hook UIDevice

static NSInteger standardInterfaceIdiom;
static UIBarButtonItem *currentBarButtonItem;

- (UIUserInterfaceIdiom)userInterfaceIdiom
{
	return standardInterfaceIdiom ? %orig() : UIUserInterfaceIdiomPhone;
}

%end

%hook UIActionSheet

- (void)showInView:(UIView *)view
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
		%orig();
	}
}

%end


%hook UIPopoverController

- (id)initWithContentViewController:(UIViewController *)contentViewController
{
	standardInterfaceIdiom++;
	self = %orig();
	standardInterfaceIdiom--;
	return self;
}

%end

%hook UIBarButtonItem

- (void)_sendAction:(id)action withEvent:(UIEvent *)event
{
	currentBarButtonItem = self;
	%orig();
	currentBarButtonItem = nil;
}

%end

%hook UIApplication

- (void)_reportAppLaunchFinished
{
	%orig();
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

%end

%end

%hook UIApplication

- (void)_runWithURL:(NSURL *)url payload:(id)payload launchOrientation:(UIInterfaceOrientation)orientation statusBarStyle:(int)style statusBarHidden:(BOOL)hidden
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	if (value) {
		%init(AppHooks);
	}
	%orig();
}

%end

%ctor
{
	%init();
}
