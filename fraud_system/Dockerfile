# Build stage
FROM elixir:1.15-alpine AS build

# Install build dependencies
RUN apk add --no-cache build-base git npm cmake

WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Set build env
ENV MIX_ENV=prod

# Install dependencies
COPY mix.exs ./
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy source
COPY config config
COPY lib lib
COPY priv priv

# Compile release
RUN mix compile
RUN mix release

# Runtime stage
FROM alpine:3.18

# Install runtime dependencies
RUN apk add --no-cache libstdc++ openssl ncurses-libs

WORKDIR /app

# Copy release from build stage
COPY --from=build /app/_build/prod/rel/fraud_system ./

# Create non-root user
RUN adduser -D fraud_user
USER fraud_user

ENV HOME=/app
ENV MIX_ENV=prod
ENV PORT=4000

EXPOSE 4000

CMD ["/app/bin/fraud_system", "start"]
