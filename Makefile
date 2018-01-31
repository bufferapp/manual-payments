NAME = julheimer/manual_payments:0.1.0

.PHONY: all build run dev

all: run

build:
	docker build -t $(NAME) .

run:
	docker run -it --rm $(NAME)

dev:
	docker run -v $(PWD):/app -it --rm --env-file ./.env $(NAME)
