# DevLab Environment Makefile

.PHONY: help install setup up-llm up-floci up-db up-kafka up-security up-cicd up-monitoring down-all k3s-up k8s-status scan-code tf-apply ansible-play

help:
	@echo "🚀 DevLab Automation CLI"
	@echo ""
	@echo "Usage:"
	@echo "  make install         - Launch the interactive installer (script.sh TUI)"
	@echo "  make setup           - Run non-interactive full installation"
	@echo "  make up-llm          - Start Local LLMs (Ollama + Open WebUI)"
	@echo "  make up-floci        - Start Floci Cloud Emulation Stack"
	@echo "  make up-db           - Start Database Stack (PostgreSQL + pgvector, Redis, Adminer)"
	@echo "  make up-kafka        - Start Kafka Streaming Stack (Redpanda + Web Console)"
	@echo "  make up-security     - Start DevSecOps Stack (SonarQube, OWASP ZAP, Trivy, Tailscale)"
	@echo "  make up-cicd         - Start CI/CD Stack (Woodpecker CI)"
	@echo "  make up-monitoring   - Start Real-Time Monitoring & Dashboard (Dashy, Beszel, Portainer)"
	@echo "  make scan-code       - Trigger Trivy local codebase vulnerability scan"
	@echo "  make tf-apply        - Run Terraform against local Floci cloud emulator"
	@echo "  make ansible-play    - Run Ansible playbook across devlab servers"
	@echo "  make k3s-up          - Install K3s Kubernetes Engine"
	@echo "  make k8s-status      - Check status of K8s cluster and pods"
	@echo "  make down-all        - Stop all Docker Compose stacks"

install:
	@chmod +x script.sh && ./script.sh

setup:
	@chmod +x script.sh && ./script.sh --all --non-interactive

up-llm:
	docker compose -f docker/docker-compose.llm.yml up -d

up-floci:
	docker compose -f docker/docker-compose.floci.yml up -d

up-db:
	docker compose -f docker/docker-compose.databases.yml up -d

up-kafka:
	docker compose -f docker/docker-compose.kafka.yml up -d

up-security:
	docker compose -f docker/docker-compose.security.yml up -d

up-cicd:
	docker compose -f docker/docker-compose.cicd.yml up -d

up-monitoring:
	docker compose -f docker/docker-compose.monitoring.yml up -d

scan-code:
	@echo "🔍 Scanning codebase with Trivy..."
	docker run --rm -v $(PWD):/work aquasec/trivy:latest fs /work

tf-apply:
	@echo "🚀 Applying Terraform against local Floci cloud emulator..."
	cd terraform && terraform init && terraform apply -auto-approve

ansible-play:
	@echo "🤖 Running Ansible playbook across nodes..."
	ansible-playbook -i ansible/inventory.ini ansible/playbook.yml

k3s-up:
	curl -sfL https://get.k3s.io | sh -
	mkdir -p ~/.kube && sudo cp /etc/rancher/k3s/k3s.yaml ~/.kube/config && sudo chown $(USER):$(USER) ~/.kube/config

k8s-status:
	kubectl get nodes
	kubectl get pods -A

down-all:
	-docker compose -f docker/docker-compose.llm.yml down
	-docker compose -f docker/docker-compose.floci.yml down
	-docker compose -f docker/docker-compose.databases.yml down
	-docker compose -f docker/docker-compose.kafka.yml down
	-docker compose -f docker/docker-compose.security.yml down
	-docker compose -f docker/docker-compose.cicd.yml down
	-docker compose -f docker/docker-compose.monitoring.yml down
	-docker compose -f docker/docker-compose.services.yml down
