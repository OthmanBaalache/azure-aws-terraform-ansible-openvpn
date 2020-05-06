.PHONY: all
all: tf-init tf-backend tf-init tf-validate tf-plan tf-apply ssh clean vm-keys

SHELL := /bin/bash -l
TERRAFORM_FOLDER :="terraform"
HOST:=
GATEWAY_ADDRESS:=

define getHost
	$(eval HOST=$(shell terraform output dnsLabel)".uksouth.cloudapp.azure.com")
endef

tf-backend:
	echo "Checking Azure Connection...."
	./scripts/setup-tf-backend.sh

tf-init:
	cd ${TERRAFORM_FOLDER} && \
	terraform init -backend-config=env/$(env)/backend.conf
	terraform get -update

tf-validate:
	cd ${TERRAFORM_FOLDER} && \
	terraform fmt
	terraform validate

tf-plan:
	cd ${TERRAFORM_FOLDER} && \
	terraform plan -var-file=env/$(env)/terraform.tfvars -var="homePip=$(shell curl -4 ifconfig.co)"

tf-apply:
	cd ${TERRAFORM_FOLDER} && \
	terraform apply -var-file=env/$(env)/terraform.tfvars --auto-approve -var="homePip=$(shell curl -4 ifconfig.co)"

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
