# Spark Image for Single-Node Big Data Cluster
# Supports: spark-master, spark-worker

ARG JAVA_VERSION=21
ARG SPARK_VERSION=4.1.1
ARG HADOOP_VERSION=3.4.2

FROM ubuntu:22.04 AS base

ARG JAVA_VERSION
ARG SPARK_VERSION
ARG HADOOP_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV SPARK_HOME=/opt/spark
ENV HADOOP_HOME=/opt/hadoop
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${SPARK_HOME}/bin:${SPARK_HOME}/sbin:${HADOOP_HOME}/bin

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-${JAVA_VERSION}-jdk \
    curl \
    wget \
    netcat-openbsd \
    procps \
    python3 \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Download and install Spark
RUN wget -q https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download and install Hadoop (for HDFS client and configs)
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz \
    && mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Create necessary directories
RUN mkdir -p ${SPARK_HOME}/logs \
    && mkdir -p ${SPARK_HOME}/work \
    && mkdir -p /entrypoints

# Copy entrypoint scripts
COPY spark-entrypoint.sh /entrypoints/spark-entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoints/spark-entrypoint.sh /healthcheck.sh

# Set environment in bashrc
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc \
    && echo "export SPARK_HOME=${SPARK_HOME}" >> ~/.bashrc \
    && echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~/.bashrc \
    && echo "export PATH=\$PATH:\$SPARK_HOME/bin:\$SPARK_HOME/sbin:\$HADOOP_HOME/bin" >> ~/.bashrc

WORKDIR ${SPARK_HOME}

#-------------------------------------------------------------------------------
# Spark Master Target
FROM base AS spark-master

ENV SERVICE_ROLE=spark-master
ENV SERVICE_TYPE=spark
ENV SPARK_MODE=master

EXPOSE 8080 7077 6066

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/spark-entrypoint.sh"]
CMD ["master"]

#-------------------------------------------------------------------------------
# Spark Worker Target
FROM base AS spark-worker

ENV SERVICE_ROLE=spark-worker
ENV SERVICE_TYPE=spark
ENV SPARK_MODE=worker

EXPOSE 8081

HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/spark-entrypoint.sh"]
CMD ["worker"]
