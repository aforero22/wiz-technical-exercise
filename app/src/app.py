from flask import Flask, render_template, request, redirect, url_for
from pymongo import MongoClient
import os
import datetime

app = Flask(__name__)

# MongoDB connection
mongo_uri = os.environ.get('MONGODB_URI', 'mongodb://localhost:27017/wizdb')
client = MongoClient(mongo_uri)
db = client.wizdb
tasks = db.tasks

@app.route('/')
def index():
    all_tasks = list(tasks.find())
    return render_template('index.html', tasks=all_tasks)

@app.route('/add', methods=['POST'])
def add_task():
    task_name = request.form.get('task')
    if task_name:
        tasks.insert_one({
            'name': task_name,
            'created_at': datetime.datetime.now()
        })
    return redirect(url_for('index'))

@app.route('/delete/<task_id>')
def delete_task(task_id):
    tasks.delete_one({'_id': task_id})
    return redirect(url_for('index'))

if __name__ == '__main__':
    app.run(host='0.0.0.0', port=8080, debug=True)