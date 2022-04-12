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
sudo swapon -v /dev/sdb4

# source dir
mkdir -v $LFS/sources\
chmod -v a+wt $LFS/sources\

# get sources
wget https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/wget-list --directory-prefix=$LFS/sources\
wget --input-file=$LFS/sources/wget-list --continue --directory-prefix=$LFS/sources\
# check md5 sum
wget https://www.linuxfromscratch.org/lfs/downloads/11.1-systemd/md5sums --directory-prefix=$LFS/sources\
pushd $LFS/source\
md5sum -c md5sums\
popd\
