#!/bin/bash

termux-setup-storage
termux-change-repo

pkg update
pkg upgrade

pkg install python
pip install wheel
pkg install rust
export CARGO_BUILD_TARGET=aarch64-linux-android
apt install python-cryptography
pip install ansible

