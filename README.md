# 🌾 Agricultural Market Price Intelligence Pipeline

> An end-to-end Data Engineering + Machine Learning pipeline that ingests Indian wholesale commodity price data, normalizes it into a relational Star Schema warehouse, and forecasts future prices using a Random Forest Regressor.

---

## 📌 Table of Contents

- [Problem Statement](#-problem-statement)
- [Architecture Overview](#-architecture-overview)
- [Tech Stack](#-tech-stack)
- [Project Structure](#-project-structure)
- [Database Schema](#-database-schema)
- [Setup & Execution](#-setup--execution)
- [Pipeline Modules](#-pipeline-modules)
- [SQL Analytics](#-sql-analytics)
- [Machine Learning](#-machine-learning)
- [Visualizations](#-visualizations)
- [Results](#-results)
- [Bonus Enhancements](#-bonus-enhancements)

---

## 🔍 Problem Statement

Agricultural commodity prices in India exhibit extreme daily volatility across 3,000+ regulated wholesale markets (mandis). Farmers and traders lack access to structured, predictive market intelligence — leading to distress sales, poor harvest timing, and economic instability.

This pipeline resolves that gap by:
- Automating ingestion of daily Agmarknet market reports
- Standardizing and warehousing data in a normalized SQLite database
- Applying time-series Machine Learning to forecast short-term commodity prices

---

## 🏗️ Architecture Overview

```
Kaggle API (CSV)
      │
      ▼
┌─────────────┐     ┌──────────────────┐     ┌─────────────────────┐
│  EXTRACTION  │────▶│  TRANSFORMATION  │────▶│   SQLITE WAREHOUSE  │
│  (extract.py)│     │  (transform.py)  │     │   (Star Schema)     │
└─────────────┘     └──────────────────┘     └──────────┬──────────┘
                                                          │
                          ┌───────────────────────────────┘
                          ▼
               ┌──────────────────┐     ┌──────────────────────┐
               │   SQL ANALYTICS  │     │   ML PIPELINE        │
               │   (queries.sql)  │     │   (ml_pipeline.py)   │
               └──────────────────┘     └──────────┬───────────┘
                                                     │
                                                     ▼
                                          ┌─────────────────────┐
                                          │  Fact_Predictions   │
                                          │  (back to SQLite)   │
                                          └─────────────────────┘
```

**ETL Flow:** `Kaggle API → Pandas (clean) → SQLite (Star Schema) → SQL Analysis + Random Forest → Predictions stored back to DB`

---

## 🛠️ Tech Stack

| Layer | Technology |
|---|---|
| Language | Python 3.10+ |
| Data Manipulation | Pandas 2.2 |
| Database | SQLite 3 + SQLAlchemy 2.0 |
| Machine Learning | Scikit-learn 1.6 (Random Forest) |
| Data Source | Kaggle API — Agmarknet Daily Prices |
| Visualization | Matplotlib 3.10 + Seaborn 0.13 |
| Environment | Google Colab / Local Python venv |
| Scheduling (optional) | Cron (Linux) / Task Scheduler (Windows) |

---

## 📁 Project Structure

```
agri-price-intelligence/
│
├── data/
│   └── commodity_price.csv          # Raw dataset (or fetch via Kaggle API)
│
├── src/
│   ├── config_and_logging.py        # Logger setup + config constants
│   ├── extract.py                   # Kaggle API ingestion module
│   ├── transform.py                 # Data cleaning & transformation
│   ├── load.py                      # SQLite Star Schema loader (incremental)
│   ├── ml_pipeline.py               # Feature engineering + Random Forest
│   └── main_pipeline.py             # Central orchestration script
│
├── sql/
│   └── queries.sql                  # 20 advanced analytical SQL queries
│
├── output/
│   ├── agri_market.db               # Populated SQLite database
│   ├── plots/
│   │   └── dashboard.png            # 6-chart analytics dashboard
│   └── pipeline_execution.log       # Execution audit trail
│
├── requirements.txt
└── README.md
```

---

## 🗄️ Database Schema

The database uses a **Star Schema** (3NF normalized) to eliminate redundancy and optimize query performance.

```
┌─────────────────────┐          ┌─────────────────────────────────────┐
│   Dim_Location      │          │         Fact_Market_Price            │
│─────────────────────│          │─────────────────────────────────────│
│ Location_ID (PK)    │◀────────▶│ Price_ID     (PK)                   │
│ State               │          │ Location_ID  (FK → Dim_Location)    │
│ District            │          │ Commodity_ID (FK → Dim_Commodity)   │
│ Market              │          │ Arrival_Date                        │
└─────────────────────┘          │ Min_Price                           │
                                  │ Max_Price                           │
┌─────────────────────┐          │ Modal_Price                         │
│   Dim_Commodity     │          └─────────────────────────────────────┘
│─────────────────────│
│ Commodity_ID (PK)   │◀────────▶┌─────────────────────────────────────┐
│ Commodity_Name      │          │         Fact_Predictions             │
│ Variety             │          │─────────────────────────────────────│
│ Grade               │          │ Prediction_ID (PK)                  │
└─────────────────────┘          │ Location_ID   (FK → Dim_Location)   │
                                  │ Commodity_ID  (FK → Dim_Commodity)  │
                                  │ Target_Date                         │
                                  │ Predicted_Price                     │
                                  └─────────────────────────────────────┘
```

**Row counts (production run):**
- `Dim_Location` — 269 unique market locations
- `Dim_Commodity` — 420 unique commodity variants
- `Fact_Market_Price` — 2,733 daily price records
- `Fact_Predictions` — 410 ML-generated forecasts

---

## ⚙️ Setup & Execution

### 1. Clone the Repository
```bash
git clone https://github.com/your-username/agri-price-intelligence.git
cd agri-price-intelligence
```

### 2. Install Dependencies
```bash
pip install -r requirements.txt
```

### 3. Configure Kaggle API
- Go to [kaggle.com](https://www.kaggle.com) → Settings → API → **Create New Token**
- Place the downloaded `kaggle.json` at `~/.config/kaggle/kaggle.json`
- Or upload it when prompted in Google Colab

### 4. Run the Full Pipeline
```bash
python src/main_pipeline.py
```

### Run in Google Colab
Open the notebook and execute cells sequentially. The Kaggle upload prompt will appear automatically in Cell 3.

### Optional: Schedule Daily Runs
```bash
# Linux/macOS — runs at 2:00 AM daily
0 2 * * * /usr/bin/python3 /path/to/main_pipeline.py
```

---

## 🔧 Pipeline Modules

### `extract.py`
- Authenticates with Kaggle API via `kagglehub`
- Downloads the [Agmarknet Daily Wholesale Prices](https://www.kaggle.com/datasets/ishankat/daily-wholesale-commodity-prices-india-mandis) dataset
- Loads up to 500,000 rows into a Pandas DataFrame

### `transform.py`
Applies 6 data quality operations:
1. Drops records with missing critical fields
2. Standardizes dates → ISO 8601 (`YYYY-MM-DD`)
3. Normalizes text → Title Case, strips whitespace
4. Fixes zero `Min_Price` values → replaced with `Modal_Price`
5. Swaps `Min_Price`/`Max_Price` if entered backwards (9 anomalies fixed)
6. Type-casts all price columns to `float`

### `load.py`
- Decomposes flat data into `Dim_Location` and `Dim_Commodity`
- Maps foreign key IDs back to build `Fact_Market_Price`
- **Incremental Load Logic**: queries `MAX(Arrival_Date)` in DB and only inserts records newer than that date — simulating a production delta load

### `ml_pipeline.py`
- Extracts time-series data from SQLite
- Engineers lag features (`Lag_1`, `Lag_3`) and rolling statistics (`Rolling_Mean_7`)
- Trains `RandomForestRegressor` with chronological 85/15 train-test split
- Writes 410 predictions back to `Fact_Predictions` table

---

## 📊 SQL Analytics

20 advanced queries saved in `sql/queries.sql`, organized across 5 categories:

| Category | Queries | Techniques Used |
|---|---|---|
| A — Aggregations | Q1–Q4 | GROUP BY, HAVING, AVG, COUNT |
| B — Joins & Subqueries | Q5–Q8 | CTEs, LEFT JOIN, correlated subqueries |
| C — Ranking & Distribution | Q9–Q12 | DENSE_RANK, NTILE, CUME_DIST, FIRST/LAST_VALUE |
| D — Time-Series Analysis | Q13–Q16 | Moving averages, LAG, LEAD, YoY growth |
| E — Data Quality & ML Prep | Q17–Q20 | Duplicate detection, gap analysis, Z-score outliers, feature matrix |

**Sample — 7-Day Moving Average (Q13):**
```sql
SELECT Arrival_Date, Location_ID, Commodity_ID, Modal_Price,
       AVG(Modal_Price) OVER(
           PARTITION BY Location_ID, Commodity_ID
           ORDER BY Arrival_Date
           ROWS BETWEEN 6 PRECEDING AND CURRENT ROW
       ) AS Moving_Avg_7D
FROM Fact_Market_Price;
```

---

## 🤖 Machine Learning

**Model:** Random Forest Regressor (`scikit-learn`)

**Feature Engineering:**

| Feature | Description |
|---|---|
| `Min_Price`, `Max_Price` | Raw price bounds |
| `Mid_Price` | `(Min + Max) / 2` — top feature |
| `Price_Spread` | `Max - Min` — volatility indicator |
| `Lag_1`, `Lag_3` | Previous 1-day and 3-day prices |
| `Rolling_Mean_7` | 7-day smoothed baseline |
| `State_Enc`, `Market_Enc` | Label-encoded location features |
| `Commodity_Enc`, `Grade_Enc` | Label-encoded commodity features |

**Training Strategy:** Chronological split (no random shuffle) to prevent data leakage.

```
Train : 2,323 records (85%)
Test  :   410 records (15%)
```

**Model Performance:**

| Metric | Value |
|---|---|
| MAE (Mean Absolute Error) | ₹ 194.69 |
| RMSE (Root Mean Squared Error) | ₹ 618.40 |
| MAPE (Mean Abs % Error) | **2.79%** ✅ |

> A MAPE of **2.79%** indicates the model predicts commodity prices within ~₹195 on average — highly actionable for real-world trading decisions.

---

## 📈 Visualizations

The dashboard (`output/plots/dashboard.png`) contains 6 charts:

1. **Modal Price Distribution** — histogram with mean/median markers
2. **Top 15 Commodities by Avg Price** — horizontal bar, ranked
3. **Top 10 High-Volatility Markets** — avg price spread per market
4. **State-wise Average Modal Price** — geographic price comparison
5. **Feature Importances** — Random Forest top 10 features
6. **Actual vs Predicted Price** — scatter plot with perfect-prediction reference line

---

## 📋 Results & Key Insights

- **High-volatility markets** identified for trader risk avoidance
- **Premium commodities** (non-FAQ grade) command significantly higher prices
- **Mid_Price** accounts for 69.5% of model's predictive power
- **2.79% MAPE** — model is production-ready for price advisory tools
- **Incremental load** design supports daily pipeline scheduling with zero data duplication

---

## 🚀 Bonus Enhancements

Three extensions to further elevate this project:

**1. Streamlit Dashboard**
```bash
pip install streamlit
streamlit run app.py
```
Interactive web UI with State/Commodity dropdowns and live chart rendering from SQLite.

**2. Data Quality Contracts (Great Expectations)**
```bash
pip install great_expectations
```
Pre-load assertions: `Modal_Price > 0`, `Arrival_Date` not in future, no nulls in key columns.

**3. Apache Airflow DAG**
Convert `main_pipeline.py` into a scheduled DAG for daily automated execution in a production environment.

---

## 📦 Requirements

```
pandas>=2.2.0
sqlalchemy>=2.0.0
scikit-learn>=1.6.0
matplotlib>=3.10.0
seaborn>=0.13.0
kagglehub
```

Install all:
```bash
pip install -r requirements.txt
```

---

## 📄 Data Source

**Agmarknet Daily Wholesale Commodity Prices — India Mandis**
- Provider: Directorate of Marketing and Inspection, Government of India
- Access: [Kaggle Dataset](https://www.kaggle.com/datasets/ishankat/daily-wholesale-commodity-prices-india-mandis)
- Coverage: 3,000+ regulated markets across India
- Format: CSV — State, District, Market, Commodity, Variety, Grade, Arrival_Date, Min/Max/Modal Price

---

## 👤 Author

Built as a portfolio Data Engineering project demonstrating:
- Production-grade ETL pipeline design
- Relational data warehousing (Star Schema + 3NF)
- Advanced SQL analytics (Window Functions, CTEs, Subqueries)
- Applied Machine Learning on structured data
- End-to-end Python pipeline orchestration

---

*Built with Python, SQLite, Scikit-learn, and ☕*
