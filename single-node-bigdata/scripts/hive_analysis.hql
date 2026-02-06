-- Create Managed Tables
CREATE TABLE IF NOT EXISTS departments (
    dept_id INT,
    dept_name STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

CREATE TABLE IF NOT EXISTS employees (
    emp_id INT,
    name STRING,
    dept_id INT,
    salary INT,
    age INT
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

-- Load Data from HDFS
LOAD DATA INPATH '/sample_data/departments.csv' OVERWRITE INTO TABLE departments;
LOAD DATA INPATH '/sample_data/employees.csv' OVERWRITE INTO TABLE employees;

-- Analysis Queries and External Result Tables

-- 1. Average salary per department
CREATE EXTERNAL TABLE IF NOT EXISTS avg_salary_per_dept (
    dept_name STRING,
    avg_salary DOUBLE
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/hive_results/avg_salary_per_dept';

INSERT OVERWRITE TABLE avg_salary_per_dept
SELECT d.dept_name, AVG(e.salary) as avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- 2. Highest paid employee in each department
CREATE EXTERNAL TABLE IF NOT EXISTS highest_paid_per_dept (
    dept_name STRING,
    emp_name STRING,
    salary INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/hive_results/highest_paid_per_dept';

INSERT OVERWRITE TABLE highest_paid_per_dept
SELECT d.dept_name, e.name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN (
    SELECT dept_id, MAX(salary) as max_salary
    FROM employees
    GROUP BY dept_id
) m ON e.dept_id = m.dept_id AND e.salary = m.max_salary;

-- 3. Count of employees per age group
CREATE EXTERNAL TABLE IF NOT EXISTS employee_age_groups (
    age_group STRING,
    employee_count INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/hive_results/employee_age_groups';

INSERT OVERWRITE TABLE employee_age_groups
SELECT 
    CASE 
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+' 
    END as age_group,
    COUNT(*) as employee_count
FROM employees
GROUP BY 
    CASE 
        WHEN age BETWEEN 20 AND 29 THEN '20-29'
        WHEN age BETWEEN 30 AND 39 THEN '30-39'
        WHEN age BETWEEN 40 AND 49 THEN '40-49'
        ELSE '50+' 
    END;

-- 4. Total employees per department
CREATE EXTERNAL TABLE IF NOT EXISTS emp_count_per_dept (
    dept_name STRING,
    emp_count INT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/hive_results/emp_count_per_dept';

INSERT OVERWRITE TABLE emp_count_per_dept
SELECT d.dept_name, COUNT(e.emp_id) as emp_count
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- 5. Total salary expenditure per department
CREATE EXTERNAL TABLE IF NOT EXISTS total_salary_per_dept (
    dept_name STRING,
    total_salary BIGINT
)
ROW FORMAT DELIMITED FIELDS TERMINATED BY ','
LOCATION '/hive_results/total_salary_per_dept';

INSERT OVERWRITE TABLE total_salary_per_dept
SELECT d.dept_name, SUM(e.salary) as total_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;
