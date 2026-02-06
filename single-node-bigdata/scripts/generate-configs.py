#!/usr/bin/env python3
"""
Configuration Generator for Single-Node Big Data Cluster
Reads cluster_config.yaml and generates all required configuration files.
"""

import yaml
import os
import sys
import argparse
from pathlib import Path
from typing import Dict, Any


def load_config(config_path: str) -> Dict[str, Any]:
    """Load and validate cluster configuration."""
    with open(config_path, 'r') as f:
        config = yaml.safe_load(f)
    
    # Validate required sections
    required_sections = ['versions', 'ports', 'databases', 'services']
    for section in required_sections:
        if section not in config:
            raise ValueError(f"Missing required section: {section}")
    
    return config


def generate_core_site_xml(config: Dict[str, Any]) -> str:
    """Generate Hadoop core-site.xml content."""
    namenode_port = config['ports']['hadoop']['namenode_ipc']
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://namenode:{namenode_port}</value>
    </property>
    <property>
        <name>hadoop.tmp.dir</name>
        <value>/opt/hadoop/tmp</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.hosts</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.proxyuser.hive.groups</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.http.filter.initializers</name>
        <value>org.apache.hadoop.security.HttpCrossOriginFilterInitializer</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.enabled</name>
        <value>true</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-origins</name>
        <value>*</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-methods</name>
        <value>GET,POST,OPTIONS,HEAD</value>
    </property>
    <property>
        <name>hadoop.http.crossorigin.allowed-headers</name>
        <value>X-Requested-With,Content-Type,Accept,Origin</value>
    </property>
</configuration>
'''


def generate_hdfs_site_xml(config: Dict[str, Any]) -> str:
    """Generate Hadoop hdfs-site.xml content."""
    ports = config['ports']['hadoop']
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>1</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>/opt/hadoop/data/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>/opt/hadoop/data/datanode</value>
    </property>
    <property>
        <name>dfs.namenode.http-address</name>
        <value>namenode:{ports['namenode_ui']}</value>
    </property>
    <property>
        <name>dfs.datanode.http.address</name>
        <value>0.0.0.0:{ports['datanode_http']}</value>
    </property>
    <property>
        <name>dfs.datanode.use.datanode.hostname</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.client.use.datanode.hostname</name>
        <value>true</value>
    </property>
    <property>
        <name>dfs.permissions.enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>dfs.webhdfs.enabled</name>
        <value>true</value>
    </property>
</configuration>
'''


def generate_yarn_site_xml(config: Dict[str, Any]) -> str:
    """Generate Hadoop yarn-site.xml content."""
    ports = config['ports']['hadoop']
    yarn_config = config['services']['hadoop'].get('yarn', {})
    resource = yarn_config.get('resource', {})
    scheduler = yarn_config.get('scheduler', {})
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>yarn.resourcemanager.hostname</name>
        <value>resourcemanager</value>
    </property>
    <property>
        <name>yarn.resourcemanager.address</name>
        <value>resourcemanager:{ports['resourcemanager_address']}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.scheduler.address</name>
        <value>resourcemanager:{ports['resourcemanager_scheduler']}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.resource-tracker.address</name>
        <value>resourcemanager:{ports['resourcemanager_tracker']}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.admin.address</name>
        <value>resourcemanager:{ports['resourcemanager_admin']}</value>
    </property>
    <property>
        <name>yarn.resourcemanager.webapp.address</name>
        <value>resourcemanager:{ports['resourcemanager_ui']}</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services</name>
        <value>mapreduce_shuffle</value>
    </property>
    <property>
        <name>yarn.nodemanager.aux-services.mapreduce_shuffle.class</name>
        <value>org.apache.hadoop.mapred.ShuffleHandler</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.memory-mb</name>
        <value>{resource.get('memory_mb', 4096)}</value>
    </property>
    <property>
        <name>yarn.nodemanager.resource.cpu-vcores</name>
        <value>{resource.get('cpu_vcores', 4)}</value>
    </property>
    <property>
        <name>yarn.scheduler.minimum-allocation-mb</name>
        <value>{scheduler.get('minimum_allocation_mb', 512)}</value>
    </property>
    <property>
        <name>yarn.scheduler.maximum-allocation-mb</name>
        <value>{scheduler.get('maximum_allocation_mb', 4096)}</value>
    </property>
    <property>
        <name>yarn.nodemanager.local-dirs</name>
        <value>/opt/hadoop/data/nodemanager/local</value>
    </property>
    <property>
        <name>yarn.nodemanager.log-dirs</name>
        <value>/opt/hadoop/data/nodemanager/logs</value>
    </property>
    <property>
        <name>yarn.log-aggregation-enable</name>
        <value>true</value>
    </property>
    <property>
        <name>yarn.nodemanager.remote-app-log-dir</name>
        <value>/app-logs</value>
    </property>
    <property>
        <name>yarn.nodemanager.vmem-check-enabled</name>
        <value>false</value>
    </property>
    <property>
        <name>yarn.nodemanager.pmem-check-enabled</name>
        <value>false</value>
    </property>
