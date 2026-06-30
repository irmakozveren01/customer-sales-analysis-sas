# Customer Sales Analysis in SAS

This project demonstrates customer-level data integration, transformation, and statistical reporting using **SAS**. Data from multiple sources are merged into a single analytical dataset, followed by feature engineering, summary reporting, and inferential statistical analysis.

The project focuses on building a reproducible reporting workflow and generating a PDF report containing descriptive statistics, customer-level purchase summaries, and hypothesis testing results.

## Project Objectives

- Merge customer information from multiple datasets.
- Create an integrated customer-level analytical dataset.
- Engineer new variables for customer segmentation and purchase analysis.
- Generate descriptive summary statistics.
- Produce customer-level purchase summaries.
- Investigate the relationship between customer country and expenditure category.
- Generate frequency tables for reporting.

## Data Sources

The analysis combines information from three datasets:

- `Customer`
- `Customer_dim`
- `Customer_orders`

Only customers with recorded purchases are retained in the final analytical dataset.

## Data Processing

The workflow includes:

- Dataset sorting using a reusable SAS macro.
- Data merging across multiple tables.
- Creation of derived variables
- Currency formatting for expenditure variables.
- Preparation of customer-level summary tables.

## Statistical Analysis

The project includes:

- Summary statistics (mean, standard deviation, minimum, and maximum) of retail prices by country.
- Customer-level aggregation of:
  - ordered quantities,
  - number of orders,
  - total expenditure.
- Chi-square analysis to investigate the association between customer country and expenditure range.
- Fisher's Exact Test as an alternative when expected frequencies are insufficient.
- Absolute and relative frequency tables by Country and Supplier.

## Technologies

- SAS
- SAS Macros
- Data Integration
- Data Wrangling
- Statistical Reporting
- Descriptive Statistics
- Chi-Square Test
- Fisher's Exact Test

## Output

The SAS program generates a PDF report containing:

- Summary statistics by country
- Customer purchase summaries
- Statistical test results
- Frequency tables

## Author

**Irmak Özveren**  
**Halit Kaan Kesgin**  
**Tatyana Li**  
**Margherita Fagan**  
