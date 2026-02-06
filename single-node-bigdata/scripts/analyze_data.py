from pyspark.sql import SparkSession
from pyspark.sql.functions import col, sum, avg, count, desc
import sys

def main():
    # Initialize Spark Session
    # The master is usually set via spark-submit, but we can provide a default
    spark = SparkSession.builder \
        .appName("BigDataAnalysis") \
        .getOrCreate()

    print("Spark Session Started")

    # Define HDFS paths
    input_path = "hdfs:///data/"
    output_path = "hdfs:///output/metrics"

    try:
        # Load datasets
        print(f"Loading data from {input_path}")
        orders_df = spark.read.csv(f"{input_path}/orders.csv", header=True, inferSchema=True)
        products_df = spark.read.csv(f"{input_path}/products.csv", header=True, inferSchema=True)
        customers_df = spark.read.csv(f"{input_path}/customers.csv", header=True, inferSchema=True)

        # 1. Total Revenue per Category
        print("Calculating Revenue per Category...")
        revenue_per_category = orders_df.join(products_df, "product_id") \
            .groupBy("category") \
            .agg(sum(col("quantity") * col("price")).alias("total_revenue")) \
            .orderBy(desc("total_revenue"))

        # 2. Average Order Value per City
        print("Calculating Average Order Value per City...")
        order_values = orders_df.join(products_df, "product_id") \
            .select("order_id", "customer_id", (col("quantity") * col("price")).alias("order_value"))
        
        avg_order_per_city = order_values.join(customers_df, "customer_id") \
            .groupBy("city") \
            .agg(avg("order_value").alias("avg_order_value"), count("order_id").alias("order_count")) \
            .orderBy(desc("avg_order_value"))

        # 3. Top 5 Products by Sales Volume
        print("Calculating Top 5 Products...")
        top_products = orders_df.groupBy("product_id") \
            .agg(sum("quantity").alias("total_quantity")) \
            .join(products_df, "product_id") \
            .select("product_name", "category", "total_quantity") \
            .orderBy(desc("total_quantity")) \
            .limit(5)

        # Show results
        print("\n--- Revenue per Category ---")
        revenue_per_category.show()
        
        print("\n--- Avg Order Value per City ---")
        avg_order_per_city.show()

        print("\n--- Top 5 Products ---")
        top_products.show()

        # Save metrics to HDFS (using overwrite to allow reruns)
        print(f"Saving metrics to {output_path}")
        revenue_per_category.write.mode("overwrite").csv(f"{output_path}/revenue_per_category", header=True)
        avg_order_per_city.write.mode("overwrite").csv(f"{output_path}/avg_order_per_city", header=True)
        top_products.write.mode("overwrite").csv(f"{output_path}/top_products", header=True)

        print("Analysis completed successfully.")

    except Exception as e:
        print(f"Error during analysis: {e}")
        sys.exit(1)
    finally:
        spark.stop()

if __name__ == "__main__":
    main()
