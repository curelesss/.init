echo -*********************************-
echo -** Update Ubuntu Mirror List   **-
echo -*********************************-

sudo rm -f /etc/apt/sources.list
sudo cp ./sources.list /etc/apt/

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

echo -*********************************-
echo -** Set current repo to ssh     **-
echo -*********************************-

git remote set-url origin git@github.com:curelesss/init.git

echo -*********************************-
echo -** Run Ansible Init Play-book  **-
echo -*********************************-

ansible-playbook playbook.yml --ask-vault-pass --tags=ubuntu

echo -*********************************-
echo -** Testing Github Connection   **-
echo -*********************************-

ssh -T git@github.com
