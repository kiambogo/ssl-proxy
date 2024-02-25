PHONY: help

GREEN = \033[32m
RESET = \033[0m

help:
	@echo "🐳 SSL Proxy Makefile$(RESET)"
	@echo "Available commands:$(RESET)"
	@echo "� $(GREEN)make build-squid$(RESET) - Build the docker image for the squid proxy"
	@echo "� $(GREEN)make build-icap-server$(RESET) - Build the docker image for the ICAP server"
	@echo "� $(GREEN)make kube-deploy$(RESET) - Deploy the squid and icap-server to minikube"
	@echo "� $(GREEN)make gen-certs$(RESET) - Generate the certificates for squid and icap-server"
	@echo "� $(GREEN)make gen-ca-cert$(RESET) - Generate the CA certificate"
	@echo "� $(GREEN)make gen-server-cert$(RESET) - Generate the server certificate"
	@echo "� $(GREEN)make gen-client-cert$(RESET) - Generate the client certificate"
	@echo "� $(GREEN)make access-logs$(RESET) - Tail the access logs of the squid proxy"
	@echo "� $(GREEN)make squid-shell$(RESET) - Open a shell in the squid container"


check-minikube:
	@if [ -z "$$(minikube status | grep Running)" ]; then \
		echo "❌ $(RED)Minikube is not running$(RESET)"; \
		echo "❌ $(RED)Please run minikube start$(RESET)"; \
		exit 1; \
	fi

check-ca-cert:
	@if [ ! -f certs/ca.crt ]; then \
		echo "❌ $(RED)certs/ca.crt not found$(RESET)"; \
		echo "❌ $(RED)Please run make gen-ca-cert$(RESET)"; \
		exit 1; \
	fi

build-squid:
	@echo "Compiling and building squid. This may take several minutes..."
	@docker build -t squid ./squid 2>/dev/null
	@echo "✅ $(GREEN)squid built$(RESET)"

build-icap-server:
	@docker build -t icap-server ./icap-server 2>/dev/null
	@echo "✅ $(GREEN)icap-server built$(RESET)"

kube-deploy: check-minikube
	@kubectl apply -f deploy >/dev/null
	@echo "✅ $(GREEN)ssl-proxy stack deployed$(RESET)"

clean-certs:
	-@sudo security delete-certificate -c ssl-proxy-ca 2>/dev/null || true
	@rm -f certs/*.crt certs/*.key certs/*.csr certs/*.srl
	@echo "✅ $(GREEN)certs cleaned$(RESET)"

gen-certs: clean-certs gen-ca-cert gen-server-cert gen-client-cert

gen-ca-cert: check-minikube
	@openssl req -x509 -newkey rsa:4096 -keyout certs/ca.key -out certs/ca.crt -nodes -subj "/CN=ssl-proxy-ca" -addext "subjectAltName = DNS:ssl-proxy-ca" -addext 'basicConstraints = critical,CA:TRUE' 2>/dev/null
	-@kubectl delete configmap ca-certs >/dev/null
	@kubectl create configmap ca-certs --from-file=certs/ca.crt --from-file=certs/ca.key >/dev/null
	@echo "✅ $(GREEN)ca-certs created$(RESET)"
	@echo "You will now be prompted to trust the CA certificate in your OSX Keychain"
	sudo security add-trusted-cert -d -r trustRoot -k /Library/Keychains/System.keychain certs/ca.crt
	@echo "✅ $(GREEN)CA cert added + trusted$(RESET)"

gen-server-cert: check-minikube check-ca-cert
	@openssl req -newkey rsa:4096 -nodes -keyout certs/server.key -out certs/server.csr -config certs/server.cnf 2>/dev/null
	@openssl x509 -req -in certs/server.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/server.crt -extensions req_ext -extfile certs/server.cnf 2>/dev/null
	-@kubectl delete configmap server-certs >/dev/null || true
	@kubectl create configmap server-certs --from-file=certs/server.crt --from-file=certs/server.key >/dev/null
	@echo "✅ $(GREEN)server-certs created$(RESET)"

gen-client-cert: check-ca-cert
	@openssl req -newkey rsa:4096 -nodes -keyout certs/client.key -out certs/client.csr -config certs/client.cnf 2>/dev/null
	@openssl x509 -req -in certs/client.csr -CA certs/ca.crt -CAkey certs/ca.key -CAcreateserial -out certs/client.crt -extensions req_ext -extfile certs/client.cnf 2>/dev/null
	@echo "✅ $(GREEN)client-certs created$(RESET)"

access-logs:
	kubectl exec -c squid -it $(shell kubectl get pods -l app=squid -o jsonpath='{.items[0].metadata.name}') -- tail -f /var/log/squid/access.log

squid-shell:
	kubectl exec -c squid -it $(shell kubectl get pods -l app=squid -o jsonpath='{.items[0].metadata.name}') -- /bin/bash
