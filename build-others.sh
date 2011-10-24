#!/bin/sh
# Author: Anthony Gelibert <anthony.gelibert@lcis.grenoble-inp.fr>

[ "root" = "`whoami`" ] && echo "Being root in all the build process isn't a good idea" && exit 1

num_cpus() {
	local tmp;

    case $(uname -s) in
        Darwin)
            tmp="`sysctl -n hw.availcpu 2> /dev/null`";;
		FreeBSD)
            tmp="`sysctl -n hw.ncpu 2> /dev/null`";;
		Linux|CYGWIN_NT*)
			tmp="`grep ^processor /proc/cpuinfo 2>/dev/null| wc -l`";;
		*)	tmp=1;;
	esac
	[ $tmp = 0 ] && tmp=1;
    echo "${tmp}";
}

BINUTILS_PATCH="`ls | grep binutils | tail -1`"
GCC_PATCH="`ls | grep gcc | tail -1`"
GDB_PATCH="`ls | grep gdb | tail -1`"
BINUTILS_VERSION="`ls | grep binutils | tail -1 | cut -f3 -d-`"
GCC_VERSION="`ls | grep gcc | tail -1 | cut -f3 -d-`"
GDB_VERSION="`ls | grep gdb | tail -1 | cut -f3 -d-`"
MSP430MCU_VERSION="`cat msp430mcu.version`"
MSP430LIBC_VERSION="`cat msp430-libc.version`"
GMP_VERSION="5.0.2"
MPFR_VERSION="3.0.1"
MPC_VERSION="0.9"

BUILDDATE="`date '+%Y%m%d'`"
BUILDDIR="$PWD/build"

TARGETDIR="/opt/msp430-gcc-$GCC_VERSION"

BINUTILS="binutils-$BINUTILS_VERSION"
GCC="gcc-$GCC_VERSION"
GDB="gdb-$GDB_VERSION"
MCU="msp430mcu-$MSP430MCU_VERSION"
LIBC="msp430-libc-$MSP430LIBC_VERSION"
GMP="gmp-$GMP_VERSION"
MPFR="mpfr-$MPFR_VERSION"
MPC="mpc-$MPC_VERSION"

MIRROR_BINUTILS="ftp://sources.redhat.com/pub/binutils/releases"
MIRROR_GDB="ftp://sources.redhat.com/pub/gdb/releases"
MIRROR_GCC="http://ftp.uni-kl.de/pub/gnu/gcc/gcc-$GCC_VERSION"
MIRROR_GMP="http://ftp.uni-kl.de/pub/gnu/gmp"
MIRROR_MPFR="http://ftp.uni-kl.de/pub/gnu/mpfr"
MIRROR_MPC="http://www.multiprecision.org/mpc/download"
MIRROR_MCU="http://sourceforge.net/projects/mspgcc/files/msp430mcu"
MIRROR_LIBC="http://sourceforge.net/projects/mspgcc/files/msp430-libc"

NUM_CPU=$(num_cpus);

TAR_GZIP=xzf
TAR_BZIP=xjf

clear
echo "/---------------------------------+"
echo "| mspgcc build and install script |"
echo "+---------------------------------/\n"

echo "  - Binutils:    $BINUTILS_VERSION must be compiled !!"

echo "I will compile:"
echo "  - GCC:         $GCC_VERSION"
echo "  - GDB:         $GDB_VERSION"
echo "  - MSP430MCU:   $MSP430MCU_VERSION"
echo "  - MSP430-LIBC: $MSP430LIBC_VERSION\n"

echo "Build settings:"
echo "  - Build dir:  $BUILDDIR"
echo "  - Target dir: $TARGETDIR"
echo "  - Binutils:   $MIRROR_BINUTILS/$BINUTILS"
echo "  - GCC:        $MIRROR_GCC/gcc-core-$GCC_VERSION and $MIRROR_GCC/gcc-g++-$GCC_VERSION"
echo "  - GMP:        $MIRROR_GMP/$GMP"
echo "  - MPFR:       $MIRROR_MPFR/$MPFR"
echo "  - MPC:        $MIRROR_MPC/$MPC"
echo "  - GDB:        $MIRROR_GDB/$GDB"
echo "  - MCU:        $MIRROR_MCU/$MCU"
echo "  - LIBC:       $MIRROR_LIBC/$LIBC\n"

echo "Build order: binutils, gcc, gdb, mcu, libc\n"

cd $BUILDDIR
echo "###############################################################################"
echo "##  msp430-gcc ($GCC_VERSION)"
echo "###############################################################################"
echo "## Cleaning $GCC & $GCC-build"
rm -rf $GCC
rm -rf $GCC-build
echo "## Download"

if [ ! -e "gcc-core-$GCC_VERSION.tar.bz2" ]; then
    wget "$MIRROR_GCC/gcc-core-$GCC_VERSION.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download GCC Core $GCC_VERSION from $MIRROR_GCC/gcc-core-$GCC_VERSION.tar.bz2";
        exit 2;
    fi
