/**
 * Copyright (c) 2024 Nightwind
 * iOS 18 port: hooks the Control Center media module views,
 * rounds the corners of the colored view, optional RGB cycling, uses a Darwin notification
 * for live updates, and writes a debug dump to /var/mobile/mpc_debug.txt
 */

#import <UIKit/UIKit.h>
#import "Notifications.h"

#pragma clang diagnostic ignored "-Warc-performSelector-leaks"

static const CGFloat kFallbackRadius = 40.0;

static UIColor *prefs_musicPlayerColor = nil;
static BOOL prefs_rgb = NO;
static CGFloat prefs_speed = 3.0;
static CGFloat baseAlpha = 1.0;
static CGFloat rgbHue = 0.0;
static NSTimer *rgbTimer = nil;
static NSHashTable<UIView *> *trackedViews = nil;

static CFStringRef const kDomain = CFSTR("com.nightwind.musicplayercolorsettings");

static UIColor *UIColorFromHex(NSString *hexString) {
	if (![hexString isKindOfClass:[NSString class]]) return nil;

	unsigned rgbValue = 0;
	NSScanner *scanner = [NSScanner scannerWithString:hexString];
	if ([hexString hasPrefix:@"#"]) scanner.scanLocation = 1;
	[scanner scanHexInt:&rgbValue];

	// Stored as #RRGGBBAA by the picker cell
	return [UIColor
		colorWithRed:((rgbValue >> 24) & 0xFF) / 255.0
		green:((rgbValue >> 16) & 0xFF) / 255.0
		blue:((rgbValue >> 8) & 0xFF) / 255.0
		alpha:(rgbValue & 0xFF) / 255.0
	];
}

static id prefValue(CFStringRef key) {
	return (__bridge_transfer id)CFPreferencesCopyAppValue(key, kDomain);
}

static void updatePrefs(void) {
	CFPreferencesAppSynchronize(kDomain);

	prefs_musicPlayerColor = UIColorFromHex(prefValue(CFSTR("MusicPlayerColor")));

	id rgb = prefValue(CFSTR("RGBEnabled"));
	prefs_rgb = [rgb respondsToSelector:@selector(boolValue)] ? [rgb boolValue] : NO;

	id speed = prefValue(CFSTR("RGBSpeed"));
	prefs_speed = [speed respondsToSelector:@selector(doubleValue)] ? [speed doubleValue] : 3.0;
	if (prefs_speed < 1.0) prefs_speed = 1.0;
	if (prefs_speed > 10.0) prefs_speed = 10.0;

	CGFloat alpha = 1.0;
	if (prefs_musicPlayerColor) {
		CGFloat r, g, b;
		[prefs_musicPlayerColor getRed:&r green:&g blue:&b alpha:&alpha];
	}
	baseAlpha = alpha;
}

static UIColor *currentColor(void) {
	if (prefs_rgb) {
		return [UIColor colorWithHue:rgbHue saturation:0.9 brightness:1.0 alpha:baseAlpha];
	}
	return prefs_musicPlayerColor;
}

static void setAllColors(UIColor *color) {
	for (UIView *view in trackedViews.allObjects) {
		view.backgroundColor = color;
	}
}

static void stopRGB(void) {
	[rgbTimer invalidate];
	rgbTimer = nil;
}

static void startRGB(void) {
	if (rgbTimer || !prefs_rgb) return;

	rgbTimer = [NSTimer timerWithTimeInterval:(1.0 / 30.0) repeats:YES block:^(NSTimer *timer) {
		BOOL anyVisible = NO;
		for (UIView *view in trackedViews.allObjects) {
			if (view.window) {
				anyVisible = YES;
				break;
			}
		}
		if (!anyVisible || !prefs_rgb) {
			stopRGB();
			return;
		}

		rgbHue += (1.0 / 30.0) * prefs_speed * 0.05;
		if (rgbHue > 1.0) rgbHue -= 1.0;
		setAllColors(currentColor());
	}];
	[[NSRunLoop mainRunLoop] addTimer:rgbTimer forMode:NSRunLoopCommonModes];
}

static void roundCorners(UIView *view) {
	CGFloat radius = 0;
	UIView *v = view;
	for (int i = 0; i < 6 && v; i++) {
		if (v.layer.cornerRadius > 0) {
			radius = v.layer.cornerRadius;
			break;
		}
		v = v.superview;
	}
	if (radius <= 0) radius = kFallbackRadius;
	view.layer.cornerRadius = radius;
	view.layer.cornerCurve = kCACornerCurveContinuous;
}

static void applyColor(UIView *view) {
	if (!trackedViews) trackedViews = [NSHashTable weakObjectsHashTable];
	[trackedViews addObject:view];
	if (!prefs_musicPlayerColor) updatePrefs();
	view.backgroundColor = currentColor();
	roundCorners(view);
	startRGB();
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	dispatch_async(dispatch_get_main_queue(), ^{
		updatePrefs();
		setAllColors(currentColor());
		if (prefs_rgb) startRGB();
		else stopRGB();
	});
}

static void dumpHierarchy(UIView *view, NSString *tag) {
	static int count = 0;
	if (count++ >= 12 || !view) return;

	NSMutableString *out = [NSMutableString stringWithFormat:@"\n===== %@ (window: %@) =====\nCHAIN:", tag, NSStringFromClass([view.window class])];
	for (UIView *v = view; v; v = v.superview) {
		[out appendFormat:@" <- %@", NSStringFromClass([v class])];
	}
	SEL sel = NSSelectorFromString(@"recursiveDescription");
	if ([view respondsToSelector:sel]) {
		[out appendFormat:@"\n%@\n", [view performSelector:sel]];
	}

	NSString *path = @"/var/mobile/mpc_debug.txt";
	NSFileHandle *fh = [NSFileHandle fileHandleForWritingAtPath:path];
	if (!fh) {
		[out writeToFile:path atomically:YES encoding:NSUTF8StringEncoding error:nil];
		return;
	}
	[fh seekToEndOfFile];
	[fh writeData:[out dataUsingEncoding:NSUTF8StringEncoding]];
	[fh closeFile];
}

@interface MRUNowPlayingView : UIView
@end
@interface MRUMediaControlsModuleBackgroundView : UIView
@end
@interface MRUMediaModuleBackdropView : UIView
@end
@interface MRUNowPlayingViewController : UIViewController
@end

%hook MRUNowPlayingView
- (void)didMoveToWindow {
	%orig;
	applyColor(self);
}
%end

%hook MRUMediaControlsModuleBackgroundView
- (void)didMoveToWindow {
	%orig;
	applyColor(self);
}
%end

%hook MRUMediaModuleBackdropView
- (void)didMoveToWindow {
	%orig;
	applyColor(self);
}
%end

%hook MRUNowPlayingViewController
- (void)viewDidAppear:(BOOL)animated {
	%orig;
	dumpHierarchy(self.view, NSStringFromClass([self class]));
}
%end

%ctor {
	updatePrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged,
		kMusicPlayerColorChangedDarwinNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
