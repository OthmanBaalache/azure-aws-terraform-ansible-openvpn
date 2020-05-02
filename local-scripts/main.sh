#!/bin/bash
#Function to create an Azure Storage Account to place our tfstate file
createTfStorage() {
  #Variables
  RESOURCE_GROUP_NAME=$1
  STORAGE_ACCOUNT_NAME=$2
  CONTAINER_NAME=$3
  REGION=$4
  # Create resource group
  az group create --name $RESOURCE_GROUP_NAME --location $REGION

  # Create storage account
  az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

  # Get storage account key
  ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)
  # Create blob container
  az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY
}
createTfStorage "$1" "$2" "$3" "$4"
