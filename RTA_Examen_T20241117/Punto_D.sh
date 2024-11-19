#!/bin/bash
ssh-keygen -t ed25519
cat $HOME/.ssh/id_ed25519.pub >> $HOME/.ssh/authorized_keys
cd ..
cd 202406/
cd ansible/
ansible-playbook -i inventory/hosts playbook.yml
