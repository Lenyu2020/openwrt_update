#!/bin/bash
_sys_judg()
{
sysa=`cat /etc/issue`
sysb="Ubuntu"
sysc=`getconf LONG_BIT`
# local timeout=2
# local target=www.google.com
# local ret_code=`curl -I -s --connect-timeout ${timeout} ${target} -w %{http_code} | tail -n1`
if [[ "$UID" = 0 ]];then
    clear
    echo
    echo -e "\033[31m警告：请在非root用户下运行该脚本……\033[0m"
    echo
    exit
elif [[ ( $sysa != *$sysb* ) || ( $sysc != 64 ) ]]; then
	clear
    echo
    echo -e "\033[31m警告：请在Ubuntu18+ x64系统下运行该脚本……\033[0m"
    echo
    exit
fi
#检查网络状态
# if [ "x$ret_code" != "x200" ]; then
	# clear
	# echo
	# echo -e "\033[31m警告：您网络不能科学上网，请检查网络后重试…\033[0m"
	# echo
	# exit
# fi
# 判断是否安装了sudo
if ! type sudo >/dev/null 2>&1; then
    clear
    echo
    echo -e "\033[31m警告：您未安装sudo，请切换至root用户下安装(apt-get install sduo)…\033[0m"
    echo
    exit
fi
# 判断是否成功安装了wget
if ! type wget >/dev/null 2>&1; then
	echo
    echo -e "\033[35m警告：您的系统未安装wget，正在给您安装，请稍后…\033[0m"
	echo
	sudo apt-get install wget -y >/dev/null 2>&1
	sleep 0.1
	if ! type wget >/dev/null 2>&1; then
		clear
		echo
		echo -e "\033[31m警告：安装wget失败，请检查网络重试…\033[0m"
		echo
		exit
	fi
fi
}
path=$(dirname $(readlink -f $0))
cd ${path}
##################################################

