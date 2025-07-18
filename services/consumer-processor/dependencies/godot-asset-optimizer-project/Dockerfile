FROM ubuntu:25.04

RUN apt-get update
RUN apt-get install -y ca-certificates tini unzip curl libfontconfig1 zip

# Install node
RUN curl -fsSL https://deb.nodesource.com/setup_20.x  | bash - && apt-get -y install nodejs

# Install Godot with multi-architecture support
ARG GODOT_VERSION=4.4.1-stable
ARG TARGETARCH

# Set architecture-specific variables
RUN if [ "$TARGETARCH" = "arm64" ]; then \
        export GODOT_FILENAME="Godot_v4.4.1-stable_linux.arm64" && \
        export GODOT_URL="https://github.com/godotengine/godot/releases/download/${GODOT_VERSION}/${GODOT_FILENAME}.zip" && \
        export GODOT_EXECUTABLE="Godot_v4.4.1-stable_linux.arm64"; \
    else \
        export GODOT_FILENAME="godot.4.4.1.stable.linux.editor.x86_64" && \
        export GODOT_URL="https://github.com/decentraland/godotengine/releases/download/${GODOT_VERSION}/${GODOT_FILENAME}.zip" && \
        export GODOT_EXECUTABLE="godot.4.4.1.stable.linux.editor.x86_64"; \
    fi && \
    echo "Architecture: $TARGETARCH" && \
    echo "Downloading: $GODOT_URL" && \
    curl -fsSL "$GODOT_URL" -o "/usr/local/bin/godot.zip" && \
    unzip "/usr/local/bin/godot.zip" -d "/usr/local/bin/" && \
    rm "/usr/local/bin/godot.zip" && \
    mv "/usr/local/bin/$GODOT_EXECUTABLE" "/usr/local/bin/godot-editor" && \
    chmod +x "/usr/local/bin/godot-editor"

ENV GODOT4_EDITOR=/usr/local/bin/godot-editor

# Clean apt cache
RUN rm -rf /var/lib/apt/lists/* /var/cache/apt/*

ARG COMMIT_HASH=local
ARG CURRENT_VERSION=Unknown

ENV COMMIT_HASH=${COMMIT_HASH:-local}
ENV CURRENT_VERSION=${CURRENT_VERSION:-Unknown}

# build the app
WORKDIR /app
COPY . /app

# TEMP
COPY dependencies/godot-asset-optimizer-project/entrypoint.sh /app/entrypoint.sh

RUN npm ci
RUN npm run build

ENV NODE_ENV=production

# Please _DO NOT_ use a custom ENTRYPOINT because it may prevent signals
# (i.e. SIGTERM) to reach the service
# Read more here: https://aws.amazon.com/blogs/containers/graceful-shutdowns-with-ecs/
#            and: https://www.ctl.io/developers/blog/post/gracefully-stopping-docker-containers/
#ENTRYPOINT ["/usr/bin/tini", "--"]
# Run the program under Tini
ENTRYPOINT ["/usr/bin/tini", "--", "/app/entrypoint.sh" ]
