.PHONY: all
all: tf-init tf-backend tf-init tf-validate tf-plan tf-apply ssh clean vm-keys

SHELL := /bin/bash -l
TERRAFORM_FOLDER ?= "terraform"
TERRAFORM_VERSION := 0.12.23
HOST:=
GATEWAY_ADDRESS:=

define getHost
	$(eval HOST=$(shell terraform output dnsLabel)".uksouth.cloudapp.azure.com")
endef

tf-backend:
	@echo "Checking Azure Connection...."
	@./local-scripts/main.sh

tf-init:
	@terraform init ${TERRAFORM_FOLDER}-backend-config=${TERRAFORM_FOLDER}/env/$(env)/backend.conf

tf-validate:
	@terraform fmt ${TERRAFORM_FOLDER}
	@terraform validate ${TERRAFORM_FOLDER}

tf-plan:
	@$(call getGateway)
	@terraform plan -var-file=${TERRAFORM_FOLDER}/env/$(env)/terraform.tfvars -var="homePip=$(shell curl -4 ifconfig.co)"

tf-apply:
	@terraform apply -var-file=${TERRAFORM_FOLDER}/env/$(env)/terraform.tfvars --auto-approve

ssh:
	@chmod 400 ~/mykeys/*
	@$(call getHost)
	@echo $(HOST)
	@ssh-keygen -R $(HOST)
	@ssh -i ~/mykeys/id_rsa "ovpnadmin@"$(HOST)

clean:
	@terraform destroy -var-file=${TERRAFORM_FOLDER}/env/$(env)/terraform.tfvars --auto-approve

vm-keys:
	@mkdir -p ./.tmp
	@ssh-keygen -C "vm-keys" -f ./.tmp/id_rsa -q -N ""
	@chmod 400 ./.tmp/*
