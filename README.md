# ⚡ Modern SQL Data Warehouse Project

> **An End-to-End Data Engineering Solution using Microsoft SQL Server, Medallion Architecture, and Dimensional Modeling.**

---

## 👨‍💻 About Me

Hi there! I'm **Seif El-Din Sameh** (Saif), a 3rd-year **Communications & Electronics Engineering** student at the Higher Technological Institute (6th of October City). 

I am actively transitioning my technical focus into **Data Engineering**, concentrating on high-performance database architectures, query optimization, ETL pipelines, and modern data warehouse design principles.

📫 **Let's Connect & Collaborate:**
* **Email:** [safeserag@gmail.com](mailto:safeserag@gmail.com)
* **LinkedIn:** [safe-serag](https://www.linkedin.com/in/safe-serag-89a8a3253)
* **GitHub:** [seif-serag](https://github.com/seif-serag)

---

## 🌟 Project Overview

This repository demonstrates the design and implementation of an **Enterprise Data Warehouse**. The core goal is to extract raw transactional data from heterogeneous source systems (ERP & CRM), resolve data quality anomalies, and transform the data into a unified, high-performance **Star Schema** to support business data warehousing needs.

---

## 🏗️ Data Architecture (Medallion Pattern)

The data pipeline implements the **Medallion Architecture** to ensure clean data processing, auditability, and clear separation of concerns across layers:

![Data Architecture](C:\Users\safes\OneDrive\Desktop\docs\data_architecture.png)

### Architectural Layers Breakdown:

1. **🥉 Bronze Layer (Raw Ingestion):**
   * **Source:** CSV files from CRM and ERP systems.
   * **Process:** Batch processing using SQL Stored Procedures (`BULK INSERT` / Full Load).
   * **Transformations:** None (stores raw data as-is for data lineage and auditing).

2. **🥈 Silver Layer (Cleansing & Standardization):**
   * **Process:** Stored procedures executing `Truncate & Insert` logic.
   * **Transformations:** Data cleansing, standardization, normalization, handling missing/NULL values, derived columns, and data enrichment.

3. **🥇 Gold Layer (Data Modeling):**
   * **Object Type:** Database Views (No physical storage load).
   * **Data Model:** **Star Schema** featuring Fact and Dimension models, flat tables, and business aggregation logic.

---

## 🎯 Technical Highlights

* **ETL Orchestration:** Stored Procedures built with robust T-SQL logic, structured `TRY...CATCH` error handling, and execution duration tracking.
* **Data Cleansing:** Automated scrubbing using `TRIM()`, `CASE` statements, `COALESCE()`, and type casting.
* **Dimensional Modeling:** Unified Star Schema joining CRM customer profiles with ERP product and sales transactions using surrogate and business keys.

---

## 🛠️ Stack & Tools

* **Database Engine:** Microsoft SQL Server
* **Management GUI:** SQL Server Management Studio (SSMS)
* **Language:** T-SQL (DDL, DML, Stored Procedures, Views)
* **Architecture Diagramming:** Draw.io

---

## 📂 Repository Structure

```text
sql-data-warehouse-project/
│
├── 📁 datasets/                   # Raw CSV source datasets (ERP & CRM)
│
├── 📁 docs/                       # Architectural diagrams & design specs
│   ├── 📄 data_architecture.png   # Medallion Architecture diagram
│   ├── 📄 data_catalog.md         # Field definitions and data dictionary
│   └── 📄 data_models.drawio      # Dimensional model (Star Schema design)
│
├── 📁 scripts/                    # T-SQL Scripts
│   ├── 📁 bronze/                 # DDL and loading procedures for raw tables
│   ├── 📁 silver/                 # Transformation and data cleansing procedures
│   └── 📁 gold/                   # Analytical DDL views (Fact & Dimensions)
│
├── 📁 tests/                      # Data quality & consistency tests
│
└── 📄 README.md                   # Project documentation
