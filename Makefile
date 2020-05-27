ARCHS = arm64
export TARGET = iphone:clang:11.2:7.0

INSTALL_TARGET_PROCESSES = SpringBoard

include $(THEOS)/makefiles/common.mk

TWEAK_NAME = Apollo

Apollo_FILES = Tweak.x
Apollo_CFLAGS = -fobjc-arc
Apollo_PRIVATE_FRAMEWORKS = MediaRemote

include $(THEOS_MAKE_PATH)/tweak.mk
