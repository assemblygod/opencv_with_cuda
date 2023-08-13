#!/usr/bin/env bash

#
# Copyright (c) 2023, ABHIYAAN Limited. All rights reserved.
#
# ABHIYAAN Limited and its licensors retain all intellectual property
# and proprietary rights in and to this software, related documentation
# and any modifications thereto. Any use, reproduction, disclosure or
# distribution of this software and related documentation without an express
# license agreement from ABHIYAAN Limited is strictly prohibited.
#

version="4.5.3"
folder="opencv_stuff"
opencv_folder="opencv-${version}"

# Setting the colors, change if the script doesn't work!!
green='\033[0;32m'
red='\033[0;31m'
nc='\033[0m'

# I refuse to tell what this line is for (bunch of laughing emojis)
set -e


if [ -n "$(dpkg -l | grep libopencv)" ]; then
    echo -e "${green}** Removing existing OpenCV installation${nc}"
    sudo apt -y purge *libopencv*
else
    echo -e "${red}OpenCV is not preinstalled.\nIf you have built it already then remove that shit respectfully.${nc}"
fi


flag_file="/tmp/opencv_install_flag"
if [ ! -f "$flag_file" ]; then
    echo -e "${green}------------------------------------${nc}"
    echo -e "${green}** Install requirement (1/4)${nc}"
    echo -e "${green}------------------------------------${nc}"
    sudo apt-get update
    sudo apt-get install -y build-essential cmake git libgtk2.0-dev pkg-config libavcodec-dev libavformat-dev libswscale-dev
    sudo apt-get install -y libgstreamer1.0-dev libgstreamer-plugins-base1.0-dev
    sudo apt-get install -y python3.8-dev python-dev python-numpy python3-numpy
    sudo apt-get install -y libtbb2 libtbb-dev libjpeg-dev libpng-dev libtiff-dev libdc1394-22-dev
    sudo apt-get install -y libv4l-dev v4l-utils qv4l2
    sudo apt-get install -y curl

    sudo touch "$flag_file"
else
    echo -e "${green}Necessary requirements already installed.${nc}"
fi

if [ ! -d "$folder" ] || [ ! -d "${folder}/${opencv_folder}" ]; then
    echo -e "${green}------------------------------------${nc}"
    echo -e "${green}** Download opencv "${version}" (2/4)${nc}"
    echo -e "${green}------------------------------------${nc}"
    mkdir -p $folder
    cd $folder
    curl -L https://github.com/opencv/opencv/archive/${version}.zip -o opencv-${version}.zip
    curl -L https://github.com/opencv/opencv_contrib/archive/${version}.zip -o opencv_contrib-${version}.zip
    unzip opencv-${version}.zip
    unzip opencv_contrib-${version}.zip
    rm opencv-${version}.zip opencv_contrib-${version}.zip
    cd $opencv_folder
else
    cd $folder
    cd $opencv_folder
    echo -e "${green}OpenCV folders already exist, skipping download and extraction.${nc}"
fi


echo -e "${green}------------------------------------${nc}"
echo -e "${green}** Build opencv "${version}" (3/4)${nc}"
echo -e "${green}------------------------------------${nc}"

if [ ! -d "build" ]; then
    mkdir build
    cd build/
else
    cd build/
fi

cmake \
    -D CMAKE_C_COMPILER=/usr/bin/gcc-11 \
    -D CMAKE_CXX_COMPILER="/usr/bin/g++-11" \
    -D BUILD_opencv_python2=OFF \
    -D WITH_CUDA=ON\
    -D WITH_CUDNN=ON \
    -D CUDA_ARCH_BIN="8.6" \
    -D CUDA_ARCH_PTX="" \
    -D OPENCV_GENERATE_PKGCONFIG=ON \
    -D OPENCV_EXTRA_MODULES_PATH=../../opencv_contrib-${version}/modules \
    -D WITH_GSTREAMER=ON \
    -D WITH_LIBV4L=ON \
    -D BUILD_opencv_python3=ON \
    -D BUILD_TESTS=OFF \
    -D BUILD_PERF_TESTS=OFF \
    -D BUILD_EXAMPLES=OFF \
    -D CMAKE_BUILD_TYPE=RELEASE \
    -D CMAKE_INSTALL_PREFIX=/usr/local \
    ..


make -j$(nproc)


echo -e "${green}------------------------------------${nc}"
echo -e "${green}** Install opencv "${version}" (4/4)${nc}"
echo -e "${green}------------------------------------${nc}"
sudo make install

echo 'export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH' >> ~/.zshrc
echo 'export PYTHONPATH=/usr/local/lib/python3.8/site-packages/:$PYTHONPATH' >> ~/.zshrc
source ~/.zshrc


echo -e "${green}** Install opencv "${version}" successfully${nc}\n\n"
python3 -c "import cv2; print('OpenCV is built with CUDA support' if 'cuda' in cv2.getBuildInformation() else 'OpenCV is not built with CUDA support')"
echo -e "\n\n${red}TILL THE NEXT TIME, BITCHES!${nc}"
