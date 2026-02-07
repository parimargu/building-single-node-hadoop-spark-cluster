from pyspark.sql import SparkSession; spark = SparkSession.builder.master('yarn').getOrCreate(); print('SUCCESS_YARN_COUNT:', spark.range(10).count()); spark.stop()
