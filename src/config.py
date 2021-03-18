from os import environ, getenv

class Config(object):
  POSTGRES_HOST = getenv('POSTGRES_HOST', 'postgresql')
  POSTGRES_DATABASE = getenv('POSTGRES_DATABASE', 'garbanzo')
  POSTGRES_USERNAME = environ['POSTGRES_USERNAME']
  POSTGRES_PASSWORD = environ['POSTGRES_USERNAME']
