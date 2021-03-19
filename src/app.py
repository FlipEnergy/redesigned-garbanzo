from flask import Flask
from flask_migrate import Migrate

from json import dumps

from config import Config
from model import db
from service import TodoService

app = Flask('garbanzo')
app.config.from_object(Config)
db.init_app(app)
migrate = Migrate(app, db)

app.todo_service = TodoService(db)


@app.route('/')
def get_list():
    return dumps(app.todo_service.get_list())

@app.route('/add', methods=['POST'])
def add_item():
    content = request.form['content'].strip()
    if not content:
        flash('Please type something in!')
    app.todo_service.add_item(content)
    app.logger.info('New task added: {}'.format(content))
    return {}

@app.route('/health')
def health():
    return {}
