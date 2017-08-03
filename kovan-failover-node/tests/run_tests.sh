#!/bin/bash

rm -f results/*

index=1

for file in azuredeploy.parameters.*.json; do
  rgname="testkovan${index}"
  echo "Deploying ${file} to ${rgname} ..."
  az group create --name ${rgname} --location westeurope
  az group deployment create --resource-group ${rgname} --template-file ../mainTemplate.json --parameters @${file} > results/${file} 2>&1
  echo "Result: ${?}"
  if [ $? -eq 0 ]; then
    echo "Deleting resource group ${rgname} ..."
    az group delete --name ${rgname}  --yes
  fi
  index=$((index + 1))
done
