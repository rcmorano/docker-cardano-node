ARG CARDANO_NODE_COMMIT=master

FROM rcmorano/cardano-node:src-${CARDANO_NODE_COMMIT} AS src
FROM rcmorano/cardano-node:src-build-${CARDANO_NODE_COMMIT} AS src-build

# production base
FROM ubuntu:20.04 AS base
ENV APT_ARGS="-y -o APT::Install-Suggests=false -o APT::Install-Recommends=false"
ARG BASE_PACKAGES="bash jq libatomic1 sudo curl screen python3-pip"
ENV BASE_PACKAGES ${BASE_PACKAGES}
ARG BUILD_PACKAGES="git"
ENV BUILD_PACKAGES ${BUILD_PACKAGES}
VOLUME ["/opt/cardano/cnode/logs", "/opt/cardano/cnode/db", "/opt/cardano/cnode/priv"]
ENV CNODE_HOME /opt/cardano/cnode
ENV CARDANO_NODE_SOCKET_PATH /opt/cardano/cnode/sockets/node0.socket
RUN mkdir -p /nonexistent /data && \
    chown nobody: /nonexistent && \
    mkdir -p ${CNODE_HOME} && \
    chown -R nobody: ${CNODE_HOME}/..
RUN apt-get update -qq && apt-get install ${APT_ARGS} ${BASE_PACKAGES} ${BUILD_PACKAGES} && \
    pip3 install yq
COPY --from=src-build /output/cardano* /usr/local/bin/
USER nobody
RUN curl -sSL https://raw.githubusercontent.com/rcmorano/baids/master/baids | bash -s install
COPY baids/* /nonexistent/.baids/functions.d/
USER nobody
## guild-ops images
FROM base AS guild-ops-ptn0-base
ENV NETWORK=guild-ops-ptn0
RUN bash -c 'source /nonexistent/.baids/baids && ${NETWORK}-setup'
USER root
RUN apt-get remove -y ${BUILD_PACKAGES} && apt-get autoremove -y && apt-get clean -y
CMD ["bash", "-c", "chown -R nobody: ${CNODE_HOME} && sudo -EHu nobody bash -c 'source ~/.baids/baids && ${NETWORK}-cnode-run-as-${CNODE_ROLE}'"]
FROM guild-ops-ptn0-base AS guild-ops-ptn0-passive
ENV CNODE_ROLE=passive
FROM guild-ops-ptn0-base AS guild-ops-ptn0-leader
ENV CNODE_ROLE=leader
## iohk images
FROM base AS iohk-fftn-base
ENV NETWORK=iohk-fftn
RUN bash -c 'source /nonexistent/.baids/baids && ${NETWORK}-setup'
USER root
RUN apt-get remove -y ${BUILD_PACKAGES} && apt-get autoremove -y && apt-get clean -y
CMD ["bash", "-c", "chown -R nobody: ${CNODE_HOME} && sudo -EHu nobody bash -c 'source ~/.baids/baids && ${NETWORK}-cnode-run-as-${CNODE_ROLE}'"]
FROM iohk-fftn-base AS iohk-fftn-passive
ENV CNODE_ROLE=passive
FROM iohk-fftn-base AS iohk-fftn-leader
ENV CNODE_ROLE=leader

FROM gcr.io/distroless/base AS barebone-node
COPY --from=src-build /output/cardano* /usr/local/bin/
CMD ["/usr/local/bin/cardano-node"]
