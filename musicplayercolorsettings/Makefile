MPC_ROOT := $(dir $(abspath $(lastword $(MAKEFILE_LIST))))..

include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = MusicPlayerColorSettings

MusicPlayerColorSettings_FILES = MPCRootListController.m MPCColorPickerCell.m
MusicPlayerColorSettings_FRAMEWORKS = UIKit
MusicPlayerColorSettings_PRIVATE_FRAMEWORKS = Preferences
MusicPlayerColorSettings_LIBRARIES = gcuniversal
MusicPlayerColorSettings_LDFLAGS = -L$(MPC_ROOT)/lib -L$(THEOS)/lib
MusicPlayerColorSettings_INSTALL_PATH = /Library/PreferenceBundles
MusicPlayerColorSettings_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/bundle.mk
