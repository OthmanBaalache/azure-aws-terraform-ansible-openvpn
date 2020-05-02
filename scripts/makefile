.PHONY: init

init:
	$(info updating the packages)
	@sudo sed -i -e 's|disco|eoan|g' /etc/apt/sources.list
	@sudo apt update -y
	@sudo apt upgrade -y
	@sudo apt install software-properties-common
	@sudo apt-add-repository --yes --update ppa:ansible/ansible
	@sudo apt install ansible

.PHONY: setup
setup:
	@ansible-playbook -i localhost ~/scripts/playbooks/install-vpn.yml

.PHONY: all
all: init setup


