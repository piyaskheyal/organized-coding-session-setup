FROM codercom/code-server:latest

USER root

RUN apt update && apt install -y g++ build-essential

USER coder


# # Install extensions
RUN code-server --install-extension formulahendry.code-runner \
    && code-server --install-extension franneck94.vscode-c-cpp-dev-extension-pack

# Create settings.json and apply config
RUN mkdir -p /home/coder/.local/share/code-server/User && \
    echo '{ "code-runner.runInTerminal": true }' > /home/coder/.local/share/code-server/User/settings.json

# Default working directory
WORKDIR /home/coder/project