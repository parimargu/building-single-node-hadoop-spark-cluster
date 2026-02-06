from pyspark.sql import SparkSession
from pyspark.sql.functions import avg, count, sum, max, col, when

def main():
    spark = SparkSession.builder \
        .appName("HiveAnalysis") \
        .getOrCreate()

    # Read CSVs from Hive warehouse paths (LOAD DATA moves them)
    employees = spark.read.option("header", "true").option("inferSchema", "true").csv("/user/hive/warehouse/employees/employees.csv")
    departments = spark.read.option("header", "true").option("inferSchema", "true").csv("/user/hive/warehouse/departments/departments.csv")

    # 1. Average salary per department
    avg_salary_per_dept = employees.join(departments, "dept_id") \
        .groupBy("dept_name") \
        .agg(avg("salary").alias("avg_salary")) \
        .select("dept_name", col("avg_salary").cast("decimal(10,2)"))
    
    avg_salary_per_dept.write.mode("overwrite").csv("/hive_results/avg_salary_per_dept", header=True)

    # 2. Highest paid employee in each department
    max_salaries = employees.groupBy("dept_id").agg(max("salary").alias("salary"))
    highest_paid_per_dept = employees.join(max_salaries, ["dept_id", "salary"]) \
        .join(departments, "dept_id") \
        .select("dept_name", "name", "salary")
    
    highest_paid_per_dept.write.mode("overwrite").csv("/hive_results/highest_paid_per_dept", header=True)

    # 3. Count of employees per age group
    age_groups = employees.withColumn("age_group", 
        when((col("age") >= 20) & (col("age") <= 29), "20-29")
        .when((col("age") >= 30) & (col("age") <= 39), "30-39")
        .when((col("age") >= 40) & (col("age") <= 49), "40-49")
        .otherwise("50+")) \
        .groupBy("age_group") \
        .count()
    
    age_groups.write.mode("overwrite").csv("/hive_results/employee_age_groups", header=True)

    # 4. Total employees per department
    emp_count_per_dept = employees.join(departments, "dept_id") \
        .groupBy("dept_name") \
        .count() \
        .withColumnRenamed("count", "emp_count")
    
    emp_count_per_dept.write.mode("overwrite").csv("/hive_results/emp_count_per_dept", header=True)

    # 5. Total salary expenditure per department
    total_salary_per_dept = employees.join(departments, "dept_id") \
        .groupBy("dept_name") \
        .agg(sum("salary").alias("total_salary"))
    
    total_salary_per_dept.write.mode("overwrite").csv("/hive_results/total_salary_per_dept", header=True)

    print("PySpark Analysis Completed Successfully.")
    spark.stop()

if __name__ == "__main__":
    main()
