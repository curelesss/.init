ansible-playbook 1.book.github.yml -K --ask-vault-pass --tags=github

git remote set-url origin git@github.com:curelesss/.init.git

ssh -T git@github.com
