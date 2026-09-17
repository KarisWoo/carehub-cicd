FROM python:3.12.4-slim

RUN apt-get update \
    && apt-get upgrade -y \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

ENV PYTHONDONTWRITEBYTECODE=1 \
    PYTHONUNBUFFERED=1

RUN groupadd --system carehub \
    && useradd --system --gid carehub --create-home carehub

WORKDIR /app

COPY app/requirements.txt ./requirements.txt


RUN python -m pip install --no-cache-dir --upgrade \
    "setuptools>=78.1.1" \
    "wheel>=0.46.2" \
    "jaraco.context>=6.1.0"


RUN pip install --no-cache-dir -r requirements.txt

COPY app/ ./app/

USER carehub

EXPOSE 8000

HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD python -c "import urllib.request; urllib.request.urlopen('http://127.0.0.1:8000/health', timeout=2)"

CMD ["gunicorn", "--bind", "0.0.0.0:8000", "--workers", "2", "app.app:app"]