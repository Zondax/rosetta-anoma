# Create builder container
FROM ubuntu:20.04 as builder

# set BRANCH or COMMIT_HASH
ARG BRANCH="v0.5.0"
ARG COMMIT_HASH=""
ARG REPO_ANOMA=https://github.com/anoma/anoma.git
ARG NODEPATH=/anoma

# set BRANCH_PROXY or COMMIT_HASH_PROXY
ARG BRANCH_PROXY=""
ARG COMMIT_HASH_PROXY=""
ARG REPO_PROXY=https://github.com/Zondax/anoma-rosetta-proxy.git
ARG PROXYPATH=/rosetta-proxy

ENV DEBIAN_FRONTEND=noninteractive

# Install deps
RUN apt-get update
RUN apt-get install -yy wget sudo curl build-essential git-core libssl-dev pkg-config libclang-12-dev

RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
ENV PATH="/root/.cargo/bin:${PATH}"
ENV RUSTFLAGS="-C target-cpu=native -g"

RUN wget https://go.dev/dl/go1.18.linux-amd64.tar.gz && \
    tar -C /usr/local -xvf go1.18.linux-amd64.tar.gz

RUN export PATH=$PATH:/usr/local/go/bin


# Clone Anoma
RUN if [ -z "${BRANCH}" ] && [ -z "${COMMIT_HASH}" ]; then \
  		echo 'Error: Both BRANCH and COMMIT_HASH are empty'; \
  		exit 1; \
    fi

RUN if [ ! -z "${BRANCH}" ] && [ ! -z "${COMMIT_HASH}" ]; then \
		echo 'Error: Both BRANCH and COMMIT_HASH are set'; \
		exit 1; \
	fi

WORKDIR ${NODEPATH}
RUN git clone ${REPO_ANOMA} ${NODEPATH}

RUN if [ ! -z "${BRANCH}" ]; then \
        echo "Checking out to Lotus branch: ${BRANCH}"; \
  		git checkout ${BRANCH}; \
    fi

RUN if [ ! -z "${COMMIT_HASH}" ]; then \
		echo "Checking out to Lotus commit: ${COMMIT_HASH}"; \
		git checkout ${COMMIT_HASH}; \
	fi

RUN make install

# Clone anoma-rosetta-proxy
#RUN if [ -z "${BRANCH_PROXY}" ] && [ -z "${COMMIT_HASH_PROXY}" ]; then \
#  		echo 'Error: Both BRANCH_PROXY and COMMIT_HASH_PROXY are empty'; \
#  		exit 1; \
#    fi
#
#RUN if [ ! -z "${BRANCH_PROXY}" ] && [ ! -z "${COMMIT_HASH_PROXY}" ]; then \
#		echo 'Error: Both BRANCH_PROXY and COMMIT_HASH_PROXY are set'; \
#		exit 1; \
#	fi
#
#WORKDIR ${PROXYPATH}
#RUN git clone --recurse-submodules ${REPO_PROXY} ${PROXYPATH}
#
#RUN if [ ! -z "${BRANCH_PROXY}" ]; then \
#        echo "Checking out to proxy branch: ${BRANCH_PROXY}"; \
#  		git checkout ${BRANCH_PROXY}; \
#    fi
#
#RUN if [ ! -z "${COMMIT_HASH_PROXY}" ]; then \
#		echo "Checking out to proxy commit: ${COMMIT_HASH_PROXY}"; \
#		git checkout ${COMMIT_HASH_PROXY}; \
#	fi
#
#RUN make build


# Create final container
#FROM ubuntu:20.04
#
#ENV DEBIAN_FRONTEND=noninteractive
#ARG ROSETTA_PORT=8080
#ARG LOTUS_API_PORT=1234
#ARG PROXYPATH=/rosetta-proxy
#
## Install Lotus deps
#RUN apt-get update && \
#    apt-get install -yy apt-utils  && \
#    apt-get install -yy curl && \
#    apt-get install -yy bzr jq pkg-config mesa-opencl-icd ocl-icd-opencl-dev wget libltdl7 libnuma1 hwloc libhwloc-dev
#
## Install Lotus
#COPY --from=builder /usr/local/bin/lotus* /usr/local/bin/
##Check Lotus installation
#RUN lotus --version
#
## Copy config files
#COPY ./tools/calibration/files/rosetta_config.yaml /config.yaml
#COPY ./tools/calibration/files/config.toml /etc/lotus_config/config.toml
#
## Copy test actors keys
#COPY ./tools/calibration/files/test_actor_1.key /test_actor_1.key
#COPY ./tools/calibration/files/test_actor_2.key /test_actor_2.key
#COPY ./tools/calibration/files/test_actor_3.key /test_actor_3.key
#
## Copy startup script
#COPY ./tools/calibration/files/start.sh /start.sh
#
#RUN mkdir -p /data/{node,storage}
#ENV LOTUS_PATH=/data/node/
#ENV LOTUS_STORAGE_PATH=/data/storage/
#
##Install rosetta proxy
#COPY --from=builder ${PROXYPATH}/filecoin-indexing-rosetta-proxy /usr/local/bin
#
#ENV LOTUS_RPC_URL=ws://127.0.0.1:1234/rpc/v0
#ENV LOTUS_RPC_TOKEN=""
#
## Enable using WASM-compiled builtin actors
#ENV LOTUS_USE_FVM_EXPERIMENTAL=1
#
#EXPOSE $ROSETTA_PORT
#EXPOSE $LOTUS_API_PORT
#
#ENTRYPOINT ["/start.sh"]
#CMD ["",""]

