ansible-playbook playbook.yml --become-password-file=sudo --ask-vault-pass --tags=arch

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com

ansible-playbook playbook.yml --tags=dotfiles
