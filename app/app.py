import os
import time
from flask import Flask, jsonify
import psycopg2

app = Flask(__name__)
APP_ENV = os.getenv('APP_ENV', 'dev')
DB_HOST = os.getenv('DB_HOST', 'db')
DB_NAME = os.getenv('POSTGRES_DB', 'carehub')
DB_USER = os.getenv('POSTGRES_USER', 'carehub')
DB_PASSWORD = os.getenv('POSTGRES_PASSWORD', '')


def db_ok():
    try:
        conn = psycopg2.connect(host=DB_HOST, dbname=DB_NAME, user=DB_USER, password=DB_PASSWORD, connect_timeout=2)
        cur = conn.cursor()
        cur.execute('SELECT 1')
        cur.close()
        conn.close()
        return True
    except Exception:
        return False


@app.get('/')
def index():
    return jsonify(application='CareHub rendez-vous', environment=APP_ENV, status='ok')


@app.get('/health')
def health():
    ok = db_ok()
    return jsonify(status='healthy' if ok else 'degraded', database=ok), (200 if ok else 503)


@app.get('/ready')
def ready():
    for _ in range(3):
        if db_ok():
            return jsonify(status='ready'), 200
        time.sleep(1)
    return jsonify(status='not-ready'), 503


if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8000)
