#!/bin/bash
#Test Azure connection
azTest() {
  TEST=$(az account list --only-show-errors)
  if [ "$TEST" != '[]' ]; then
    echo You are already connected!

  elif [ "$TEST" = '[]' ]; then
    echo Authenticating to azure...
    azConnect
  else
    echo Fatal error check your connectivity and that you have the azure-cli installed!
  fi
}

#Connect and authenticate to Azure
azConnect() {
    az login --only-show-errors
}

#Get Input Variables
getInput() {
read -p "Enter RESOURCE_GROUP_NAME: " RESOURCE_GROUP_NAME
read -p "Enter STORAGE_ACCOUNT_NAME: " STORAGE_ACCOUNT_NAME
read -p "Enter CONTAINER_NAME: " CONTAINER_NAME
read -p "Enter REGION: " REGION
}

#Function to create an Azure Storage Account to place our tfstate file
createTfStorage() {

  # Create resource group
  az group create --name $RESOURCE_GROUP_NAME --location $REGION

  # Create storage account
  az storage account create --resource-group $RESOURCE_GROUP_NAME --name $STORAGE_ACCOUNT_NAME --sku Standard_LRS --encryption-services blob

  # Get storage account key
  ACCOUNT_KEY=$(az storage account keys list --resource-group $RESOURCE_GROUP_NAME --account-name $STORAGE_ACCOUNT_NAME --query [0].value -o tsv)
  # Create blob container
  az storage container create --name $CONTAINER_NAME --account-name $STORAGE_ACCOUNT_NAME --account-key $ACCOUNT_KEY
}
azTest
getInput
createTfStorage "$RESOURCE_GROUP_NAME" "$STORAGE_ACCOUNT_NAME" "$CONTAINER_NAME" "$REGION"