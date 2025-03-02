echo -*********************************-
echo -** Add Ansible Repository      **-
echo -*********************************-

sudo apt-add-repository ppa:ansible/ansible -y

echo -*********************************-
echo -** Update and Upgrade Sysytem  **-
echo -*********************************-

sudo apt update
sudo apt upgrade -y

echo -*********************************-
echo -** Install Ansible             **-
echo -*********************************-

sudo apt install software-properties-common ansible -y



ansible-playbook playbook.yml --become-password-file=sudo --ask-vault-pass --tags=wsl

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com

ansible-playbook playbook.yml --tags=dotfiles

ansible-playbook playbook.yml --tags=.init.ubuntu
