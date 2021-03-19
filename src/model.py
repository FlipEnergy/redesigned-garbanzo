
from flask_sqlalchemy import SQLAlchemy

db = SQLAlchemy()

class Todo(db.Model):
    __tablename__ = 'todo'

    id = db.Column(db.Integer, primary_key=True)
    content = db.Column(db.String())

    def __repr__(self):
        return '<todo {}>'.format(self.id)
