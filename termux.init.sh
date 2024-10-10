#!/bin/bash

mv termux/termux.init.sh ./

termux-setup-storage
sleep 30s
termux-change-repo

pkg update
pkg upgrade

pkg install python
pip install wheel
pkg install rust
export CARGO_BUILD_TARGET=aarch64-linux-android
apt install python-cryptography
pip install ansible

ansible-playbook playbook.yml --ask-vault-pass --tags=github

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com

mv termux.init.sh termux/
