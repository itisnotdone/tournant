#!/bin/bash

GIT_USER=\"Don Draper\"
GIT_MAIL=\"donoldfashioned@gmail.com\"

echo "[user]" >> .git/config
echo "  user = $GIT_USER" >> .git/config
echo "  mail = $GIT_MAIL" >> .git/config

git config --list | egrep 'user|mail"
