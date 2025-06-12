REGION=ap-northeast-1
IMAGE_TAG=latest

dev:
	@env $$(cat .env | xargs) uvicorn app.main:app --reload

gen-requirements:
	pipenv requirements > requirements.txt

docker-build: gen-requirements
	docker build $$(cat .env | xargs -n1 echo --build-arg) -t fastapi_app:latest --force-rm=true .

docker-push: docker-build
	@env $$(cat .env | xargs); \
	AWS_ACCOUNT_ID=$$(aws sts get-caller-identity --output text --query 'Account'); \
	docker tag fastapi_app:${IMAGE_TAG} $${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/fastapi_app:${IMAGE_TAG}; \
	aws ecr get-login-password --region ${REGION} | docker login --username AWS --password-stdin $${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com; \
	docker push $${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/fastapi_app:${IMAGE_TAG};

lambda-deploy: docker-push
	@env $$(cat .env | xargs); \
	AWS_ACCOUNT_ID=$$(aws sts get-caller-identity --output text --query 'Account'); \
	aws lambda update-function-code --function-name fastapi_lambda --image-uri $${AWS_ACCOUNT_ID}.dkr.ecr.${REGION}.amazonaws.com/fastapi_app:${IMAGE_TAG}

terraform-plan:
	@env $$(cat .env | xargs); \
	cd terraform; \
	terraform plan

terraform-apply:
	@env $$(cat .env | xargs); \
	cd terraform; \
	terraform apply -auto-approve
