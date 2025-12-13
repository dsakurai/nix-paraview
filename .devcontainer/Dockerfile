FROM debian:stable-slim

# Install any additional dependencies if needed
# Purely necessary for VSCode
RUN apt update && \
    apt install -y sudo ssh git && \
    # Clean up apt cache when done
    rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y build-essential cmake pkgconf gcc && \
    # Clean up apt cache when done
    rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y curl

RUN apt install -y zip unzip tar
RUN apt install -y linux-libc-dev
RUN apt install -y bison flex autoconf
RUN apt install -y python3
RUN apt install -y autoconf autoconf-archive automake libtool
RUN apt install -y python3-jinja2
RUN apt install -y libgl1-mesa-dev \
                                  libegl1-mesa-dev \
                                  libx11-dev \
                                  libx11-xcb-dev \
                                  libxcb1-dev \
                                  libxkbcommon-dev \
                                  libxkbcommon-x11-dev \
                                  libxrender-dev \
                                  libfontconfig1-dev \
	libx11-xcb-dev libglu1-mesa-dev libxrender-dev libxi-dev libxkbcommon-dev libxkbcommon-x11-dev libegl1-mesa-dev \
	# Seems to be needed for GUI apps for WSL2.
	libxcb-xinerama0 libxcb-icccm4 libxcb-image0 libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-xfixes0 libxcb-xinerama0 libgl1-mesa-dev

RUN apt install -y '^libxcb.*-dev'

RUN useradd -m -c "" -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER vscode

CMD ["bash"]