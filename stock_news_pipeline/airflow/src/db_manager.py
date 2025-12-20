import psycopg2
from psycopg2.extras import execute_batch
from src.config import POSTGRES_CONFIG
from src.logger import get_logger

logger = get_logger(__name__)

def get_connection():
    return psycopg2.connect(**POSTGRES_CONFIG)

def insert_dataframe(df, table_name):
    if df.empty:
        logger.warning(f"No data to insert into {table_name}")
        return

    conn = get_connection()
    cur = conn.cursor()

    columns = list(df.columns)
    values = [tuple(row) for row in df.to_numpy()]

    insert_sql = f"""
        INSERT INTO {table_name} ({','.join(columns)})
        VALUES ({','.join(['%s'] * len(columns))})
    """

    try:
        execute_batch(cur, insert_sql, values, page_size=500)
        conn.commit()
        logger.info(f"Inserted {len(df)} rows into {table_name}")
    except Exception as e:
        conn.rollback()
        logger.error(f"Insert failed for {table_name}: {e}")
        raise
    finally:
        cur.close()
        conn.close()
