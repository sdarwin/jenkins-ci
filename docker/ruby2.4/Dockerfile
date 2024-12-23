
FROM circleci/ruby:2.4-node-browsers-legacy
LABEL maintainer="samuel.d.darwin@gmail.com"

RUN sudo groupadd -g 150 jenkins
RUN sudo useradd jenkins -u 150 -g 150 -m -s /bin/bash
RUN sudo echo "ALL ALL=(ALL) NOPASSWD:ALL" | sudo tee /etc/sudoers.d/all
