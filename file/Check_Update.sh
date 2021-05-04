#!/bin/bash
# https://github.com/Lenyu2020/openwrt-update-script
# openwrt-update-script By Lenyu 20210505
#path=$(dirname $(readlink -f $0))
# cd ${path}
#检测准备
if [ ! -f  "/etc/lenyu_version" ]; then
	echo
	echo -e "\033[31m 该脚本在非Lenyu固件上运行，为避免不必要的麻烦，准备退出… \033[0m"
	echo
	exit 0
fi
rm -f /tmp/cloud_version
# 获取固件云端版本号、内核版本号信息
current_version=`cat /etc/lenyu_version`
wget -qO- -t1 -T2 "https://api.github.com/repos/Lenyu2020/openwrt-update-script/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Lenyu2020/openwrt-update-script/releases/download/${new_version}/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Lenyu2020/openwrt-update-script/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	openwrt_dev=https://github.com/Lenyu2020/openwrt-update-script/releases/download/${new_version}/openwrt_dev.md5
	openwrt_dev_uefi=https://github.com/Lenyu2020/openwrt-update-script/releases/download/${new_version}/openwrt_dev_uefi.md5
else
	echo "请检测网络，查看是否能打开谷歌！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type


#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz  >/dev/null 2>&1
		wget -P /tmp "$openwrt_dev" -O /tmp/openwrt_dev.md5  >/dev/null 2>&1
		cd /tmp && md5sum -c openwrt_dev.md5
		if [ $? != 0 ]; then
		echo "您下载文件失败，请检查网络重试…"
		sleep 4
		exit
		fi
		Boot_type=logic
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz >/dev/null 2>&1
		wget -P /tmp "$openwrt_dev_uefi" -O /tmp/openwrt_dev_uefi.md5 >/dev/null 2>&1
		cd /tmp && md5sum -c openwrt_dev_uefi.md5
		if [ $? != 0 ]; then
		echo "您下载文件失败，请检查网络重试…"
		sleep 4
		exit
		fi
		Boot_type=efi
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi

open_up()
{
echo
read -n 1 -p  " 您是否要保留配置升级，保留选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	echo
    echo -e "\033[32m >>>正在准备保留配置升级，请稍后，等待系统重启…-> \033[0m"
	echo
	sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d openwrt_x86-64-${new_version}_dev_Lenyu.img.gz >/dev/null 2>&1
		sysupgrade /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz >/dev/null 2>&1
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img
	fi
    ;;
    n|N)
	echo
	echo -e "\033[32m >>>正在准备不保留配置升级，请稍后，等待系统重启…-> \033[0m"
	echo
	sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d openwrt_x86-64-${new_version}_dev_Lenyu.img.gz >/dev/null 2>&1
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz >/dev/null 2>&1
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img
	fi
    ;;
    *)
	echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
	echo
    read -n 1 -p  "请回车继续…"
	echo
	open_up
esac
}
open_up

exit 0
