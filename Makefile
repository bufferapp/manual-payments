NAME = bufferapp/manual-payments:0.3.0

.PHONY: all build run dev

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run --env-file .env -v $(PWD)/google:/scripts/google -it --rm $(NAME)

run-remote: push
	kubectl delete job manual-payments-manual-run --ignore-not-found=true
	kubectl create job --from cronjob/manual-payments manual-payments-manual-run

push: build
	docker push $(NAME)

dev:
	docker run -v $(PWD):/app -it --rm --env-file .env $(NAME)

deploy: push
	kubectl apply -f "cronjob.yaml"