dev_force_update()
{
if [[  ! -d ${path}/lede  ]]; then
	clear
	echo
	echo -e "\033[31m警告：本地还没源码，请选脚本第1项目初始化…\033[0m"
	echo
	read -n 1 -p  "请回车继续…"
	echo
	menub
fi
cd ${path}
clear
echo
echo "脚本正在运行中…"
##lede
#由于源码xray位置改变，需要加入一个判断清除必要的文件
if [ ! -d  "${path}/lede/feeds/helloworld/xray-core" ]; then
	sed -i 's/#src-git helloworld/src-git helloworld/'  ${path}/lede/feeds.conf.default
	rm -rf ${path}/lede/package/lean/xray
	rm -rf ${path}/lede/tmp
fi
#清理
rm -rf ${path}/lede/rename.sh
rm -rf ${path}/lede/package/lean/default-settings/files/zzz-default-settings
rm -rf ${path}/lede/feeds/helloworld/xray-core/Makefile
rm -rf ${path}/lede/bin/targets/x86/64/openwrt_dev_uefi.md5
rm -rf ${path}/lede/bin/targets/x86/64/openwrt_dev.md5
echo
git -C ${path}/lede pull >/dev/null 2>&1
git -C ${path}/lede rev-parse HEAD > new_lede
echo
wget -P ${path}/lede/package/lean/default-settings/files https://raw.githubusercontent.com/coolsnowwolf/lede/master/package/lean/default-settings/files/zzz-default-settings -O  ${path}/lede/package/lean/default-settings/files/zzz-default-settings >/dev/null 2>&1
echo
#自动从桌面复制xray到files文件处并给相应权限
if [[ -f  "/mnt/c/Users/perfume/Desktop/xray" ]]; then
	cp -f /mnt/c/Users/perfume/Desktop/xray ${path}/lede/files/usr/bin/
	chmod 755 ${path}/lede/files/usr/bin/xray
	#rm -rf /mnt/c/Users/perfume/Desktop/xray
else
	rm -rf ${path}/lede/files/usr/bin/xray
fi
#####网络配置######
if [[ ! -d "${path}/lede/files/etc/config" ]]; then
	sed -i 's/192.168.1.2/192.168.1.1/g' ${path}/lede/package/base-files/files/bin/config_generate
	mkdir -p ${path}/lede/files/etc/config
	cat>${path}/lede/files/etc/config/network<<-EOF
	config interface 'loopback'
		option ifname 'lo'
		option proto 'static'
		option ipaddr '127.0.0.1'
		option netmask '255.0.0.0'

	config globals 'globals'
		option ula_prefix 'fd3f:2c76:9c66::/48'

	config interface 'lan'
		option type 'bridge'
		option ifname 'eth0'
		option proto 'static'
		option ipaddr '192.168.1.2'
		option netmask '255.255.255.0'
		option ip6assign '60'

	config interface 'wan'
		option ifname 'eth1'
		option proto 'dhcp'

	config interface 'wan6'
		option ifname 'eth1'
		option proto 'dhcpv6'
	EOF
else
	if [[ ! -f "${path}/lede/files/etc/config/network" ]]; then
		cat>${path}/lede/files/etc/config/network<<-EOF
		config interface 'loopback'
			option ifname 'lo'
			option proto 'static'
			option ipaddr '127.0.0.1'
			option netmask '255.0.0.0'

		config globals 'globals'
			option ula_prefix 'fd3f:2c76:9c66::/48'

		config interface 'lan'
			option type 'bridge'
			option ifname 'eth0'
			option proto 'static'
			option ipaddr '192.168.1.2'
			option netmask '255.255.255.0'
			option ip6assign '60'

		config interface 'wan'
			option ifname 'eth1'
			option proto 'dhcp'

		config interface 'wan6'
			option ifname 'eth1'
			option proto 'dhcpv6'
	EOF
	fi

fi
if [[ ! -f "${path}/lede/files/usr/share/Check_Update.sh" ]]; then
mkdir -p ${path}/lede/files/usr/share/
cat>${path}/lede/files/usr/share/Check_Update.sh<<-\EOF
#!/bin/bash
# https://github.com/Lenyu2020/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
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
wget -qO- -t1 -T2 "https://api.github.com/repos/Lenyu2020/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	openwrt_dev=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev.md5
	openwrt_dev_uefi=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
	echo
	echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
	echo
	exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev" -O /tmp/openwrt_dev.md5
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
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev_uefi" -O /tmp/openwrt_dev_uefi.md5
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
clear
read -n 1 -p  " 您是否要保留配置升级，保留选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	echo
  echo -e "\033[32m >>>正在准备保留配置升级，请稍后，等待系统重启…-> \033[0m"
	echo
	sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img
	fi
    ;;
    n|N)
    echo
    echo -e "\033[32m >>>正在准备不保留配置升级，请稍后，等待系统重启…-> \033[0m"
    echo
    sleep 3
	if [ ! -d /sys/firmware/efi ];then
		gzip -d openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		sysupgrade -n  /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img
	else
		gzip -d openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
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
open_op()
{
echo
read -n 1 -p  " 您确定要升级吗，升级选择Y,否则选N:" num1
echo
case $num1 in
	Y|y)
	  open_up
    ;;
  n|N)
    echo
    echo -e "\033[31m >>>您已选择退出固件升级，已经终止脚本…-> \033[0m"
    echo
    exit 1
    ;;
  *)
    echo
    echo -e "\033[31m err：只能选择Y/N\033[0m"
    echo
    read -n 1 -p  "请回车继续…"
    echo
    open_op
esac
}
open_op
exit 0
EOF
fi
if [[ ! -f "${path}/lede/files/usr/share/Lenyu-auto.sh" ]]; then
cat>${path}/lede/files/usr/share/Lenyu-auto.sh<<-\EOF
#!/bin/bash
# https://github.com/Lenyu2020/Actions-OpenWrt-x86
# Actions-OpenWrt-x86 By Lenyu 20210505
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
wget -qO- -t1 -T2 "https://api.github.com/repos/Lenyu2020/Actions-OpenWrt-x86/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g'  > /tmp/cloud_ts_version
if [ -s  "/tmp/cloud_ts_version" ]; then
	cloud_version=`cat /tmp/cloud_ts_version | cut -d _ -f 1`
	cloud_kernel=`cat /tmp/cloud_ts_version | cut -d _ -f 2`
	#固件下载地址
	new_version=`cat /tmp/cloud_ts_version`
	DEV_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
	DEV_UEFI_URL=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
	openwrt_dev=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev.md5
	openwrt_dev_uefi=https://github.com/Lenyu2020/Actions-OpenWrt-x86/releases/download/${new_version}/openwrt_dev_uefi.md5
