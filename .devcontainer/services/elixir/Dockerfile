FROM elixir:1.19

RUN apt-get update && \
    apt-get upgrade -y && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y --no-install-recommends \
        git \
        inotify-tools \
        libpq-dev \
        ripgrep
RUN curl -fsSL https://deb.nodesource.com/setup_24.x | bash - && \
    apt-get install -y nodejs
RUN rm -rf /var/lib/apt/lists/* && \
    apt-get autoremove -y && \
    apt-get clean && \
	rm -rf /var/lib/apt/lists/*
ARG VSCODE_UID=1000
ARG VSCODE_USER=vscode
ARG VSCODE_GID=1000
ARG VSCODE_GROUP=vscode
ARG VSCODE_HOME=/home/vscode
ARG WORKSPACE_DIR=/workspace
RUN groupadd -g ${VSCODE_GID} ${VSCODE_GROUP} && \
    useradd -g ${VSCODE_GROUP} -u ${VSCODE_UID} -d ${VSCODE_HOME} -m ${VSCODE_USER} && \
    mkdir -p ${WORKSPACE_DIR}
