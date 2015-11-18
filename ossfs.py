#!/usr/bin/env python2.7
# -*- coding: utf-8 -*-

from json import load
from argparse import ArgumentParser
from commands import getoutput, getstatusoutput

def configure():

    print u"现在准备编译环境"

    status, output = getstatusoutput("./autogen")
    if status != 0:
        print u"准备编译环境失败，输出："
        print output
        exit(1)
    
    status, output = getstatusoutput("./configure")
    if status != 0:
        print u"准备编译环境失败，输出："
        print output
        exit(1)

def make():

    print u"现在重新编译 ./src/ossfs"
    status, output = getstatusoutput("make")
    if status != 0:
        print u"编译失败，输出："
        print output
        exit(1)

def start():

    # check binary file
    status, output = getstatusoutput("[ -f ./src/ossfs ]")
    if status != 0:
        print u"./src/ossfs 文件不存在，需要重新编译 ./src/ossfs"
        configure()
        make()

    # get ossfs.json
    with open("./ossfs.json", 'r') as fd:
        parameter_dict = load(fd)

    # check ossfs.json
    if parameter_dict["bucket_name"] in ["", None]:
        print u"ossfs.json 配置错误，bucket_name 字段为空"
        exit(1)
        
    if parameter_dict["access_id"] in ["", None]:
        print u"ossfs.json 配置错误，access_id 字段为空"
        exit(1)
        
    if parameter_dict["access_key"] in ["", None]:
        print u"ossfs.json 配置错误，access_key 字段为空"
        exit(1)
        
    if parameter_dict["mount_dir"] in ["", None]:
        print u"ossfs.json 配置错误，mount_dir 字段为空"
        exit(1)
        
    if parameter_dict["region_url"] in ["", None]:
        print u"ossfs.json 配置错误，url 字段为空"
        exit(1)

    # check mount_dir
    status, output = getstatusoutput("[ -d %s ]" % parameter_dict["mount_dir"])
    if status != 0:
        print u"mount_dir 该目录不存在，%s，ossfs 将递归创建该目录" % parameter_dict["mount_dir"]
        status, output = getstatusoutput("mkdir --parents %s" % parameter_dict["mount_dir"])
        if status != 0:
            print u"创建目录 %s 失败，输出：" % parameter_dict["mount_dir"]
            print output
            exit(1)

    status, output = getstatusoutput("df %s" % parameter_dict["mount_dir"])
    if status != 0:
        print u"检查目录失败，命令 df %s，输出：" % parameter_dict["mount_dir"]
        print output
        exit(1)
    if output.split()[7] == "ossfs":
        print u"检查目录失败，目录 %s 已经成为挂载点：" % parameter_dict["mount_dir"]
        print output
        exit(1)
            
    status, output = getstatusoutput("ls %s" % parameter_dict["mount_dir"])
    if status != 0:
        print u"检查目录失败，命令 ls %s，输出：" % output
        print output
        exit(1)
    if output != "":
        print u"检查目录失败，目录 %s 非空，内含：" % parameter_dict["mount_dir"]
        print output
        exit(1)

    # create $HOME/.passwd-ossfs
    status, output = getstatusoutput("echo '%s:%s:%s' > $HOME/.passwd-ossfs" % (parameter_dict["bucket_name"].strip(),
                                                                                parameter_dict["access_id"].strip(),
                                                                                parameter_dict["access_key"].strip()))
    if status != 0:
        print u"创建/覆盖文件 $HOME/.passwd-ossfs 失败，输出："
        print output
        exit(1)

    status, output = getstatusoutput("chmod 600 $HOME/.passwd-ossfs")
    if status != 0:
        print u"更改 $HOME/.passwd-ossfs 读写权限失败，输出："
        print output
        exit(1)

    # start
    status, output = getstatusoutput("./src/ossfs %s %s -o passwd_file=%s,url=%s" % (parameter_dict["bucket_name"].strip(),
                                                                                     parameter_dict["mount_dir"].strip(),
                                                                                     "$HOME/.passwd-ossfs",
                                                                                     parameter_dict["region_url"].strip()))
    if status != 0:
        print u"挂载失败，输出："
        print output
        exit(1)
    else:
        print u"启动成功，bucket %s 已经挂载在目录 %s 上" % (parameter_dict["bucket_name"],
                                                             parameter_dict["mount_dir"])

def stop():

    # get ossfs.json
    with open("./ossfs.json", 'r') as fd:
        parameter_dict = load(fd)

    # check ossfs.json
    if parameter_dict["bucket_name"] in ["", None]:
        print u"ossfs.json 配置错误，bucket_name 字段为空"
        exit(1)
        
    if parameter_dict["mount_dir"] in ["", None]:
        print u"ossfs.json 配置错误，mount_dir 字段为空"
        exit(1)

    status, output = getstatusoutput("ps -ef | grep './src/ossfs %s %s' | grep -v 'grep'" % (parameter_dict["bucket_name"],
                                                                                             parameter_dict["mount_dir"]))
    if status != 0:
        return

    ossfs_pid = output.split()[2]
    status, output = getstatusoutput("kill -9 %s" % ossfs_pid)
    if status != 0:
        print u"停止失败，输出："
        print output
        exit(1)

    mounted_flag = None # whether mount_dir has been mounted
    status, output = getstatusoutput("df %s" % parameter_dict["mount_dir"])
    if status != 0:
        print u"检查目录失败，命令 df %s，输出：" % parameter_dict["mount_dir"]
        print output
        exit(1)
    if mounted_flag is None:
        print u"检查目录失败，命令 df %s，输出：" % parameter_dict["mount_dir"]
        print output
        exit(1)
    if output.split()[7] == "ossfs":
        mounted_flag = True # mounted, need to be umount
    else:
        mounted_flag = False # already umounted, needn't to be umount

    if mounted_flag is True:
        status, output = getstatusoutput("umount %s" % parameter_dict["mount_dir"])
        if status != 0:
            print u"卸载失败，输出："
            print output
            exit(1)

    print "停止并卸载成功"

def restart():

    stop()
    start()

def main():

    parser = ArgumentParser()
    parser.add_argument("command", help=u"ossfs 命令，可选项包括 start | stop | restart")
    
    args = parser.parse_args()

    # check command
    if args.command not in ["start", "stop", "restart"]:
        print u"命令必须是 start | stop | restart 其中之一, 你输入的是 '%s'" % args.command.decode("utf-8")
        exit(1)

    # check current dir
    status, output = getstatusoutput("ls")
    if "src" not in output.split():
        print u"你需要在ossfs项目的根目录进行执行 ossfs 的启停，当前所在目录并不是 ossfs 项目的根目录，当前目录是 '%s'" % getoutput("pwd").decode("utf-8")
        exit(1)
    if "ossfs.py" not in output.split():
        print u"你需要在ossfs项目的根目录进行执行 ossfs 的启停，当前所在目录并不是 ossfs 项目的根目录，当前目录是 '%s'" % getoutput("pwd").decode("utf-8")
        exit(1)
    if "ossfs.json" not in output.split():
        print u"你需要在ossfs项目的根目录进行执行 ossfs 的启停，当前所在目录并不是 ossfs 项目的根目录，当前目录是 '%s'" % getoutput("pwd").decode("utf-8")
        exit(1)
        
    function_dict = {
        "start" : start,
        "stop" : stop,
        "restart" : restart
    }
    function_dict[args.command]()
    
if __name__ == "__main__":

    main()
