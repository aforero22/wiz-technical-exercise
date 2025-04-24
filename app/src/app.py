from flask import Flask, jsonify
from config.config import MONGO_URI
from pymongo import MongoClient

app = Flask(__name__)
client = MongoClient(MONGO_URI)
db = client.get_default_database()

@app.route('/')
def home():
    count = db.test_collection.count_documents({})
    return jsonify(message="Hola desde Wiz App!", documents=count)

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=80)