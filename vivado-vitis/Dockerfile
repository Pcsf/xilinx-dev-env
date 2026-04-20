# Ubuntu 20.04 is officially supported by Vivado 2021.2
FROM ubuntu:20.04

# 1. Install all dependencies Vivado needs (aligned with phwl/docker-vivado reference)
RUN dpkg --add-architecture i386 && \
    apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    ca-certificates curl \
    xorg dbus dbus-x11 \
    gtk2-engines \
    ttf-ubuntu-font-family fonts-ubuntu-console fonts-droid-fallback \
    lxappearance \
    libtinfo5 libncurses5 libncurses5-dev libncursesw5-dev \
    libxrender1 libxtst6 libxi6 libxft2 libxext6 libx11-6 libxau6 \
    libjpeg-turbo8 \
    build-essential git \
    gcc-multilib libc6-dev:i386 libc6-i386 lib32stdc++6 lib32gcc-s1 \
    ocl-icd-opencl-dev \
    python3 python3-pip \
    locales \
    sudo \
    faketime libfaketime \
    && locale-gen en_US.UTF-8

# 2. Set up the environment variables
ENV LANG=en_US.UTF-8
ENV LANGUAGE=en_US:en
ENV LC_ALL=en_US.UTF-8

# 3. Create a user that matches your Arch Linux User ID (1000)
# This prevents permission issues when writing files to your host
ARG USER_ID=1000
ARG GROUP_ID=1000
RUN groupadd -g ${GROUP_ID} fpgauser && \
    useradd -l -u ${USER_ID} -g fpgauser -m fpgauser && \
    usermod -aG sudo fpgauser && \
    echo "fpgauser ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

USER fpgauser
WORKDIR /home/fpgauser/workspace

# 4. (Optional) Dummy entrypoint to keep it alive if needed
CMD ["/bin/bash"]
