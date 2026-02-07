# Jupyter Service for Single-Node Big Data Cluster
# Supports PySpark on YARN/Standalone, HDFS, Hive, and ML/DL/NLP libraries

ARG JAVA_VERSION=21
ARG HADOOP_VERSION=3.4.2
ARG SPARK_VERSION=4.1.1
ARG HIVE_VERSION=4.2.0

FROM ubuntu:22.04

ARG JAVA_VERSION
ARG HADOOP_VERSION
ARG SPARK_VERSION
ARG HIVE_VERSION

ENV DEBIAN_FRONTEND=noninteractive
ENV JAVA_HOME=/usr/lib/jvm/java-${JAVA_VERSION}-openjdk-amd64
ENV HADOOP_HOME=/opt/hadoop
ENV SPARK_HOME=/opt/spark
ENV HIVE_HOME=/opt/hive
ENV HADOOP_CONF_DIR=${HADOOP_HOME}/etc/hadoop
ENV PATH=${PATH}:${HADOOP_HOME}/bin:${SPARK_HOME}/bin:${HIVE_HOME}/bin

# Install system dependencies
RUN apt-get update && apt-get install -y \
    openjdk-${JAVA_VERSION}-jdk \
    curl \
    wget \
    netcat-openbsd \
    procps \
    python3 \
    python3-pip \
    python3-venv \
    libsasl2-dev \
    libssl-dev \
    gcc \
    g++ \
    make \
    && rm -rf /var/lib/apt/lists/*

# Download and install Hadoop
RUN wget -q https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz \
    && tar -xzf hadoop-${HADOOP_VERSION}.tar.gz \
    && mv hadoop-${HADOOP_VERSION} ${HADOOP_HOME} \
    && rm hadoop-${HADOOP_VERSION}.tar.gz

# Download and install Spark
RUN wget -q https://dlcdn.apache.org/spark/spark-${SPARK_VERSION}/spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && tar -xzf spark-${SPARK_VERSION}-bin-hadoop3.tgz \
    && mv spark-${SPARK_VERSION}-bin-hadoop3 ${SPARK_HOME} \
    && rm spark-${SPARK_VERSION}-bin-hadoop3.tgz

# Download and install Hive Client (only binaries needed)
RUN wget -q https://dlcdn.apache.org/hive/hive-${HIVE_VERSION}/apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && tar -xzf apache-hive-${HIVE_VERSION}-bin.tar.gz \
    && mv apache-hive-${HIVE_VERSION}-bin ${HIVE_HOME} \
    && rm apache-hive-${HIVE_VERSION}-bin.tar.gz

# Create necessary directories
RUN mkdir -p /entrypoints /opt/jupyter/notebooks /opt/spark/logs /opt/hadoop/logs

# Install Python requirements
COPY requirements.txt /tmp/requirements.txt
RUN pip3 install --no-cache-dir -r /tmp/requirements.txt

# Copy entrypoint script
COPY jupyter-entrypoint.sh /entrypoints/jupyter-entrypoint.sh
RUN chmod +x /entrypoints/jupyter-entrypoint.sh

# Set up environment in bashrc
RUN echo "export JAVA_HOME=${JAVA_HOME}" >> ~/.bashrc \
    && echo "export HADOOP_HOME=${HADOOP_HOME}" >> ~/.bashrc \
    && echo "export SPARK_HOME=${SPARK_HOME}" >> ~/.bashrc \
    && echo "export HIVE_HOME=${HIVE_HOME}" >> ~/.bashrc \
    && echo "export HADOOP_CONF_DIR=${HADOOP_CONF_DIR}" >> ~/.bashrc \
    && echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$SPARK_HOME/bin:\$HIVE_HOME/bin" >> ~/.bashrc

# Set PySpark environment variables
ENV PYSPARK_PYTHON=python3
ENV PYSPARK_DRIVER_PYTHON=jupyter
ENV PYSPARK_DRIVER_PYTHON_OPTS="lab --ip=0.0.0.0 --port=8888 --no-browser --allow-root --NotebookApp.token='' --NotebookApp.password=''"

WORKDIR /opt/jupyter/notebooks

EXPOSE 8888

ENTRYPOINT ["/entrypoints/jupyter-entrypoint.sh"]
