FROM elixir:1.7.1-alpine

RUN mix local.hex --force && mix local.rebar --force
COPY . .
export MIX_ENV=prod
RUN mix deps.get && mix compile
CMD mix phx.server
