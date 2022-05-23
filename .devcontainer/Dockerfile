FROM ubuntu:20.04

ARG VSCODE_DEV_CONTAINERS="v0.236.0"

ARG INSTALL_ZSH="true"
ARG UPGRADE_PACKAGES="false"
ARG FLUTTER_VERSION="stable"

# Install needed packages and setup non-root user.
ARG USERNAME=vscode
ARG USER_UID=1000
ARG USER_GID=$USER_UID
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install curl \
    && bash -c "$(curl -fsSL "https://raw.githubusercontent.com/microsoft/vscode-dev-containers/$VSCODE_DEV_CONTAINERS/script-library/common-debian.sh")" -- "${INSTALL_ZSH}" "${USERNAME}" "${USER_UID}" "${USER_GID}" "${UPGRADE_PACKAGES}" "true" "true" \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install xvfb.
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends xvfb \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

# Install Flutter Linux Desktop dependencies
RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
    && apt-get -y install --no-install-recommends clang cmake ninja-build pkg-config libgtk-3-dev liblzma-dev \
    && apt-get autoremove -y && apt-get clean -y && rm -rf /var/lib/apt/lists/*

USER $USERNAME

ENV FLUTTER_SDK="/home/$USERNAME/flutter"
ENV PUB_CACHE="/home/$USERNAME/.pub-cache"

# Install Flutter.
RUN git clone https://github.com/flutter/flutter.git --depth 1 -b "${FLUTTER_VERSION}" "$FLUTTER_SDK" \
    && "$FLUTTER_SDK/bin/flutter" precache

# Add flutter and pub-cache bin location to path.
ENV PATH="$FLUTTER_SDK/bin:$PUB_CACHE/bin:$PATH"

# Install Melos.
RUN dart pub global activate melos
