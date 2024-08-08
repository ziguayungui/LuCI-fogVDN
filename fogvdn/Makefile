include $(TOPDIR)/rules.mk

PKG_NAME:=fogvdn
PKG_VERSION:=621
PKG_RELEASE:=2

include $(INCLUDE_DIR)/package.mk

define Package/$(PKG_NAME)
  SECTION:=PCDN
  CATEGORY:=PCDN
  TITLE:=Pear PCDN binary
  DEPENDS:=+bash +libc +getopt +jq +ntpdate +whereis +smartmontools +zoneinfo-all +coreutils-nohup
endef

define Build/Prepare
	mkdir -p $(PKG_BUILD_DIR)
endef

define Build/Compile/Default

endef
Build/Compile = $(Build/Compile/Default)

# define Package/$(PKG_NAME)/conffiles
# endef

define Package/$(PKG_NAME)/install
	$(CP) ./files/* $(1)/
endef

define Package/$(PKG_NAME)/postinst
#!/bin/sh

# 从pear_id转换为biz_id
/etc/pear/pear_scripts/node_info_file_create.sh

# 迁移业务程序
if [ ! -d /opt/pear ]; then
    mkdir -p /opt/pear
    chmod -R 644 /opt/pear
fi
for dir in /etc/pear/pear_plugin/*/; do
    if [ -d "${dir}" ]; then
        dir_name=$(basename "${dir}")
        if [ "${dir_name}1" = "plugin_stop1" ]; then
            continue
        fi
        if [ ! -d "/opt/pear/${dir_name}" ]; then
            cp -v -f -a "$dir" "/opt/pear/${dir_name}"
        else
            echo "/opt/pear/${dir_name} exists, skip."
        fi
    fi
done

# 打入定时任务
if [ -z "$(cat /etc/crontabs/root | grep pear_cron.sh | grep -v '#')" ]; then 
    echo "* * * * * root /root/pear/cron/pear_cron.sh -1m" >> /etc/crontabs/root
    echo "*/5 * * * * root /root/pear/cron/pear_cron.sh -5m" >> /etc/crontabs/root
    echo "*/30 * * * * root /root/pear/cron/pear_cron.sh -30m" >> /etc/crontabs/root
    echo "15 4 * * * root /root/pear/cron/pear_cron.sh -1d" >> /etc/crontabs/root
fi

/etc/init.d/cron reload
endef

define Package/$(PKG_NAME)/postrm
#!/bin/sh
sed -i '/pear_cron.sh/d' /etc/crontabs/root
/etc/init.d/cron reload
#endef
endef

$(eval $(call BuildPackage,$(PKG_NAME)))
