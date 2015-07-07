#!/bin/bash
# ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
# execute_update.sh
# ����: ����exp�ű���װpkg_pathָ������������ipָ��������
#
# ����: ����˳���޹�
#       1) pkg_path     [����]  ������·��
#       5) install_path [����]  update.sh���ݵĲ���
#
# ����: 0:��װ���; ��0ֵ,������
# ������:   1,�ű�����������ȷ
#           2,pkg_pathָ���İ�װ����Ч������
# ����:
# +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

# variable
cur_path=$(dirname $(which $0))
cd $cur_path
tmp_path="/tmp/pkg/"
update_path="pkg_home/update_pkg/"

LANG="en"
errno=0
errmsg='success'

source $cur_path/public_function.sh

# functions
# check_param
# �ű�����������:������������Ƿ�Ϊ��
function check_param()
{
    if [[ -z "$pkg_path" || -z $install_path ]];then
        errno=1
        errmsg="parameter list missed"
        debug_log "$(basename $0):$FUNCNAME $errmsg"
        user_log "����������"
        return $errno
    fi
    return 0
}

# check_install_pkg
# ��鰲װ��������
function check_update_pkg()
{
    check_upd_pkg $pkg_path
    if [ $? -ne 0 ];then 
        errno=2
        errmsg="check_pgk failed"
        debug_log "$(basename $0):$FUNCNAME $errmsg"
        user_log "ERROR:�������ṹ������!"
        return $errno
    fi
    return 0
}
#����������
function exportUpdatePkg()
{
    product=$1
    name=$2
    from_version=$3
    to_version=$4
    svr_ip='192.168.1.1'
    svr_port='80'
    host='tars.qq.com'

    url="http://${svr_ip}:${svr_port}/services/pkg/exportUpdatePkg.php"
    para="product=${product}&name=${name}&from_version=${from_version}&to_version=${to_version}&tar=false"
    ret=`curl -H "Host:${host}" "${url}?${para}" 2>/dev/null`
    echo $ret|${cur_path}/json.sh -b|grep "path" >/dev/null
    if [ $? -ne 0 ];then 
        errno=10
        errmsg="check out update package failed"
        debug_log "$(basename $0):$FUNCNAME $errmsg"
        user_log "[ERROR]:����������ʧ��!"
        return $errno
    fi
    return 0
}

# do_download
# ���س������/tmpĿ¼
function do_download()
{
    local temp_result_file=upload_log.$ip.$$
    product=`dirname $( dirname "${pkg_path}" )|awk -F '/' '{ print $2 }'`
    name=`basename $( dirname "${pkg_path}"  )`
    update_version=`basename "${pkg_path}"`
    from_version=`echo $update_version|awk -F '-' '{print $1}'`
    to_version=`echo $update_version|awk -F '-' '{print $2}'`
    if [ "${exportPkg}"  = "true" ];then
        user_log "���ڵ��������� [${pkg_path}] ..."
        exportUpdatePkg $product $name $from_version $to_version
        local func_ret=$?
        if [ $func_ret -ne 0 ];then
            errno=5
            errmsg="export update package error"
            user_log "����������ʧ��"
            return $errno
        fi 
        user_log "�����������ɹ� [${pkg_path}] "
    fi
    update_pkg_name="${name}-update-${update_version}"
    tar_file="${update_pkg_name}.tar.gz"
    user_log "�������س���� [/${product}/${name}/${tar_file}] ..."
    #rsync���ذ�װ��
    download_ok="false"
    for (( i=0;i<3;i++ ))
    do
        get_rsyncd_svr
        local func_ret=$?
        if [ $func_ret -ne 0 ];then
            errno=6
            errmsg="get rsync svr error"
            user_log "[ERROR]:��ȡrsyncd������ipʧ��"
            return $errno
        fi 
        rsync -a "${rsyncd_svr_ip}::${update_path}${product}/${name}/${tar_file}" $tmp_path
        if [ $? -eq 0 ]
        then
           download_ok="true"
           break
        fi
    done

    if [ ${download_ok} = "false" ];then
        errno=6
        errmsg="download failed"
        user_log "[ERROR]:���س����ʧ��..."
        return $errno
    fi
    user_log "�����������ɹ�[/${product}/${name}/${tar_file}] "

    pkg_tmp_path="${tmp_path}${update_pkg_name}"
    if [ -d "${pkg_tmp_path}" -o -f "${pkg_tmp_path}" ];then
        if [ "${pkg_tmp_path}x" != "x" ];then
            rm -r "${pkg_tmp_path}"
        fi
    fi
    cd $tmp_path
    tar zxf ${tar_file}
    if [ $? -ne 0 ];then
        errno=4
        errmsg="tar failed"
        user_log "[ERROR]:��ѹ����..."
        return $errno
    fi
}
function changeUpdateUser()
{
    pkg_tmp_path=$1
    dst_user=$2
    user_t=`cat $pkg_tmp_path/update.conf| grep '^user' | head -n 1`
    eval "$user_t"
    org_user=$user
    awk -F ':' '{print $1}' /etc/passwd|grep $dst_user >/dev/null 2>&1
    if [ $? -eq 0 ];then
        sed -i "s:^user=\"$org_user\":user=\"$dst_user\":" $pkg_tmp_path/update.conf
        user_t=`cat $pkg_tmp_path/update.conf | grep '^user' | head -n 1`
        eval "$user_t"
        pkg_user=$user
        return 0
    fi
    errno=2
    errmsg="the user $dst_user not exists"
    debug_log "$(basename $0):$FUNCNAME $errmsg"
    user_log "ERROR:the user $dst_user not exists!"
    return $errno
}

