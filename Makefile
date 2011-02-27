# Makefile for Bootlace

PROJECTNAME=Bootlace
APPFOLDER=$(PROJECTNAME).app
INSTALLFOLDER=$(PROJECTNAME).app

IPHONE_IP=192.168.0.4

SDKVER=3.1.2
SDKROOT=/SDK/Platforms/iPhoneOS.platform
SDK=$(SDKROOT)/Developer/SDKs/iPhoneOS$(SDKVER).sdk
SDKSIM=/SDK/Platforms/iPhoneSimulator.platform/Developer/SDKs/iPhoneOS$(SDKVER).sdk

CC=/SDK/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-gcc-4.2.1
CPP=/SDK/Platforms/iPhoneOS.platform/Developer/usr/bin/arm-apple-darwin9-g++-4.2.1
LD=$(CC)

LDFLAGS += -framework CoreFoundation 
LDFLAGS += -framework Foundation 
LDFLAGS += -framework UIKit 
LDFLAGS += -framework CoreGraphics
LDFLAGS += -framework WebCore
LDFLAGS += -framework SystemConfiguration
LDFLAGS += -framework CFNetwork
LDFLAGS += -framework MobileCoreServices
//LDFLAGS += -framework GraphicsServices
//LDFLAGS += -framework AddressBookUI
//LDFLAGS += -framework AddressBook
//LDFLAGS += -framework QuartzCore
//LDFLAGS += -framework CoreSurface
//LDFLAGS += -framework CoreAudio
//LDFLAGS += -framework Celestial
//LDFLAGS += -framework AudioToolbox
//LDFLAGS += -framework WebKit
//LDFLAGS += -framework MediaPlayer
//LDFLAGS += -framework OpenGLES
//LDFLAGS += -framework OpenAL

LDFLAGS += -L"$(SDK)/usr/lib"
LDFLAGS += -F"$(SDK)/System/Library/Frameworks"
LDFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"
LDFLAGS += -lcurl
LDFLAGS += -lIOKit
LDFLAGS += -lz
LDFLAGS += -lbz2
LDFLAGS += build/Release-iphoneos/libpartialzip.a
LDFLAGS += build/Release-iphoneos/libbz2.a
LDFLAGS += Libraries/arm/libarchive.a

CFLAGS += -IBZip2
CFLAGS += -I"$(SDKROOT)/Developer/usr/lib/gcc/arm-apple-darwin9/4.2.1/include/"
CFLAGS += -I"$(SDK)/usr/include"
CFLAGS += -IHeaders
CFLAGS += -IPartialZip
CFLAGS += -DDEBUG -std=c99
CFLAGS += -Diphoneos_version_min=3.1.2
CFLAGS += -F"$(SDK)/System/Library/Frameworks"
CFLAGS += -F"$(SDK)/System/Library/PrivateFrameworks"

CPPFLAGS=$CFLAGS

BUILDDIR=./build/$(SDKVER)
SRCDIR=./Classes
RESDIR=./Resources
XIBDIR=./Views
OBJS=$(patsubst %.m,%.o,$(wildcard $(SRCDIR)/*.m))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(SRCDIR)/*.c))
OBJS+=$(patsubst %.c,%.o,$(wildcard $(ASIDIR)/*.m))
OBJS+=$(patsubst %.cpp,%.o,$(wildcard $(SRCDIR)/*.cpp))
OBJS+=$(patsubst %.m,%.o,$(wildcard *.m))
PCH=$(wildcard *.pch)
RESOURCES=$(wildcard $(RESDIR)/*)
NIBS=$(patsubst %.xib,%.nib,$(wildcard $(XIBDIR)/*.xib))

all:	$(PROJECTNAME)

$(PROJECTNAME):	$(OBJS)
	$(LD) $(LDFLAGS) -o $@ $^ 

%.o:	%.m
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.c
	$(CC) -c $(CFLAGS) $< -o $@

%.o:	%.cpp
	$(CPP) -c $(CPPFLAGS) $< -o $@

%.nib:	%.xib
	ibtool $< --compile $@

dist:	$(PROJECTNAME) $(NIBS)
	rm -rf $(BUILDDIR)
	mkdir -p $(BUILDDIR)/$(APPFOLDER)
	cp -r $(RESOURCES) $(BUILDDIR)/$(APPFOLDER)
	cp Info.plist $(BUILDDIR)/$(APPFOLDER)/Info.plist
	cp Bootlace_ $(BUILDDIR)/$(APPFOLDER)/Bootlace_
	@echo "APPL????" > $(BUILDDIR)/$(APPFOLDER)/PkgInfo
	mv $(NIBS) $(BUILDDIR)/$(APPFOLDER)
	export CODESIGN_ALLOCATE=/SDK/Platforms/iPhoneOS.platform/Developer/usr/bin/codesign_allocate;
	./ldid_intel -S $(PROJECTNAME)
	mv $(PROJECTNAME) $(BUILDDIR)/$(APPFOLDER)

install: dist
	scp Settings/Bootlace.plist root@$(IPHONE_IP):/Library/PreferenceLoader/Preferences/Bootlace.plist
	scp -r $(BUILDDIR)/$(APPFOLDER) root@$(IPHONE_IP):/Applications/$(INSTALLFOLDER)
	@echo "Application $(INSTALLFOLDER) installed, please respring iPhone"
	ssh root@$(IPHONE_IP) 'respring && chmod +s /Applications/Bootlace.app/Bootlace'

uninstall:
	ssh root@$(IPHONE_IP) 'rm -fr /Applications/$(INSTALLFOLDER); respring'
	@echo "Application $(INSTALLFOLDER) uninstalled, please respring iPhone"

install_respring:
	scp respring_arm root@$(IPHONE_IP):/usr/bin/respring

clean:
	@rm -f $(SRCDIR)/*.o *.o
	@rm -rf $(BUILDDIR)
	@rm -f $(PROJECTNAME)

