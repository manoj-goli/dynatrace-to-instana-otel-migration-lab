#!/usr/bin/env bash
set -euo pipefail

# Baseline package setup for the MVP VM only.
# This does not deploy Astronomy Shop or configure observability vendors.

if [[ "$(id -u)" -eq 0 ]]; then
  SUDO=""
else
  SUDO="sudo"
fi

export DEBIAN_FRONTEND=noninteractive

$SUDO apt-get update
$SUDO apt-get install -y \
  ca-certificates \
  curl \
  git \
  gnupg \
  lsb-release

. /etc/os-release
DOCKER_DISTRO_ID="${ID}"
DOCKER_CODENAME="${VERSION_CODENAME}"

if [[ "${DOCKER_DISTRO_ID}" != "ubuntu" && "${DOCKER_DISTRO_ID}" != "debian" ]]; then
  echo "Unsupported OS for this setup script: ${DOCKER_DISTRO_ID}" >&2
  exit 1
fi

$SUDO install -m 0755 -d /etc/apt/keyrings
curl -fsSL "https://download.docker.com/linux/${DOCKER_DISTRO_ID}/gpg" | $SUDO gpg --dearmor -o /etc/apt/keyrings/docker.gpg
$SUDO chmod a+r /etc/apt/keyrings/docker.gpg

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/${DOCKER_DISTRO_ID} ${DOCKER_CODENAME} stable" \
  | $SUDO tee /etc/apt/sources.list.d/docker.list >/dev/null

$SUDO apt-get update
$SUDO apt-get install -y \
  docker-ce \
  docker-ce-cli \
  containerd.io \
  docker-buildx-plugin \
  docker-compose-plugin

$SUDO systemctl enable --now docker

if [[ -n "${SUDO}" ]]; then
  $SUDO usermod -aG docker "${USER}"
  echo "Docker group membership added for ${USER}. Log out and back in before running Docker without sudo."
fi

docker --version
docker compose version
