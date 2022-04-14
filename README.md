# ft_linux
My own linux distro (manual: https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/).

# Host OS & VM
Debian 11 (using VM VirtualBox).\
Added new vdi named "lfs" for 30Gb and attached to Debian.

# check Host System Requirements
chmod +x version-check.sh\
./version-check.sh

# Partition structure of LFS disk with gparted: 
|name  |size   |partition |file system |
|------|-------|----------|------------|
| boot | 200MB |/dev/sdb1 |ext2        |
| root | 15GB  |/dev/sdb2 |ext4        |
| home | 10GB  |/dev/sdb3 |ext4        |
| swap | 4GB   |/dev/sdb4 |linux-swap  |


possible partitioning with fdisc\
and coomands:
- mkfs -v -t ext4 /dev/<xxx>
- mkswap /dev/<yyy>
- lsblk - list of storage devs

# routine
su - become superuser\
export LFS=/mnt/lfs - remember mount point\
mkdir -pv $LFS\
mount -v -t ext4 /dev/sdb2 $LFS\
mkdir -v $LFS/home\
mount -v -t ext4 /dev/sdb3 $LFS/home\
sudo swapon -v /dev/sdb4\
## !!!
  One way to ensure that the LFS variable is always set is to edit the .bash_profile file in both your personal home directory and in /root/.bash_profile and enter the export command above. In addition, the shell specified in the /etc/passwd file for all users that need the LFS variable needs to be bash to ensure that the /root/.bash_profile file is incorporated as a part of the login process.
Another consideration is the method that is used to log into the host system. If logging in through a graphical display manager, the user's .bash_profile is not normally used when a virtual terminal is started. In this case, add the export command to the .bashrc file for the user and root. In addition, some distributions have instructions to not run the .bashrc instructions in a non-interactive bash invocation. Be sure to add the export command before the test for non-interactive use.\
The above instructions assume that you will not be restarting your computer throughout the LFS process. If you shut down your system, you will either need to remount the LFS partition each time you restart the build process or modify your host system's /etc/fstab file to automatically remount it upon boot. For example:
/dev/<xxx> /mnt/lfs ext4 defaults 1 1\
If you use additional optional partitions, be sure to add them also.\
sudo blkid - get device UUID\
## !!!

# source dir
mkdir -v $LFS/sources\
chmod -v a+wt $LFS/sources\

# get sources
wget https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/wget-list --directory-prefix=$LFS/sources\
wget --input-file=$LFS/sources/wget-list --continue --directory-prefix=$LFS/sources\
# check md5 sum
wget https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/md5sums --directory-prefix=$LFS/sources\
pushd $LFS/sources\
md5sum -c md5sums\
popd\
Troubles occured with https://zlib.net/zlib-1.2.11.tar.xz, because of incorrect link.\
Correct one is : http://zlib.net/fossils/zlib-1.2.11.tar.gz. \
MD5 corrected too.

# creating a limited directory layout in LFS filesystem
````bash
mkdir -pv $LFS/{etc,var} $LFS/usr/{bin,lib,sbin}

for i in bin lib sbin; do
  ln -sv usr/$i $LFS/$i
done

case $(uname -m) in
  x86_64) mkdir -pv $LFS/lib64 ;;
esac
  
mkdir -pv $LFS/tools
````

