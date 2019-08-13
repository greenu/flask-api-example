from flask_api import db

class User(db.Model):
    id = db.Column(db.Integer, primary_key=True)
    username = db.Column(db.String(64), index=True, unique=True)
    dateOfBirth = db.Column(db.Date)

    def __repr__(self):
        return '<User {}>'.format(self.username)
