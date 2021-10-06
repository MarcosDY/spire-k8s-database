.PHONY: images 
images: client-image api-image spiffe-helper-image

.PHONY: spiffe-helper-image
spiffe-helper-image: Dockerfile
	docker build --target spiffe-helper -t spiffe-helper .
	docker tag spiffe-helper:latest spiffe-helper:latest-local

.PHONY: client-image
client-image: Dockerfile
	docker build --target client-service -t client-service .
	docker tag client-service:latest client-service:latest-local

.PHONY: service-image
api-image: Dockerfile
	docker build --target api-service -t api-service .
	docker tag api-service:latest api-service:latest-local

.PHONY: cluster-create
cluster-create:
	./1-cluster-create.sh

.PHONY: cluster-delete
cluster-delete:
	./8-cluster-delete.sh

.PHONY: deploy
deploy: images
	./3-deploy.sh

.PHONY: test
test:
	./4-call-client.sh

.PHONY: clean
clean: 
	./clean.sh
