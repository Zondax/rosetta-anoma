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
        echo "Checking out to Anoma branch: ${BRANCH}"; \
  		git checkout ${BRANCH}; \
    fi

RUN if [ ! -z "${COMMIT_HASH}" ]; then \
		echo "Checking out to Anoma commit: ${COMMIT_HASH}"; \
		git checkout ${COMMIT_HASH}; \
	fi

RUN make install

COPY ./start.sh /

ENTRYPOINT ["/start.sh"]
CMD ["",""]

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
#ARG PROXYPATH=/rosetta-proxy
#
## Install deps
#RUN apt-get update && \
#    apt-get install -yy curl
#
#RUN curl https://sh.rustup.rs -sSf | bash -s -- -y
#ENV PATH="/root/.cargo/bin:${PATH}"
#
## Install Anoma
#COPY --from=builder /root/.cargo/bin/anoma* /usr/local/bin/
##Check Anoma installation
#RUN anoma node ledger -V
#
##Install rosetta proxy
##COPY --from=builder ${PROXYPATH}/anoma-rosetta-proxy /usr/local/bin
#
##Copy entrypoint script
#COPY ./start.sh /
#
#ENTRYPOINT ["/start.sh"]
#CMD ["",""]

