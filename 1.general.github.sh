ansible-playbook book.1.github.yml -K --ask-vault-pass --tags=github

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com
