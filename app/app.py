from flask import Flask, jsonify

app = Flask(__name__)

@app.get("/")
def home():
    return jsonify(application="CloudCart", message="CloudCart API is running!", version="1.0.0")

@app.get("/health")
def health():
    return jsonify(status="healthy"), 200

@app.get("/ready")
def ready():
    # Add dependency checks (database, cache) here when those services are introduced.
    return jsonify(status="ready"), 200
