#!/bin/bash
# Auto assign CPU time for limit %CPU per VM
# Limit ratio 1 vCPU = 75% CPU
# Date: 03/03/2017
# Author: vy.nt@vinahost.vn

LOG="/var/log/kvm-cpu-quota.log"
BCPU=1024
LISTVM=$(/usr/bin/find /sys/fs/cgroup/cpu/machine.slice/*/ -maxdepth 1 -name cpu.shares | /usr/bin/awk -F 'cpu.shares' '{print $1}')
for vmid in $LISTVM; do
        [ ! -e $vmid'cpu.shares' ] && echo "Error: CPU.shares VMID $vmid not found !" >> $LOG && exit
        CPUSHARES=$(cat $vmid'cpu.shares')
        RATIO=$(($CPUSHARES/$BCPU))
        CFSQUOTA=$(($RATIO*75000))
        CURRENTCFSQUOTA=$(cat $vmid'cpu.cfs_quota_us')
        if [ $CFSQUOTA -ne $CURRENTCFSQUOTA ]; then
		echo 100000 > $vmid'cpu.cfs_period_us'
		echo $CFSQUOTA > $vmid'cpu.cfs_quota_us'
		[ $? -ne 0 ] && echo "Error: Cannot set CPU quota to VMID $vmid with CFSQUOTA = $CFSQUOTA" >> $LOG || echo "Success: Set CPU quota to VMID $vmid with CFSQUOTA = $CFSQUOTA" >> $LOG
		fi
done
