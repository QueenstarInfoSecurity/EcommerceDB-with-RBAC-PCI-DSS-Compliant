CREATE DATABASE ecommercedb;

USE ecommercedb;

CREATE TABLE users (
    user_id INT PRIMARY KEY AUTO_INCREMENT,
    username VARCHAR(50) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    email VARCHAR(100) UNIQUE NOT NULL,
    account_created DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    last_login DATETIME,
    is_active BOOLEAN DEFAULT TRUE,
    must_change_password BOOLEAN DEFAULT FALSE,
    password_changed_at DATETIME
);

CREATE TABLE user_roles (
    role_id INT PRIMARY KEY AUTO_INCREMENT,
    role_name VARCHAR(50) UNIQUE NOT NULL,
    description TEXT
);


CREATE TABLE user_role_mapping (
    user_id INT NOT NULL,
    role_id INT NOT NULL,
    assigned_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    assigned_by INT,
    PRIMARY KEY (user_id, role_id),
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    FOREIGN KEY (role_id) REFERENCES user_roles(role_id),
    FOREIGN KEY (assigned_by) REFERENCES users(user_id)
);

CREATE TABLE customers (
    customer_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT UNIQUE,
    first_name VARCHAR(100) NOT NULL,
    last_name VARCHAR(100) NOT NULL,
    date_of_birth DATE,
    phone VARCHAR(20),
    FOREIGN KEY (user_id) REFERENCES users(user_id)
);

CREATE TABLE customer_addresses (
    address_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    address_type ENUM('billing', 'shipping', 'both') NOT NULL,
    street_address1 VARCHAR(255) NOT NULL,
    street_address2 VARCHAR(255),
    city VARCHAR(100) NOT NULL,
    state VARCHAR(100) NOT NULL,
    postal_code VARCHAR(20) NOT NULL,
    country VARCHAR(100) NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);



CREATE TABLE payment_methods (
    payment_method_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    payment_type ENUM('credit_card', 'debit_card', 'paypal', 'bank_transfer') NOT NULL,
    is_default BOOLEAN DEFAULT FALSE,
    is_active BOOLEAN DEFAULT TRUE,
    added_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE payment_card_tokens (
    token_id INT PRIMARY KEY AUTO_INCREMENT,
    payment_method_id INT NOT NULL,
    token VARCHAR(255) UNIQUE NOT NULL,
    card_last4 CHAR(4) NOT NULL,
    card_brand VARCHAR(50) NOT NULL,
    card_exp_month CHAR(2) NOT NULL,
    card_exp_year CHAR(4) NOT NULL,
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
);

CREATE TABLE products (
    product_id INT PRIMARY KEY AUTO_INCREMENT,
    sku VARCHAR(50) UNIQUE NOT NULL,
    name VARCHAR(255) NOT NULL,
    description TEXT,
    price DECIMAL(10,2) NOT NULL,
    cost DECIMAL(10,2),
    is_active BOOLEAN DEFAULT TRUE,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at DATETIME ON UPDATE CURRENT_TIMESTAMP
);

CREATE TABLE inventory (
    inventory_id INT PRIMARY KEY AUTO_INCREMENT,
    product_id INT NOT NULL,
    quantity INT NOT NULL DEFAULT 0,
    low_stock_threshold INT DEFAULT 5,
    last_restocked DATETIME,
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE orders (
    order_id INT PRIMARY KEY AUTO_INCREMENT,
    customer_id INT NOT NULL,
    order_date DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    status ENUM('pending', 'processing', 'shipped', 'delivered', 'cancelled', 'refunded') NOT NULL DEFAULT 'pending',
    shipping_address_id INT NOT NULL,
    billing_address_id INT NOT NULL,
    subtotal DECIMAL(10,2) NOT NULL,
    tax_amount DECIMAL(10,2) NOT NULL,
    shipping_cost DECIMAL(10,2) NOT NULL,
    total_amount DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id),
    FOREIGN KEY (shipping_address_id) REFERENCES customer_addresses(address_id),
    FOREIGN KEY (billing_address_id) REFERENCES customer_addresses(address_id)
);

CREATE TABLE order_items (
    order_item_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    product_id INT NOT NULL,
    quantity INT NOT NULL,
    unit_price DECIMAL(10,2) NOT NULL,
    total_price DECIMAL(10,2) NOT NULL,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id)
);

