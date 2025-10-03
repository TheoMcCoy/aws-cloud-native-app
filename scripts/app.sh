#!/bin/bash
# app.sh - bootstrap frontend + API

set -xe

yum update -y
amazon-linux-extras enable nginx1
yum install -y nginx jq tar curl

systemctl enable nginx
systemctl start nginx

# ALB + MongoDB injected by Terraform
ALB_DNS="${ALB_DNS}"
MONGODB_PRIVATEIP="${MONGODB_PRIVATEIP}"

mkdir -p /tmp/cloudacademy-app
cd /tmp/cloudacademy-app

echo "==========================="
echo "FRONTEND - download latest release and install..."
mkdir -p ./voteapp-frontend-react-2020
pushd ./voteapp-frontend-react-2020
curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest | jq -r '.assets[0].browser_download_url' | xargs curl -OL
INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-frontend-react-2020/releases/latest | jq -r '.assets[0].name')
tar -xvzf $INSTALL_FILENAME
rm -rf /usr/share/nginx/html
cp -R build /usr/share/nginx/html
cat > /usr/share/nginx/html/env-config.js << EOFF
window._env_ = {REACT_APP_APIHOSTPORT: "$ALB_DNS"}
EOFF
popd

echo "==========================="
echo "API - download latest release, install, and start..."
mkdir -p ./voteapp-api-go
pushd ./voteapp-api-go
curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .browser_download_url' | xargs curl -OL
INSTALL_FILENAME=$(curl -sL https://api.github.com/repos/cloudacademy/voteapp-api-go/releases/latest | jq -r '.assets[] | select(.name | contains("linux-amd64")) | .name')
tar -xvzf $INSTALL_FILENAME
MONGO_CONN_STR="mongodb://$MONGODB_PRIVATEIP:27017/langdb" ./api &
popd

systemctl restart nginx
