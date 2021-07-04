# Openwrt-Update-Script
Openwrt 固件一键检测更新/编译固件脚本！

【运行脚本请保证网络能科学】【固件默认x86-64架构·不要在root账户下运行】

【IP:192.168.1.2 USER:root PASSWD:password】

1.平台是基于win10 wsl2环境的linux 当然也可以运行到其他地方Linux上，推荐Ubuntu 18 LTS x64：
    
    a.脚本一键运行后有哪些插件？
    答：基本上就是群主自己定义的简单固件，大致包含常用插件该有的都有，但是绝不臃肿，可以看看下面部分固件截图；

    b.后期如何自定义自己插件？x86其他机型？
    答：第一运行脚本会自动检测本地是否有源码，如果没源码就会运行首次初始化项，一直进行直到第一次编译成功后，第二次
    编译的时候，自己先进入源码目录make menuconfig下（ 如开发版：cd ~/lede && make menuconfig )即可自己选择好插件、机型等配置，然后运行脚本编译！
    即可实现自己的定制化操作！enjoy！
    注：自定义只需要修改一次！！只要不删除源码，自定义的不会被脚本覆盖。

    c.简单叙述下脚本特色？
    答：能在win10 wsl2环境的linux的Ubuntu 18 x64或者其他linux的Ubuntu 18 x64一键运行编译固件；
    本脚本不仅能自动检测lean大雕开发和稳定版源码分支有无更新，而且同步检测xray、openclash、passwall、helloword等组件有无更新，能在有更新的
    时编译固件；具体的百闻不如一试。

2.脚本升级为一键按傻瓜操作，无需自己配置，只需要准备好良好网络和一台充满能量的linux系统PC;

3.初次编译会花费很长时间，根据电脑配置约1-3小时之间，请耐心等待，不要惊慌失措，百无聊赖至于可以进群吹水打发时间;

4.一键脚本运行：

    cd && bash -c "$(wget -O- https://git.io/Jt8nn)"

5.若有问题讨论群：https://t.me/openwrt_lede_v2ray_plugin

6.附录部分脚本状态图片：

![img_3.png](image/img_3.png)

![img_1.png](image/img_1.png)

![img_2.png](image/img_2.png)

![img.png](image/img2222.png)

7.附录部分固件状态图片：

![img_4.png](image/img_4.png)

![img_5.png](image/img_5.png)

