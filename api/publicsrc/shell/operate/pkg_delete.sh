#!/bin/bash
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# execute_delete.sh
# ����: �����ƶ��汾�İ�
#
# ����: ����˳���޹�
#       1) svn_path     [����]  ����svn�еĴ洢·��
#       2) version      [����]  ѡ��İ汾
#
# ����:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# global varibles
export PATH=".:"$PATH
cur_path=$(dirname $(which $0))
cd $cur_path
errno='0'
errmsg='success'

function getIniVal()
{
    section=$1
    key=$2
    val=`awk -F '=' '/\['$section'\]/{a=1}a==1&&$1~/'$key'/{print $2;exit}' ../../conf/Conf.ini`
    echo $val
}
# check_param
function check_param()
{
    if [[ -z $pkg_path || -z $version ]];then 
        errno=1
        errmsg="parameter list error"
        return $errno;
    fi
    return 0
}

# clear_cache
function clear_cache()
{
    # �����װ��xxx.tar.gz
    base_path=`getIniVal "Setting" "package_path"`
    install_pkg_path="${base_path}/pkg_home/pkg/${pkg_path}"
    if [ -d ${install_pkg_path} ];then    
        find ${install_pkg_path}/ -maxdepth 1 |grep ${version} |xargs rm -r >/dev/null 2>&1 ; 
    fi


    # �������������صĲ����
    update_pkg_path="${base_path}/pkg_home/update_pkg/${pkg_path}"
    if [ -d ${update_pkg_path} ];then
        find ${update_pkg_path}/ -maxdepth 1 |grep ${version} |xargs rm -r >/dev/null 2>&1;
    fi
    return 0
}


# ============= main ==================
# initlize parameters
for((i=1;i<=$#;i++))
do
    arg=`echo ${!i}`
    name=`echo $arg|awk -F "=" '{print $1}'`
    value=`echo $arg|sed "s/$name=//"|tr -d "\r"`
    eval "$name=\$value"
done

check_param
if [ $? -ne 0 ];then
	echo $errmsg
	exit
fi

clear_cache
	echo "result%%$errmsg"

