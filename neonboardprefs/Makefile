export GO_EASY_ON_ME = 1

TARGET := iphone:clang:14.5:13.0
include $(THEOS)/makefiles/common.mk

BUNDLE_NAME = neonboardprefs

neonboardprefs_FILES = NBPShared.m NBPRootListController.m NBPThemingOptionsController.m NBPThemeCell.m NBPThemeListController.m NBPCustomizationController.m PSSearchableListController.m NBPOverridesController.m NBPSelectAppController.m NBPSelectThemeController.m NBPSelectIconController.m
neonboardprefs_INSTALL_PATH = /Library/PreferenceBundles
neonboardprefs_FRAMEWORKS = UIKit
neonboardprefs_PRIVATE_FRAMEWORKS = Preferences AppSupport
neonboardprefs_CFLAGS = -fobjc-arc -Wall

include $(THEOS_MAKE_PATH)/bundle.mk

internal-stage::
	$(ECHO_NOTHING)mkdir -p $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences$(ECHO_END)
	$(ECHO_NOTHING)cp entry.plist $(THEOS_STAGING_DIR)/Library/PreferenceLoader/Preferences/neonboardprefs.plist$(ECHO_END)
