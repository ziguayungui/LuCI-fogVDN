include $(TOPDIR)/rules.mk

PKG_NAME:=fogvdn
PKG_VERSION:=621
PKG_RELEASE:=7

ifeq ($(ARCH),x86_64)
	PKG_ARCH:=X64
else ifeq ($(ARCH),aarch64)
	PKG_ARCH:=ARM64
endif

PKG_SOURCE_URL:=https://download.openfogos.com/spare/
PKG_VENDOR:=PEAR
PKG_SOURCE:=$(PKG_NAME)_$(PKG_VENDOR)_$(PKG_ARCH)_LINUX_$(PKG_VERSION).tar.gz
PKG_HASH:=skip

include $(INCLUDE_DIR)/package.mk
PKG_UNPACK:=$(HOST_TAR) -C $(PKG_BUILD_DIR)/root --strip-components=1 -xzf $(DL_DIR)/$(PKG_SOURCE)

define Package/$(PKG_NAME)
  SECTION:=PCDN
  CATEGORY:=PCDN
  TITLE:=Pear PCDN binary
  DEPENDS:=+bash +libc +getopt +jq +ntpdate +whereis +smartmontools +zoneinfo-all +coreutils-nohup
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)/root
	$(PKG_UNPACK)
endef

define Build/Compile/Default

endef
Build/Compile = $(Build/Compile/Default)

# define Package/$(PKG_NAME)/conffiles
# endef

define Package/$(PKG_NAME)/install
	$(CP) $(PKG_BUILD_DIR)/root/* $(1)/
	$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
sed -i '/pear_cron.sh/d' /etc/crontabs/root
/etc/init.d/cron reload

uci delete ucitrack.@fogvdn[0]
uci commit ucitrack
#endef
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
