# Hive Image for Single-Node Big Data Cluster
# Supports: hive-metastore, hiveserver2

ARG JAVA_VERSION=21
ARG HIVE_VERSION=4.2.0
ARG HADOOP_VERSION=3.4.2
ARG SPARK_VERSION=4.1.1

FROM ubuntu:22.04 AS base

ARG JAVA_VERSION
ARG HIVE_VERSION
ARG HADOOP_VERSION
ARG SPARK_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV HIVE_HOME=/opt/hive
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HIVE_HOME}/bin:${HADOOP_HOME}/bin:${SPARK_HOME}/bin

# Install dependencies
RUN apt-get update && apt-get install -y \
    openjdk-${JAVA_VERSION}-jdk \
    curl \
    wget \
    netcat-openbsd \
    procps \
    python3 \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hive
RUN wget https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && mv apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} \
    && rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# Download and install Hadoop (for HDFS client and configs)
RUN wget https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz \
    && mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Download and install Spark (for Hive on Spark)
RUN wget https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download MySQL JDBC driver
RUN wget -q https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/8.3.0/mysql-connector-j-8.3.0.jar \
    -O ${HIVE_HOME}/lib/mysql-connector-j-8.3.0.jar

# Create necessary directories
RUN mkdir -p ${HIVE_HOME}/logs \
    && mkdir -p /entrypoints \
    && mkdir -p /user/hive/warehouse

# Copy entrypoint scripts
COPY hive-entrypoint.sh /entrypoints/hive-entrypoint.sh
COPY healthcheck.sh /healthcheck.sh
RUN chmod +x /entrypoints/hive-entrypoint.sh /healthcheck.sh

# Set environment in bashrc
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc \
    && echo "export HIVE_HOME=${HIVE_HOME}" >> ~/.bashrc \
    && echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~/.bashrc \
    && echo "export PATH=\$PATH:\$HIVE_HOME/bin:\$HADOOP_HOME/bin" >> ~/.bashrc

WORKDIR ${HIVE_HOME}

#-------------------------------------------------------------------------------
# Hive Metastore Target
FROM base AS hive-metastore

ENV SERVICE_ROLE=hive-metastore
ENV SERVICE_TYPE=hive
ENV HIVE_MODE=metastore

EXPOSE 9083

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hive-entrypoint.sh"]
CMD ["metastore"]

#-------------------------------------------------------------------------------
# HiveServer2 Target
FROM base AS hiveserver2

ENV SERVICE_ROLE=hiveserver2
ENV SERVICE_TYPE=hive
ENV HIVE_MODE=hiveserver2

EXPOSE 10000 10002

HEALTHCHECK --interval=30s --timeout=10s --start-period=120s --retries=5 \
    CMD /healthcheck.sh

ENTRYPOINT ["/entrypoints/hive-entrypoint.sh"]
CMD ["hiveserver2"]
