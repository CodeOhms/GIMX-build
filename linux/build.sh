#!/bin/bash

#don't forget to add universe to ~/.pbuilderrc

#uncomment in a new build environment
#sudo apt-get install gdebi devscripts pbuilder debhelper curl build-essential

PACKAGE="gimx"
OS=$1
DIST=$2
ARCH=$3
DATE=`date -R`
YEAR=`date +"%Y"`
BRANCH="master"

usage() {
  echo "usage: ./build <ubuntu, debian, raspbian> <xenial, jessie, stretch> <amd64, i386, armhf>"
}

echo "OS: "${OS}

if [ -z ${OS} ]
then
  echo No OS specified.
  usage
  exit
fi

echo "Distribution: "${DIST}

if [ -z ${DIST} ]
then
  echo No distribution specified.
  usage
  exit
fi

echo "Architecture: "${ARCH}

if [ -z ${ARCH} ]
then
  echo No architecture specified.
  usage
  exit
fi

FIXED=`curl -s -L "https://github.com/matlo/GIMX/issues?labels=GIMX+${VERSION}&state=closed" | grep "        #[0-9][0-9]*" | sed 's/        //g' | sed ':a;N;$!ba;s/\n/ /g'`

echo Fixed: $FIXED
echo Date: $DATE
echo Year: $YEAR

rm -rf $PACKAGE*

git clone -b $BRANCH --single-branch --depth 1 --recursive https://github.com/matlo/GIMX.git

VERSION=$(grep "#define INFO_VERSION " GIMX/info.h)
VERSION=${VERSION#*\"}
VERSION=${VERSION%%\"*}

mv GIMX $PACKAGE-${VERSION}

cp -r debian $PACKAGE-${VERSION}

cd $PACKAGE-${VERSION}

sed -i "s/#VERSION#/${VERSION}/" debian/changelog
sed -i "s/#FIXED#/$FIXED/" debian/changelog
sed -i "s/#DATE#/$DATE/" debian/changelog

sed -i "s/#DATE#/$DATE/" debian/copyright
sed -i "s/#YEAR#/$YEAR/" debian/copyright

if [ "${DIST}" == "jessie" ]
then
  sed -i "s/libwxgtk3.0-0v5/libwxgtk3.0-0/" debian/control
fi

if [ -n ${VERSION} ]
then
  MAJOR=$(echo ${VERSION} | awk -F"." '{print $1}')
  MINOR=$(echo ${VERSION} | awk -F"." '{print $2}')
  echo Major release number: $MAJOR
  echo Minor release number: $MINOR
  if [ -z $MAJOR ] || [ -z $MINOR ]
  then
    echo Invalid release number!
    exit
  fi

  sed -i "s/#define[ ]*INFO_VERSION[ ]*\"[0-9]*.[0-9]*\"/#define INFO_VERSION \"$MAJOR.$MINOR\"/" info.h
  sed -i "s/#define[ ]*INFO_YEAR[ ]*\"2010-[0-9]*\"/#define INFO_YEAR \"2010-$(date '+%Y')\"/" info.h
fi

OS=${OS} DIST=${DIST} ARCH=${ARCH} pdebuild

cp /var/cache/pbuilder/${OS}-${DIST}-${ARCH}/result/$PACKAGE\_${VERSION}-1_*.deb ../old
