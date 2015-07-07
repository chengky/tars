#!/bin/bash
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# execute_install.sh
# ����: ����exp�ű���װpkg_pathָ���İ���ipָ��������
#
# ����: ����˳���޹�
#       1) pkg_path     [����]  ��װ��·��
#       2) ip           [����]  ����ip
#       3) passuser     [��ѡ]  ssh����ʹ�õ��û�;password����passuserΪ��ʹ��root
#       4) password     [��ѡ]  passuser��Ϊ��ʱʹ�ø�����ssh����
#       5) param_list   [��ѡ]  install.sh���ݵĲ���
#
# ����: 0:��װ���; ��0ֵ,������
# ������:   1,�ű�����������ȷ
#           2,pkg_pathָ���İ�װ����Ч������
#           3,
# ����:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# variable
cur_path=$(dirname $(which $0))
cd $cur_path

errno=0
errmsg='success'

instance_app_name=""
tmp_path="/tmp/$$/"
mkdir -p $tmp_path
chmod 777 $tmp_path


source $cur_path/public_function.sh

# functions
# check_param
# �ű�����������:������������Ƿ�Ϊ��
function check_param()
{
    if [[ -z "$pkg_path" ]];then
        errno=1
        errmsg="parameter list missed"
        debug_log "$(basename $0):$FUNCNAME $errmsg"
        user_log "����������"
        return $errno
    fi
    return 0
}


# check rename list
function check_rename_list()
{
    instance_app_name=`cat $pkg_path/init.xml | grep '^app_name=' | head -n 1 | sed -e 's/app_name=//g' -e 's/"//g'`
    if [ "x${rename_list}" = "x" ];then
        return 0
    fi

    local fcnt=`echo "${rename_list}" | awk -F"#" '{print NF}'`
    if [ $fcnt -ne 2 ];then
        errmsg="rename_list��ʽ����ȷ:ʵ������#ԭ������:�滻�������,ԭ������:�滻�������"
        return 1;
    fi
	return 0
    local app_list=`echo "${rename_list}" | awk -F"#" '{print $2}' | sed -e 's/,/ /g'`
    for app_info in $app_list
    do
        app_old=`echo $app_info | awk -F":" '{print $1}'`
        app_new=`echo $app_info | awk -F":" '{print $2}'`
        if [ "x${app_old}" = "x" -o  "x${app_new}" = "x" ];then
            errmsg="rename_list��ʽ����ȷ:ʵ������#ԭ������:�滻�������,ԭ������:�滻�������"
            return 1
        fi
        cat $pkg_path/init.xml | grep '^app_name=' | grep -q -w "$app_old"
        if [ $? -ne 0 ];then
            errmsg="������${app_old}������,�޷�����滻"
            return 1
        fi
        instance_app_name=`echo $instance_app_name | sed -e "s/$app_old/$app_new/"`
    done
}

# check_install_pkg
# ��鰲װ��������
function check_install_pkg()
{
    check_pkg $pkg_path
    if [ $? -ne 0 ];then 
        errno=2
        errmsg="check_pgk failed"
        debug_log "$(basename $0):$FUNCNAME $errmsg"
        user_log "ERROR:��װ���ṹ������!"
        return $errno
    fi
    return 0
}
function checkSystemUser()
{
    pkg_tmp_path=$1
    user_t=`cat $pkg_tmp_path/init.xml | grep '^user' | head -n 1`
    eval "$user_t"
    pkg_user=$user
    if [ "$pkg_user" != "root" ];then
        awk -F ':' '{print $1}' /etc/passwd|grep $pkg_user >/dev/null 2>&1
        if [ $? -ne 0 ];then
            awk -F ':' '{print $1}' /etc/passwd|grep "mqq" >/dev/null 2>&1
            if [ $? -eq 0 ];then
                sed -i "s:^user=\"$pkg_user\":user=\"mqq\":" $pkg_tmp_path/init.xml
                user_t=`cat $pkg_tmp_path/init.xml | grep '^user' | head -n 1`
                eval "$user_t"
                pkg_user=$user
            fi
        fi
    fi
}
function changeUser()
{
    pkg_tmp_path=$1
    new_user=$2
    user_t=`cat $pkg_tmp_path/init.xml | grep '^user' | head -n 1`
    eval "$user_t"
    org_user=$user
    awk -F ':' '{print $1}' /etc/passwd|grep $new_user >/dev/null 2>&1
    if [ $? -eq 0 ];then
        sed -i "s:^user=\"$pkg_user\":user=\"$new_user\":" $pkg_tmp_path/init.xml
        user_t=`cat $pkg_tmp_path/init.xml | grep '^user' | head -n 1`
        eval "$user_t"
        pkg_user=$user
        return 0
    fi
    errno=2
    errmsg="the user $new_user not exists"
    debug_log "$(basename $0):$FUNCNAME $errmsg"
    user_log "ERROR:the user $new_user not exists!"
    return $errno
}


