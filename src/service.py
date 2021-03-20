from retrying import retry
from sqlalchemy.exc import SQLAlchemyError

from model import Todo

class TodoService(object):
    def __init__(self, db):
        self.db_session = db.session

    @retry(stop_max_attempt_number=3, wait_random_max=500)
    def get_list(self):
        '''Returns a list of todo contents'''
        return [item[0] for item in Todo.query.with_entities(Todo.content)]
    
    @retry(stop_max_attempt_number=3, wait_random_max=500)
    def add_item(self, content):
        '''Adds a new Todo item with content'''
        try:
            self.db_session.add(Todo(content=content))
            self.db_session.commit()
        except SQLAlchemyError:
            self.db_session.rollback()
            raise
