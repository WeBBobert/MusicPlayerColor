/**
 * Copyright (c) 2024 Nightwind
 * iOS 18 port: hooks the new Control Center media module views too,
 * and uses a Darwin notification for live updates.
 */

#import <UIKit/UIKit.h>
#import "Notifications.h"

static UIColor *prefs_musicPlayerColor = nil;
static NSHashTable<UIView *> *trackedViews = nil;

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

static void updatePrefs(void) {
	NSDictionary *prefs = [NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.nightwind.musicplayercolorsettings.plist"];
	if (prefs) prefs_musicPlayerColor = UIColorFromHex(prefs[@"MusicPlayerColor"]);
}

static void applyColor(UIView *view) {
	if (!trackedViews) trackedViews = [NSHashTable weakObjectsHashTable];
	[trackedViews addObject:view];
	if (!prefs_musicPlayerColor) updatePrefs();
	view.backgroundColor = prefs_musicPlayerColor;
}

static void prefsChanged(CFNotificationCenterRef center, void *observer, CFStringRef name, const void *object, CFDictionaryRef userInfo) {
	dispatch_async(dispatch_get_main_queue(), ^{
		updatePrefs();
		for (UIView *view in trackedViews.allObjects) {
			view.backgroundColor = prefs_musicPlayerColor;
		}
	});
}

@interface MRUNowPlayingView : UIView
@end
@interface MRUMediaControlsModuleBackgroundView : UIView
@end
@interface MRUMediaModuleBackdropView : UIView
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

%ctor {
	updatePrefs();
	CFNotificationCenterAddObserver(CFNotificationCenterGetDarwinNotifyCenter(), NULL, prefsChanged,
		kMusicPlayerColorChangedDarwinNotification, NULL, CFNotificationSuspensionBehaviorDeliverImmediately);
}