</configuration>
'''


def generate_mapred_site_xml(config: Dict[str, Any]) -> str:
    """Generate Hadoop mapred-site.xml content."""
    ports = config['ports']['hadoop']
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>mapreduce.framework.name</name>
        <value>yarn</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.address</name>
        <value>historyserver:{ports['historyserver_address']}</value>
    </property>
    <property>
        <name>mapreduce.jobhistory.webapp.address</name>
        <value>historyserver:{ports['historyserver_ui']}</value>
    </property>
    <property>
        <name>yarn.app.mapreduce.am.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
    <property>
        <name>mapreduce.map.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
    <property>
        <name>mapreduce.reduce.env</name>
        <value>HADOOP_MAPRED_HOME=/opt/hadoop</value>
    </property>
</configuration>
'''


def generate_spark_defaults_conf(config: Dict[str, Any]) -> str:
    """Generate Spark spark-defaults.conf content."""
    ports = config['ports']
    spark_config = config['services']['spark']
    
    return f'''# Spark Configuration - Generated from cluster_config.yaml

spark.master                     spark://spark-master:{ports['spark']['master_port']}
spark.eventLog.enabled           true
spark.eventLog.dir               hdfs://namenode:{ports['hadoop']['namenode_ipc']}/spark-logs
spark.history.fs.logDirectory    hdfs://namenode:{ports['hadoop']['namenode_ipc']}/spark-logs
spark.sql.warehouse.dir          hdfs://namenode:{ports['hadoop']['namenode_ipc']}/user/hive/warehouse
spark.hadoop.hive.metastore.uris thrift://hive-metastore:{ports['hive']['metastore']}
spark.sql.catalogImplementation  hive
spark.driver.memory              {spark_config['master']['memory']}
spark.executor.memory            {spark_config['worker']['memory']}
spark.executor.cores             {spark_config['worker']['cores']}
'''


def generate_hive_site_xml(config: Dict[str, Any]) -> str:
    """Generate Hive hive-site.xml content."""
    ports = config['ports']
    mysql = config['databases']['mysql']
    
    return f'''<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>javax.jdo.option.ConnectionURL</name>
        <value>jdbc:mysql://{mysql['host']}:{mysql['port']}/{mysql['database']}?createDatabaseIfNotExist=true&amp;useSSL=false&amp;allowPublicKeyRetrieval=true</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionDriverName</name>
        <value>com.mysql.cj.jdbc.Driver</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionUserName</name>
        <value>{mysql['user']}</value>
    </property>
    <property>
        <name>javax.jdo.option.ConnectionPassword</name>
        <value>{mysql['password']}</value>
    </property>
    <property>
        <name>hive.metastore.uris</name>
        <value>thrift://hive-metastore:{ports['hive']['metastore']}</value>
    </property>
    <property>
        <name>hive.metastore.warehouse.dir</name>
        <value>hdfs://namenode:{ports['hadoop']['namenode_ipc']}/user/hive/warehouse</value>
    </property>
    <property>
        <name>hive.server2.thrift.port</name>
        <value>{ports['hive']['hiveserver2']}</value>
    </property>
    <property>
        <name>hive.server2.webui.port</name>
        <value>{ports['hive']['hiveserver2_ui']}</value>
    </property>
    <property>
        <name>hive.server2.enable.doAs</name>
        <value>false</value>
    </property>
    <property>
        <name>hive.metastore.schema.verification</name>
        <value>false</value>
    </property>
    <property>
        <name>datanucleus.schema.autoCreateAll</name>
        <value>true</value>
    </property>
    <property>
        <name>hive.server2.authentication</name>
        <value>NONE</value>
    </property>
    <property>
        <name>hive.execution.engine</name>
        <value>{config['services']['hive'].get('execution_engine', 'mr')}</value>
    </property>
    <property>
        <name>spark.master</name>
        <value>spark://spark-master:{ports['spark']['master_port']}</value>
    </property>
    <property>
        <name>spark.serializer</name>
        <value>org.apache.spark.serializer.KryoSerializer</value>
    </property>
</configuration>
'''


