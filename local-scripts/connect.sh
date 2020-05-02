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
    echo Fatal error check your connectivity andyou have the azure-cli installed!
  fi
}
#Connect and authenticate to Azure
azConnect() {
    az login --only-show-errors
}
azTest
