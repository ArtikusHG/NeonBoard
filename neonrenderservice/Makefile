TARGET := iphone:clang:latest:7.0

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeonRenderService

NeonRenderService_FILES = NeonRenderService.x
NeonRenderService_CFLAGS = -fobjc-arc
NeonRenderService_FRAMEWORKS = UIKit

include $(THEOS_MAKE_PATH)/tweak.mk
