#!/bin/sh

wget -O- https://apt.releases.hashicorp.com/gpg \
  | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com bullseye main" \
  | sudo tee /etc/apt/sources.list.d/hashicorp.list

sudo apt update
sudo apt install -yq \
  packer \
  vim \
  git \
  unzip

sudo update-alternatives --set editor "$(which vim.basic)"

echo "LC_ALL=en_US.UTF-8" >> /etc/default/locale

curl https://releases.hashicorp.com/vault/1.17.2/vault_1.17.2_linux_amd64.zip -o vault.zip
unzip vault.zip
mv vault /usr/bin/
