import os
from datetime import datetime

from flask import Flask, request
from flask_restful import Resource, Api
from sqlalchemy.exc import IntegrityError

from flask_api import db
from flask_api.config import config_by_name
from flask_api.models import User

app = Flask(__name__)
config_name = os.getenv('FLASK_ENV') or 'development'
app.config.from_object(config_by_name[config_name])
db.init_app(app)

# create tables. TODO: refactor me
with app.app_context():
    db.create_all()

api = Api(app)

class Hello(Resource):
    def get(self, username):
        user = User.query.filter_by(username=username).first()
        if user is None:
            return ({'status': 404, 'message': 'Username not found'}, 404)
        days = _days_to_birthday(user.dateOfBirth)
        if days == 0:
            bd_string = 'Happy birthday!'
        else:
            bd_string = f'Your birtday is in {days} day(s)'
        resp = {'message': f'Hello, {username}! {bd_string}'}
        return resp

    def put(self, username):
        # <username> only letters
        # expected data: { "dateOfBirth": "YYYY-MM-DD" }
        # force=True means don't expect 'application/json'

        if not str.isalpha(username):
            return ({'status': 400, 'message': 'Invalid username'}, 400)

        # validate key and value
        try:
            json_content = request.get_json(force=False)
            _validate_date(json_content['dateOfBirth'])
        except:
            return ({'status': 400, 'message': 'Invalid data provided'}, 400)
        ## TODO add birthday update
        try:
            u = User(username=username, dateOfBirth=json_content['dateOfBirth'])
            db.session.add(u)
            db.session.commit()
        except IntegrityError:
            return ({'status': 409, 'message': 'Username already exists'}, 409)
        return ('', 204)

api.add_resource(Hello, '/hello/<string:username>')

def _validate_date(date: str) -> bool:
    try:
        datetime.strptime(date, '%Y-%m-%d')
    except ValueError:
        raise

def _days_to_birthday(original_date: datetime.date) -> int:
    """ Returns days left to birthday """
    now = datetime.now()
    date_this_year = datetime(now.year, original_date.month, original_date.day)
    date_next_year = datetime(now.year+1, original_date.month, original_date.day)
    if date_this_year.date() < now.date():
        next_bd = date_next_year
    else:
        next_bd = date_this_year
    days_left = next_bd.date() - now.date()
    return days_left.days
