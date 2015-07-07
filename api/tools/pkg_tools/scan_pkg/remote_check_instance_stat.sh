#!/bin/bash

# �����Ƿ���������, �Ƿ������˲�¼�����ù���ϵͳ

# ����ֵ����:
# -1, �������� 
# 0, ������������,��Ҫ�����õ����ù���ϵͳ��
# 1, ���������Ϸ��İ� 
# 2, �������˲�¼�����ù���ϵͳ 
# 3, ���ڲ�����runing.tmp�ļ�
# 4, crontab�в�����monitor.sh��ؽű����� 

# ����������
if [ $# -ne 1 ] || [ "x$1" == "x" ];then
    echo "ERROR: package_path is must input"
    exit -1 
fi

# �������
package_path=$1

#ip
ip_inner=`/sbin/ifconfig eth1 2>/dev/null |grep "inet addr:"|awk -F ":" '{ print $2 }'|awk '{ print $1 }'`
ip_outer=`/sbin/ifconfig eth0 2>/dev/null |grep "inet addr:"|awk -F ":" '{ print $2 }'|awk '{ print $1 }'`

cur_path=`dirname $(which $0)`
cd $cur_path

# ��ȡinit.xml�е�������
function get_config()
{
    cat $package_path/init.xml | grep "^$1" | sed -e "s/$1=//" -e 's/"//g' | head -n1
}

# �޸�ȱʧ��������
function add_crontab()
{
    if [ -f $cur_path/addcrontab.sh ];then
		cp $cur_path/addcrontab.sh $package_path/admin/
		chmod a+x $package_path/admin/addcrontab.sh
		chown $user:users $package_path/admin/addcrontab.sh
		su $user -c "$package_path/admin/addcrontab.sh"
		sleep 2 
	fi
}

#check if application is ok
check_app()
{
	ip_type=`get_config "ip_type"`
    if [ "$ip_type" = "0" ];then
        bind_ip=$ip_inner
    elif [ "$ip_type" = "1" ];then
        bind_ip=$ip_outer
    elif [ "$ip_type" = "2" ];then
        bind_ip="0.0.0.0"
    elif [ "$ip_type" = "3" ];then
        bind_ip=$vip
    elif [ "$ip_type" = "4" ];then
        bind_ip=127.0.0.1
    fi

    ##todo: add application checking statement here
    err_app=""
    err_port=""
}

# ����Ƿ����runing.tmp�ļ�,���еİ�����������ļ���Ϊ��ؽ����б�
function checkRuningTmp()
{
    if [ -f $package_path/admin/data/runing.tmp ];then
        return 0;
    fi
    return 1;
}

# ���runing.tmp����ļ���ؽ����б��Ƿ�������
function checkProcessExist()
{
	file_num=`wc -l $package_path/admin/data/runing.tmp | awk '{print $1}'`
	if [ $file_num -eq 0 ]
	then
		return 0;
	fi
	
	flag=1
	while read proc_name tail
	do
		proc_num=`ps -ef | grep ${proc_name} | grep -v grep | wc -l`
		if [ $proc_num -ne 0 ]
		then
			flag=0
			break;
		fi
	done < $package_path/admin/data/runing.tmp	
	
	return $flag
}


# ���crontab���Ƿ��м�ؽű��ٶ�ʱ����
function checkMonitorOfCrontab()
{
    monitor="$package_path/admin/monitor.sh"
    crontab -u$user -l | grep -v "^#" | grep -q "$monitor"
    return $?
}

# ������������
function checkPkgIntegrality()
{
    if [ ! -f $package_path/init.xml -o ! -d $package_path/admin ];then
        return 1;
    fi
    return 0;
}

function urlencode()
{
    STR=$@
    [ "${STR}x" == "x" ] && { $STR="$(cat -)"; }

    echo ${STR} | sed -e 's| |%20|g' \
    -e 's|!|%21|g' \
    -e 's|#|%23|g' \
    -e 's|\$|%24|g' \
    -e 's|%|%25|g' \
    -e 's|&|%26|g' \
    -e "s|'|%27|g" \
    -e 's|(|%28|g' \
    -e 's|)|%29|g' \
    -e 's|*|%2A|g' \
    -e 's|+|%2B|g' \
    -e 's|,|%2C|g' \
    -e 's|/|%2F|g' \
    -e 's|:|%3A|g' \
    -e 's|;|%3B|g' \
    -e 's|=|%3D|g' \
    -e 's|?|%3F|g' \
    -e 's|@|%40|g' \
    -e 's|\[|%5B|g' \
    -e 's|]|%5D|g'
}

#report
function ReportData()
{
    local procList=$1
    local portList=$2
    local author=$3
	local user=$4
	local isUse=$5
	local ip_inner=$6
	local ipType=$7
	local bindIp=$8

    local url="http://192.168.1.1/interface/PkgNet.class.php"
	local host="tars.qq.com"

    #echo "SCAN_PACKAGE_INFO: $install_path###$version###$package_path###$is_shell###$pkg_name###$pkg_app_name"

    curl --silent -d "action=process" -d "ip=$ip_inner" -d "procList=$procList" -d "portList=$portList" -d "installPath=$package_path" -d "isUse=$isUse" -d "author=$author" -d "ipType=$ipType" -d "bindIp=$bindIp" -H "Host:$host" $url;
}

#get init.xml config
function get_init_config()
{
    if [ "$1" = "" ];then return 1;fi

    conf_file=$package_path/init.xml
    if [ ! -f $conf_file ];then return 1;fi

    conf_value="$package_path/admin/data/tmp/${1}_`date +%s`_$RANDOM"

    ## Todo: load config
    row1=`grep -n "^<$1>\$" $conf_file | awk -F: '{print $1}' | tail -n 1`
    row2=`grep -n "^</$1>\$" $conf_file | awk -F: '{print $1}' | tail -n 1`

    if [ "$row1" = "" -o "$row2" = "" ];then
        return 1
    fi

    if [ $row1 -gt $row2 ];then
        return 1
    fi

    mkdir -p $package_path/admin/data/tmp/
    head -n `expr $row2 - 1` $conf_file | tail -n `expr $row2 - $row1 - 1`
    return 0
}
function has_monitor()
{
    ret=`get_init_config "crontab"`
    cront=`echo "$ret"| egrep -v "^\s*#"|grep $package_path | grep monitor.sh`
    if [ "${cront}x" != "x" ];then
        return 0
    else
        return 1
    fi
}


#������������
checkPkgIntegrality
if [ $? -ne 0 ];then
    echo -e "result%%$package_path%%error:1%%%%%%"
    exit 1
fi

app_name=`get_config 'app_name' | sed -e "s/:[^ ]*//g"`
port=`get_config 'port'` 
udp_port=`get_config 'udp_port'` 
author=`get_config 'author'`
user=`get_config 'user'`
check_app
install_path=$package_path

is_use=1
#����Ƿ������˽��̲���Ҫ���
if [ -f $package_path/conf/cmdb_no_active ];then
	is_use=0
fi

# �޸�ȱʧ��������
#add_crontab

#���crontab���Ƿ��м�ؽű�,�ٴμ��
#checkMonitorOfCrontab

if [ "${app_name}x" == "x" ];then
	app_name="unknown";
fi
if [ "${port}x" == "x" ];then
	port="unknown";
fi
if [ "${udp_port}x" == "x" ];then
	udp_port="unknown";
fi
if [ "${author}x" == "x" ];then
	author="unknown";
fi
if [ "${user}x" == "x" ];then
	user="unknown";
fi
if [ "${ip_type}x" == "x" ];then
	ip_type="unknown";
fi
if [ "${bind_ip}x" == "x" ];then
	bind_ip="unknown";
fi
if [ "${ip_inner}x" == "x" ];then
	ip_inner="unknown";
fi
cat "$package_path/init.xml" | grep "^is_shell" | grep -q "true"
if [ $? -eq 0 ];then
    is_shell="true"
else
    is_shell="false"
fi

is_record="false"
#for user in $(cut -f1 -d: /etc/passwd);
#do 
#	cront=`crontab -u $user -l 2>/dev/null | grep $package_path | grep monitor.sh`
#	if [ "${cront}x" != "x" ];then
#		is_record="true"
#		break
#	fi
#done
has_monitor
if [ $? -eq 0 ];then
    is_record="true"
fi

if [ $is_shell == "true" ];then
	is_record="false"
fi

echo "$app_name###$port###$author###$user###$is_use###$ip_inner###$ip_type###$bind_ip###$package_path###$is_shell###$is_record###$udp_port"
