ansible-playbook playbook.yml --become-password-file=sudo --ask-vault-pass --tags=github

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com