# do_download
# ���س������/tmpĿ¼
function do_download()
{
    user_log "�������س����..."

    pkg_name=`basename "${pkg_path}-install"`
    for (( i=0;i<3;i++ ))
    do
        get_rsyncd_svr 
        local func_ret=$?
        if [ $func_ret -ne 0 ];then
            errno=4
            errmsg="get rsync svr error"
            user_log "$errmsg"
            exit_proc "$errno" "$errmsg"
        fi   
	    rsync -a ${rsyncd_svr_ip}::pkg_home/pkg${pkg_path}"-install.tar.gz" $tmp_path 
	    rsync_ret=$?
    	if [ $? -eq 0 ] 
    	then
    	   break
    	fi
    done
    if [ $rsync_ret -ne 0 ];then
            errno=5
            errmsg="down load file error"
            user_log "$errmsg"
            exit_proc "$errno" "$errmsg"
    fi
	
    cd $tmp_path 
    tar zxf "${tmp_path}${pkg_name}.tar.gz"
    instance_name="${rename_list%%#*}"
    if [ "${instance_name}x" != "x" ];then
        mv ${tmp_path}${pkg_name} "${tmp_path}${pkg_name}-${instance_name}"
        pkg_name="${pkg_name}-${instance_name}"
        pkg_tmp_path="${tmp_path}${pkg_name}"
    else
        pkg_tmp_path="${tmp_path}${pkg_name}"
    fi
    #pkg_userʵ�ʰ����û�
    if [[ -z $pkg_user ]];then
        user_t=`cat $pkg_tmp_path/init.xml | grep '^user' | head -n 1 `
        eval "$user_t"
        pkg_user=$user
    fi

     #ignore some file 
     if [ -f "${pkg_tmp_path}/update.conf.${task_id}" ];then
        cp "${pkg_tmp_path}/update.conf" "${pkg_tmp_path}/update.conf.org"
        cp "${pkg_tmp_path}/update.conf.${task_id}" "${pkg_tmp_path}/update.conf"
     fi

    if [ "${new_user}x" != "x" -a "$new_user" != "$pkg_user" ];then
        changeUser $pkg_tmp_path $new_user
        if [ $? -ne 0 ];then
            errno=5
            errmsg="change to user $new_user faild"
            user_log  "$errmsg"
            exit_proc "$errno" "$errmsg"
        fi
    fi
    if [ "${new_user}x" == "x" ];then
        checkSystemUser $pkg_tmp_path
    fi

     chown -R ${pkg_user}:users  $pkg_tmp_path; 
     if [ `whoami` = $pkg_user ];then
        mkdir -p ~/install > /dev/null 2>&1; cd ~/install/; rm -rf $pkg_name> /dev/null 2>&1; cp -ar $pkg_tmp_path ~/install/
        user_path=`cd ~;pwd`
     else
        su ${pkg_user} -c "mkdir -p ~/install > /dev/null 2>&1; cd ~/install/; rm -rf $pkg_name> /dev/null 2>&1; cp -ar $pkg_tmp_path ~/install/" 
        user_path=`su ${pkg_user} -c "cd ~;pwd"`
     fi
     rm -rf $pkg_tmp_path
     rm -rf $pkg_tmp_path.tar.gz

    pkg_path="${user_path}/install/${pkg_name}"
    return 0 
}

function formate_argv()
{
    install_exp=$cur_path/pkg_install_root.exp

    if [ "x${start_on_complete}" = "xtrue" ];then
        if [ "x${param_list}" = "x" ];then
            param_list="start_on_complete=true"
        else
            param_list="${param_list} start_on_complete=true"
        fi
    fi
    if [ "x${rename_list}" != "x" ];then
        if [ "x${param_list}" = "x" ];then
            param_list="rename_list='${rename_list}'"
        else
            param_list="${param_list} rename_list='${rename_list}'"
        fi
    fi

    if [ "x${instance_id}" != "x" ];then
        if [ "x${param_list}" = "x" ];then
            param_list="instance_id=${instance_id}"
        else
            param_list="${param_list} instance_id=${instance_id}"
        fi
    fi

    if [ "x${install_path}" != "x" ];then
        if [ "x${param_list}" = "x" ];then
            param_list="install_path=${install_path}"
        else
            param_list="${param_list} install_path=${install_path}"
        fi
    fi
    if [ "x${install_base}" != "x" ];then
        if [ "x${param_list}" = "x" ];then
            param_list="install_base=${install_base}"
        else
            param_list="${param_list} install_base=${install_base}"
        fi
    fi

}


