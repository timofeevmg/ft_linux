#!/bin/bash

#check virtual kernel mount through command
# findmnt | grep $LFS
# (check under root user $LFS)
# should be:
# ├─/mnt/lfs                   /dev/sdb2  ext4       rw,relatime
# │ ├─/mnt/lfs/home            /dev/sdb3  ext4       rw,relatime
# │ ├─/mnt/lfs/dev             udev       devtmpfs   rw,nosuid,relatime,size=1989320k,nr_inodes=497330,mode=755
# │ │ └─/mnt/lfs/dev/pts       devpts     devpts     rw,nosuid,noexec,relatime,gid=5,mode=620,ptmxmode=000
# │ ├─/mnt/lfs/proc            proc       proc       rw,relatime
# │ ├─/mnt/lfs/sys             sysfs      sysfs      rw,relatime
# │ └─/mnt/lfs/run             tmpfs      tmpfs      rw,relatime


mkdir -pv $LFS/{dev,proc,sys,run}
mknod -m 600 $LFS/dev/console c 5 1
mknod -m 666 $LFS/dev/null c 1 3
mount -v --bind /dev $LFS/dev
mount -v --bind /dev/pts $LFS/dev/pts
mount -vt proc proc $LFS/proc
mount -vt sysfs sysfs $LFS/sys
mount -vt tmpfs tmpfs $LFS/run
if [ -h $LFS/dev/shm ]; then
  mkdir -pv $LFS/$(readlink $LFS/dev/shm)
fi
sudo chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login

