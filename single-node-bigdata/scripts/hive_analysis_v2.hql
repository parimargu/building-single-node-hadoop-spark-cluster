-- Cleanup Hive Tables
DROP TABLE IF EXISTS employees;
DROP TABLE IF EXISTS departments;
DROP TABLE IF EXISTS avg_salary_per_dept;
DROP TABLE IF EXISTS highest_paid_per_dept;
DROP TABLE IF EXISTS employee_age_groups;
DROP TABLE IF EXISTS emp_count_per_dept;
DROP TABLE IF EXISTS total_salary_per_dept;

-- 1. Create Managed Table for Departments
CREATE TABLE departments (
    dept_id INT,
    dept_name STRING
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ','
STORED AS TEXTFILE
TBLPROPERTIES ("skip.header.line.count"="1");

-- 2. Create Managed Table for Employees
CREATE TABLE employees (
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

-- 3. Load Data from HDFS (Managed Tables)
LOAD DATA INPATH '/sample_data/departments.csv' INTO TABLE departments;
LOAD DATA INPATH '/sample_data/employees.csv' INTO TABLE employees;

-- 4. Analytical Query 1: Average salary per department
CREATE TABLE avg_salary_per_dept
STORED AS TEXTFILE
LOCATION '/hive_results/avg_salary_per_dept'
AS
SELECT d.dept_name, CAST(AVG(e.salary) AS DECIMAL(10,2)) as avg_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- 5. Analytical Query 2: Highest paid employee in each department
CREATE TABLE highest_paid_per_dept
STORED AS TEXTFILE
LOCATION '/hive_results/highest_paid_per_dept'
AS
SELECT d.dept_name, e.name as emp_name, e.salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
JOIN (
    SELECT dept_id, MAX(salary) as max_salary
    FROM employees
    GROUP BY dept_id
) m ON e.dept_id = m.dept_id AND e.salary = m.max_salary;

-- 6. Analytical Query 3: Employee count per age group
CREATE TABLE employee_age_groups
STORED AS TEXTFILE
LOCATION '/hive_results/employee_age_groups'
AS
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

-- 7. Analytical Query 4: Total employees per department
CREATE TABLE emp_count_per_dept
STORED AS TEXTFILE
LOCATION '/hive_results/emp_count_per_dept'
AS
SELECT d.dept_name, COUNT(e.emp_id) as emp_count
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;

-- 8. Analytical Query 5: Total salary expenditure per department
CREATE TABLE total_salary_per_dept
STORED AS TEXTFILE
LOCATION '/hive_results/total_salary_per_dept'
AS
SELECT d.dept_name, SUM(e.salary) as total_salary
FROM employees e
JOIN departments d ON e.dept_id = d.dept_id
GROUP BY d.dept_name;
