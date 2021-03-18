from flask import Flask

from config import Config

app = Flask('garbanzo')
app.config.from_object(Config)


@app.route('/')
def ping():
    return "Pong!"


@app.route('/health')
def health():
    return {}
