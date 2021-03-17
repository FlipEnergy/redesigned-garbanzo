from flask import Flask

app = Flask('garbonzo')


@app.route('/')
def ping():
    return "Pong!"