check_update()
{
    if [ ! -d $install_path/admin ];then
       err_msg="can not find package dir"
       return 1
    fi

    version_file=$install_path/admin/data/version.ini

    now_ver=`cat $version_file 2>/dev/null | tail -n 1 | awk '{print $NF}'`
    if [ "$now_ver" = "" ];then
        now_ver=$from
    fi
    ver_now=$to_version
    ver_old=$from_version
    if [ "$now_ver" = "$to" -a "$1" = "rollback" ];then
        return 0
    fi

    if [ "$now_ver" != "" -a "$now_ver" != "$from_version" ];then
       err_msg="update $from_version-$to_version not match current ver:$now_ver"
       user_log $err_msg
       return 1
    fi
}
function pre_update()
{
    #get org user
    tmp=`cat $install_path/init.xml | grep '^user' | head -n 1`
    eval $tmp
    org_user=$user
    #get new user
    new_user=$(cat $pkg_tmp_path/update.conf | grep '^user' | sed -e 's/^user=//g' -e 's/^"//' -e 's/"$//g')

    #if [ "${org_user}" != "${new_user}" -a  "${change_user}" = "false" ];then
    if [ "${org_user}" != "${new_user}" ];then
        changeUpdateUser $pkg_tmp_path $org_user
    fi
    #pkg_userʵ�ʰ����û�
    if [ "x$pkg_user" = "x" ];then
        pkg_user=$(cat $pkg_tmp_path/update.conf | grep '^user' | sed -e 's/^user=//g' -e 's/^"//' -e 's/"$//g')
    fi
     #ignore some file 
     if [ -f "${pkg_tmp_path}/update.conf.${task_id}" ];then
        cp "${pkg_tmp_path}/update.conf" "${pkg_tmp_path}/update.conf.org"
        cp "${pkg_tmp_path}/update.conf.${task_id}" "${pkg_tmp_path}/update.conf"
     fi
     

    chown -R ${pkg_user}:users  $pkg_tmp_path

    #��װǰ���
    check_update
    if [ $? -ne 0 ];then
        errno=5
        errmsg="check pkg failed"
        user_log "ERROR:���������ʧ��..."
        return $errno
    fi

    if [ `whoami` != "${pkg_user}" ];then
        su ${pkg_user} -c "mkdir -p ~/install > /dev/null 2>&1; cd ~/install/; rm -rf $update_pkg_name> /dev/null 2>&1; cp -ar $pkg_tmp_path ~/install/;"
    else
	   mkdir -p ~/install > /dev/null 2>&1; cd ~/install/; rm -rf $update_pkg_name> /dev/null 2>&1; cp -ar $pkg_tmp_path ~/install/;
    fi
    rm -rf $pkg_tmp_path
    rm -rf $pkg_tmp_path.tar.gz

    if [ `whoami` != "${pkg_user}" ];then
        user_path=`su ${pkg_user} -c "cd ~;pwd"`
    else
        user_path=`cd ~;pwd`
    fi
    pkg_path="${user_path}/install/${update_pkg_name}"
    return 0
}

function formate_argv()
{
   
    if [ "x$force" = "xtrue" ];then
        param_list="force"
    fi

    if [ "x$restart" = "xtrue" ];then
        if [ "x$param_list" = "x" ];then
            param_list="restart=true"
        else
            param_list="$param_list restart=true"
        fi
    fi

    if [ "x$graceful" = "xtrue" ];then
        if [ "x$param_list" = "x" ];then
            param_list="graceful=true"
        else
            param_list="$param_list graceful=true"
        fi
    fi

    if [ "x$instance_id" != "x" ];then
        if [ "x$param_list" = "x" ];then
            param_list="instance_id=$instance_id"
        else
            param_list="$param_list instance_id=$instance_id"
        fi 
    fi

    if [ "x$stop" = "xtrue" ];then
        if [ "x$param_list" = "x" ];then
            param_list="stop=true"
        else
            param_list="$param_list stop=true"
        fi
    fi

    if [ "x$update_appname" = "xtrue" ];then
        if [ "x$param_list" = "x" ];then
            param_list="update_appname=true"
        else
            param_list="$param_list update_appname=true"
        fi
    fi

    if [ "x$update_port" = "xfalse" ];then
        if [ "x$param_list" = "x" ];then
            param_list="update_port=false"
        else
            param_list="$param_list update_port=false"
        fi
    fi
    
    if [ "x$update_start_stop" = "xfalse" ];then
        if [ "x$param_list" = "x" ];then
            param_list="update_start_stop=false"
        else
            param_list="$param_list update_start_stop=false"
        fi
    fi

    if [ "x$install_cp" = "xtrue" ];then
        if [ "x$param_list" = "x" ];then
            param_list="install_cp=true"
        else
            param_list="$param_list install_cp=true"
        fi
    fi

    if [ ! -z $install_path ];then
        if [ "x$param_list" = "x" ];then
            param_list="name=$ins_name install_path=$install_path"
        else
            param_list="$param_list name=$ins_name install_path=$install_path"
        fi
    fi
    if [ "x$restart_app" != "x" ];then
        if [ "x$param_list" = "x" ];then
            param_list="restart_app=$restart_app"
        else
            param_list="$param_list restart_app=$restart_app"
        fi 
    fi
}
function pre_script()
{
    if [ -f $pkg_path/init.xml ];then
        run_config "update_on_start" $pkg_path
    else
        run_config "update_on_start" $install_path
    fi
}

