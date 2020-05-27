ARCHS = arm64 arm64e
export TARGET = iphone:clang:13.0:12.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Apollo

Apollo_FILES = Tweak.x
Apollo_CFLAGS = -fobjc-arc
Apollo_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk

BUNDLE_NAME = ApolloBundle
ApolloBundle_INSTALL_PATH = /Library/Application Support

include $(THEOS)/makefiles/bundle.mk
