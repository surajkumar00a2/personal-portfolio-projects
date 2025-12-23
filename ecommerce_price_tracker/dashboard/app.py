import streamlit as st
import pandas as pd
import psycopg2
from core.config import POSTGRES_CONFIG

st.set_page_config(page_title="Price Tracker", layout="wide")

@st.cache_data
def load_data():
    conn = psycopg2.connect(**POSTGRES_CONFIG)
    df = pd.read_sql("SELECT * FROM prices", conn)
    conn.close()
    return df

df = load_data()

st.title("🛒 E-Commerce Price Tracker")

st.metric("Total Products", df["product_id"].nunique())
st.metric("Sites Tracked", df["site"].nunique())

product = st.selectbox("Select Product", df["product_id"].unique())

filtered = df[df["product_id"] == product]

st.line_chart(filtered.set_index("scraped_at")["price"])
