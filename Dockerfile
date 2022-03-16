# [[file:conformance-tools.org::*Dockerfile dev environment][Dockerfile dev environment:1]]
FROM fedora
VOLUME /data # mount this directory here.
RUN dnf install -y poetry jq curl bash
# pre-fetch deps
COPY pyproject.toml /pyproject.toml 
RUN poetry install
WORKDIR /data
ENV SHELL=bash
ENV PS1="[drp-cert]# "
EXPOSE 8000
EXPOSE 8001
CMD "/usr/bin/bash" "-c" "poetry shell"
# Dockerfile dev environment:1 ends here
