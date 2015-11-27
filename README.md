# OSSFS-Fuse

## 介绍

OSSFS-Fuse是实现将阿里云OSS bucket挂载成为阿里云ECS服务器本地盘功能的工具，方便阿里云用户快捷地使用OSS。

## 支持系统

* Ubuntu 14.04 LTS 及以上
* CentOS 7 及以上

## 安装前准备

在阿里云(www.aliyun.com)官方网站上申请一台ECS机器，操作系统为CentOS 7 或者Ubuntu 14.04 (64bit)。

## 安装步骤

1. 申请ECS:

   首先在阿里云申请一台ECS，操作系统版本为CentOS 7或者Ubuntu 14.04 (64bit)，申请和购买方法参照阿里云ECS，此处不赘述。

2. 通过ssh登陆到ECS机器:

   您可以通过如putty/secureCRT等常用远程登陆软件，此处不赘述。

3. 下载ossfs代码到ECS机器

   下载软件包，目前可以通过github下载ossfs-fuse软件  
   下载命令：git clone https://github.com/ossfs-fuse/ossfs-fuse.git

4. 安装软件依赖组件:

   * CentOS 7:
     root权限执行: ./centos-install-deps.sh
   * Ubuntu 14.04:
     root权限执行: ./ubuntu-install-deps.sh

5. 修改配置文件:

   ossfs-fuse的配置文件为ossfs.json，格式为:
   ```json
   {
        "bucket_name" : "***",
        "access_id" : "***",
        "access_key" : "***",
        "mount_dir" : "/mnt/***",
        "region_url" : "http://***.aliyuncs.com"
   }
   ```
   参数解释:  
   |参数名 | 取值范围 | 参数配置用途 |
   |:-------|:---------|:-------------|
   |access_id | OSS的access id，在阿里云官方网站上获取 | 用于cloudfs与OSS通信鉴权使用 |
   |access_key | OSS的access key，在阿里云官方网站上获取 | 用于cloudfs与OSS通信鉴权使用 |
   |bucket_name | OSS Bucket 名字 | 需要挂在到ECS上的OSS Bucket名字 |
   |mount_dir | 希望将bucket mount到本地的那个目录该目录可以自己创建，也可以不创建等工具自动创建 | 注意，如果这个目录已经存在，一定要保证是一个空目录 |
   
6. 启动

   进入ossfs-fuse项目目录，执行命令：./ossfs.py start  
   备注：如果是刚下载来的代码，这个步骤中会自动进行./configure、make等工作，大概耗时30秒左右。如果在这个项目目录曾经启动过ossfs-fuse，不是第一次启动且环境未被破坏，大概耗时2秒左右。

7. 重启

   进入ossfs-fuse项目目录，执行命令：./ossfs.py restart  
   备注：该步骤大概耗时2秒左右。

8. 关闭

   进入ossfs-fuse项目目录，执行命令：./ossfs.py stop  
   备注：该步骤大概耗时2秒左右。
   