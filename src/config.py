from os import environ, getenv

class Config(object):
    SQLALCHEMY_DATABASE_URI = 'postgresql://{}:{}@{}/{}'.format(environ['POSTGRES_USERNAME'],
                                                                environ['POSTGRES_PASSWORD'],
                                                                getenv('POSTGRES_HOST', 'postgresql'),
                                                                getenv('POSTGRES_DATABASE', 'garbanzo'))
