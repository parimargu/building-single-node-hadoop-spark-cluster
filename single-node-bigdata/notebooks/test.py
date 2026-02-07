from pyspark.sql import SparkSession; spark = SparkSession.builder.master('spark://spark-master:7077').getOrCreate(); print('SUCCESS_COUNT:', spark.range(10).count()); spark.stop()
