SITES = ["amazon", "flipkart", "croma", "reliance", "snapdeal"]

CATEGORIES = ["Electronics", "Fashion", "Books", "Home & Kitchen"]

REQUEST_DELAY = 2

POSTGRES_CONFIG = {
    "host": "localhost",
    "database": "price_tracker",
    "user": "postgres",
    "password": "postgres",
    "port": 5432
}
EMAIL_ALERTS = {
    "enabled": True,
    "smtp_server": "smtp.gmail.com",
    "smtp_port": 587,
    "sender": "your_email@gmail.com",
    "receiver": "surajkumar00a2@gmail.com",
    "password": "sk@987654321"
}

