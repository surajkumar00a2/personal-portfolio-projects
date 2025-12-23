# 🛒 Multi-Source E-Commerce Price Tracker

**Author:** Suraj Kumar  
[![Python](https://img.shields.io/badge/Python-3.8%2B-blue.svg)](https://www.python.org/)
[![PostgreSQL](https://img.shields.io/badge/PostgreSQL-13%2B-336791.svg)](https://www.postgresql.org/)
[![Streamlit](https://img.shields.io/badge/Streamlit-Dashboard-FF4B4B.svg)](https://streamlit.io/)

A portfolio-grade data engineering project that tracks product prices across multiple e-commerce platforms, stores historical price data, and enables automation, monitoring, and visualization.

The project focuses on **robust pipeline design**, **data modeling**, and **automation**, while handling real-world scraping challenges responsibly.

---

## 🚀 Project Overview

This system:
- Collects product price data from multiple e-commerce sources
- Stores historical price snapshots in PostgreSQL
- Supports automation via cron / GitHub Actions
- Includes monitoring, logging, and alerting
- Provides a Streamlit dashboard for analysis and visualization

---

## 🌐 Data Sources Strategy

| Platform | Approach | Reason |
|----------|----------|--------|
| **Amazon** | Simulated | Heavy anti-bot & ToS restrictions |
| **Flipkart** | Simulated | CAPTCHA & blocking |
| **Croma** | Real scraping + fallback | Mostly static HTML |
| **Reliance Digital** | Real scraping + fallback | Partially static |
| **Snapdeal** | Real scraping + fallback | Accessible HTML |

> ⚠️ **Why simulation?**  
> Major e-commerce platforms restrict scraping. For stability and compliance, Amazon and Flipkart are simulated, while real scraping is attempted for accessible platforms with graceful fallback.

---

## 🧱 Architecture

```
Scheduler (Cron / GitHub Actions)
           |
           v
Scrapers (Multi-Source)
           |
           v
Data Validation & Normalization
           |
           v
PostgreSQL (Historical Prices)
           |
           v
Streamlit Dashboard
```

---

## 🗂️ Project Structure

```
ecommerce_price_tracker/
├── scrapers/
│   ├── amazon_scraper.py         # simulated
│   ├── flipkart_scraper.py       # simulated
│   ├── croma_scraper.py          # real + fallback
│   ├── reliance_scraper.py       # real + fallback
│   ├── snapdeal_scraper.py       # real + fallback
│   └── simulated_scraper.py
│
├── core/
│   ├── config.py                 # configuration management
│   ├── db_manager.py             # database operations
│   ├── validator.py              # data validation
│   ├── alerts.py                 # email alerting
│   ├── logger.py                 # logging setup
│   └── product_catalog.py        # product definitions
│
├── scheduler/
│   └── main.py                   # pipeline orchestrator
│
├── dashboard/
│   └── app.py                    # Streamlit dashboard
│
├── sql/
│   └── schema.sql                # database schema
│
├── requirements.txt
└── README.md
```

---

## 🗄️ Database Schema

### `prices` table

| Column | Type | Description |
|--------|------|-------------|
| `id` | SERIAL | Primary key |
| `product_id` | TEXT | Deterministic product identifier |
| `site` | TEXT | Source website |
| `price` | NUMERIC | Product price |
| `rating` | NUMERIC | Product rating |
| `availability` | TEXT | Stock status |
| `scraped_at` | TIMESTAMP | Scrape timestamp |
| `url` | TEXT | Product URL |

---

## ⚙️ Setup Instructions

### Prerequisites
- Python 3.8+
- PostgreSQL 13+
- pip package manager

### 1️⃣ Create PostgreSQL Database

```bash
psql -U postgres
CREATE DATABASE price_tracker;
\q
```

### 2️⃣ Apply Schema

```bash
psql -U postgres -d price_tracker -f sql/schema.sql
```

### 3️⃣ Create Virtual Environment

```bash
python3 -m venv venv
source venv/bin/activate  # On Windows: venv\Scripts\activate
```

### 4️⃣ Install Dependencies

```bash
pip install -r requirements.txt
```

### 5️⃣ Configure Database & Alerts

Edit `core/config.py` or set environment variables:

```python
# Database Configuration
DB_HOST = "localhost"
DB_PORT = 5432
DB_NAME = "price_tracker"
DB_USER = "postgres"
DB_PASSWORD = "your_password"

# Email Alert Configuration (Optional)
SMTP_SERVER = "smtp.gmail.com"
SMTP_PORT = 587
EMAIL_SENDER = "your_email@gmail.com"
EMAIL_PASSWORD = "your_app_password"
EMAIL_RECIPIENT = "recipient@email.com"
```

---

## ▶️ Run the Pipeline

From project root:

```bash
python -m scheduler.main
```

**Expected Output:**
- Logs for each scraper
- Rows inserted into PostgreSQL
- Email alert if failures occur

---

## ⏱️ Automation Options

### Option 1: Cron (Local)

```bash
# Edit crontab
crontab -e

# Add line to run daily at 8 AM
0 8 * * * cd /path/to/ecommerce_price_tracker && /path/to/venv/bin/python -m scheduler.main
```

### Option 2: GitHub Actions

Create `.github/workflows/scrape_prices.yml`:

```yaml
name: Price Scraper

on:
  schedule:
    - cron: '0 8 * * *'  # Daily at 8 AM UTC
  workflow_dispatch:

jobs:
  scrape:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-python@v4
        with:
          python-version: '3.9'
      - run: pip install -r requirements.txt
      - run: python -m scheduler.main
        env:
          DB_HOST: ${{ secrets.DB_HOST }}
          DB_PASSWORD: ${{ secrets.DB_PASSWORD }}
```

**Benefits:**
- Daily scheduled workflow
- Secrets stored securely
- Automated failure notifications

---

## 📊 Streamlit Dashboard

### Run Locally

```bash
streamlit run dashboard/app.py
```

### Features

- **Product Search**: Filter by product name or ID
- **Price History Trends**: Visualize price changes over time
- **Site-wise Comparison**: Compare prices across platforms
- **Deal Detection**: Highlight price drops >15%
- **Analytics**: Average prices, trend analysis, best deals

---

## 🧪 Data Validation & Monitoring

- ✅ Row count checks per scraping run
- ✅ Per-site ingestion metrics
- ✅ Deterministic `product_id` generation
- ✅ Graceful fallback on scraper failures
- ✅ Email alerts for pipeline failures
- ✅ Duplicate detection and handling

---

## 🧠 Design Highlights

- **Modular Architecture**: Easily add new scrapers
- **Time-Series Tracking**: Historical price analysis
- **Automation-Ready**: Cron and GitHub Actions support
- **Realistic Constraints**: Handles scraping limitations responsibly
- **Production-Quality**: Logging, monitoring, and error handling
- **Portfolio-Ready**: Clean code and comprehensive documentation

---

## 🔮 Future Enhancements

- [ ] Async scraping with `aiohttp` for better performance
- [ ] Advanced product matching algorithms
- [ ] Real-time deal alert notifications
- [ ] Streamlit Cloud deployment
- [ ] Data quality monitoring dashboard
- [ ] GitHub Actions status badges
- [ ] Price prediction using ML models
- [ ] Mobile app notifications
- [ ] Export data to CSV/Excel

---

## 🛠️ Technologies Used

- **Python 3.8+**: Core language
- **PostgreSQL**: Time-series data storage
- **BeautifulSoup4**: HTML parsing
- **Requests**: HTTP requests
- **Pandas**: Data manipulation
- **Streamlit**: Interactive dashboard
- **SMTP**: Email notifications
- **GitHub Actions**: CI/CD automation

---

## 📈 Sample Queries

```sql
-- Get latest prices for a product
SELECT site, price, scraped_at 
FROM prices 
WHERE product_id = 'laptop_dell_xps_13' 
ORDER BY scraped_at DESC 
LIMIT 5;

-- Find best deals (>15% price drop)
WITH latest AS (
  SELECT DISTINCT ON (product_id, site) *
  FROM prices 
  ORDER BY product_id, site, scraped_at DESC
),
previous AS (
  SELECT DISTINCT ON (product_id, site) *
  FROM prices 
  WHERE scraped_at < NOW() - INTERVAL '7 days'
  ORDER BY product_id, site, scraped_at DESC
)
SELECT l.product_id, l.site, 
       p.price as old_price, l.price as new_price,
       ROUND(((p.price - l.price) / p.price * 100)::numeric, 2) as discount_pct
FROM latest l
JOIN previous p ON l.product_id = p.product_id AND l.site = p.site
WHERE (p.price - l.price) / p.price > 0.15
ORDER BY discount_pct DESC;
```

---

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📜 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙌 Acknowledgements

Built as part of a personal data engineering portfolio to demonstrate real-world pipeline design, automation, and analytics.

## 👤 Author

**Suraj Kumar**
- **Role:** Analytics Engineer | Data Engineering
- **GitHub:** [@surajkumar00a2](https://github.com/surajkumar00a2)
- **LinkedIn:** [Suraj Kumar](https://linkedin.com/in/suraj-kumar-0700ba193)
- **Email:** surajkumar00a2@gmail.com

---

## 📞 Support

If you encounter any issues or have questions, please open an issue on GitHub.

**Happy Price Tracking! 🎯**
