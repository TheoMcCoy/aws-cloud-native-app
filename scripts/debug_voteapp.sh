#!/bin/bash

echo "=== Debugging CloudAcademy Vote App ==="

# Check Nginx status
echo -e "\n--- Nginx Status ---"
sudo systemctl status nginx
sudo nginx -t

# Verify frontend files
echo -e "\n--- Frontend Files ---"
ls -l /usr/share/nginx/html
cat /usr/share/nginx/html/env-config.js 2>/dev/null

# Test local frontend access
echo -e "\n--- Test Frontend Access ---"
curl -I http://localhost

# Check API process
echo -e "\n--- API Process ---"
ps aux | grep ./api | grep -v grep

# Check API binary and logs
echo -e "\n--- API Binary and Logs ---"
ls -l /tmp/cloudacademy-app/api
grep "API" /var/log/userdata.log

# Test API endpoint
echo -e "\n--- Test API Endpoint ---"
curl http://localhost:8080/api/languages

# Check MongoDB connectivity
echo -e "\n--- MongoDB Connectivity ---"
MONGODB_PRIVATEIP=$(grep "mongodb://" /var/log/userdata.log | sed -E 's/.*mongodb:\/\/(.*):27017.*/\1/')
if [ -n "$MONGODB_PRIVATEIP" ]; then
  echo "Testing MongoDB connection to $MONGODB_PRIVATEIP:27017"
  nc -zv $MONGODB_PRIVATEIP 27017
else
  echo "MongoDB IP not found in logs."
fi

# Parse userdata log for errors
echo -e "\n--- Errors in /var/log/userdata.log ---"
grep -i "error" /var/log/userdata.log

echo -e "\n=== Debugging Complete ==="
