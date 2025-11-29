FROM debian:stable-slim

# Install any additional dependencies if needed
# Purely necessary for VSCode
RUN apt update && \
    apt install -y sudo && \
    # Clean up apt cache when done
    rm -rf /var/lib/apt/lists/*

RUN apt update && \
    apt install -y sudo && \
    # Clean up apt cache when done
    rm -rf /var/lib/apt/lists/*

RUN useradd -m -c "" -s /bin/bash vscode && \
    usermod -aG sudo vscode && \
    echo "vscode ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/nopasswd

USER vscode

CMD ["bash"]