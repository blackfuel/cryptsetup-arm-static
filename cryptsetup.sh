#!/mmc/bin/bash
#############################################################################
# Usage examples:
#
# CRYPTO_BACKEND="gcrypt" ./cryptsetup.sh
# CRYPTO_BACKEND="openssl" ./cryptsetup.sh
# CRYPTO_BACKEND="nettle" ./cryptsetup.sh
# CRYPTO_BACKEND="kernel" ./cryptsetup.sh
#
#############################################################################
PATH_CMD="$(readlink -f $0)"
set -e
set -x

#REBUILD_ALL=1
mkdir -p /mmc/src/cryptsetup
SRC=/mmc/src/cryptsetup
MAKE="make -j`nproc`"
#PATH=/mmc/usr/bin:/mmc/usr/local/sbin:/mmc/usr/local/bin:/mmc/usr/sbin:/mmc/usr/bin:/mmc/sbin:/mmc/bin:/usr/bin:/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
PATH=/mmc/usr/bin:/mmc/usr/local/sbin:/mmc/usr/local/bin:/mmc/usr/sbin:/mmc/usr/bin:/mmc/sbin:/mmc/bin

######## ####################################################################
# LVM2 # ####################################################################
######## ####################################################################

mkdir -p $SRC/lvm2 && cd $SRC/lvm2
DL="LVM2.2.02.168.tgz"
FOLDER="${DL%.tgz*}"
URL="ftp://sources.redhat.com/pub/lvm2/releases/$DL"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

LIBS="-lpthread -luuid -lrt" \
PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
./configure \
--prefix=/mmc \
--with-confdir=/mmc/etc \
--with-default-system-dir=/mmc/etc/lvm \
--enable-static_link \
--disable-nls

cp -p "libdm/libdevmapper.pc" /mmc/lib/pkgconfig
pushd .
cd /mmc/lib/pkgconfig
ln -sf libdevmapper.pc devmapper.pc
popd

LIBS="-luuid -lm" \
$MAKE device-mapper
make install_device-mapper
touch __package_installed
fi

######## ####################################################################
# POPT # ####################################################################
######## ####################################################################

mkdir -p $SRC/popt && cd $SRC/popt
DL="popt-1.16.tar.gz"
FOLDER="${DL%.tar.gz*}"
URL="http://rpm5.org/files/popt/$DL"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xzvf $DL
cd $FOLDER

PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
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
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvjf $DL
cd $FOLDER

PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
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
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER"
if [ ! -f "$FOLDER/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ ! -d "$FOLDER" ] && tar xvjf $DL
cd $FOLDER

PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
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

if [ -z "$CRYPTO_BACKEND" ]; then
  # select the crypto backend for cryptsetup
  #CRYPTO_BACKEND="gcrypt"
  #CRYPTO_BACKEND="openssl"
  #CRYPTO_BACKEND="nettle"
  CRYPTO_BACKEND="kernel"
fi

mkdir -p "$SRC/cryptsetup" && cd "$SRC/cryptsetup"
DL="cryptsetup-1.7.4.tar.xz"
FOLDER="${DL%.tar.xz*}"
FOLDER_CRYPTO="${FOLDER}-${CRYPTO_BACKEND}"
URL="https://www.kernel.org/pub/linux/utils/cryptsetup/v1.7/$DL"
[ "$REBUILD_ALL" == "1" ] && rm -rf "$FOLDER_CRYPTO"
if [ ! -f "$FOLDER_CRYPTO/__package_installed" ]; then
[ ! -f "$DL" ] && wget $URL
[ -d "$FOLDER" ] && rm -rf $FOLDER
[ ! -d "$FOLDER_CRYPTO" ] && tar xvJf $DL && mv $FOLDER $FOLDER_CRYPTO
cd $FOLDER_CRYPTO

# compiling without "--disable-kernel-crypto" requires a header file: linux/if_alg.h
HEADER_KERNEL_CRYPTO="${PATH_CMD%/*}/if_alg.h"
[ ! -f "/mmc/include/linux/if_alg.h" ] && [ -f "$HEADER_KERNEL_CRYPTO" ] && cp -p "$HEADER_KERNEL_CRYPTO" /mmc/include/linux

if [ "$CRYPTO_BACKEND" == "gcrypt" ]; then

LIBS="-lpthread -lgcrypt" \
PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
./configure \
--prefix=/mmc \
--disable-nls \
--enable-cryptsetup-reencrypt \
--with-crypto_backend=gcrypt \
--enable-shared \
--enable-static \
--enable-static-cryptsetup

elif [ "$CRYPTO_BACKEND" == "openssl" ]; then

LIBS="-lpthread -lssl -lcrypto -lz" \
PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
./configure \
--prefix=/mmc \
--disable-nls \
--enable-cryptsetup-reencrypt \
--with-crypto_backend=openssl \
--enable-shared \
--enable-static \
--enable-static-cryptsetup

elif [ "$CRYPTO_BACKEND" == "nettle" ]; then

LIBS="-lpthread -lnettle" \
PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
./configure \
--prefix=/mmc \
--disable-nls \
--enable-cryptsetup-reencrypt \
--with-crypto_backend=nettle \
--enable-shared \
--enable-static \
--enable-static-cryptsetup

elif [ "$CRYPTO_BACKEND" == "kernel" ]; then

LIBS="-lpthread" \
PKG_CONFIG_PATH="/mmc/lib/pkgconfig" \
./configure \
--prefix=/mmc \
--disable-nls \
--enable-cryptsetup-reencrypt \
--with-crypto_backend=kernel \
--enable-shared \
--enable-static \
--enable-static-cryptsetup

fi

$MAKE
make install
touch __package_installed
fi

