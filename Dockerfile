FROM elixir:1.3.1

RUN mix local.hex --force

ADD . /app

WORKDIR /app
