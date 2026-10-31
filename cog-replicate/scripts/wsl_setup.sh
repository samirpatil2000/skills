#!/bin/bash
# One-time toolchain for Cog inside WSL2 Ubuntu. Run as root:
#   MSYS_NO_PATHCONV=1 wsl -d Ubuntu -u root -- bash /mnt/c/Users/<you>/.claude/skills/cog-replicate/scripts/wsl_setup.sh
# Installs Docker Engine (Ubuntu docker.io) + buildx, nvidia-container-toolkit, cog.
# Changes /etc/docker/daemon.json and restarts docker: SHARED state - tell other sessions first.
set -euo pipefail
COG_VERSION="${COG_VERSION:-v0.23.0}"
export DEBIAN_FRONTEND=noninteractive

apt-get update -qq
apt-get install -y -qq docker.io docker-buildx ca-certificates curl gnupg >/dev/null
systemctl enable --now docker

# NVIDIA container toolkit (needed for `cog predict` / `docker run --gpus all`)
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey \
  | gpg --dearmor --yes -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -fsSL https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list \
  | sed "s#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g" \
  > /etc/apt/sources.list.d/nvidia-container-toolkit.list
apt-get update -qq
apt-get install -y -qq nvidia-container-toolkit >/dev/null

# Classic image store: the containerd snapshotter causes 403s on r8.im pushes (cog #2093).
echo '{"features":{"containerd-snapshotter":false}}' > /etc/docker/daemon.json
nvidia-ctk runtime configure --runtime=docker   # merges the nvidia runtime into daemon.json
systemctl restart docker

curl -fsSL -o /usr/local/bin/cog "https://github.com/replicate/cog/releases/download/${COG_VERSION}/cog_Linux_x86_64"
chmod +x /usr/local/bin/cog

docker version --format 'docker {{.Server.Version}}'
docker info --format 'storage driver: {{.Driver}}'
cog --version
docker run --rm --gpus all nvidia/cuda:12.8.0-base-ubuntu22.04 nvidia-smi -L
echo "Next: cat <api-token-file> | docker login r8.im -u <replicate-owner> --password-stdin"
