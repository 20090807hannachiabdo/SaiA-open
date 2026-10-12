from flask import Flask, render_template, redirect
import os
current_dir = os.path.dirname(os.path.abspath(os.path.abspath(__file__)))
base_dir = os.path.dirname(current_dir)
templates_dir = os.path.join(base_dir, 'ui', 'templates')
static_dir = os.path.join(base_dir, 'ui', 'static')

app = Flask(__name__, template_folder=templates_dir, static_folder=static_dir)

@app.route('/')
def index():
    return render_template('index.html')
def run_web_server():
    app.run( port=5000, debug=False, use_reloader=False)