else
	echo "请检测网络或重试！"
	exit 1
fi
####
Firmware_Type="$(grep 'DISTRIB_ARCH=' /etc/openwrt_release | cut -d \' -f 2)"
echo $Firmware_Type > /etc/lenyu_firmware_type
echo
if [[ "$cloud_kernel" =~ "4.19" ]]; then
	echo
	echo -e "\033[31m 该脚本在Lenyu固件Sta版本上运行，目前只建议在Dev版本上运行，准备退出… \033[0m"
	echo
	exit 0
fi
#md5值验证，固件类型判断
if [ ! -d /sys/firmware/efi ];then
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_URL" -O /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev" -O /tmp/openwrt_dev.md5
		cd /tmp && md5sum -c openwrt_dev.md5
		if [ $? != 0 ]; then
		  echo "您下载文件失败，请检查网络重试…"
		  sleep 4
		  exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_dev_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
else
	if [ "$current_version" != "$cloud_version" ];then
		wget -P /tmp "$DEV_UEFI_URL" -O /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		wget -P /tmp "$openwrt_dev_uefi" -O /tmp/openwrt_dev_uefi.md5
		cd /tmp && md5sum -c openwrt_dev_uefi.md5
		if [ $? != 0 ]; then
			echo "您下载文件失败，请检查网络重试…"
			sleep 1
			exit
		fi
		gzip -d /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img.gz
		sysupgrade /tmp/openwrt_x86-64-${new_version}_uefi-gpt_dev_Lenyu.img
	else
		echo -e "\033[32m 本地已经是最新版本，还更个鸡巴毛啊… \033[0m"
		echo
		exit
	fi
fi
exit 0
EOF
fi
######
echo
#检查文件是否下载成功；
if [[ ! -s ${path}/lede/package/lean/default-settings/files/zzz-default-settings ]]; then # -s 判断文件长度是否不为0；
	clear
	echo
	echo "同步下载openwrt源码出错，请检查网络问题…"
	echo
	exit
fi
new_lede=`cat new_lede`
#判断old_lede是否存在，不存在创建
if [ ! -f "old_lede" ]; then
  clear
  echo "old_lede被删除正在创建！"
  sleep 0.1
  echo $new_lede > old_lede
fi
sleep 0.1
old_lede=`cat old_lede`
if [ "$new_lede" = "$old_lede" ]; then
	echo "no_update" > ${path}/nolede
else
	echo "update" > ${path}/nolede
	echo $new_lede > old_lede
fi
echo
##ssr+
git -C ${path}/lede/feeds/helloworld pull >/dev/null 2>&1
git -C ${path}/lede/feeds/helloworld rev-parse HEAD > new_ssr
#增加xray的makefile文件
wget -P ${path}/lede/feeds/helloworld/xray-core https://raw.githubusercontent.com/fw876/helloworld/master/xray-core/Makefile -O  ${path}/lede/feeds/helloworld/xray-core/Makefile >/dev/null 2>&1
new_ssr=`cat new_ssr`
#判断old_ssr是否存在，不存在创建
if [ ! -f "old_ssr" ]; then
  echo "old_ssr被删除正在创建！"
  sleep 0.1
  echo $new_ssr > old_ssr
fi
sleep 0.1
old_ssr=`cat old_ssr`
if [ "$new_ssr" = "$old_ssr" ]; then
	echo "no_update" > ${path}/nossr
else
	echo "update" > ${path}/nossr
	echo $new_ssr > old_ssr
fi
echo
##xray
#由于源码xray位置改变，需要加入一个判断
if [ ! -d  "${path}/lede/feeds/helloworld/xray-core" ]; then
	clear
	echo
	echo "正在更新feeds源，请稍后…"
	cd ${path}/lede && ./scripts/feeds update -a >/dev/null 2>&1 && ./scripts/feeds install -a >/dev/null 2>&1
	cd ${path}
fi
echo
if [ ! -d  "xray_update" ]; then
	mkdir -p ${path}/xray_update
