# properdocs-materialx
#
# A Docker image bundling ProperDocs (https://properdocs.org/), the community-maintained successor to MkDocs, with
# MaterialX (https://github.com/jaywhj/mkdocs-materialx), the community-maintained successor to mkdocs-material.
#
# Modeled after the images and usage of:
#   - squidfunk/mkdocs-material: https://github.com/squidfunk/mkdocs-material/blob/master/Dockerfile
#   - jaywhj/mkdocs-materialx:   https://github.com/jaywhj/mkdocs-materialx/blob/main/Dockerfile

ARG BASE_IMAGE=python:3.14-alpine3.24

FROM ${BASE_IMAGE} AS build

# Build-time flags
ARG WITH_PLUGINS=true

# Environment variables
ENV PACKAGES=/usr/local/lib/python3.14/site-packages
ENV PYTHONDONTWRITEBYTECODE=1

# Set build directory
WORKDIR /tmp

# Pinned versions of properdocs and mkdocs-materialx, see versions.env
COPY versions.env versions.env

# Perform build and cleanup artifacts and caches
RUN . ./versions.env                                                                                                   \
  && apk upgrade --update-cache -a                                                                                     \
  && apk add --no-cache cairo freetype-dev git git-fast-import jpeg-dev openssh pngquant tini zlib-dev                 \
  && apk add --no-cache --virtual .build gcc g++ libffi-dev musl-dev                                                   \
  && pip install --no-cache-dir --upgrade pip                                                                          \
  && pip install --no-cache-dir "properdocs==${PROPERDOCS_VERSION}"                                                    \
  &&                                                                                                                   \
    if [ "${WITH_PLUGINS}" = "true" ]; then                                                                            \
      pip install --no-cache-dir "mkdocs-materialx[recommended,imaging]==${MATERIALX_VERSION}";                        \
    else                                                                                                               \
      pip install --no-cache-dir "mkdocs-materialx==${MATERIALX_VERSION}";                                             \
    fi                                                                                                                 \
  && apk del .build                                                                                                    \
  && rm -rf /tmp/* /root/.cache                                                                                        \
  && find ${PACKAGES} -type f -path "*/__pycache__/*" -exec rm -f {} \;                                                \
  && git config --system --add safe.directory /docs                                                                    \
  && git config --system --add safe.directory /site

# From empty image
FROM scratch

ARG BASE_IMAGE

# Copy all from build
COPY --from=build / /

# OCI annotations, see https://github.com/opencontainers/image-spec/blob/main/annotations.md
# org.opencontainers.image.version/created/revision are added at push time by the release
# workflow (docker/metadata-action), since they depend on the release, not the build.
LABEL org.opencontainers.image.title="properdocs-materialx" \
      org.opencontainers.image.description="ProperDocs + MaterialX on Alpine: a maintained, drop-in successor to the MkDocs + mkdocs-material Docker image." \
      org.opencontainers.image.url="https://github.com/qligier/properdocs-materialx" \
      org.opencontainers.image.source="https://github.com/qligier/properdocs-materialx" \
      org.opencontainers.image.documentation="https://github.com/qligier/properdocs-materialx#readme" \
      org.opencontainers.image.vendor="Quentin Ligier" \
      org.opencontainers.image.licenses="MIT" \
      org.opencontainers.image.base.name="${BASE_IMAGE}"

# Set working directory
WORKDIR /docs

# Expose ProperDocs development server port
EXPOSE 8000

# Start development server by default
ENTRYPOINT ["/sbin/tini", "--", "properdocs"]
CMD ["serve", "--dev-addr=0.0.0.0:8000"]
