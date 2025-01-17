FROM debian:trixie-slim

LABEL maintainer="Murat Can Üste <mcanueste@gmail.com>"

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# make /bin/sh symlink to bash instead of dash:
RUN echo "dash dash/sh boolean false" | debconf-set-selections
RUN DEBIAN_FRONTEND=noninteractive dpkg-reconfigure dash

# install core utils that don't change frequently here
# nix installation is possible, but they make the base image massive
RUN apt-get update -y \
    && apt-get -y install --no-install-recommends \
      sudo \
      ca-certificates \
      curl \
      locales \
      git \
      ssh \
      gnupg2 \
      direnv \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# create at least locale for en_US.UTF-8
RUN echo "en_US.UTF-8 UTF-8" >> /etc/locale.gen && locale-gen

# create non-root user and group and add it sudoers
ARG USERNAME=devcontainer
ARG USER_UID=1000
ARG USER_GID=${USER_UID}
RUN groupadd --gid ${USER_GID} ${USERNAME} && \
    useradd --uid ${USER_UID} --gid ${USER_GID} -m ${USERNAME} -s /bin/bash && \
    echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/devcontainer && \
    chmod 0440 /etc/sudoers.d/devcontainer

ENV PATH="${PATH}:/nix/var/nix/profiles/default/bin"
RUN curl --proto '=https' --tlsv1.2 -sSf -L https://install.determinate.systems/nix | \
  sh -s -- install linux --extra-conf "sandbox = false" --init none --no-confirm && \
  chown -R ${USERNAME} /nix

USER devcontainer