fi
#sed -i 's/Xray, Penetrates Everything/lenyu/g' ${path}/lede/feeds/helloworld/xray-core/Makefile
#获取xray-core/Makefile最新的版本号信息并修改；
wget -qO- -t1 -T2 "https://api.github.com/repos/XTLS/Xray-core/releases/latest" | grep "tag_name" | head -n 1 | awk -F ":" '{print $2}' | sed 's/\"//g;s/,//g;s/ //g;s/v//g' > ${path}/xray_lastest
#sed 's/\"//g;s/,//g;s/ //g;s/v//g'利用sed数据查找替换；
new_xray=`cat ${path}/xray_lastest`
if [ ! -f ${path}/xray_update/xray_version ]; then
	echo $new_xray > ${path}/xray_update/xray_version
fi
old_xray_ver=`cat ${path}/xray_update/xray_version`
if [ "$new_xray" != "$old_xray_ver" ]; then
	echo $new_xray > ${path}/xray_update/xray_version
	echo "update" > ${path}/noxray
else
	echo "no_update" > ${path}/noxray
fi
echo
rm -rf ${path}/xray_lastest
#本地版本号；
grep "PKG_VERSION:=" ${path}/lede/feeds/helloworld/xray-core/Makefile | awk -F "=" '{print $2}' > ${path}/jud_Makefile
old_xray=`cat ${path}/jud_Makefile`
rm -rf ${path}/jud_Makefile
echo
if [ "$new_xray" != "$old_xray" ]; then
	sed -i "s/.*PKG_VERSION:=.*/PKG_VERSION:=$new_xray/" ${path}/lede/feeds/helloworld/xray-core/Makefile
	#计算xray最新发布版本源码哈希值
	PKG_SOURCE_URL=https://codeload.github.com/XTLS/xray-core/tar.gz/v${new_xray}?
	wget -P ${path}/xray_update "$PKG_SOURCE_URL" -O  ${path}/xray_update/xray-core.tar.gz >/dev/null 2>&1
	sleep 0.1
	sha256sum ${path}/xray_update/xray-core.tar.gz > ${path}/xray_update/xray-core.tar.gz.sha256sum
	grep "xray-core.tar.gz" ${path}/xray_update/xray-core.tar.gz.sha256sum | awk -F " " '{print $1}' | sed 's/ //g' > ${path}/xray_update/xray-core_sha256sum
	echo
	xray_sha256sum=`cat ${path}/xray_update/xray-core_sha256sum`
	rm -rf ${path}/xray_update/xray-core.tar.gz.sha256sum
	rm -rf ${path}/xray_update/xray-core_sha256sum
	rm -rf ${path}/xray_update/xray-core.tar.gz
	sed -i "s/.*PKG_HASH:=.*/PKG_HASH:=$xray_sha256sum/" ${path}/lede/feeds/helloworld/xray-core/Makefile
	echo "update" > ${path}/noxray
fi
echo
##passwall
git -C ${path}/lede/feeds/passwall pull >/dev/null 2>&1
git -C ${path}/lede/feeds/passwall rev-parse HEAD > new_passw
new_passw=`cat new_passw`
#判断old_passw是否存在，不存在创建
if [ ! -f "old_passw" ]; then
  echo "old_passw被删除正在创建！"
  sleep 0.1
  echo $new_passw > old_passw
fi
sleep 0.1
old_passw=`cat old_passw`
if [ "$new_passw" = "$old_passw" ]; then
	echo "no_update" > ${path}/nopassw
else
	echo "update" > ${path}/nopassw
	echo $new_passw > old_passw
fi
echo
##openclash
git -C ${path}/lede/package/luci-app-openclash  pull >/dev/null 2>&1
git -C ${path}/lede/package/luci-app-openclash  rev-parse HEAD > new_clash
new_clash=`cat new_clash`
#判断old_clash是否存在，不存在创建
if [ ! -f "old_clash" ]; then
  echo "old_ssr被删除正在创建！"
  sleep 0.1
  echo $new_clash > old_clash
fi
sleep 0.1
old_clash=`cat old_clash`
if [ "$new_clash" = "$old_clash" ]; then
	echo "no_update" > ${path}/noclash
