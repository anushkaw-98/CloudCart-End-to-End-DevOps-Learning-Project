from app import app

def test_home_returns_cloudcart():
    client = app.test_client()
    response = client.get("/")
    assert response.status_code == 200
    assert response.get_json()["application"] == "CloudCart"

def test_health():
    response = app.test_client().get("/health")
    assert response.status_code == 200
    assert response.get_json()["status"] == "healthy"

def test_ready():
    assert app.test_client().get("/ready").status_code == 200
