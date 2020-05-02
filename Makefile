
HOST:=
GATEWAY_ADDRESS:=

define getHost
	$(eval HOST=$(shell terraform output dnsLabel)".uksouth.cloudapp.azure.com")
endef

.PHONY: setup-backend
setup-backend:
	@./local-scripts/connect.sh
	@./local-scripts/main.sh "rg-uks-tfstate" "saukstfstate" "prod" "uksouth"

.PHONY: tf-init
tf-init:
	@terraform init -backend-config=./environment/$(env)/backend.conf

.PHONY: tf-plan
tf-plan:
	@terraform fmt
	@terraform validate
	@$(call getGateway)
	@terraform plan -var-file=./environment/$(env)/terraform.tfvars -var="homePip=$(shell curl -4 ifconfig.co)"
tf-apply:
	@terraform apply -var-file=./environment/$(env)/terraform.tfvars --auto-approve

ssh:
	@chmod 400 ~/mykeys/*
	@$(call getHost)
	@echo $(HOST)
	@ssh-keygen -R $(HOST)
	@ssh -i ~/mykeys/id_rsa "ovpnadmin@"$(HOST)

.PHONY: clean

clean:
	@terraform destroy -var-file=./environment/$(env)/terraform.tfvars --auto-approve