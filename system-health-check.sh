#!/bin/bash

# system-health-check.sh
# Server monitoring for CPU, memory, swap, process, storage, and more
# Copyright (c) 2012, Stephen Lang
# All rights reserved.
#
# Git repository available at:
# https://github.com/stephenlang/system-health-check
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.


# Status page
status_page=/var/www/system-health-check.html


# Enable / Disable Checks
memory_check=off
swap_check=on
load_check=on
storage_check=on
process_check=on
replication_check=off


# Configure partitions for storage check
partitions=( / )


# Configure process(es) to check
process_names=( httpd mysqld postfix )


# Configure Thresholds
memory_threshold=99
swap_threshold=80
load_threshold=10
storage_threshold=80


# Logging Metrics

cpu=`vmstat 1 2 | tail -1 | awk '{print $13,$14,$15}'`
load=`/usr/bin/uptime | awk -F'load average:' '{ print $2}'`
load_alarm=`/usr/bin/uptime | awk -F'load average:' '{ print $2}' | sed 's/\./ /g' | awk '{print $1}'`
memory_alarm=`/usr/bin/free -m | grep Mem | awk '{print $3/$2 * 100.0}' | cut -d\. -f1`
swap_alarm=`/usr/bin/free -m | grep Swap | awk '{print $3/$2 * 100.0}' | cut -d\. -f1`
disk_alarm=`/bin/df -h | grep -v shm  | tail -1 |awk '{print $5}' | sed -e 's/\%//g'`
diskused=`/bin/df -h | grep -v shm | tail -1 | awk '{print $3}'`
diskmax=`/bin/df -h |grep -v shm | tail -1 | awk '{print $2}'` 
Slave_IO_Running=`/usr/bin/mysql -Bse "show slave status\G" | grep Slave_IO_Running | awk '{ print $2 }'`
Slave_SQL_Running=`/usr/bin/mysql -Bse "show slave status\G" | grep Slave_SQL_Running | awk '{ print $2 }'`
Last_error=`/usr/bin/mysql -Bse "show slave status\G" | grep Last_error | awk -F \: '{ print $2 }'`


# Clear status page and initialize variable

> $status_page
ok=1


# Memory Check

if [ $memory_check = on ]; then
	if [ $memory_alarm -ge $memory_threshold ]; then
        	echo "CRITICAL : Memory usage of $memory_alarm% detected." >> $status_page
        	ok=0
	fi
fi


# Swap Check

if [ $swap_check = on ]; then
	if [ $swap_alarm -ge $swap_threshold ]; then
        	echo "CRITICAL : Swap usage of $swap_alarm% detected." >> $status_page
        	ok=0
	fi
fi


# Load Check

if [ $load_check = on ]; then
	if [ $load_alarm -ge 10 ]; then
        	echo "CRITICAL : Load Average of $load_alarm detected." >> $status_page
        	ok=0
	fi
fi


# Storage Check

if [ $storage_check = on ]; then
	for i in ${partitions[@]}; do
		disk_alarm=`/bin/df -h $i | tail -1 |awk '{print $5}' | sed -e 's/\%//g'`
		diskused=`/bin/df -h $i | tail -1 | awk '{print $3}'`
		diskmax=`/bin/df -h $i | tail -1 | awk '{print $2}'`
			if [ $disk_alarm -ge $storage_threshold ]; then
        			echo "CRITICAL : $i currently at $disk_alarm% capacity." >> $status_page
				ok=0
			fi
	done;
fi


# Process Check

if [ $process_check = on ]; then
	for i in ${process_names[@]}; do
		check=`ps ax |grep -v grep | grep -c $i`
		if [ $check = 0 ]; then
			echo "CRITICAL : $i not running!" >> $status_page
			ok=0
		fi;
	done	
fi


# Replication Check

if [ $replication_check = on ]; then

	if [ -z $Slave_IO_Running -o -z $Slave_SQL_Running ] ; then
        	echo "CRITICAL : Replication is not configured or you do not have the required access to MySQL" >> $status_page
		ok=0
	fi

	if [ $Slave_SQL_Running == 'No' ] ; then
       		echo "CRITICAL : Replication SQL thread not running on server `hostname -s`!" >> $status_page
        	echo "Last Error: $Last_error" >> $status_page
		ok=0
	fi

	if [ $Slave_IO_Running == 'No' ] ; then
        	echo "CRITICAL : Replication LOG IO thread not running on server `hostname -s`!" >> $status_page
        	echo "Last Error:" $Last_error >> $status_page
		ok=0
	fi
fi


# Change status page if anything failed

if [ $ok = 1 ]; then
	echo "OK" >> $status_page
fi

