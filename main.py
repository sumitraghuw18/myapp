import logging
from flask import Flask, render_template, request, redirect, url_for
from prometheus_flask_exporter import PrometheusMetrics
import sqlite3
from datetime import datetime

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s [%(levelname)s] %(message)s',
    handlers=[logging.StreamHandler()]  # Console only
)

logger = logging.getLogger(__name__)

app = Flask(__name__)

# Initialize Prometheus metrics
metrics = PrometheusMetrics(app)

# Static info metric
metrics.info('app_info', 'Application info', version='1.0.0')

# Initialize SQLite database
def init_db():
    try:
        conn = sqlite3.connect('tasks.db')
        c = conn.cursor()
        c.execute('''CREATE TABLE IF NOT EXISTS tasks
                     (id INTEGER PRIMARY KEY AUTOINCREMENT, task TEXT NOT NULL)''')
        conn.commit()
        conn.close()
        logger.info("Database initialized successfully")
    except Exception as e:
        logger.error(f"Failed to initialize database: {str(e)}")
        raise


@app.route('/health')
def health():
    return "OK", 200

# Home route to display tasks
@app.route('/')
def index():
    start_time = datetime.now()
    logger.info(f"Handling GET request to / from {request.remote_addr}")
    try:
        conn = sqlite3.connect('tasks.db')
        c = conn.cursor()
        c.execute('SELECT * FROM tasks')
        tasks = c.fetchall()
        conn.close()
        logger.info(f"Retrieved {len(tasks)} tasks from database")
        response = render_template('index.html', tasks=tasks)
        logger.info(f"Request to / completed in {(datetime.now() - start_time).total_seconds()} seconds")
        return response
    except Exception as e:
        logger.error(f"Error in index route: {str(e)}")
        return "Internal Server Error", 500

# Route to add a task
@app.route('/add', methods=['POST'])
def add_task():
    start_time = datetime.now()
    task = request.form.get('task')
    logger.info(f"Handling POST request to /add from {request.remote_addr} with task: {task}")
    try:
        if not task:
            logger.warning("Task input is empty")
            return "Task cannot be empty", 400
        conn = sqlite3.connect('tasks.db')
        c = conn.cursor()
        c.execute('INSERT INTO tasks (task) VALUES (?)', (task,))
        conn.commit()
        conn.close()
        logger.info(f"Task '{task}' added successfully")
        logger.info(f"Request to /add completed in {(datetime.now() - start_time).total_seconds()} seconds")
        return redirect(url_for('index'))
    except Exception as e:
        logger.error(f"Error adding task: {str(e)}")
        return "Internal Server Error", 500

# Route to delete a task
@app.route('/delete/<int:id>')
def delete_task(id):
    start_time = datetime.now()
    logger.info(f"Handling GET request to /delete/{id} from {request.remote_addr}")
    try:
        conn = sqlite3.connect('tasks.db')
        c = conn.cursor()
        c.execute('DELETE FROM tasks WHERE id = ?', (id,))
        if c.rowcount == 0:
            logger.warning(f"No task found with id {id}")
            return "Task not found", 404
        conn.commit()
        conn.close()
        logger.info(f"Task with id {id} deleted successfully")
        logger.info(f"Request to /delete/{id} completed in {(datetime.now() - start_time).total_seconds()} seconds")
        return redirect(url_for('index'))
    except Exception as e:
        logger.error(f"Error deleting task with id {id}: {str(e)}")
        return "Internal Server Error", 500

if __name__ == '__main__':
    logger.info("Starting Flask application")
    init_db()
    app.run(host='0.0.0.0', port=5000)