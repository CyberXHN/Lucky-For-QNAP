# Lucky for QNAP NAS
 * Lucky项目地址：https://github.com/gdy666/lucky
 * 2.20大版本开始，**Releases**中的版本全程由**Github Action**构建，二进制文件全部源自官网
 * 本软件可能会被威联通**MalwareRemover**误报为病毒软件导致无法运行，安装运行前需自行禁用**MalwareRemover**

## 安装注意

 * 安装过程会提示无数字签名，若您对此有所顾虑，请使用[Docker版Lucky](https://hub.docker.com/r/gdy666/lucky)

## Lucky项目介绍
 * Lucky 是一个高效稳定的网络工具，提供IPv6/IPv4 端口转发、Web服务、动态域名、IPv4 内网穿透、计划任务、自动证书、filebrowser等服务，自带WebUI，简单易用。
 * 如果您是第一次使用Lucky，请务必先访问 https://lucky666.cn ，并仔细阅读相关的文档，以获得必要的信息和答案。在这些文档中，您可以了解到Lucky的基本功能和特性，掌握Lucky的使用方法，以及解决常见的问题和疑惑。
 
## 如何使用
 本项目支持 x86_64 和 arm_64 构架的QNAP存储设备
 1. 使用App Center手动安装。（无法安装需在APP Center中启用未签名应用安装）
 2. 访问URL：http://[NAS-IP]:16601/
 3. 默认用户名：666 默认密码：666

 ## Lucky版与Wanji版区别
 1. Lucky 轻量版 ：<br>
    包含常用模块：如动态域名、Web 服务、端口转发、STUN 穿透、计划任务、证书管理（ACME）、网络唤醒、FTP 服务、WebDAV 服务等。<br>
    去除了一些不常用的功能，使 Lucky 变得更加轻量，非常适合在资源有限的威联通NAS上运行。
 2. 万吉（Wanji）全能版：<br>
    在Lucky基础功能上增加了 grpc反向代理支持，CorazaWAF, rclone，filebrowser，DLNA服务，CloudFlare tunnel 客户端等功能。
