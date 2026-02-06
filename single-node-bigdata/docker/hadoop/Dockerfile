# Hadoop Base Image for Single-Node Big Data Cluster
# Supports: namenode, datanode, resourcemanager, nodemanager, historyserver

ARG JAVA_VERSION=21
ARG HADOOP_VERSION=3.4.2

FROM ubuntu:22.04 AS base

ARG JAVA_VERSION
ARG HADOOP_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin:${HADOOP_HOME}/sbin

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-${JAVA_VERSION}-jdk \
    curl \
    wget \
    netcat-openbsd \
    ssh \
    rsync \
    procps \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz \
    && mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Create necessary directories
RUN mkdir -p ${HADOOP_HOME}/data/namenode \
    && mkdir -p ${HADOOP_HOME}/data/datanode \
    && mkdir -p ${HADOOP_HOME}/data/nodemanager/local \
    && mkdir -p ${HADOOP_HOME}/data/nodemanager/logs \
    && mkdir -p ${HADOOP_HOME}/tmp \
    && mkdir -p ${HADOOP_HOME}/logs \
    && mkdir -p /entrypoints

# Copy entrypoint scripts
COPY hadoop-entrypoint.sh /entrypoints/hadoop-entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoints/hadoop-entrypoint.sh /healthcheck.sh

# Set Hadoop environment in bashrc
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc \
    && echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~/.bashrc \
    && echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.bashrc

# Configure Java for Hadoop
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> ${HADOOP_CONF_DIR}/hadoop-env.sh

WORKDIR ${HADOOP_HOME}

#-------------------------------------------------------------------------------
# NameNode Target
FROM base AS namenode

ENV SERVICE_ROLE=namenode
ENV SERVICE_TYPE=hadoop

EXPOSE 9870 9000

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hadoop-entrypoint.sh"]
CMD ["namenode"]

#-------------------------------------------------------------------------------
# DataNode Target
FROM base AS datanode

ENV SERVICE_ROLE=datanode
ENV SERVICE_TYPE=hadoop

EXPOSE 9866 9867 9864

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hadoop-entrypoint.sh"]
CMD ["datanode"]

#-------------------------------------------------------------------------------
# ResourceManager Target
FROM base AS resourcemanager

ENV SERVICE_ROLE=resourcemanager
ENV SERVICE_TYPE=hadoop

EXPOSE 8088 8030 8031 8032 8033

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hadoop-entrypoint.sh"]
CMD ["resourcemanager"]

#-------------------------------------------------------------------------------
# NodeManager Target
FROM base AS nodemanager

ENV SERVICE_ROLE=nodemanager
ENV SERVICE_TYPE=hadoop

EXPOSE 8042 8040

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hadoop-entrypoint.sh"]
CMD ["nodemanager"]

#-------------------------------------------------------------------------------
# HistoryServer Target
FROM base AS historyserver

ENV SERVICE_ROLE=historyserver
ENV SERVICE_TYPE=hadoop

EXPOSE 19888 10020

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hadoop-entrypoint.sh"]
CMD ["historyserver"]
