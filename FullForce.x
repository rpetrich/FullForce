#import <UIKit/UIKit.h>

#import "Headers.h"

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

static BOOL supportsApplication(SBApplication *app)
{
	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	NSString *displayIdentifier = [app respondsToSelector:@selector(displayIdentifier)] ? [app displayIdentifier] : [app bundleIdentifier];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:displayIdentifier]] boolValue];
	value &= ![[app tags] containsObject:@"no-fullforce"];
	[pool drain];
	return value;
}

%hook SBApplication

static NSInteger inActuallyClassic;

- (BOOL)isClassic
{
	if (inActuallyClassic)
		return %orig();
	if (supportsApplication(self)) {
		%orig();
		return NO;
	} else {
		return %orig();
	}
}

- (BOOL)supportsApplicationType:(int)type
{
	if (inActuallyClassic)
		return %orig();
	return %orig() || supportsApplication(self);
}

%new
- (BOOL)isActuallyClassic
{
	inActuallyClassic++;
	BOOL result = [self isClassic];
	inActuallyClassic--;
	return result;
}

- (BOOL)isMedusaCapable
{
	%orig();
	return YES;
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

// iOS6's keyboard insanity

%hook UIKeyboardCandidateToggleButton
- (CGRect)labelFrameFromFrame:(CGRect)frame
{
	standardInterfaceIdiom++;
	CGRect result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardCandidatePocketShadow
- (void)drawRect:(CGRect)rect
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardEmojiCategoryController
+ (Class)classForCategoryControl
{
	standardInterfaceIdiom++;
	Class result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardEmojiInputController
- (void)emojiUsed:(id)sender
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
+ (Class)classForInputView
{
	standardInterfaceIdiom++;
	Class result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKBCacheToken
+ (id)tokenTemplateFilledForKey:(id)key style:(int)style size:(CGSize)size
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (id)tokenTemplateForKey:(id)key name:(id)name style:(int)style size:(CGSize)size
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (id)tokenForKey:(id)key style:(int)style state:(int)state clipCorners:(int)clipCorners
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (id)tokenForKey:(id)key style:(int)style state:(int)state
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIDictationView
- (id)initWithFrame:(CGRect)frame
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)layoutSubviews
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (id)endpointButton
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (UIImage *)endpointButtonImageWithRect:(CGRect)rect pressed:(BOOL)pressed
{
	standardInterfaceIdiom++;
	UIImage *result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (Class)dictationViewClass
{
	standardInterfaceIdiom++;
	Class result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardDicationBackground
- (id)initWithFrame:(CGRect)frame
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
 - (void)layoutSubviews
 {
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardDicationBackgroundGradientView
- (void)drawRect:(CGRect)rect
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (CGRect)_backgroundFillFrame
{
	standardInterfaceIdiom++;
	CGRect result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIDictationController
- (void)dealloc
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)setState:(int)state
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardLayoutDictation
- (void)showKeyboardType:(int)keyboardType withAppearance:(int)appearance
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
+ (CGSize)dictationLayoutSize
{
	standardInterfaceIdiom++;
	CGSize result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook NSBundle
+ (NSBundle *)_rivenBundle
{
	standardInterfaceIdiom++;
	NSBundle *result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardEmojiGraphics
+ (CGPoint)padding:(BOOL)something
{
	standardInterfaceIdiom++;
	CGPoint result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (CGPoint)margin:(BOOL)something
{
	standardInterfaceIdiom++;
	CGPoint result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (unsigned char)colCount:(BOOL)something
{
	standardInterfaceIdiom++;
	unsigned char result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (unsigned char)rowCount:(BOOL)something
{
	standardInterfaceIdiom++;
	unsigned char result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (CGSize)emojiSize:(BOOL)something
{
	standardInterfaceIdiom++;
	CGSize result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (id)dividerWithTheme:(void * /*struct UIKBTheme **/)theme
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)initializeThemes
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIInputViewSet
- (BOOL)_accessorySuppressesShadow
{
	standardInterfaceIdiom++;
	BOOL result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIPeripheralHost
- (void)peripheralViewMinMaximized:(id)animation finished:(id)something context:(id)context
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)moveToPersistentOffset
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)refreshCorners
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)updateDropShadow
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)showCorners:(BOOL)shouldShow withDuration:(float)duration
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)adjustHostViewForTransitionStartFrame:(id)something
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardCornerView
- (id)initWithFrame:(CGRect)frame left:(BOOL)isLeft
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardLayoutStar
- (void)showKeyboardType:(int)keyboardType appearance:(int)appearance orientation:(id)orientation withShift:(BOOL)shifted
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
} 
- (id)activationIndicatorView
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)showPopupVariantsForKey:(id)key
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardEmojiView
- (id)createAndInstallKeyPopupView
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)drawRect:(CGRect)rect
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardEmojiScrollView
- (void)layoutRecents
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)doLayout
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (id)initWithFrame:(CGRect)frame keyboard:(id)keyboard key:(id)key state:(int)state
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UITextEffectsWindow
- (CGPoint)magnifierScreenPointForPoint:(CGPoint)point targetWindow:(UIWindow *)targetWindow
{
	standardInterfaceIdiom++;
	CGPoint result = %orig();
	standardInterfaceIdiom--;
	return result;
}
%end

%hook UIKeyboardLayout
- (id)initWithFrame:(CGRect)frame
{
	standardInterfaceIdiom++;
	self = %orig();
	standardInterfaceIdiom--;
	return self;
}
- (CGFloat)flickDistance
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardImpl
+ (CGSize)defaultSizeForInterfaceOrientation:(UIInterfaceOrientation)orientation
{
	standardInterfaceIdiom++;
	CGSize result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (CGSize)sizeForInterfaceOrientation:(UIInterfaceOrientation)orientation textInputTraits:(id)traits
{
	standardInterfaceIdiom++;
	CGSize result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (UIInterfaceOrientation)interfaceOrientationForSize:(CGSize)size
{
	standardInterfaceIdiom++;
	UIInterfaceOrientation result = %orig();
	standardInterfaceIdiom--;
	return result;
}
+ (void)refreshRivenStateWithTraits:(id)traits isKeyboard:(BOOL)isKeyboard
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)delayedInit
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (CGFloat)currentPortraitWidth
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (CGFloat)currentPortraitHeight
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (CGFloat)currentLandscapeWidth
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (CGFloat)currentLandscapeHeight
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (id)inputOverlayContainer
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (BOOL)_shouldShowCandidateBar:(BOOL)something
{
	standardInterfaceIdiom++;
	BOOL result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)resizeForKeyplaneSize:(CGSize)size
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)updateLayout
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKeyboardLayoutStar
- (void)touchDragged:(UITouch *)touch
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)setKeyboardDim:(BOOL)dim
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)touchUp:(UITouch *)touch
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (unsigned int)downActionFlagsForKey:(id)key
{
	standardInterfaceIdiom++;
	unsigned int result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (id)keyHitTest:(CGPoint)point
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (id)keyHitTestForTouchInfo:(id)touchInfo touchStage:(int)touchStage
{
	standardInterfaceIdiom++;
	id result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (BOOL)pointInside:(CGPoint)point forEvent:(GSEventRef)event
{
	standardInterfaceIdiom++;
	BOOL result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (CGFloat)hitBuffer
{
	standardInterfaceIdiom++;
	CGFloat result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (BOOL)backgroundNeedsRedraw
{
	standardInterfaceIdiom++;
	BOOL result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (int)stateForShiftKey:(id)key
{
	standardInterfaceIdiom++;
	int result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)updateBackgroundIfNeeded
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)updateMoreAndInternationalKeys
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)setKeyboardAppearance:(int)appearance
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)installGestureRecognizers
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
%end

%hook UIKBKeyplaneView
- (void)drawRect:(CGRect)rect
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (int)cornerMaskForKey:(id)key recursive:(BOOL)recursive
{
	standardInterfaceIdiom++;
	int result = %orig();
	standardInterfaceIdiom--;
	return result;
}
- (void)setState:(int)state forKey:(id)key
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (void)updateDecorationViewsIfNeeded
{
	standardInterfaceIdiom++;
	%orig();
	standardInterfaceIdiom--;
}
- (id)initWithFrame:(CGRect)frame keyboard:(id)keyboard keyplane:(id)keyplane
{
	standardInterfaceIdiom++;
	self = %orig();
	standardInterfaceIdiom--;
	return self;
}
%end

%hook UIPeripheralHostView
- (id)initWithFrame:(CGRect)frame
{
	standardInterfaceIdiom++;
	self = %orig();
	standardInterfaceIdiom--;
	return self;
}
%end

%end

static void initApp(UIApplication *self)
{
	NSDictionary *dict = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.booleanmagic.fullforce.plist"];
	BOOL value = [[dict objectForKey:[@"FFEnabled-" stringByAppendingString:[self displayIdentifier]]] boolValue];
	if (value) {
		%init(AppHooks);
	}
}

%hook UIApplication

- (void)_runWithURL:(NSURL *)url payload:(id)payload launchOrientation:(UIInterfaceOrientation)orientation statusBarStyle:(int)style statusBarHidden:(BOOL)hidden
{
	initApp(self);
	%orig();
}

- (void)_runWithMainScene:(id)mainScene transitionContext:(id)transitionContext completion:(dispatch_block_t)completion
{
	initApp(self);
	%orig();
}

%end

%hook UIDevice

- (BOOL)wa_isDeviceSupported
{
	%log();
	%orig();
	return YES;
}

%end

%ctor
{
	%init();
}
