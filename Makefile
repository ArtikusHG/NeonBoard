export DEBUG = 0
export FINALPACKAGE = 1
export GO_EASY_ON_ME = 1                # Do not treat warnings as errors
export ARCHS = arm64 arm64e             # I hope nobody still uses armv7
export TARGET = iphone:clang:14.5:13.0  # I hope nobody still uses iOS 7.0

export CFLAGS = -include $(realpath who_sucks.pch)

# It’s better to write following lines in your .zshrc or .bashrc
# export THEOS_DEVICE_IP = localhost
# export THEOS_DEVICE_PORT = 2222

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
	install.exec "rm -rf /var/containers/Shared/SystemGroup/systemgroup.com.apple.lsd.iconscache/Library/Caches/com.apple.IconsCache && rm -rf /var/mobile/Library/Caches/MappedImageCache/Persistent && killall -9 lsd lsdiconservice iconservicesagent fontservicesd SpringBoard"
# install.exec "rm -rf /var/mobile/Library/Caches/com.apple.IconsCache && rm -rf /var/mobile/Library/Caches/MappedImageCache/Persistent && killall -KILL lsd lsdiconservice && killall -9 lsd SpringBoard"
