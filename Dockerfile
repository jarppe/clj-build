FROM debian:13-slim


WORKDIR /workspace
ENV LANG=C.UTF-8


#
# Base deps:
#

RUN \
  apt update -q                                                                    && \
  apt upgrade -y                                                                   && \
  apt install -y                                                                   \
    gnupg                                                                          \
    ca-certificates                                                                \
    apt-transport-https                                                            \
    lsb-release-minimal                                                            \
    git                                                                            \
    curl                                                                           \
    unzip                                                                          \
    jq


#
# Java:
#

ARG JAVA_VERSION=24

RUN \
  curl -sSLf https://packages.adoptium.net/artifactory/api/gpg/key/public          \
    | gpg --dearmor                                                                \
    > /etc/apt/trusted.gpg.d/temurin.gpg                                           && \
  echo "deb https://packages.adoptium.net/artifactory/deb"                         \
            $(lsb_release -cs)                                                     \
            "main"                                                                 \
    > /etc/apt/sources.list.d/adoptium.list                                        && \
  apt update -q                                                                    && \
  apt install -y                                                                   \
    temurin-${JAVA_VERSION}-jdk                                                    && \
  java --version


#
# Clojure:
#

RUN \
  RELEASE=$(curl -sSLf "https://api.github.com/repos/clojure/brew-install/releases/latest" | jq -r ".tag_name") && \
  curl -sSLf https://github.com/clojure/brew-install/releases/download/${RELEASE}/posix-install.sh \
    | bash -                                                                       && \
  clojure -P                                                                       && \
  clojure --version

#
# Babashka:
#

RUN \
  RELEASE=$(curl -sSLf "https://api.github.com/repos/babashka/babashka/releases/latest" | jq -r ".tag_name[1:]") && \
  case $(uname -m) in                                                              \
    aarch64) ARCH=aarch64;;                                                        \
    x86_64)  ARCH=amd64;;                                                          \ 
    *) echo "Unknown CPU: $(uname -m)"; exit 1;;                                   \
  esac                                                                             && \
  BB_BASE="https://github.com/babashka/babashka/releases/download"                 && \
  BB_TAR="babashka-${RELEASE}-linux-${ARCH}-static.tar.gz"                         && \
  curl -sSL "${BB_BASE}/v${RELEASE}/${BB_TAR}"                                     \
    | tar xzCf /usr/local/bin -                                                    && \
  bb --version

#
# Bun:
#

RUN \
  export BUN_INSTALL=/usr/local                                                    && \
  curl -fsSL https://bun.sh/install | bash                                         && \
  bun --version

#
# Workspace:
#


WORKDIR /workspace
COPY ./.bashrc /root/
CMD ["/bin/bash"]
