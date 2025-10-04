# Use the official Elixir image as the build stage
ARG ELIXIR_VERSION=1.15.7
ARG OTP_VERSION=26.1.2
ARG DEBIAN_VERSION=bookworm-20231009-slim

ARG BUILDER_IMAGE="hexpm/elixir:${ELIXIR_VERSION}-erlang-${OTP_VERSION}-debian-${DEBIAN_VERSION}"
ARG RUNNER_IMAGE="debian:${DEBIAN_VERSION}"

FROM ${BUILDER_IMAGE} AS builder

# Set build ENV
ARG MIX_ENV="prod"

# Install build dependencies
RUN apt-get update -y && apt-get install -y build-essential git curl \
&& if [ "$MIX_ENV" = "dev" ]; then apt-get install -y inotify-tools watchman; fi \
&& apt-get clean && rm -f /var/lib/apt/lists/*_*

# Install Node.js for asset compilation
RUN curl -fsSL https://deb.nodesource.com/setup_20.x | bash - \
    && apt-get install -y nodejs

# Prepare build dir
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Install mix dependencies
COPY mix.exs mix.lock ./
RUN mix deps.get --only $MIX_ENV
RUN mkdir config

# Copy compile-time config files before we compile dependencies
# to ensure any relevant config change will trigger the dependencies
# to be re-compiled.
COPY config/config.exs config/${MIX_ENV}.exs config/
RUN mix deps.compile

# Copy assets
COPY assets assets

# Install asset dependencies and build assets
RUN mix assets.setup
RUN mix assets.build

# Copy source code
COPY priv priv
COPY lib lib

# Compile the release
RUN mix compile

# Copy runtime configuration
COPY config/runtime.exs config/

# Build assets for production
RUN mix assets.deploy

# Build the release
RUN mix release

# Start a new build stage for the runtime image
FROM ${RUNNER_IMAGE}

RUN apt-get update -y && \
    apt-get install -y libstdc++6 openssl libncurses5 locales ca-certificates \
    && apt-get clean && rm -f /var/lib/apt/lists/*_*

# Set the locale
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG en_US.UTF-8
ENV LANGUAGE en_US:en
ENV LC_ALL en_US.UTF-8

# Create a non-root user
RUN useradd --create-home --shell /bin/bash app
WORKDIR /app

# Set runner ENV
ENV MIX_ENV="prod"

# Copy the release from the builder stage
COPY --from=builder --chown=app:app /app/_build/${MIX_ENV}/rel/tictactoe ./

USER app

# Expose the port that the app runs on
EXPOSE 4000

# Set the default command to run when starting the container
CMD ["/app/bin/tictactoe", "start"]
