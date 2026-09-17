import os
os.environ['POSTGRES_PASSWORD'] = 'test-only'
from app.app import app


def test_index():
    client = app.test_client()
    response = client.get('/')
    assert response.status_code == 200
    data = response.get_json()
    assert data['application'] == 'CareHub rendez-vous'