CREATE TABLE transactions (
    transaction_id INT PRIMARY KEY AUTO_INCREMENT,
    order_id INT NOT NULL,
    payment_method_id INT NOT NULL,
    amount DECIMAL(10,2) NOT NULL,
    currency CHAR(3) NOT NULL DEFAULT 'USD',
    status ENUM('pending', 'completed', 'failed', 'refunded') NOT NULL,
    processor_transaction_id VARCHAR(255),
    processor_response TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (payment_method_id) REFERENCES payment_methods(payment_method_id)
);

CREATE TABLE audit_logs (
    log_id INT PRIMARY KEY AUTO_INCREMENT,
    user_id INT,
    action VARCHAR(50) NOT NULL,
    table_affected VARCHAR(50) NOT NULL,
    record_id INT,
    old_values TEXT,  -- 
    new_values TEXT,
    ip_address VARCHAR(45),
    user_agent TEXT,
    created_at DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    FOREIGN KEY (user_id) REFERENCES users(user_id),
    CHECK (JSON_VALID(old_values)),
    CHECK (JSON_VALID(new_values))
);
-- Defining roles 
INSERT INTO user_roles (role_name, description) VALUES 
('admin', 'Full system access with all privileges'),
('customer', 'Standard customer access'),
('inventory_manager', 'Manages product inventory and listings'),
('order_processor', 'Processes orders and updates status'),
('customer_support', 'Access to customer data for support purposes'),
('finance', 'Access to financial reports and transactions'),
('auditor', 'Read-only access for compliance auditing');

-- Implementation of Role-Based Data Access
-- CUSTOMER RESTRICTED ACCESS
CREATE VIEW customer_support_view AS
SELECT 
    c.customer_id, c.first_name, c.last_name, 
    u.email, ca.street_address1, ca.city, ca.state, ca.postal_code, ca.country,
    o.order_id, o.order_date, o.status, o.total_amount
FROM customers c
JOIN users u ON c.user_id = u.user_id
JOIN customer_addresses ca ON c.customer_id = ca.customer_id
JOIN orders o ON c.customer_id = o.customer_id
WHERE ca.is_default = TRUE;

-- PAYMENTS DATA WITHOUT FULL CARD DETAILS
CREATE VIEW finance_payment_view AS
SELECT 
    t.transaction_id, o.order_id, 
    c.customer_id, CONCAT(c.first_name, ' ', c.last_name) AS customer_name,
    pm.payment_type, pct.card_last4, pct.card_brand, pct.card_exp_month, pct.card_exp_year,
    t.amount, t.currency, t.status, t.created_at
FROM transactions t
JOIN orders o ON t.order_id = o.order_id
JOIN customers c ON o.customer_id = c.customer_id
JOIN payment_methods pm ON t.payment_method_id = pm.payment_method_id
LEFT JOIN payment_card_tokens pct ON pm.payment_method_id = pct.payment_method_id;

-- Securing customer registration
DELIMITER 
CREATE PROCEDURE register_customer(
    IN p_username VARCHAR(50),
    IN p_password VARCHAR(255),
    IN p_email VARCHAR(100),
    IN p_first_name VARCHAR(100),
    IN p_last_name VARCHAR(100),
    IN p_phone VARCHAR(20)
)
BEGIN
    DECLARE user_count INT;
    DECLARE new_user_id INT;
    
    -- checking if username or email exist.
      SELECT COUNT(*) INTO user_count FROM users WHERE username = p_username OR email = p_email;
    
    IF user_count > 0 THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Username or email already exists';
    ELSE
    
    -- Creating user 
     INSERT INTO users (username, password_hash, email) 
        VALUES (p_username, p_password, p_email);
        
        SET new_user_id = LAST_INSERT_ID();
        -- creating customer record 
        INSERT INTO customers (user_id, first_name, last_name, phone)
        VALUES (new_user_id, p_first_name, p_last_name, p_phone);
	
        -- assigning customer role
        INSERT INTO user_role_mapping (user_id, role_id)
        VALUES (new_user_id, (SELECT role_id FROM user_roles WHERE role_name = 'customer'));
    END IF;
