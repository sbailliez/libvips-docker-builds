FROM amazonlinux:2023

USER root
WORKDIR /tmp

COPY . .

RUN chmod +x ./install-libvips.sh && ./install-libvips.sh

