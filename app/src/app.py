"""
Aplicación web de gestión de tareas con vulnerabilidades intencionales para demostración de Wiz.
Esta aplicación implementa una lista de tareas simple con MongoDB como base de datos.

VULNERABILIDADES INTENCIONALES:
1. Conexión insegura a MongoDB sin autenticación ni TLS
2. No hay validación de entrada de datos (permite inyección NoSQL)
3. Debug mode activado en producción (expone información sensible)
4. No hay protección contra ataques CSRF
5. No hay manejo de errores adecuado
6. Los IDs de MongoDB se exponen directamente en las URLs
7. No hay sanitización de la salida de datos (XSS potencial)

Esta aplicación está diseñada específicamente para demostrar vulnerabilidades
que pueden ser detectadas por herramientas de seguridad CSP como Wiz.
"""

from flask import Flask, render_template, request, redirect, url_for
from pymongo import MongoClient
import os
import datetime

# Inicialización de la aplicación Flask
app = Flask(__name__)

# Configuración de la conexión a MongoDB
# VULNERABILIDAD: Conexión sin autenticación, sin TLS y sin validación de certificados
# En un entorno de producción, debería usar una conexión segura con autenticación
mongo_uri = os.environ.get('MONGODB_URI', 'mongodb://localhost:27017/wizdb')
client = MongoClient(mongo_uri)
db = client.wizdb
tasks = db.tasks

@app.route('/')
def index():
    """
    Ruta principal que muestra todas las tareas.
    
    VULNERABILIDADES:
    1. No hay paginación ni límite de resultados (DoS potencial)
    2. No hay sanitización de la salida de datos (XSS potencial)
    3. No hay control de acceso (cualquiera puede ver todas las tareas)
    """
    all_tasks = list(tasks.find())
    return render_template('index.html', tasks=all_tasks)

@app.route('/add', methods=['POST'])
def add_task():
    """
    Ruta para añadir una nueva tarea.
    
    VULNERABILIDADES:
    1. No hay validación de entrada ni sanitización
    2. No hay protección CSRF
    3. No hay control de acceso (cualquiera puede añadir tareas)
    4. No hay límite de tamaño para las tareas
    """
    task_name = request.form.get('task')
    if task_name:
        tasks.insert_one({
            'name': task_name,
            'created_at': datetime.datetime.now()
        })
    return redirect(url_for('index'))

@app.route('/delete/<task_id>')
def delete_task(task_id):
    """
    Ruta para eliminar una tarea.
    
    VULNERABILIDADES:
    1. No hay validación del ID (inyección NoSQL potencial)
    2. No hay control de acceso (cualquiera puede eliminar cualquier tarea)
    3. No hay confirmación antes de eliminar
    4. No hay manejo de errores si la tarea no existe
    5. Método GET para operación de modificación (no idempotente)
    """
    tasks.delete_one({'_id': task_id})
    return redirect(url_for('index'))

if __name__ == '__main__':
    # VULNERABILIDAD: Debug mode activado en producción
    # Esto expone información sensible y permite ejecución remota de código
    app.run(host='0.0.0.0', port=8080, debug=True)