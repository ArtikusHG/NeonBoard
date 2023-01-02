TARGET := iphone:clang:14.5:13.0
include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeonEngine

NeonEngine_FILES = Neon.x
NeonEngine_CFLAGS = -fobjc-arc -Wall
NeonEngine_LIBRARIES = MobileGestalt

include $(THEOS_MAKE_PATH)/tweak.mk
