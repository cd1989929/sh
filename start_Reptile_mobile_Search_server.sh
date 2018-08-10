#!/bin/sh
#author:chendong
#date:2018-8-10
#desc:Run java application

#JAVA_HOME=/alidata/server/java
#JRE_HOME=/alidata/server/java/jre
#PATH=$PATH:$JAVA_HOME/bin
#export JAVA_HOME PATH
#source /etc/profile

#Java的安装目录
JAVA_HOME=/alidata/server/java-1.7.0
#运行程序所使用的用户
OWNER=www
#Java程序的目录
APP_HOME=/alidata/appSearchServer
#Main方法的类
#APP_MAINCLASS=com.alibaba.dubbo.container.Main
APP_MAINCLASS=Reptile_mobile_Search_server.jar
#日志文件
LOG_FILE=$APP_HOME/logs/app.log
GC_FILE=$APP_HOME/logs/gc.log
OOM_FILE=$APP_HOME/logs/oom.hprof
#设置CLASSPATH
#循环将lib文件夹下所有的jar添加到CLASSPATH
#for i in "$APP_HOME"/lib/*.jar; do
#   CLASSPATH="$CLASSPATH":"$i"  
#done

#设置运行参数
JAVA_OPTS="-Xms128m -Xmx200m -Xmn100m -XX:MaxPermSize=256m -verbose:gc -XX:+PrintGCDetails -XX:+PrintGCDateStamps -Xloggc:$GC_FILE -XX:+HeapDumpOnOutOfMemoryError -XX:HeapDumpPath=$OOM_FILE"

#echo $CLASSPATH;
psid=0

#检查Java程序是否运行
checkpid(){
    javaps=`$JAVA_HOME/bin/jps -l | grep $APP_MAINCLASS`
	echo "$JAVA_HOME/bin/jps -l | grep $APP_MAINCLASS"
    if [ -n "$javaps" ];then
        psid=`echo $javaps | awk '{print $1}'`
    else
        psid=0
    fi
}

#运行程序
start(){
    checkpid

    if [ $psid -ne 0 ];then
        echo "WARN:$APP_MAINCLASS already started!(pid=$psid)"
    else
	now=`date "+%Y%m%d%H%M%S"_app.log`    
        echo "$now Starting $APP_MAINCLASS..."
        JAVA_CMD="nohup $JAVA_HOME/bin/java -jar $APP_HOME/$APP_MAINCLASS >$APP_HOME/logs/$now 2>&1 &"
	echo $JAVA_CMD
        su - $OWNER -c "$JAVA_CMD"
        checkpid
        if [ $psid -ne 0 ];then
            echo "Started $APP_MAINCLASS (pid=$psid)[OK]"
        else
            echo "Started $APP_MAINCLASS [FAILED]"
        fi
    fi
}

#停止程序
stop(){
    checkpid
    if [ $psid -ne 0 ];then
        echo "Stoping $APP_MAINCLASS...(pid=$psid)"
        su - $OWNER -c "kill $psid"

        checkpid
        if [ $psid -ne 0 ];then
            echo "Stoping use kill -9"
            su - $OWNER -c "kill -9 $psid"
        fi

        checkpid
        if [ $psid -eq 0 ];then
            echo "Stoped $APP_MAINCLASS [OK]"
        else
            echo "Stoped $APP_MAINCLASS [Failed]"
            stop
        fi

    else
        echo "WARN:$APP_MAINCLASS is not runing"
    fi
}

#查看状态
status(){
    checkpid

    if [ $psid -ne 0 ];then
        echo "$APP_MAINCLASS is runing (pid=$psid)"
    else
        echo "$APP_MAINCLASS is not runing"
    fi
}

#帮助信息
info() {
    echo "System Information:"
    echo "****************************"
    echo `head -n 1 /etc/issue`
    echo `uname -a`
    echo
    echo "JAVA_HOME=$JAVA_HOME"
    echo `$JAVA_HOME/bin/java -version`
    echo
    echo "APP_HOME=$APP_HOME"
    echo "APP_MAINCLASS=$APP_MAINCLASS"
    echo "****************************"
}

#$1表示接收第一个参数，如 ./run.sh start 。则$1就是start 
case "$1" in
    'start')
        start
        ;;
    'stop')
        stop
        ;;
    'restart')
        stop
        start
        ;;
    'info')
        info
        ;;
    'status')
        status
        ;;
    *)
    echo "Usage: $0 {start|stop|restart|status|info}"
    exit 1
esac
exit 0;
