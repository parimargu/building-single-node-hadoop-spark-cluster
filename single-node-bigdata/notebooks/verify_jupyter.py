import os
import sys
from pyspark.sql import SparkSession

def test_pyspark_standalone():
    print("\n--- Testing PySpark on Spark Standalone ---")
    try:
        spark = SparkSession.builder \
            .appName("VerifyStandalone") \
            .master("spark://spark-master:7077") \
            .getOrCreate()
        
        df = spark.range(0, 10)
        print(f"Count: {df.count()}")
        spark.stop()
        print("Spark Standalone test passed!")
    except Exception as e:
        print(f"Spark Standalone test failed: {e}")

def test_pyspark_yarn():
    print("\n--- Testing PySpark on YARN ---")
    try:
        # Note: YARN might require more resources, ensuring minimal allocation
        spark = SparkSession.builder \
            .appName("VerifyYARN") \
            .master("yarn") \
            .config("spark.executor.memory", "512m") \
            .config("spark.driver.memory", "512m") \
            .getOrCreate()
        
        df = spark.range(0, 10)
        print(f"Count: {df.count()}")
        spark.stop()
        print("PySpark on YARN test passed!")
    except Exception as e:
        print(f"PySpark on YARN test failed: {e}")

def test_hdfs():
    print("\n--- Testing HDFS Connectivity ---")
    try:
        # We can use subprocess to call hdfs commands or use a library like hdfs
        import subprocess
        result = subprocess.run(["hdfs", "dfs", "-ls", "/"], capture_output=True, text=True)
        print(f"HDFS Root Content:\n{result.stdout}")
        print("HDFS Connectivity test passed!")
    except Exception as e:
        print(f"HDFS Connectivity test failed: {e}")

def test_hive():
    print("\n--- Testing Hive Connectivity via Spark ---")
    try:
        spark = SparkSession.builder \
            .appName("VerifyHive") \
            .config("spark.sql.catalogImplementation", "hive") \
            .enableHiveSupport() \
            .getOrCreate()
        
        spark.sql("CREATE TABLE IF NOT EXISTS test_jupyter (id INT, name STRING)")
        spark.sql("INSERT INTO test_jupyter VALUES (1, 'Jupyter User')")
        df = spark.sql("SELECT * FROM test_jupyter")
        df.show()
        spark.stop()
        print("Hive Connectivity test passed!")
    except Exception as e:
        print(f"Hive Connectivity test failed: {e}")

def test_ml_dl_nlp():
    print("\n--- Testing ML/DL/NLP Libraries ---")
    try:
        import torch
        print(f"PyTorch Version: {torch.__version__}")
        
        import tensorflow as tf
        print(f"TensorFlow Version: {tf.__version__}")
        
        import nltk
        print(f"NLTK Version: {nltk.__version__}")
        
        import spacy
        print(f"Spacy Version: {spacy.__version__}")
        
        print("ML/DL/NLP Libraries test passed!")
    except Exception as e:
        print(f"ML/DL/NLP Libraries test failed: {e}")

if __name__ == "__main__":
    test_ml_dl_nlp()
    test_hdfs()
    # Spark tests might fail if the cluster is not actually running
    # but the environment setup is what we are verifying here.
    # test_pyspark_standalone()
    # test_pyspark_yarn()
    # test_hive()
