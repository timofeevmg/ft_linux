# ft_linux
My own linux distro (manual: https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/).

# Host OS & VM
Debian 11 (using VM VirtualBox).\
Added new vdi named "lfs" for 30Gb and attached to Debian.

# check Host System Requirements
chmod +x version-check.sh\
./version-check.sh

# Partition structure of LFS disk with gparted: 
|name  |size   |partition |file system    |
|------|-------|----------|---------------|
| boot | 200MB |/dev/sdb1 |ext2(boot_grub)|
| root | 15GB  |/dev/sdb2 |ext4           |
| home | 10GB  |/dev/sdb3 |ext4           |
| swap | 4GB   |/dev/sdb4 |linux-swap     |


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
  
  RESTORE AFTER REBOOT SCRIPT: restore_virt_kernel_FS_after_reboot.sh
  
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
  
  cd ../
 
  # Cleaning up and Saving the Temporary System
  ````bash
  rm -rf /usr/share/{info,man,doc}/*
  find /usr/{lib,libexec} -name \*.la -delete
  rm -rf /tools
  ````
  
  # !!! at this point a backup can be made
  
  # Installing Basic System Software
  cd sources
  
  script: install_basic_soft.sh
  
  !!!don`t forget make check during Glibc install!!!
  
  # Stripping is skipped!
  
  # Cleaning
  ````bash
  rm -rf /tmp/*
  find /usr/lib /usr/libexec -name \*.la -delete
  find /usr -depth -name $(uname -m)-lfs-linux-gnu\* | xargs rm -rf
  userdel -r tester
  ````
  
  # General Network Configuration <<<<<<<<<<<<<<<<<<<<<<<< may be dhcpd requaried
  
  ````bash
  cat > /etc/systemd/network/10-ether0.link << "EOF"
  [Match]
  # Change the MAC address as appropriate for your network device
  MACAddress=08:00:27:20:A1:D5
  
  [Link]
  Name=ether0
  EOF  
  
  cat > /etc/systemd/network/10-eth-dhcp.network << "EOF"
  [Match]
  Name=ether0
  
  [Network]
  DHCP=ipv4
  
  [DHCP]
  UseDomains=true
  EOF
  
  echo "epilar" > /etc/hostname
  
  cat > /etc/hosts << "EOF"
  # Begin /etc/hosts
  
  127.0.0.1 localhost
  127.0.1.1 epilar21
  ::1       localhost ip6-localhost ip6-loopback
  ff02::1   ip6-allnodes
  ff02::2   ip6-allrouters
  
  # End /etc/hosts
  EOF
  ````
  
  # Configuring the system clock
  
  ````bash
  cat > /etc/adjtime << "EOF"
  0.0 0 0.0
  0
  UTC
  EOF
  ````
  
  # Configuring the Linux Console
  
  ````bash
  cat > /etc/vconsole.conf << "EOF"
  KEYMAP=us
  FONT=UniCyr_8x16
  EOF
  ````
  
  # Configuring the System Locale
  
  locale -a - list of all locales supported by Glibc\
  for ex. choose "ru_RU.utf8"\
  Command "LC_ALL=ru-RU.utf8 locale charmap" will give proper map:\
  UTF-8\
  
  Check commands for locale:\
  LC_ALL=<locale name> locale language\
  LC_ALL=<locale name> locale charmap\
  LC_ALL=<locale name> locale int_curr_symbol\
  LC_ALL=<locale name> locale int_prefix\
  For "ru-RU.utf8" are: "Russian"/"UTF-8"/"RUB"/"7"
  
  ````bash
  cat > /etc/locale.conf << "EOF"
  LANG=ru_RU.UTF-8
  EOF
  ````
  
  # Creating the /etc/inputrc File
  ````bash
  cat > /etc/inputrc << "EOF"
  # Begin /etc/inputrc
  # Modified by Chris Lynn <roryo@roryo.dynup.net>
  
  # Allow the command prompt to wrap to the next line
  set horizontal-scroll-mode Off
  
  # Enable 8bit input
  set meta-flag On
  set input-meta On
  
  # Turns off 8th bit stripping
  set convert-meta Off
  
  # Keep the 8th bit for display
  set output-meta On
  
  # none, visible or audible
  set bell-style none
  
  # All of the following map the escape sequence of the value
  # contained in the 1st argument to the readline specific functions
  "\eOd": backward-word
  "\eOc": forward-word
  
  # for linux console
  "\e[1~": beginning-of-line
  "\e[4~": end-of-line
  "\e[5~": beginning-of-history
  "\e[6~": end-of-history
  "\e[3~": delete-char
  "\e[2~": quoted-insert
  
  # for xterm
  "\eOH": beginning-of-line
  "\eOF": end-of-line
  
  # for Konsole
  "\e[H": beginning-of-line
  "\e[F": end-of-line
  
  # End /etc/inputrc
  EOF
  ````
  
  # Creating the /etc/shells File
  ````bash
  cat > /etc/shells << "EOF"
  # Begin /etc/shells
  
  /bin/sh
  /bin/bash
  
  # End /etc/shells
  EOF
  ````
  
  # Disabling Screen Clearing at Boot Time
  ````bash
  mkdir -pv /etc/systemd/system/getty@tty1.service.d
  
  cat > /etc/systemd/system/getty@tty1.service.d/noclear.conf << EOF
  [Service]
  TTYVTDisallocate=no
  EOF
  ````
  
  # Disabling tmpfs for /tmp (only if a separate partition for /tmp is not desired)
  ````bash
  ln -sfv /dev/null /etc/systemd/system/tmp.mount
  ````
  
  # Configuring Automatic File Creation and Deletion
  ````bash
  mkdir -p /etc/tmpfiles.d
  cp /usr/lib/tmpfiles.d/tmp.conf /etc/tmpfiles.d
  ````
  
  # Limit core dumps
  ````bash
  mkdir -pv /etc/systemd/coredump.conf.d
  
  cat > /etc/systemd/coredump.conf.d/maxuse.conf << EOF
  [Coredump]
  MaxUse=1G
  EOF
  ````
  
  # Making the LFS System Bootable
  ````bash
  # Creating the /etc/fstab File
cat > /etc/fstab << "EOF"
# Begin /etc/fstab

# file system   mount-point   type      options             dump    fsck
#                                                                   order

/dev/sda1       /boot         ext2      defaults            0       0
/dev/sda2       /             ext4      defaults            1       1
/dev/sda3       /home         ext4      defaults            0       0
/dev/sda4       swap          swap      pri=1               0       0
proc            /proc         proc      nosuid,noexec,nodev 0       0
sysfs           /sys          sysfs     nosuid,noexec,nodev 0       0
devpts          /dev/pts      devpts    gid=5,mode=620      0       0
tmpfs           /run          tmpfs     defaults            0       0
devtmpfs        /dev          devtmpfs  mode=0755,nosuid    0       0
# End /etc/fstab
EOF
  ````
  
  # Install linux kernel
  cd /sources\
  ````bash
  tar -xf linux-5.16.9.tar.xz
  cd linux-5.16.9
  
  make mrproper
  make menuconfig
  make
  make modules_install
  
  cp -iv arch/x86_64/boot/bzImage /boot/vmlinuz-5.16.9-lfs-11.1-systemd-epilar
  cp -iv System.map /boot/System.map-5.16.9
  cp -iv .config /boot/config-5.16.9
  install -d /usr/share/doc/linux-5.16.9
  cp -r Documentation/* /usr/share/doc/linux-5.16.9
  cd ../
  chown -R 0:0 linux-5.16.9
  mv -v linux-5.16.9 /usr/src/kernel-5.16.9
  ````
  
  # Configuring Linux Module Load Order
  ````bash
  install -v -m755 -d /etc/modprobe.d
  cat > /etc/modprobe.d/usb.conf << "EOF"
  # Begin /etc/modprobe.d/usb.conf
  
  install ohci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i ohci_hcd ; true
  install uhci_hcd /sbin/modprobe ehci_hcd ; /sbin/modprobe -i uhci_hcd ; true
  
  # End /etc/modprobe.d/usb.conf
  EOF
  ````
  
  # Using GRUB to Set Up the Boot Process
  
  ````bash
  grub-install /dev/sdb
  
  cat > /boot/grub/grub.cfg << "EOF"
  # Begin /boot/grub/grub.cfg
  set default=0
  set timeout=5

  insmod ext2
  set root=(hd0,2)

  menuentry "GNU/Linux, Linux 5.16.9-lfs-11.1-systemd" {
          linux   /boot/vmlinuz-5.16.9-lfs-11.1-systemd-epilar root=/dev/sda2 ro
  }
  EOF
  ````

  # The End
  ````bash
  echo 11.1-systemd > /etc/lfs-release
  
  cat > /etc/lsb-release << "EOF"
  DISTRIB_ID="Linux From Scratch"
  DISTRIB_RELEASE="11.1-systemd"
  DISTRIB_CODENAME="epilar"
  DISTRIB_DESCRIPTION="Linux From Scratch"
  EOF
  
  cat > /etc/os-release << "EOF"
  NAME="Linux From Scratch"
  VERSION="11.1-systemd"
  ID=lfs
  PRETTY_NAME="Linux From Scratch 11.1-systemd"
  VERSION_CODENAME="epilar"
  EOF
  ````
  
  # Reboot
  ````bash
  logout
  
  umount -v $LFS/dev/pts
  umount -v $LFS/dev
  umount -v $LFS/run
  umount -v $LFS/proc
  umount -v $LFS/sys
  
  umount -v $LFS/home
  umount -v $LFS
  ````
