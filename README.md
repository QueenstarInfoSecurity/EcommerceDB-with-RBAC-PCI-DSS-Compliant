# EcommerceDB-with-RBAC-PCI-DSS-Compliant
This project implements a secure SQL database schema for ecommerce applications with built-in `role based access controls (RBAC)` and `Payments Card Industry Data Security Standard (PCI DSS)` compliance features. The design focuses on protecting sensitive customer and payments data while maintaining functionality for e-commerce operations.

## Features
 ### PCI DSS Copliant Data Storage
- Tokenized payment information
- Encrypted sensitive data
- Audit logging for all sensitive operations

### Role-Based Access Control
   - Granular permissions for different user roles
   - Secure views and stored procedures
   - Least privilege principle implementation
     
### Comprehensive E-Commerce Schema
  - Customer management
  - Product catalog and inventory
  - Order processing system
  - Transaction tracking

##    Core Tables
### Users and Roles
- Users and Authentication: `users`, `users_roles`, `user_role_mapping`
- Customer Data : `customers`, `customer_addresses`
- Payment Information: `payment_methods`, `payments_card_tokens`.
- Products and Inventory: `products`, `inventory`.
- Orders and Transactions: `orders`, `order_items`, `transactions`.
- Audit Logs: `audit_logs`.

## Views for Role-Based Access
| View                   | Purpose                         |
|------------------------|---------------------------------|
| `customer_support_view`| Customer/order data for support |
| `finance_payment_view` | Masked payment info for finance |

##  Installation

### Prerequisites
- MySQL 5.7+
- Database administration privileges

## Getting Started
- Clone the repo
- Import `schema.sql` into your MYSQL server
- Use included scripts to populate users and simulate transaction (Optional)
- Call procedures like `register_customer` to test workflow

## License
 This project is licensed under the MIT License.
## ** Disclaimer:**
This project is provided **as is**, without any warranties or guarantees. The author assumes **no responsibility** for any issues, damages,or legal consequences arising from the use of this content. Users should consult legal professionals before implementing any contractual or security related clauses.
  

## Acknowledgments
 - PCI Security Standards Council
 - OWASP Database Secuirty Project
 - NIST Cybersecurity Framework 
