# Oracle Inventory Ageing Pivot

## 📌 Context
This repository contains an Oracle SQL snippet designed for **stock/inventory ageing (aging) analysis**.  
It is specifically built for **Oracle E-Business Suite R12 (12.2)** environments running on **Oracle Database 19c**.

---

## 🎯 Purpose
The script generates a **7-bucket ageing/aging stock pivot table** for organizations that:
- Use **FIFO (First-In-First-Out)** for inventory management  
- Apply the **Average Costing Method**  

This helps supply chain and finance teams quickly identify how long inventory has been held, improving visibility into stock utilization and valuation.

---

## ⚙️ Environment
- **Application**: Oracle EBS R12 (12.2) Inventory Module  
- **Database**: Oracle 19c  
- **Access Requirement**: DBA-level access is **mandatory** to create additional database objects (e.g., temporary tables, materialized views, or helper functions).  

---

## 📊 Features
- Produces a **pivoted ageing report** with **7 time buckets** (e.g., 0–30 days, 31–60 days, …, >360 days).  
- Supports **multi-organization inventory structures**.  
- Compatible with **FIFO valuation** and **average costing** setups.  
- Can be extended for **custom buckets** or **organization-specific rules**.  

---

## 🚀 Usage
1. Clone this repository:
   ```bash
   git clone https://github.com/rajthampi/oracle-ebs-r12-stock-aging

   Connect to your Oracle EBS R12 12.2 database (19c).

2. Run the SQL script as APPS

3. Review the pivoted ageing output in your SQL client or reporting tool.
