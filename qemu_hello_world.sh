#!/bin/sh

# write my own init
cat > hello_world.c << EOF
#include <stdio.h>
#include <unistd.h>

int main(int argc, char **argv) {
  printf("hello world\n");
  while (1)
    sleep(10);

  return 0;
}
EOF

gcc -Wall -static -o hello_world hello_world.c

# build kernel from source
wget https://cdn.kernel.org/pub/linux/kernel/v4.x/linux-4.14.307.tar.xz
tar xvf linux-4.14.307.tar.xz
cd linux-4.14.307/
make x86_64_defconfig
make -j$(nproc)
cd ..

# create a hd
truncate -s 256M hda.img

/sbin/parted -s hda.img mktable msdos
/sbin/parted -s hda.img mkpart primary ext4 1 "100%"
/sbin/parted -s hda.img set 1 boot on

HDA_LOOP_DEV=$(sudo losetup -Pf --show hda.img)
FS_LOOP_DEV="${HDA_LOOP_DEV}p1"

sudo mkfs.ext4 -v "${FS_LOOP_DEV}"

mkdir mnt
sudo mount "${FS_LOOP_DEV}" mnt
sudo chown -R ${USER} mnt

# install grub2
mkdir -p mnt/boot/grub
echo "(hd0) ${HDA_LOOP_DEV}" > mnt/boot/grub/device.map
sudo grub-install                   \
  -v                                \
  --directory=/usr/lib/grub/i386-pc \
  --boot-directory=mnt/boot         \
  ${HDA_LOOP_DEV}                   \
  2>&1

sudo losetup -d ${HDA_LOOP_DEV}

# create a minimal grub.cfg
cat > mnt/boot/grub/grub.cfg << EOF
serial
terminal_input serial
terminal_output serial
set root=(hd0,1)
linux /boot/bzImage \
  root=/dev/sda1    \
  console=ttyS0     \
  init=/bin/hello_world
boot
EOF

# copy the kernel to /boot
cp linux-4.14.307/arch/x86_64/boot/bzImage mnt/boot/bzImage

# copy hello_world to /bin as init
mkdir -p mnt/bin
cp hello_world mnt/bin

sudo umount mnt

# boot qemu
qemu-system-x86_64 -hda hda.img -serial mon:stdio