fi
if [ ! -e "gcc-g++-$GCC_VERSION.tar.bz2" ]; then
    wget "$MIRROR_GCC/gcc-g++-$GCC_VERSION.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download GCC Core $GCC_VERSION from $MIRROR_GCC/gcc-g++-$GCC_VERSION.tar.bz2";
        exit 2;
    fi
fi

if [ ! -e "$MPFR.tar.bz2" ]; then
    wget "$MIRROR_MPFR/$MPFR.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download MPFR $MPFR_VERSION from $MIRROR_MPFR/$MPFR.tar.bz2";
        exit 2;
    fi
fi
if [ ! -e "$GMP.tar.bz2" ]; then
    wget "$MIRROR_GMP/$GMP.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download GMP $GMP_VERSION from $MIRROR_GMP/$GMP.tar.bz2";
        exit 2;
    fi
fi
if [ ! -e "$MPC.tar.gz" ]; then
    wget "$MIRROR_MPC/$MPC.tar.gz"
    if [ $? -ne 0 ]; then
        echo "I can't download MPC $MPC_VERSION from $MIRROR_MPC/$MPC.tar.gz";
        exit 2;
    fi
fi



echo "## Unpacking"
tar $TAR_BZIP "gcc-core-$GCC_VERSION.tar.bz2"
tar $TAR_BZIP "gcc-g++-$GCC_VERSION.tar.bz2"
cd $GCC
tar $TAR_BZIP "../$GMP.tar.bz2"
rm -rf gmp
mv "$GMP" gmp

echo "## Patch"
( cd $GCC ; patch -p1 < ../../$GCC_PATCH )

echo "## Unpacking"
tar $TAR_BZIP "../$MPFR.tar.bz2"
rm -rf mpfr
mv $MPFR mpfr

tar $TAR_GZIP "../$MPC.tar.gz"
rm -rf mpc
mv $MPC mpc

cd ..
mkdir -p "$GCC-build"
cd "$GCC-build"
echo "## Configure"
../$GCC/configure --prefix="$TARGETDIR" --target=msp430 --enable-languages=c,c++ --disable-nls
echo "## Build"
make -j$NUM_CPU
echo "## Install"
echo "Note: I will request your root password to install in the target directory"
sudo make -j$NUM_CPU install
clear


cd $BUILDDIR
echo "###############################################################################"
echo "##  msp430-gdb ($GDB_VERSION)"
echo "###############################################################################"
echo "## Clean"
rm -rf $GDB
rm -rf $GDB-build
echo "## Download"
if [[ ! -e "$GDB.tar.gz" && ! -e "${GDB}a.tar.gz" ]]; then
    wget $MIRROR_GDB/$GDB.tar.gz
    if [ $? -ne 0 ]; then
        wget "$MIRROR_GDB/${GDB}a.tar.gz"
        if [ $? -ne 0 ]; then
            echo "I can't download GDB $GDB_VERSION from $MIRROR_GDB/$GDB{,a}.tar.gz";
            exit 3;
        fi
    fi
fi
echo "## Unpacking"
tar $TAR_GZIP $GDB.tar.gz 2> /dev/null
if [ $? -ne 0 ]; then
    tar $TAR_GZIP ${GDB}a.tar.gz
fi
echo "## Patch"
( cd $GDB ; patch -p1 < ../../$GDB_PATCH )
mkdir -p $GDB-build
cd $GDB-build
echo "## Configure"
../$GDB/configure --target=msp430 --prefix=$TARGETDIR
echo "## Build"
make -j$NUM_CPU
echo "## Install"
echo "Note: I will request your root password to install in the target directory"
sudo make -j$NUM_CPU install
clear

cd $BUILDDIR
echo "###############################################################################"
echo "##  msp430-mcu ($MCU_VERSION)"
echo "###############################################################################"
echo "## Clean"
rm -rf $MCU
echo "## Download"
if [ ! -e "$MCU.tar.bz2" ]; then
    wget "$MIRROR_MCU/$MCU.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download GCC MCU $MCU_VERSION from $MIRROR_MCU/$MCU.tar.bz2";
        exit 2;
    fi
fi
echo "## Unpacking"
tar $TAR_BZIP $MCU.tar.bz2
cd $MCU
echo "## Install"
echo "Note: I will request your root password to install in the target directory"
sudo MSP430MCU_ROOT="`pwd`" scripts/install.sh "$TARGETDIR"
clear

cd $BUILDDIR
echo "###############################################################################"
echo "##  msp430-libc ($LIBC_VERSION)"
echo "###############################################################################"
echo "## Clean"
rm -rf $LIBC
echo "## Download"
if [ ! -e "$LIBC.tar.bz2" ]; then
    wget "$MIRROR_LIBC/$LIBC.tar.bz2"
    if [ $? -ne 0 ]; then
        echo "I can't download GCC LIBC $LIBC_VERSION from $MIRROR_LIBC/$LIBC.tar.bz2";
        exit 2;
    fi
fi
echo "## Unpacking"
tar $TAR_BZIP $LIBC.tar.bz2
cd $LIBC/src
echo "## Build"
make -j$NUM_CPU
echo "## Install"
echo "Note: I will request your root password to install in the target directory"
sudo make -j$NUM_CPU PREFIX="$TARGETDIR" install
clear

