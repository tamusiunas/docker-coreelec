#!/bin/bash

DOCKER_TAG="v20.10.6"
DOCKER_VERSION="v20.10.6-2-g4af54f15ed.m"
DOCKER_DATE="20210424000000"

arch_uname=$(uname -m)
if [ -z "${arch_uname##*aarch64*}" ]; then
  ARCH_TAR="arm64"
elif [ -z "${arch_uname##*hf*}" ]; then
  ARCH_TAR="armv7"
elif [ -z "${arch_uname##*v7*}" ]; then
  ARCH_TAR="armv7"
elif [ -z "${arch_uname##*v6*}" ]; then
  ARCH_TAR="armv6"
else
  echo "Architecture $arch_uname not supported"
  exit 1
fi

DOCKER_FILE="docker_${DOCKER_VERSION}_coreelec_${ARCH_TAR}_${DOCKER_DATE}.tar.gz" 
DOCKER_URL="https://github.com/tamusiunas/docker-coreelec/releases/download/${DOCKER_TAG}/${DOCKER_FILE}"

if [ -f "/storage/.kodi/addons/service.system.docker/bin/dockerd" ]; then
  echo ""
  read -p "Found a Docker package installed via kodi addon. Do you want to remove it and install corelec-docker 20.10 [y/N]? " choise
  if [ "$choise" == "y" -o "$choise" == "Y" ]; then
      echo ""
      echo "Uninstalling Docker addon"
      echo ""
      #
      # Stop and remove files
      #
      systemctl stop service.system.docker.service
      systemctl disable service.system.docker.service
      rm -rf /storage/.kodi/addons/service.system.docker
      rm -rf /storage/.kodi/userdata/addon_data/service.system.docker
      rm -rf /storage/.kodi/addons/packages/service.system.docker-19.1.133.zip
      #
      # Remove from sqlite (addons)
      #
      echo "delete from installed where addonID like '%docker%'; vacuum;" | sqlite3 /storage/.kodi/userdata/Database/Addons33.db
      echo "delete from texture where url like '%docker%'; vacuum;" | sqlite3 /storage/.kodi/userdata/Database/Textures13.db
  else
    echo ""
    echo "Installation aborted."
    echo ""
    exit 1
  fi
fi

#
# Install docker

echo ""
echo "DOCKER_URL: ${DOCKER_URL}"
echo "Downloading docker. This may take a while."
echo ""
curl -L --fail ${DOCKER_URL} -o /storage/${DOCKER_FILE}
cd /
echo ""
echo "Installing Docker"
echo ""
tar zxvf /storage/${DOCKER_FILE}
echo ""
echo "Configuring dockerd service"
echo "This may take a while"
echo ""
systemctl daemon-reload
systemctl enable service.system.docker.service  
systemctl restart service.system.docker
rm /storage/${DOCKER_FILE}

#
# /storage/.profile
#
echo ""
echo "Configuring PATH"
echo ""
path_found=$(grep "PATH=/storage/.docker/bin" /storage/.profile 2>/dev/null)
if [ "$path_found" == "" ]; then
  echo "export PATH=/storage/.docker/bin:\$PATH" >> /storage/.profile
  echo "docker PATH added to /storage/.profile"
fi
echo ""           
echo "Installation is almost finished. You have to reboot the system now to finish it."
echo "For more information about the package visit https://github.com/tamusiunas/docker-coreelec"
echo ""
if [ "$1" == "noshutdown" ]; then
  exit 0
fi
read -p "Do you want to reboot the system now [y/N]? " choise
if [ "$choise" == "y" -o "$choise" == "Y" ]; then
  shutdown -r now
fi
