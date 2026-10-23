export TARGET = iphone:clang:latest:16.0
export THEOS_PACKAGE_SCHEME = rootless
export ARCHS = arm64 arm64e

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = MusicPlayerColor

MusicPlayerColor_FILES = Tweak.x
MusicPlayerColor_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
SUBPROJECTS += musicplayercolorsettings
include $(THEOS_MAKE_PATH)/aggregate.mk