def validate_config(config: Dict[str, Any]) -> bool:
    """Validate configuration values."""
    errors = []
    
    # Check versions
    versions = config.get('versions', {})
    if not versions.get('java'):
        errors.append("Java version not specified")
    if not versions.get('hadoop'):
        errors.append("Hadoop version not specified")
    if not versions.get('spark'):
        errors.append("Spark version not specified")
    if not versions.get('hive'):
        errors.append("Hive version not specified")
    
    # Check ports
    ports = config.get('ports', {})
    if not ports.get('hadoop'):
        errors.append("Hadoop ports not specified")
    if not ports.get('spark'):
        errors.append("Spark ports not specified")
    if not ports.get('hive'):
        errors.append("Hive ports not specified")
    
    # Check databases
    databases = config.get('databases', {})
    if not databases.get('mysql'):
        errors.append("MySQL configuration not specified")
    if not databases.get('postgres'):
        errors.append("PostgreSQL configuration not specified")
    
    if errors:
        for error in errors:
            print(f"ERROR: {error}", file=sys.stderr)
        return False
    
    print("Configuration validation passed!")
    return True


def write_config_file(output_dir: str, filename: str, content: str):
    """Write configuration content to file."""
    filepath = os.path.join(output_dir, filename)
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    with open(filepath, 'w') as f:
        f.write(content)
    print(f"Generated: {filepath}")


def main():
    parser = argparse.ArgumentParser(description='Generate configuration files from cluster_config.yaml')
    parser.add_argument('--config', '-c', default='cluster_config.yaml', help='Path to cluster config file')
    parser.add_argument('--output', '-o', default='generated-configs', help='Output directory for generated configs')
    parser.add_argument('--validate', '-v', action='store_true', help='Only validate configuration')
    args = parser.parse_args()
    
    # Load configuration
    try:
        config = load_config(args.config)
    except FileNotFoundError:
        print(f"ERROR: Configuration file not found: {args.config}", file=sys.stderr)
        sys.exit(1)
    except yaml.YAMLError as e:
        print(f"ERROR: Invalid YAML in configuration file: {e}", file=sys.stderr)
        sys.exit(1)
    
    # Validate configuration
    if not validate_config(config):
        sys.exit(1)
    
    if args.validate:
        print("Validation completed successfully!")
        sys.exit(0)
    
    # Generate configuration files
    output_dir = args.output
    
    # Hadoop configurations
    write_config_file(output_dir, 'hadoop/core-site.xml', generate_core_site_xml(config))
    write_config_file(output_dir, 'hadoop/hdfs-site.xml', generate_hdfs_site_xml(config))
    write_config_file(output_dir, 'hadoop/yarn-site.xml', generate_yarn_site_xml(config))
    write_config_file(output_dir, 'hadoop/mapred-site.xml', generate_mapred_site_xml(config))
    
    # Spark configuration
    write_config_file(output_dir, 'spark/spark-defaults.conf', generate_spark_defaults_conf(config))
    
    # Hive configuration
    write_config_file(output_dir, 'hive/hive-site.xml', generate_hive_site_xml(config))
    
    print(f"\nAll configurations generated in: {output_dir}")


if __name__ == '__main__':
    main()