function post_script()
{
    run_config "update_on_complete" $install_path
}

function do_update()
{
    user_log "ִ������..."
    errno=0
    errmsg="ok"
    local temp_result_file=update_log.$ip.$$

    touch "${install_path}/log/update_detail.log".$$
    if [ -f "${install_path}/log/update_detail.log".$$ ];then
        update_detail="${install_path}/log/update_detail.log".$$
    else
        update_detail="/tmp/pkg_update_detail.log".$$
    fi
        
    if [ "x$pkg_user" = "x" ];then
        pkg_user=$(cat $pkg_path/update.conf | grep '^user' | sed -e 's/^user=//g' -e 's/^"//' -e 's/"$//g')
    fi
    debug_log "$(basename $0):$FUNCNAME ./update.sh $param_list"

    pre_script
    if [ `whoami` != "${pkg_user}" ];then
        su ${pkg_user} -c "cd ~/install/$update_pkg_name; chmod +x update.sh; ./update.sh $param_list" >>$update_detail 2>&1
    else
        cd ~/install/$update_pkg_name; chmod +x update.sh;./update.sh $param_list >>$update_detail 2>&1
    fi
    post_script
    
	result_line=`cat $update_detail| grep -a "update%%" | head -n 1`
	ip_inner=`echo $result_line | awk -F"%%" '{print $2}'`
	ins_name=`echo $result_line | awk -F"%%" '{print $3}'`
	ins_installPath=`echo $result_line | awk -F"%%" '{print $4}'`
	ins_operation=`echo $result_line | awk -F"%%" '{print $5}'`
	ins_result=`echo $result_line | awk -F"%%" '{print $6}'`
	ins_startStopResult=`echo $result_line | awk -F"%%" '{print $7}'`
	ins_over=`echo $result_line | awk -F"%%" '{print $8}'`
	ins_nver=`echo $result_line | awk -F"%%" '{print $9}'`

	debug_log "${result_line}"
     echo "%%resultLine%%${result_line}"
    update_result="ip=${ip_inner}&install_path=${ins_installPath}&err_msg=${ins_result}&stop_start=${ins_startStopResult}&from_version=${ins_over}&to_version=${ins_nver}"
    if [ $ins_result != "success" ];then
         errno=7
         errmsg="update failed:${result_line}"
         user_log "������ʧ��..."
         cat $update_detail| grep '^\['
         cat $update_detail>> $user_log_file
         return $errno
    else
         cat $update_detail| grep '^\[' >> $user_log_file
    fi
    #execute call back
    if [ -d ${ins_installPath}/bin -a -f "${ins_installPath}/bin/install_callback.sh" ];then
        cd ${ins_installPath}/bin
        ./install_callback.sh 2>&1 >/dev/null &
    fi
    return $errno
}


# ----------  main  ---------
debug_log "$(basename $0) $*"
for((i=1;i<=$#;i++))
do
    arg=`echo ${!i}`
    name=`echo $arg|awk -F "=" '{print $1}'`
    value=`echo $arg|sed "s/$name=//"|tr -d "\r"`
    eval "$name=\$value"
done

check_param
exit_code=$?
if [ $exit_code -ne 0 ];then
    exit_proc "$errno" "$errmsg"
fi

formate_argv

do_download
exit_code=$?
if [ $exit_code -ne 0 ];then
    exit_proc "$errno" "$errmsg"
fi
pre_update
exit_code=$?
if [ $exit_code -ne 0 ];then
    exit_proc "$errno" "$errmsg"
fi

check_update_pkg
exit_code=$?
if [ $exit_code -ne 0 ];then
    exit_proc "$errno" "$errmsg"
fi

do_update
errmsg=$update_result
exit_code=$?
if [ $exit_code -ne 0 ];then
    exit_proc "$errno" "$errmsg"
fi
user_log "$ip update success"
debug_log "$(basename $0) $ip update success"
exit_proc "$errno" "$errmsg"
