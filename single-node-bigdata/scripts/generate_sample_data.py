import csv
import random
from datetime import datetime, timedelta
import os

def generate_customers(num_rows=100):
    customers = []
    for i in range(1, num_rows + 1):
        customers.append({
            'customer_id': i,
            'name': f'Customer_{i}',
            'email': f'customer_{i}@example.com',
            'city': random.choice(['New York', 'Los Angeles', 'Chicago', 'Houston', 'Phoenix'])
        })
    return customers

def generate_products(num_rows=100):
    products = []
    for i in range(1, num_rows + 1):
        products.append({
            'product_id': i,
            'product_name': f'Product_{i}',
            'category': random.choice(['Electronics', 'Books', 'Clothing', 'Home', 'Toys']),
            'price': round(random.uniform(10.0, 500.0), 2)
        })
    return products

def generate_orders(num_rows=100, num_customers=100, num_products=100):
    orders = []
    start_date = datetime(2023, 1, 1)
    for i in range(1, num_rows + 1):
        order_date = start_date + timedelta(days=random.randint(0, 365))
        orders.append({
            'order_id': i,
            'customer_id': random.randint(1, num_customers),
            'product_id': random.randint(1, num_products),
            'quantity': random.randint(1, 5),
            'order_date': order_date.strftime('%Y-%m-%d')
        })
    return orders

def save_to_csv(data, filename):
    if not data:
        return
    keys = data[0].keys()
    os.makedirs('sample_data', exist_ok=True)
    filepath = os.path.join('sample_data', filename)
    with open(filepath, 'w', newline='') as f:
        dict_writer = csv.DictWriter(f, fieldnames=keys)
        dict_writer.writeheader()
        dict_writer.writerows(data)
    print(f"Generated {filepath}")

if __name__ == "__main__":
    customers = generate_customers(100)
    products = generate_products(100)
    orders = generate_orders(100)

    save_to_csv(customers, 'customers.csv')
    save_to_csv(products, 'products.csv')
    save_to_csv(orders, 'orders.csv')
