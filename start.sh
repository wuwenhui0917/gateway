#!/usr/bin/env bash

current_path=`pwd`
pid=""

if [ -f $current_path/logs/nginx.pid ]
then
	pid=`cat $current_path/logs/nginx.pid`
fi

if [ ! -f ./conf/nginx.conf ] || [ ! -f ./conf/gateway.conf ]
then
    make init-config
fi

if [ "$pid" = "" ]
then
	echo "start gateway.."
else
	echo "kill "$pid
	#kill -s QUIT $pid
	nginx -p `pwd` -c ./conf/nginx.conf -s stop
	echo "restart gateway.."
fi

mkdir -p logs
nginx -p `pwd` -c ./conf/nginx.conf
