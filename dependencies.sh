#!/usr/bin/env bash

# Miscellaneous
sudo apt install -y git octave octave-io jq

# Python
sudo apt install -y python python-pip python3 python3-pip python3-tk
sudo pip3 install Pmw # sudo may not be needed

# Perl
sudo apt install -y perl libyaml-perl libxml-perl

# CAD tools and SW toolchains dependencies
sudo apt install -y xterm
sudo apt install -y csh ksh zsh tcl
sudo apt install -y build-essential
sudo apt install -y libgl1-mesa-dev libglu1-mesa libgl1-mesa-dri
sudo apt install -y libreadline-dev
sudo apt install -y libxpm-dev
sudo apt install -y libmotif-dev
sudo apt install -y libncurses5
sudo apt install -y libncurses-dev
sudo apt install -y libgdbm-dev
sudo apt install -y libsm-dev
sudo apt install -y libxcursor-dev
sudo apt install -y libxft-dev
sudo apt install -y libxrandr-dev
sudo apt install -y libxss-dev
sudo apt install -y libmpc-dev
sudo apt install -y libnspr4
sudo apt install -y libnspr4-dev
sudo apt install -y libboost-all-dev
sudo apt install -y tk tk-dev
sudo apt install -y flex
sudo apt install -y rename
sudo apt install -y zlib1g:i386
sudo apt install -y gcc-multilib
sudo apt install -y device-tree-compiler
sudo apt install -y bison
sudo apt install -y xvfb

# For older GUIs (e.g. Stratus)
echo 'deb http://security.ubuntu.com/ubuntu xenial-security main' | sudo tee -a /etc/apt/sources.list
sudo apt install -y libpng12-0

# QT
sudo apt install -y qtcreator
