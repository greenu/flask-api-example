from datetime import datetime

from flask import Flask, request
from flask_restful import Resource, Api

app = Flask(__name__)
api = Api(app)

# users "db"
users = {}

class Hello(Resource):
    def get(self, username):
        userdata = users.get(username)
        bd = userdata.get('dateOfBirth')
        days = _days_to_birthday(bd)
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
        json_content = request.get_json(force=False)
        users[username] = json_content
        return '', 204

api.add_resource(Hello, '/hello/<string:username>')

def _days_to_birthday(date: str) -> int:
    """ Returns days left to birthday """
    now = datetime.now()
    original_date = datetime.strptime(date, '%Y-%m-%d')
    date_this_year = datetime(now.year, original_date.month, original_date.day)
    date_next_year = datetime(now.year+1, original_date.month, original_date.day)
    if date_this_year.date() < now.date():
        next_bd = date_next_year
    else:
        next_bd = date_this_year
    days_left = next_bd.date() - now.date()
    return days_left.days


# @app.route('/hello')
# def hello_world():
#     return 'Hello, World!'

# ### saves/updates users
# ### PUT /hello/<username> { "dateOfBirth": "YYYY-MM-DD" }
# ### 204 No content
# ### <username> only letters
# ### YYYY-MM-DD date must be before today
# @app.route('/hello/<username>', methods=['GET', 'PUT'])
# def user(username):
#     if request.method == 'PUT':
#         #returns the username
#         a = json.loads(request.form)
#         return a
#     if request.method == 'GET':
#         # users = get_all_users()
#         # return jsonify([user.to_json() for user in users])
#         return request.form


# def get_all_users():
#     return users
# # @app.route("/users")
# # def users_api():
#     # users = get_all_users()
#     # return jsonify([user.to_json() for user in users])


if __name__ == '__main__':
    app.run(debug=True)