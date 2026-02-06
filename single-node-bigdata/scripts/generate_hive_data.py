#!/usr/bin/env python3
import csv
import os
import random

def generate_departments(filename):
    departments = [
        (1, 'Engineering'),
        (2, 'Sales'),
        (3, 'Marketing'),
        (4, 'HR'),
        (5, 'Product')
    ]
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['dept_id', 'dept_name'])
        writer.writerows(departments)
    print(f"Generated {filename}")

def generate_employees(filename, num_employees=100):
    first_names = ['John', 'Jane', 'Michael', 'Emily', 'Robert', 'Emma', 'David', 'Olivia', 'William', 'Sophia']
    last_names = ['Smith', 'Johnson', 'Williams', 'Brown', 'Jones', 'Garcia', 'Miller', 'Davis', 'Rodriguez', 'Martinez']
    
    os.makedirs(os.path.dirname(filename), exist_ok=True)
    with open(filename, 'w', newline='') as f:
        writer = csv.writer(f)
        writer.writerow(['emp_id', 'name', 'dept_id', 'salary', 'age'])
        for i in range(1, num_employees + 1):
            name = f"{random.choice(first_names)} {random.choice(last_names)}"
            dept_id = random.randint(1, 5)
            salary = random.randint(40000, 150000)
            age = random.randint(22, 60)
            writer.writerow([i, name, dept_id, salary, age])
    print(f"Generated {filename}")

if __name__ == "__main__":
    base_dir = "/tmp/hive_sample_data"
    generate_departments(os.path.join(base_dir, "departments.csv"))
    generate_employees(os.path.join(base_dir, "employees.csv"))
