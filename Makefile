export DEBUG = 0
export FINALPACKAGE = 1
export ARCHS = armv7 arm64 arm64e
#export ARCHS = arm64
export TARGET = iphone:clang:14.4:7.0

export CFLAGS = -include $(realpath theos_sucks.h)

#THEOS_DEVICE_IP = 192.168.1.159
THEOS_DEVICE_IP = localhost
THEOS_DEVICE_PORT = 2222

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = NeonBoard

NeonBoard_FILES = UIColor+CSSColors.m NeonLabelRenderService.m Clock.xm Calendar.x MasksSB.xm Badges.x PageDots.x IconShadows.xm IconLabels.x Dock.xm Customizations.xm Folders.xm
NeonBoard_FRAMEWORKS = UIKit CoreGraphics
NeonBoard_PRIVATE_FRAMEWORKS = AppSupport
NeonBoard_CFLAGS = -fobjc-arc -Wall

include $(THEOS_MAKE_PATH)/tweak.mk
#SUBPROJECTS += neonboardprefs neonengine neoncore neonkit neonpaths neonsettings neonrenderservice neonfonts neonsounds
SUBPROJECTS += neonboardprefs neonengine neoncore neonkit neonpaths neonsettings neonrenderservice neonfonts
include $(THEOS_MAKE_PATH)/aggregate.mk

after-install::
	install.exec "rm -rf /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache && rm -rf /var/mobile/Library/Caches/MappedImageCache/Persistent && killall -KILL lsd lsdiconservice && killall -9 lsd fontservicesd SpringBoard"
# install.exec "rm -rf /var/mobile/Library/Caches/com.apple.IconsCache && rm -rf /var/mobile/Library/Caches/MappedImageCache/Persistent && killall -KILL lsd lsdiconservice && killall -9 lsd SpringBoard"
