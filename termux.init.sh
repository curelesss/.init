#!/bin/bash

mv termux/ansible.cfg ./

termux-setup-storage
sleep 5s
termux-change-repo

pkg update
pkg upgrade

pkg install python -y
pip install wheel
pkg install rust -y
export CARGO_BUILD_TARGET=aarch64-linux-android
apt install python-cryptography -y
pip install ansible

ansible-playbook playbook.yml --ask-vault-pass --tags=github
ansible-playbook playbook.yml --tags=termux

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com

mv ansible.cfg termux/
