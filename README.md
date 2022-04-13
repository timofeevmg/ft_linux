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