END //
DELIMITER ;

-- Securing order process
DELIMITER 
CREATE PROCEDURE process_order(
    IN p_customer_id INT,
    IN p_shipping_address_id INT,
    IN p_billing_address_id INT,
    IN p_payment_method_id INT,
    OUT p_order_id INT
)
BEGIN
    DECLARE v_subtotal DECIMAL(10,2);
    DECLARE v_tax_amount DECIMAL(10,2);
    DECLARE v_shipping_cost DECIMAL(10,2);
    DECLARE v_total DECIMAL(10,2);
    DECLARE v_cart_items INT;
    
    -- Validate customer addresses
    IF NOT EXISTS (
        SELECT 1 FROM customer_addresses 
        WHERE address_id IN (p_shipping_address_id, p_billing_address_id)
        AND customer_id = p_customer_id
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid shipping or billing address';
    END IF;
    
    -- Validating payment method
     IF NOT EXISTS (
        SELECT 1 FROM payment_methods 
        WHERE payment_method_id = p_payment_method_id
        AND customer_id = p_customer_id
        AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method';
    END IF;
     -- Validate payment method
     -- Validate payment method
    IF NOT EXISTS (
        SELECT 1 FROM payment_methods 
        WHERE payment_method_id = p_payment_method_id
        AND customer_id = p_customer_id
        AND is_active = TRUE
    ) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'Invalid payment method';
    END IF;
    
    -- Calculate order totals 
    SET v_subtotal = 0; -- Would normally calculate from cart
    SET v_tax_amount = 0; -- Would calculate based on location
    SET v_shipping_cost = 0; -- Would calculate based on shipping method
    
    SET v_total = v_subtotal + v_tax_amount + v_shipping_cost;
    
    INSERT INTO orders (
        customer_id, shipping_address_id, billing_address_id,
        subtotal, tax_amount, shipping_cost, total_amount
    ) VALUES (
        p_customer_id, p_shipping_address_id, p_billing_address_id,
        v_subtotal, v_tax_amount, v_shipping_cost, v_total
    );
    
    SET p_order_id = LAST_INSERT_ID();
    
    -- Process payment 
    INSERT INTO transactions (
        order_id, payment_method_id, amount, status
    ) VALUES (
        p_order_id, p_payment_method_id, v_total, 'pending'
    );
    
   
    -- Implementation depends on business logic
    
    -- Log the transaction
    INSERT INTO audit_logs (
        user_id, action, table_affected, record_id
    ) VALUES (
        (SELECT user_id FROM customers WHERE customer_id = p_customer_id),
        'create', 'orders', p_order_id
    );
END //
DELIMITER ;

 -- Creating role-specific  for database users
CREATE USER 'customer_app'@'%' IDENTIFIED BY 'secure_password';
CREATE USER 'admin_app'@'localhost' IDENTIFIED BY 'secure_password';
CREATE USER 'reporting'@'internal_network' IDENTIFIED BY 'secure_password';

-- Grant minimal required privileges
GRANT SELECT, INSERT, UPDATE ON ecommerce_db.customers TO 'customer_app'@'%';
GRANT SELECT ON ecommerce_db.products TO 'customer_app'@'%';
GRANT EXECUTE ON PROCEDURE ecommerce_db.register_customer TO 'customer_app'@'%';
GRANT EXECUTE ON PROCEDURE ecommerce_db.process_order TO 'customer_app'@'%';

GRANT ALL PRIVILEGES ON ecommerce_db.* TO 'admin_app'@'localhost' WITH GRANT OPTION;

GRANT SELECT ON ecommerce_db.finance_payment_view TO 'reporting'@'internal_network';
GRANT SELECT ON ecommerce_db.customer_support_view TO 'reporting'@'internal_network';