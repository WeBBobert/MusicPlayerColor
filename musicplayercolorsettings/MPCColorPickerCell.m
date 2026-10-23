/**
 * Copyright (c) 2024 Nightwind
 */

#import <Foundation/Foundation.h>
#import "MPCColorPickerCell.h"
#import "../Notifications.h"

@implementation MPCColorPickerCell

/**
 * Override the colorPickerViewController:didSelectColor:continuously: method in order to dynamically change the color in the plist.
 */
- (void)colorPickerViewController:(UIColorPickerViewController *)viewController didSelectColor:(UIColor *)color continuously:(BOOL)continuously {
	[super colorPickerViewController:viewController didSelectColor:color continuously:continuously];

	const CGFloat *colorComponents = CGColorGetComponents([color CGColor]);
	NSString *const colorHexString = [NSString stringWithFormat:@"#%02lX%02lX%02lX%02lX", lroundf(colorComponents[0] * 255), lroundf(colorComponents[1] * 255), lroundf(colorComponents[2] * 255), lroundf(colorComponents[3] * 255)];

	CFPreferencesSetAppValue(CFSTR("MusicPlayerColor"), (__bridge CFStringRef)colorHexString, CFSTR("com.nightwind.musicplayercolorsettings"));
	CFPreferencesAppSynchronize(CFSTR("com.nightwind.musicplayercolorsettings"));

	CFNotificationCenterPostNotification(CFNotificationCenterGetDarwinNotifyCenter(), kMusicPlayerColorChangedDarwinNotification, NULL, NULL, YES);
}

@end