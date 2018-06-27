#!/bin/bash
# Auto assign CPU time for limit %CPU per VM
# Limit ratio 1 vCPU = 75% CPU
# Date: 12/10/2016
# Author: vy.nt@vinahost.vn

LOG="/var/log/kvm-cpu-quota.log"
BCPU=200
LISTVM=$(/usr/sbin/qm list | grep running  | grep -v '6868001\|6868002' | awk '{print $1}')
for vmid in $LISTVM; do
	[ ! -e /sys/fs/cgroup/cpu/qemu.slice/$vmid.scope/cpu.shares ] && echo "Error: CPU.shares VMID $vmid not found !" >> $LOG && exit
	CPUSHARES=$(cat /sys/fs/cgroup/cpu/qemu.slice/$vmid.scope/cpu.shares)
	RATIO=$(($CPUSHARES/$BCPU))
	CFSQUOTA=$(($RATIO*75000))
	CURRENTCFSQUOTA=$(cat /sys/fs/cgroup/cpu/qemu.slice/$vmid.scope/cpu.cfs_quota_us)
	if [ $CFSQUOTA -ne $CURRENTCFSQUOTA ]; then
		echo 100000 > /sys/fs/cgroup/cpu/qemu.slice/$vmid.scope/cpu.cfs_period_us
		echo $CFSQUOTA > /sys/fs/cgroup/cpu/qemu.slice/$vmid.scope/cpu.cfs_quota_us
		[ $? -ne 0 ] && echo "Error: Cannot set CPU quota to VMID $vmid with CFSQUOTA = $CFSQUOTA" >> $LOG || echo "Success: Set CPU quota to VMID $vmid with CFSQUOTA = $CFSQUOTA" >> $LOG
	fi
done