else
	echo "update" > ${path}/noclash
	echo $new_clash > old_clash
fi
##luci-theme-argon
git -C ${path}/lede/package/lean/luci-theme-argon  pull >/dev/null 2>&1
echo
sleep 0.1
####智能判断并替换大雕openwrt版本号的变动并自定义格式####
#下载GitHub使用raw页面，-P 指定目录 -O强制覆盖效果；
lenyu_version="`date '+%y%m%d%H%M'`_dev_Len yu"
echo $lenyu_version > ${path}/wget/DISTRIB_REVISION1
echo $lenyu_version | cut -d _ -f 1 > ${path}/lede/files/etc/lenyu_version
#######
#-s代表文件存在不为空,!将他取反
if [ -s  "${path}/lede/package/lean/default-settings/files/zzz-default-settings" ]; then
	new_DISTRIB_REVISION=`cat ${path}/wget/DISTRIB_REVISION1`
	grep "DISTRIB_REVISION=" ${path}/lede/package/lean/default-settings/files/zzz-default-settings | cut -d \' -f 2 > ${path}/wget/DISTRIB_REVISION3
	old_DISTRIB_REVISION=`cat ${path}/wget/DISTRIB_REVISION3`
	#替换自定义版本…
			sed -i "s/${old_DISTRIB_REVISION}/${new_DISTRIB_REVISION}/"  ${path}/lede/package/lean/default-settings/files/zzz-default-settings
	rm -rf ${path}/wget/DISTRIB_REVISION*
	rm -rf ${path}/wget/zzz-default-settings*
	#添加脚本alias
	grep "Check_Update.sh" ${path}/lede/package/lean/default-settings/files/zzz-default-settings
	if [ $? != 0 ]; then
		sed -i 's/exit 0/ /' ${path}/lede/package/lean/default-settings/files/zzz-default-settings
		cat>>${path}/lede/package/lean/default-settings/files/zzz-default-settings<<-EOF
		sed -i '$ a alias lenyu="bash /usr/share/Check_Update.sh"' /etc/profile
		exit 0
		EOF
	fi
	grep "Lenyu-auto.sh" ${path}/lede/package/lean/default-settings/files/zzz-default-settings
	if [ $? != 0 ]; then
		sed -i 's/exit 0/ /' ${path}/lede/package/lean/default-settings/files/zzz-default-settings
		cat>>${path}/lede/package/lean/default-settings/files/zzz-default-settings<<-EOF
		sed -i '$ a alias lenyu-auto="bash /usr/share/Lenyu-auto.sh"' /etc/profile
		exit 0
		EOF
	fi
