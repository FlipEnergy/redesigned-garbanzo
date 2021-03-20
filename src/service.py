from model import Todo

class TodoService(object):
    def __init__(self, db):
        self.db_session = db.session

    def get_list(self):
        '''Returns a list of todo contents'''
        return [item[0] for item in Todo.query.with_entities(Todo.content)]
    
    def add_item(self, content):
        '''Adds a new Todo item with content'''
        new_todo = Todo(content=content)
        self.db_session.add(new_todo)
        self.db_session.commit()