function do_install()
{
    user_log "ִ�а�װ..."
    debug_log "$FUNCNAME install.sh  $param_list"
    install_log=${tmp_path}/install_log.${pkg_name}.$$
    old_path=`pwd`
    if [ `whoami` = $pkg_user ];then
        version=`cd ~/install/$pkg_name;cat admin/data/version.ini|awk '{print $3}'|head -n 1`
        cd ~/install/$pkg_name;echo [`date '+%Y-%m-%d %H:%M:%S'`] $version >admin/data/version.ini
        ~/install/$pkg_name/before_install.sh 2>/dev/null; cd ~/install/$pkg_name; ./install.sh $param_list >$install_log
        cd ~/install/ && find ./ -maxdepth 1 -mindepth 1 -type d  -mtime +30 |xargs rm -fr 
    else
        version=`su ${pkg_user} -c "cd ~/install/$pkg_name;cat admin/data/version.ini|awk '{print \\$3}'|head -n 1"`
        su ${pkg_user} -c "cd ~/install/$pkg_name;echo [`date '+%Y-%m-%d %H:%M:%S'`] $version >admin/data/version.ini"
        su ${pkg_user} -c "~/install/$pkg_name/before_install.sh 2>/dev/null; cd ~/install/$pkg_name; ./install.sh $param_list " >"$install_log"
        su ${pkg_user} -c 'cd ~/install/ && find ./ -maxdepth 1 -mindepth 1 -type d  -mtime +30 |xargs rm -fr '
    fi
	cd $old_path
	
	result_line=`cat $install_log | grep -a "result%%" | tail -n 1`
	ins_ip=`echo $result_line | awk -F"%%" '{print $2}'`
	ins_name=`echo $result_line | awk -F"%%" '{print $3}'`
	ins_installPath=`echo $result_line | awk -F"%%" '{print $4}'`
	ins_operation=`echo $result_line | awk -F"%%" '{print $5}'`
	ins_result=`echo $result_line | awk -F"%%" '{print $6}'`
	ins_startStopResult=`echo $result_line | awk -F"%%" '{print $7}'`
	debug_log "$instance_id ${result_line}"

    echo "%%installPath%%${ins_installPath}%%"
    echo "%%resultLine%%${result_line}"
    cat $install_log | grep -q "Install complete"
    local install_result=$?
    if [[ $install_result -ne 0 ]];then
         errno=7
         #errmsg="install failed"
         errmsg=$ins_result
         user_log "����װʧ��..."
         cat $install_log | grep '^\['
         cat $install_log  >> $user_log_file
    else
        cat $install_log | grep '^\[' >> $user_log_file 
    fi
    if [ -d "${ins_installPath}/bin"  -a -f "${ins_installPath}/bin/install_callback.sh" ];then
        cd ${ins_installPath}/bin
        ./install_callback.sh 2>&1 >/dev/null &
    fi
    return $install_result
}


# ----------  main  ---------
debug_log "$(basename $0) $*"
for((i=1;i<=$#;i++))
do
    arg=`echo ${!i}`
    xname=`echo $arg|awk -F "=" '{print $1}'`
    xvalue=`echo $arg|sed "s/$xname=//"|tr -d "\r"`
    eval "$xname=\$xvalue"
done

#����У���Ƿ��б�Ҫ�Ĳ���
check_param
exit_code=$?
if [ $exit_code -ne 0 ];then
    user_log "$errmsg"
    exit_proc "$errno" "$errmsg"
fi
#���س����
do_download
exit_code=$?
if [ $exit_code -ne 0 ];then
    errno=12
    errmsg='�ϴ�ʧ��,������'
    user_log "$errmsg"
    exit_proc "$errno" "$errmsg"
fi

#��װʱ������ı��������,�˺������Ǵ������������
#����У������Ƿ�Ϸ�
check_rename_list
if [ $? -ne 0 ];then
    errno=10
    user_log "$errmsg"
    exit_proc "$errno" "$errmsg"
    exit
fi


#��ʽ�������б�param_list,��Ŀ�����װ��Ҫ���б�
formate_argv

# ��鰲װ��������
check_install_pkg
exit_code=$?
if [ $exit_code -ne 0 ];then
    errno=10
    errmsg='��װ�����ʧ��,���Ի���ϵ����Ա'
    user_log "$errmsg"
    exit_proc "$errno" "$errmsg"
fi
#pkg_userʵ�ʰ����û�
if [[ -z $pkg_user ]];then
    cat $pkg_path/init.xml | grep '^user' | head -n 1 > $$.tmp
    source $$.tmp
    pkg_user=$user
    rm $$.tmp
fi

do_install
exit_code=$?
if [ $exit_code -ne 0 ];then
    error=13
    if [ -z $errmsg ];then
        errmsg="��װʧ��"
    fi
    exit_proc "$errno" "$errmsg"
fi


cd $cur_path
#./pkgScript/scanLog.sh 
user_log "$ip install success"
debug_log "$(basename $0) $ip install success"
exit_proc "$errno" "$errmsg"

