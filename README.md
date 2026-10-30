<div align="center">

# 💳 Fraudulent Financial Transaction Detection

**End-to-end machine learning pipeline that detects fraudulent transactions in a 5-million-row dataset — from SQL database design to model deployment.**

*MSc Data Science Dissertation · Teesside University (Distinction)*

![Python](https://img.shields.io/badge/Python-3776AB?style=for-the-badge&logo=python&logoColor=white)
![SQL](https://img.shields.io/badge/SQL-4479A1?style=for-the-badge&logo=postgresql&logoColor=white)
![scikit-learn](https://img.shields.io/badge/scikit--learn-F7931E?style=for-the-badge&logo=scikitlearn&logoColor=white)
![pandas](https://img.shields.io/badge/pandas-150458?style=for-the-badge&logo=pandas&logoColor=white)
![NumPy](https://img.shields.io/badge/NumPy-013243?style=for-the-badge&logo=numpy&logoColor=white)
![Flask](https://img.shields.io/badge/Flask-000000?style=for-the-badge&logo=flask&logoColor=white)
![Plotly](https://img.shields.io/badge/Plotly-3F4F75?style=for-the-badge&logo=plotly&logoColor=white)

</div>

---

## 📌 Overview

Financial fraud is rare but costly. Only **3.59%** of transactions in this dataset are fraudulent, so a naive model can score high accuracy while missing almost every fraud case. This project builds a pipeline focused on **catching fraud (recall)** while keeping false alarms in check, then puts the model in the hands of non-technical users through an interactive web app.

## 📊 Key Results

| Metric | Random Forest (best model) |
|---|---|
| **Recall** | **0.69** (up from below 0.20 before SMOTE) |
| **ROC-AUC** | **0.93** |
| **F1-score** | **0.51** |

## ⚙️ What I Did

- **Data:** 5,000,000 synthetic financial transactions with a 3.59% fraud rate
- **Database:** designed a relational schema in **SQL**, loaded the data, and wrote analytical queries to explore fraud patterns
- **Feature engineering:** designed **11 behavioural features**; **8 of the top 10** most important model features were ones I engineered
- **Class imbalance:** applied **SMOTE to the training data only** (no leakage into the test set), raising Random Forest recall from below 0.20 to 0.69
- **Model comparison:** trained and evaluated **six classifiers**
- **Threshold tuning:** tested **91 decision thresholds** to find the best trade-off between precision and recall
- **Deployment:** built a **Flask web app** with **six Plotly dashboards** and a **live fraud-prediction page** for non-technical users

## 📂 Repository Structure

| File | Description |
|---|---|
| `01_create_database_and_tables.sql` | Creates the database and tables |
| `02_load_data.sql` | Loads the transaction data |
| `03_analytical_queries.sql` | SQL queries exploring fraud patterns |
| `04_ERD_diagram.sql` | Entity-relationship diagram of the schema |
| `Fraud_Detection_Analysis.ipynb` | Full ML analysis: preprocessing, feature engineering, SMOTE, model comparison, threshold tuning |

## 📁 Dataset

The full 5-million-row dataset is not uploaded to this repo because of GitHub's file size limits.
The complete analysis is in the notebook:
👉 **[Fraud_Detection_Analysis.ipynb](https://github.com/Yaswanthtummala/fraud-detection-ml/blob/main/Fraud_Detection_Analysis.ipynb)**

## 🚀 How to Run

1. **Database:** run the SQL scripts in order (`01` → `04`)
2. **Analysis:** open `Fraud_Detection_Analysis.ipynb` in Jupyter Notebook or Google Colab and run all cells

```bash
git clone https://github.com/Yaswanthtummala/fraud-detection-ml.git
cd fraud-detection-ml
pip install pandas numpy scikit-learn imbalanced-learn xgboost plotly jupyter
jupyter notebook Fraud_Detection_Analysis.ipynb
```

## 🛠️ Tech Stack

Python · SQL · pandas · NumPy · scikit-learn · imbalanced-learn (SMOTE) · XGBoost · Flask · Plotly

## 👤 Author

**Tummala Yaswanth Sai** · [LinkedIn](https://www.linkedin.com/in/tummala-yaswanth-sai-2131a1286) · [GitHub](https://github.com/Yaswanthtummala)
