NAME = bufferapp/manual-payments:0.1.0

.PHONY: all build run dev

all: run

build:
	docker build -t $(NAME) .

run: build
	docker run -it --rm $(NAME)

push: build
	docker push $(NAME)

dev:
	docker run -v $(PWD):/app -it --rm --env-file .env $(NAME)
