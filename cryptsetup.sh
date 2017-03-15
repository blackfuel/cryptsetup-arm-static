#!/mmc/bin/bash
PATH_CMD="$(readlink -f $0)"

set -e
set -x

REBUILD=1
mkdir -p /mmc/src/cryptsetup
SRC=/mmc/src/cryptsetup
MAKE="make -j`nproc`"
PATH=/mmc/usr/bin:/mmc/usr/local/sbin:/mmc/usr/local/bin:/mmc/usr/sbin:/mmc/usr/bin:/mmc/sbin:/mmc/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

######## ####################################################################
# LVM2 # ####################################################################
######## ####################################################################

mkdir -p $SRC/lvm2 && cd $SRC/lvm2
DL="LVM2.2.02.168.tgz"
FOLDER="${DL%.tgz*}"
URL="ftp://sources.redhat.com/pub/lvm2/releases/$DL"
[ "$REBUILD" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

# build static libraries
./configure \
--prefix=/mmc \
--with-confdir=/mmc/etc \
--with-default-system-dir=/mmc/etc/lvm \
--enable-static_link \
--disable-nls

$MAKE LIBS="-lm -lpthread -luuid"
make install

# build dynamic/shared libraries
./configure \
--prefix=/mmc \
--with-confdir=/mmc/etc \
--with-default-system-dir=/mmc/etc/lvm \
--disable-nls

$MAKE LIBS="-lm -lpthread -luuid"
make install

touch __package_installed
fi

######## ####################################################################
# POPT # ####################################################################
######## ####################################################################

mkdir -p $SRC/popt && cd $SRC/popt
DL="popt-1.16.tar.gz"
FOLDER="${DL%.tar.gz*}"
URL="http://rpm5.org/files/popt/$DL"
[ "$REBUILD" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

./configure \
--prefix=/mmc \
--enable-static \
--enable-shared \
--disable-nls

$MAKE
make install
touch __package_installed
fi

################ ############################################################
# LIBGPG-ERROR # ############################################################
################ ############################################################

mkdir -p $SRC/libgpg-error && cd $SRC/libgpg-error
DL="libgpg-error-1.27.tar.bz2"
FOLDER="${DL%.tar.bz2*}"
URL="https://gnupg.org/ftp/gcrypt/libgpg-error/$DL"
[ "$REBUILD" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvjf $DL
cd $FOLDER

./configure \
--prefix=/mmc \
--enable-static \
--enable-shared \
--disable-nls

$MAKE
make install
touch __package_installed
fi

########## ##################################################################
# GCRYPT # ##################################################################
########## ##################################################################

mkdir -p $SRC/gcrypt && cd $SRC/gcrypt
DL="libgcrypt-1.7.6.tar.bz2"
FOLDER="${DL%.tar.bz2*}"
URL="https://gnupg.org/ftp/gcrypt/libgcrypt/$DL"
[ "$REBUILD" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvjf $DL
cd $FOLDER

./configure \
--prefix=/mmc \
--enable-static \
--enable-shared \
--disable-amd64-as-feature-detection \
--with-gpg-error-prefix=/mmc

$MAKE
make install
touch __package_installed
fi

############## ##############################################################
# CRYPTSETUP # ##############################################################
############## ##############################################################

# compiling without "--disable-kernel-crypto" requires a header file: linux/if_alg.h
HEADER_KERNEL_CRYPTO="${PATH_CMD%/*}/if_alg.h"
[ ! -f "/mmc/include/linux/if_alg.h" ] && [ -f "$HEADER_KERNEL_CRYPTO" ] && cp -p "$HEADER_KERNEL_CRYPTO" /mmc/include/linux

mkdir -p $SRC/cryptsetup && cd $SRC/cryptsetup
DL="cryptsetup-1.7.3.tar.xz"
FOLDER="${DL%.tar.xz*}"
URL="https://www.kernel.org/pub/linux/utils/cryptsetup/v1.7/$DL"
[ "$REBUILD" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvJf $DL
cd $FOLDER

LIBS="-lpthread" \
./configure \
--prefix=/mmc \
--disable-nls \
--enable-static \
--enable-shared \
--enable-static-cryptsetup \
--enable-cryptsetup-reencrypt

$MAKE
make install
touch __package_installed
fi

