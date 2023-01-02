TARGET := iphone:clang:14.5:13.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeonKit

NeonKit_FILES = NeonImage.x NeonCacheManager.m Assets.xm LegacyFixup.x StatusBar11Later.xm SwitchesSliders13Later.x MasksWorkaround.x
NeonKit_CFLAGS = -fobjc-arc

include $(THEOS_MAKE_PATH)/tweak.mk
