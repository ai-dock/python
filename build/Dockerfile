# For build automation - Allows building from any ai-dock base image
ARG IMAGE_BASE="ghcr.io/ai-dock/base-image:v2-cuda-12.1.1-base-22.04"
FROM ${IMAGE_BASE}

LABEL org.opencontainers.image.source https://github.com/ai-dock/python

LABEL org.opencontainers.image.description "Python development environment in a cloud-first docker container"

LABEL maintainer="Rob Ballantyne <rob@dynamedia.uk>"

ENV JUPYTER_VENV=$VENV_DIR/jupyter
ENV JUPYTER_VENV_PYTHON=$JUPYTER_VENV/bin/python
ENV JUPYTER_VENV_PIP=$JUPYTER_VENV/bin/pip

# Copy early so we can use scripts in the build - Changes to these files will invalidate the cache and cause a rebuild.
COPY --chown=0:1111 ./COPY_ROOT_0/ /

# Define the startup environment for interactive sessions.
# ENV for inheritance
ARG PYTHON_VERSION=all
ENV PYTHON_VERSION=${PYTHON_VERSION}
ARG PYTHON_VENV_NAME=python_310
ENV PYTHON_VENV_NAME=${PYTHON_VENV_NAME}
ENV PYTHON_DEFAULT_VENV=${PYTHON_VENV_NAME}
ENV OPT_SYNC=$OPT_SYNC
ENV IMAGE_SLUG="python"
# Use build scripts to ensure we can build all targets from one Dockerfile in a single layer.
# Don't put anything heavy in here - We can use multi-stage building above if necessary.

RUN set -eo pipefail && /opt/ai-dock/bin/build/layer0/init.sh | tee /var/log/build.log

# Keep init.sh as-is and place additional logic in /opt/ai-dock/bin/preflight.sh
CMD ["init.sh"]
