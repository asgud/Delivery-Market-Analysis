# 🍕 Delivery Market Analysis

A SQL-based analysis of food delivery platform data, exploring restaurant distribution, pricing trends, and consumer insights.

## 📋 Project Overview

This project analyzes data from a food delivery platform (Takeaway.com) to answer key business questions about the market. The primary focus is on **SQL querying** with **Python** used for data visualization.

### Business Questions Answered

**Must-Have Analysis:**
1. What is the price distribution of menu items?
2. What is the distribution of restaurants per location?
3. Which are the top 10 pizza restaurants by rating?
4. Where can you find kapsalons and at what average price?

**Open-Ended Exploration:**
1. Which restaurants have the best price-to-rating ratio?
2. Where are the delivery "dead zones" with minimal coverage?
3. How does vegetarian/vegan availability vary by area?
4. World Hummus Order (WHO) — Top 3 hummus restaurants

---

## 🗄️ Database Schema

![ER Diagram](ER_schema_takeaway.png)

The database consists of 6 tables:
- `restaurants` — Core restaurant data (ratings, location, delivery info)
- `menuItems` — Menu items with prices and descriptions
- `locations` — Geographic locations with coordinates
- `locations_to_restaurants` — Links locations to restaurants
- `categories` — Restaurant category classifications
- `categories_restaurants` — Category mappings

---

## 🛠️ Tools & Technologies

| Tool | Purpose |
|------|---------|
| **SQLite** | Database management |
| **VS Code** | Code editor |
| **SQLite Viewer** | VS Code extension for database exploration |
| **Python** | Data visualization |
| **Pandas** | Data manipulation |
| **Matplotlib/Seaborn** | Static charts |
| **Folium** | Interactive maps |

---

## 📁 Repository Structure

```
DELIVERY-MARKET-ANALYSIS/
├── README.md                      # Project documentation
├── ER_schema_takeaway.png         # Database schema diagram
├── takeaway_analysis.sql          # All SQL queries (structured & documented)
├── takeaway_visualization.ipynb   # Python visualizations (Jupyter Notebook)
├── veg_map_clustered.html         # Interactive map output
├── requirements.txt               # Python dependencies
└── .gitignore                     # Ignored files
```

---

## 🚀 Getting Started

### Prerequisites
- Python 3.x
- SQLite3
- VS Code with SQLite Viewer extension (recommended)

### Installation

1. Clone the repository:
   ```bash
   git clone https://github.com/yourusername/DELIVERY-MARKET-ANALYSIS.git
   cd DELIVERY-MARKET-ANALYSIS
   ```

2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```

3. Open the SQL file in VS Code and use SQLite Viewer to explore the queries.

4. Run the Jupyter notebook for visualizations:
   ```bash
   jupyter notebook takeaway_visualization.ipynb
   ```

---

## 📊 Key Insights (STAR Method)

### Price Distribution Analysis

| STAR | Description |
|------|-------------|
| **Situation** | Needed to understand menu pricing strategy across the platform |
| **Task** | Analyze price distribution to identify market positioning |
| **Action** | Grouped menu items into price brackets (€0-5, €5-10, €10-15, €15-20, €20+) using SQL CASE statements |
| **Result** | Found majority of items priced €5-€15, indicating mid-range market focus with opportunities at budget/premium ends |

### Restaurant Distribution

| STAR | Description |
|------|-------------|
| **Situation** | Platform needed to understand geographic market coverage |
| **Task** | Map restaurant density across cities |
| **Action** | Joined locations and restaurants tables, aggregated counts by city |
| **Result** | Identified Antwerp as most saturated market; discovered underserved areas for potential expansion |

### World Hummus Order (WHO)

| STAR | Description |
|------|-------------|
| **Situation** | Wanted to identify top-quality restaurants for a specific cuisine |
| **Task** | Rank hummus-serving restaurants fairly |
| **Action** | Created weighted score formula: `Rating × log(Reviews + 1)` to balance quality with credibility |
| **Result** | Cairo One ranked #1 with score of 13.40 (4.8 rating, 619 reviews) |

### Vegetarian/Vegan Availability

| STAR | Description |
|------|-------------|
| **Situation** | Plant-based diets are growing; needed to assess platform readiness |
| **Task** | Map veg/vegan dish availability across locations |
| **Action** | Filtered menu items by keywords, visualized with Folium clustered markers |
| **Result** | Created interactive map showing veg/vegan distribution across all locations |

---

## 📝 SQL Techniques Used

- `CASE` statements for data categorization
- `JOIN` operations across multiple tables
- `GROUP BY` with aggregate functions
- `HAVING` clause for filtered aggregations
- Weighted scoring formulas with `LOG()`

---

## 👤 Author

Astha Gudgilla

---

## 📄 License

This project is for educational purposes.