fi
####；
#总结判断;
#监测如果不存在rename.sh则创建该文件；
if [ ! -f "${path}/lede/rename.sh" ]; then
cat>${path}/lede/rename.sh<<EOF
#/usr/bin/bash
path=\$(dirname \$(readlink -f \$0))
cd \${path}
	if [ ! -f \${path}/bin/targets/x86/64/*combined*.img.gz ] >/dev/null 2>&1; then
		echo
		echo "您编译时未选择压缩固件，故不进行重命名操作…"
		echo
		echo "为了减少固件体积，建议选择压缩（运行make menuconfig命令，在Target Images下勾选[*] GZip images）"
		echo
		exit 2
	fi
	rm -rf \${path}/bin/targets/x86/64/*Lenyu.img.gz
    	rm -rf \${path}/bin/targets/x86/64/packages
    	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic.manifest
    	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-rootfs-squashfs.img.gz
    	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-combined-squashfs.vmdk
    	rm -rf \${path}/bin/targets/x86/64/config.seed
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-uefi-gpt-squashfs.vmdk
    	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-vmlinuz
	rm -rf \${path}/bin/targets/x86/64/config.buildinfo
	rm -rf \${path}/bin/targets/x86/64/feeds.buildinfo
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-kernel.bin
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.vmdk
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.vmdk
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img.gz
	rm -rf \${path}/bin/targets/x86/64/version.buildinfo
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img
	rm -rf \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-rootfs.img
    sleep 2
	rename_version=\`cat ${path}/lede/files/etc/lenyu_version\`
    str1=\`grep "KERNEL_PATCHVER:=" \${path}/target/linux/x86/Makefile | cut -d = -f 2\` #判断当前默认内核版本号如5.10
	ver414=\`grep "LINUX_VERSION-4.14 =" \${path}/include/kernel-4.14 | cut -d . -f 3\`
	ver419=\`grep "LINUX_VERSION-4.19 =" \${path}/include/kernel-4.19 | cut -d . -f 3\`
	ver54=\`grep "LINUX_VERSION-5.4 =" \${path}/include/kernel-5.4 | cut -d . -f 3\`
	ver510=\`grep "LINUX_VERSION-5.10 =" \${path}/include/kernel-5.10 | cut -d . -f 3\`
	ver515=\`grep "LINUX_VERSION-5.15 =" \${path}/include/kernel-5.15 | cut -d . -f 3\`
	if [ "\$str1" = "5.4" ];then
		 mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz      \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver54}_dev_Lenyu.img.gz
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz  \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver54}_uefi-gpt_dev_Lenyu.img.gz
		exit 0
	elif [ "\$str1" = "4.19" ];then
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz      \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver419}_dev_Lenyu.img.gz
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz  \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver419}_uefi-gpt_dev_Lenyu.img.gz
		exit 0
	elif [ "\$str1" = "4.14" ];then
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz      \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver414}_dev_Lenyu.img.gz
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz  \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver414}_uefi-gpt_dev_Lenyu.img.gz
		exit 0
	elif [ "\$str1" = "5.10" ];then
		 mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz      \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver510}_dev_Lenyu.img.gz
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz  \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver510}_uefi-gpt_dev_Lenyu.img.gz
		exit 0
	elif [ "\$str1" = "5.15" ];then
		 mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined.img.gz      \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver515}_dev_Lenyu.img.gz
		mv \${path}/bin/targets/x86/64/openwrt-x86-64-generic-squashfs-combined-efi.img.gz  \${path}/bin/targets/x86/64/openwrt_x86-64-\${rename_version}_\${str1}.\${ver515}_uefi-gpt_dev_Lenyu.img.gz
		exit 0

	fi
EOF
fi
sleep 0.2
nolede=`cat ${path}/nolede`
noclash=`cat ${path}/noclash`
noxray=`cat ${path}/noxray`
nossr=`cat ${path}/nossr`
nopassw=`cat ${path}/nopassw`
#判断是否为x86机型编译，否是结束提示语改变
grep "CONFIG_TARGET_x86_64=y" ${path}/lede/.config  > ${path}/xray_update/sys_jud
sleep 0.5
if [[ ("$nolede" = "update") || ("$noclash" = "update") || ("$nossr" = "update" ) || ("$noxray" = "update") || ("$nopassw"  = "update" ) ]]; then
	clear
	echo
	echo "发现更新，请稍后…"
	clear
	echo
	echo "准备开始编译最新固件…"
	source /etc/environment && cd ${path}/lede && ./scripts/feeds update -a >/dev/null 2>&1 && ./scripts/feeds install -a >/dev/null 2>&1 && make defconfig && make -j8 download && make -j$(($(nproc) + 0)) V=s &&  bash rename.sh
	echo
	cd ${path}
	rm -rf ${path}/noxray
	rm -rf ${path}/noclash
	rm -rf ${path}/nolede
	rm -rf ${path}/nossr
	rm -rf ${path}/nopassw
	if [ -s  "${path}/xray_update/sys_jud" ]; then
		if [ ! -f ${path}/lede/bin/targets/x86/64/sha256sums ]; then
			echo
			echo "固件编译出错，请到${path}/lede/bin/targets/x86/64/目录下查看…"
			echo
			read -n 1 -p  "请回车继续…"
			menu
		else
			echo
			echo "固件编译成功，脚本退出！"
			echo
			echo "编译好的固件在${path}/lede/bin/targets/x86/64/目录下，enjoy！"
			echo
			###计算本地MD5值
			ls -l  "${path}/lede/bin/targets/x86/64" | awk -F " " '{print $9}' > ${path}/wget/open_dev_md5
			dev_version=`grep "_uefi-gpt_dev_Lenyu.img.gz" ${path}/wget/open_dev_md5 | cut -d - -f 3 | cut -d _ -f 1-2`
			openwrt_dev=openwrt_x86-64-${dev_version}_dev_Lenyu.img.gz
			openwrt_dev_uefi=openwrt_x86-64-${dev_version}_uefi-gpt_dev_Lenyu.img.gz
			cd ${path}/lede/bin/targets/x86/64
			md5sum $openwrt_dev > openwrt_dev.md5
			md5sum $openwrt_dev_uefi > openwrt_dev_uefi.md5
			cd ${path}
			rm -rf ${path}/wget/open_dev_md*
			echo
			########自动更新openwrt发布名称
			#c对一行或多行进行整行替换
			sed -i "1c $openwrt_dev"  /mnt/c/Users/perfume/Documents/openwrt.txt
			sed -i "2c $openwrt_dev_uefi"  /mnt/c/Users/perfume/Documents/openwrt.txt
			echo
			##########
			rm -rf ${path}/lede/bin/targets/x86/64/sha256sums
			read -n 1 -p  "请回车继续…"
			menu
		fi
	else
		echo "您编译的是非x86架构的固件，请自行到${path}/lede/bin/targets/*目录里查找所编译的固件…"
	fi
fi
echo
if [[ ("$nolede" = "no_update") && ("$noclash" = "no_update") && ("$noxray" = "no_update") && ("$nossr" = "no_update" ) && ("$nopassw"  = "no_update" ) ]]; then
	clear
	echo
	echo "呃呃…检查lede/ssr+/xray/passwall/openclash源码，没有一个源码更新…开始进入强制更新模式…"
	echo
	echo "准备开始编译最新固件…"
	source /etc/environment && cd ${path}/lede && ./scripts/feeds update -a >/dev/null 2>&1 && ./scripts/feeds install -a >/dev/null 2>&1 && make defconfig && make -j8 download && make -j$(($(nproc) + 0)) V=s &&  bash rename.sh
	echo
	cd ${path}
	rm -rf ${path}/noxray
	rm -rf ${path}/noclash
	rm -rf ${path}/nolede
	rm -rf ${path}/nossr
	rm -rf ${path}/nopassw
	if [ -s  "${path}/xray_update/sys_jud" ]; then
		if [ ! -f ${path}/lede/bin/targets/x86/64/sha256sums ]; then
			echo
			echo "固件编译出错，请到${path}/lede/bin/targets/x86/64/目录下查看…"
			echo
			read -n 1 -p  "请回车继续…"
			exit
		else
			echo
			echo "固件编译成功，脚本退出！"
			echo
			echo "编译好的固件在${path}/lede/bin/targets/x86/64/目录下，enjoy！"
			echo
			###计算本地MD5值
			ls -l  "${path}/lede/bin/targets/x86/64" | awk -F " " '{print $9}' > ${path}/wget/open_dev_md5
			dev_version=`grep "_uefi-gpt_dev_Lenyu.img.gz" ${path}/wget/open_dev_md5 | cut -d - -f 3 | cut -d _ -f 1-2`
			openwrt_dev=openwrt_x86-64-${dev_version}_dev_Lenyu.img.gz
			openwrt_dev_uefi=openwrt_x86-64-${dev_version}_uefi-gpt_dev_Lenyu.img.gz
			cd ${path}/lede/bin/targets/x86/64
			md5sum $openwrt_dev > openwrt_dev.md5
			md5sum $openwrt_dev_uefi > openwrt_dev_uefi.md5
			cd ${path}
			rm -rf ${path}/wget/open_dev_md*
			echo
			########自动更新openwrt发布名称
			#c对一行或多行进行整行替换
			sed -i "1c $openwrt_dev"  /mnt/c/Users/perfume/Documents/openwrt.txt
			sed -i "2c $openwrt_dev_uefi"  /mnt/c/Users/perfume/Documents/openwrt.txt
			echo
			##########
			rm -rf ${path}/lede/bin/targets/x86/64/sha256sums
			read -n 1 -p  "请回车继续…"
			exit
		fi
	else
		echo "您编译的是非x86架构的固件，请自行到${path}/lede/bin/targets/*目录里查找所编译的固件…"
	fi
fi
}
_sys_judg
dev_force_update