# adding the LFS user
````bash
sudo groupadd lfs
useradd -s /bin/bash -g lfs -m -k /dev/null lfs
#setting password "xxxxx"
passwd lfs
# grant lfs full access to all directories under $LFS by making lfs the directory owner
chown -v lfs $LFS/{usr{,/*},lib,var,etc,bin,sbin,tools}
case $(uname -m) in
  x86_64) chown -v lfs $LFS/lib64 ;;
esac

chown -v lfs $LFS/sources
````
# setting Up the Environment
!!!\
  remember login as lfs user\
!!!
````bash
  su - lfs
  
  cat > ~/.bash_profile << "EOF"
    exec env -i HOME=$HOME TERM=$TERM PS1='\u:\w\$ ' /bin/bash
  EOF
  
  cat > ~/.bashrc << "EOF"
    set +h
    umask 022
    LFS=/mnt/lfs
    LC_ALL=POSIX
    LFS_TGT=$(uname -m)-lfs-linux-gnu
    PATH=/usr/bin
    if [ ! -L /bin ]; then PATH=/bin:$PATH; fi
    PATH=$LFS/tools/bin:$PATH
    CONFIG_SITE=$LFS/usr/share/config.site
    export LFS LC_ALL LFS_TGT PATH CONFIG_SITE
  EOF
````
## !!!
  Several commercial distributions add a non-documented instantiation of /etc/bash.bashrc to the initialization of bash. This file has the potential to modify the lfs user's environment in ways that can affect the building of critical LFS packages. To make sure the lfs user's environment is clean, check for the presence of /etc/bash.bashrc and, if present, move it out of the way. As the root user, run:\
[ ! -e /etc/bash.bashrc ] || mv -v /etc/bash.bashrc /etc/bash.bashrc.NOUSE\
  After use of the lfs user is finished at the beginning of Chapter 7, you can restore /etc/bash.bashrc
(if desired).\
Note that the LFS Bash package we will build in Section 8.34, “Bash-5.1.16” is not configured to load or
execute /etc/bash.bashrc, so this file is useless on a completed LFS system.
## !!!
````bash
  source ~/.bash_profile
````
Be sure of env variables with command "set".

Turn on (NOT RECOMMENDED!) a multicore compilation(4 - num of cores/proccessors):
  ````bash
  export MAKEFLAGS='-j4'
  ````
Return to single core if errors occured.\
  
# building the LFS Cross Toolchain and Temporary Tools
  !!!\
The build instructions assume that the Host System Requirements, including symbolic links, have been set properly:\
- bash is the shell in use.
- sh is a symbolic link to bash.
- /usr/bin/awk is a symbolic link to gawk.
- /usr/bin/yacc is a symbolic link to bison or a small script that executes bison.\
!!!\
  compile_temp_lools_1.sh\

# entering Chroot and Building Additional Temporary Tools
  
  findmnt - list all of the mounted dir-s
  
  ````bash
  # change the ownership of the $LFS/* directories to user root
  chown -R root:root $LFS/{usr,lib,var,etc,bin,sbin,tools}
  case $(uname -m) in
    x86_64) chown -R root:root $LFS/lib64 ;;
  esac
  
  # creating directories onto which the file systems will be mounted
  mkdir -pv $LFS/{dev,proc,sys,run}
  
  # Creating Initial Device Nodes
  mknod -m 600 $LFS/dev/console c 5 1
  mknod -m 666 $LFS/dev/null c 1 3
  
  # Mounting and Populating /dev
  mount -v --bind /dev $LFS/dev
  
  # Mounting Virtual Kernel File Systems
  mount -v --bind /dev/pts $LFS/dev/pts
  mount -vt proc proc $LFS/proc
  mount -vt sysfs sysfs $LFS/sys
  mount -vt tmpfs tmpfs $LFS/run
  
  if [ -h $LFS/dev/shm ]; then
     mkdir -pv $LFS/$(readlink $LFS/dev/shm)
  fi
  
  # Entering the Chroot Environment
  sudo chroot "$LFS" /usr/bin/env -i   \
    HOME=/root                  \
    TERM="$TERM"                \
    PS1='(lfs chroot) \u:\w\$ ' \
    PATH=/usr/bin:/usr/sbin     \
    /bin/bash --login
  
  # Creating Directories
  mkdir -pv /{boot,home,mnt,opt,srv}
  
  mkdir -pv /etc/{opt,sysconfig}
  mkdir -pv /lib/firmware
  mkdir -pv /media/{floppy,cdrom}
  mkdir -pv /usr/{,local/}{include,src}
  mkdir -pv /usr/local/{bin,lib,sbin}
  mkdir -pv /usr/{,local/}share/{color,dict,doc,info,locale,man}
  mkdir -pv /usr/{,local/}share/{misc,terminfo,zoneinfo}
  mkdir -pv /usr/{,local/}share/man/man{1..8}
  mkdir -pv /var/{cache,local,log,mail,opt,spool}
  mkdir -pv /var/lib/{color,misc,locate}
  ln -sfv /run /var/run
  ln -sfv /run/lock /var/lock
  install -dv -m 0750 /root
  install -dv -m 1777 /tmp /var/tmp
  
  # Creating Essential Files and Symlinks
  ln -sv /proc/self/mounts /etc/mtab
  
  cat > /etc/hosts << EOF
    127.0.0.1  localhost $(hostname)
    ::1        localhost
  EOF
  
  cat > /etc/passwd << "EOF"
    root:x:0:0:root:/root:/bin/bash
    bin:x:1:1:bin:/dev/null:/usr/bin/false
    daemon:x:6:6:Daemon User:/dev/null:/usr/bin/false
    messagebus:x:18:18:D-Bus Message Daemon User:/run/dbus:/usr/bin/false
    systemd-journal-gateway:x:73:73:systemd Journal Gateway:/:/usr/bin/false
    systemd-journal-remote:x:74:74:systemd Journal Remote:/:/usr/bin/false
    systemd-journal-upload:x:75:75:systemd Journal Upload:/:/usr/bin/false
    systemd-network:x:76:76:systemd Network Management:/:/usr/bin/false
    systemd-resolve:x:77:77:systemd Resolver:/:/usr/bin/false
    systemd-timesync:x:78:78:systemd Time Synchronization:/:/usr/bin/false
    systemd-coredump:x:79:79:systemd Core Dumper:/:/usr/bin/false
    uuidd:x:80:80:UUID Generation Daemon User:/dev/null:/usr/bin/false
    systemd-oom:x:81:81:systemd Out Of Memory Daemon:/:/usr/bin/false
    nobody:x:99:99:Unprivileged User:/dev/null:/usr/bin/false
   EOF
  
  cat > /etc/group << "EOF"
    root:x:0:
    bin:x:1:daemon
    sys:x:2:
    kmem:x:3:
    tape:x:4:
    tty:x:5:
    daemon:x:6:
    floppy:x:7:
    disk:x:8:
    lp:x:9:
    dialout:x:10:
    audio:x:11:
    video:x:12:
    utmp:x:13:
    usb:x:14:
    cdrom:x:15:
    adm:x:16:
    messagebus:x:18:
    systemd-journal:x:23:
    input:x:24:
    mail:x:34:
    kvm:x:61: systemd-journal-gateway:x:73: systemd-journal-remote:x:74: systemd-journal-upload:x:75: systemd-network:x:76: systemd-resolve:x:77: systemd-timesync:x:78: systemd-coredump:x:79: uuidd:x:80: systemd-oom:x:81: wheel:x:97:
    nogroup:x:99:
    users:x:999:
  EOF
  
  # temp regular user for testing
  echo "tester:x:101:101::/home/tester:/bin/bash" >> /etc/passwd
  echo "tester:x:101:" >> /etc/group
  install -o tester -d /home/tester
  
  exec /usr/bin/bash --login
  
  touch /var/log/{btmp,lastlog,faillog,wtmp}
  chgrp -v utmp /var/log/lastlog
  chmod -v 664  /var/log/lastlog
  chmod -v 600  /var/log/btmp
  ````
  
  # compile and install 2nd part of software
  cd sources
  
  script: compile_temp_tools_2.sh
 
