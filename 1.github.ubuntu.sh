sudo apt-add-repository ppa:ansible/ansible -y
sudo apt update
sudo apt install software-properties-common ansible -y


git remote set-url origin git@github.com:curelesss/init.git
ansible-playbook playbook.yml --become-password-file=sudo --ask-vault-pass --tags=github
ssh -T git@github.com
