#!/bin/bash
VERSION=0.1
echo ""
echo "$0 version $VERSION"
echo "Docker compiler (client and server) for CoreELEC systems"
while getopts ":h" opt; do
  case ${opt} in
    h )
      echo "Usage:"
      echo "    $0 -h                      Display this help message."
      echo "    $0 build                   Build docker for local architecture."
      echo "    $0 buildx                  Build docker using buildx for other architecture."
      exit 0
      ;;
    \? )
      echo "Invalid Option: -$OPTARG" 1>&2
      echo "Usage:"
      echo "    $0 -h                      Display help message."
      exit 1
      ;;
  esac
done
shift $((OPTIND -1))

bold=$(tput bold)
normal=$(tput sgr0)

function print_error_arg_buildx () {
  echo "Invalid architecture"
  echo "Usage:"
  echo "    $0 buildx -a <arch>"
  echo "    <arch> must be ${bold}arm64${normal}, ${bold}armv7${normal} or ${bold}armv6${normal}"
}

BUILDX_PREFIX="buildx-v0.5.1."
CTOP_PREFIX="ctop-0.7.5-"
ARCH=""
arch_uname=$(uname -m)
if [ -z "${arch_uname##*aarch64*}" ]; then
  ARCH="linux/arm64"
  ARCH_TAR="arm64"
  BUILDX_SUFFIX="linux-arm64"
  CTOP_SUFFIX="linux-arm64"
elif [ -z "${arch_uname##*hf*}" ]; then
  ARCH="linux/arm/v7"
  ARCH_TAR="armv7"
  BUILDX_SUFFIX="linux-arm-v7"
  CTOP_SUFFIX="linux-arm"
elif [ -z "${arch_uname##*v7*}" ]; then
  ARCH="linux/arm/v7"
  ARCH_TAR="armv7"
  BUILDX_SUFFIX="linux-arm-v7"
  CTOP_SUFFIX="linux-arm"
elif [ -z "${arch_uname##*v6*}" ]; then
  ARCH="linux/arm/v6"
  ARCH_TAR="armv6"
  BUILDX_SUFFIX="linux-arm-v6"
  CTOP_SUFFIX="linux-arm"
fi

subcommand=$1; shift
case "$subcommand" in
  build )
    BUILD_METHOD="build"
    if [ "$ARCH" == "" ]; then
      echo "Your architecture is not compatible. Try using \"$0 buildx\" instead \"$0 build\""
      exit 1
    fi
    ;;
  buildx )
    BUILD_METHOD="buildx"
    if [ $# -eq 0 ]; then
      print_error_arg_buildx
      exit 1
    fi
    while getopts ":a" opt; do
      case ${opt} in
        a ) 
          if [ $# -eq 0 ]; then
	    print_error_arg_buildx
          fi
	  shift $((OPTIND -1))
          architecturespecified=$1; shift
          case "$architecturespecified" in
	    "arm64" )
	      ARCH="linux/arm64"
              ARCH_TAR="arm64"
	      BUILDX_SUFFIX="linux-arm64"
	      CTOP_SUFFIX="linux-arm64"
              ;;
	    "armv7" )
	      ARCH="linux/arm/v7"
              ARCH_TAR="armv7"
	      BUILDX_SUFFIX="linux-arm-v7"
	      CTOP_SUFFIX="linux-arm"
              ;;
	    "armv6" )
	      ARCH="linux/arm/v6"
              ARCH_TAR="armv6"
	      BUILDX_SUFFIX="linux-arm-v6"
	      CTOP_SUFFIX="linux-arm"
              ;;
	    * )
	      print_error_arg_buildx
	      exit 1
	      ;;
	  esac
          ;;
        * ) 
          echo "Invalid option"
          echo "Usage:"
          echo "    $0 buildx -a <arch>"
	  exit 1
          ;;
      esac
    done
    ;;
  *)
    echo "Invalid option $subcommand"
    echo "Usage:"
    echo "    $0 -h                      Display help message."
    exit 1
    ;;
esac
if [ "$ARCH" == "" ]; then
  print_error_arg_buildx
  exit 1
fi
echo "BUILD_METHOD: $BUILD_METHOD"
echo "ARCH: $ARCH"
echo "BUILDX_SUFFIX: $BUILDX_SUFFIX"
docker_buildx_found=$(docker info 2>/dev/null | grep buildx)
if [ "$BUILD_METHOD" == "buildx" ]; then
  if [ -z "${docker_buildx_found##*buildx*}" ]; then
    echo "Support for buildx detected"
  else
    echo "Support for buildx not detected"
    exit 1
  fi 
fi

#
# Preparing environment
#
rm -rf ./build_tmp && rm -f ./storage/.docker/bin/* && rm -f ./storage/.docker/cli-plugins/*
mkdir -p storage/.docker/bin storage/.docker/cli-plugins storage/.docker/data-root build_tmp

#
# Download from github
#

curl -L --fail https://github.com/docker/buildx/releases/download/v0.5.1/$BUILDX_PREFIX$BUILDX_SUFFIX -o ./storage/.docker/cli-plugins/docker-buildx && chmod a+x ./storage/.docker/cli-plugins/docker-buildx
curl -L --fail https://github.com/bcicen/ctop/releases/download/v0.7.5/$CTOP_PREFIX$CTOP_SUFFIX -o ./storage/.docker/bin/ctop && chmod a+x ./storage/.docker/bin/ctop
curl -L --fail https://raw.githubusercontent.com/linuxserver/docker-docker-compose/master/run.sh -o ./storage/.docker/bin/docker-compose && chmod a+x ./storage/.docker/bin/docker-compose
cd build_tmp
git clone https://github.com/moby/moby.git
cd moby && git checkout -t origin/20.10 && cd ..
patch -p0 < ../patch/patch_daemon_unix_go.patch
git clone https://github.com/docker/cli.git
cd cli && git checkout -t origin/20.10 && cd ..
if [ "$BUILD_METHOD" == "buildx" ]; then
  cd moby
  MOBY_VERSION=$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)
  VERSION="$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)" USE_BUILDX=1 BUILDX="docker buildx" BUILDX_BUILD_EXTRA_OPTS="--platform $ARCH" make 
  cd ../cli
  VERSION="$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)" docker buildx bake --set binary.platform=$ARCH
  cd ../..
else
  cd moby
  MOBY_VERSION=$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)
  VERSION="$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)"  make 
  cd ../cli
  VERSION="$(git describe --match 'v[0-9]*' --dirty='.m' --always --tags)" docker buildx bake
  cd ../..
fi
cp -p build_tmp/moby/bundles/binary-daemon/{containerd,containerd-shim,containerd-shim-runc-v2,ctr,docker-init,docker-proxy,dockerd,dockerd-rootless-setuptool.sh,dockerd-rootless.sh,rootlesskit,rootlesskit-docker-proxy,runc,vpnkit} ./storage/.docker/bin
cp -p build_tmp/cli/build/docker* ./storage/.docker/bin
TIME_NOW=$(date +"%Y%m%d%H%M%S")
tar zcvf docker_${MOBY_VERSION}_coreelec_${ARCH_TAR}_${TIME_NOW}.tar.gz storage
