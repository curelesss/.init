
echo -*********************************-
echo -** Set current repo to ssh     **-
echo -*********************************-

git remote set-url origin git@github.com:curelesss/.init.git

echo -*********************************-
echo -** Run Ansible Init Play-book  **-
echo -*********************************-

ansible-playbook playbook.yml --ask-vault-pass --tags=macos

echo -*********************************-
echo -** Testing Github Connection   **-
echo -*********************************-

ssh -T git@github.com
