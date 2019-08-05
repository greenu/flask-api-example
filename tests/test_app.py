import unittest
from unittest.mock import patch
from datetime import datetime

from flask_api.app import app, _days_to_birthday

# https://williambert.online/2011/07/how-to-unit-testing-in-django-with-mocking-and-patching/
class FakeDatetime(datetime):
	""" A fake replacement for datetime that can be mocked for testing."""
	def __new__(cls, *args, **kwargs):
		return datetime.__new__(datetime, *args, **kwargs)


class AppGoodTestCase(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()
        self.app = app.test_client()

    @patch('flask_api.app._days_to_birthday', return_value = 363)
    def test_get(self, days):
        """ test get when 363 days to birthday """
        username = 'user'
        self.app.put(f'/hello/{username}', json={'dateOfBirth': '2019-07-31'})
        rv = self.app.get(f'/hello/{username}')
        json_data = rv.get_json()
        self.assertEqual(f'Hello, {username}! Your birtday is in 363 day(s)', json_data['message'])

    @patch('flask_api.app._days_to_birthday', return_value = 0)
    def test_get_birthday(self, days):
        """ test get on birthday"""
        username = 'user'
        self.app.put(f'/hello/{username}', json={'dateOfBirth': '2019-07-31'})
        rv = self.app.get(f'/hello/{username}')
        json_data = rv.get_json()
        self.assertEqual(f'Hello, {username}! Happy birthday!', json_data['message'])
    
    def test_put(self):
        """ test get """
        username = 'user'
        rv = self.app.put(f'/hello/{username}', json={'dateOfBirth': '2019-07-31'})
        self.assertEqual(204, rv.status_code)

class AppBadTestCase(unittest.TestCase):

    def setUp(self):
        self.app = app.test_client()

    @unittest.skip
    def test_put_bad_date(self):
        """ test put bad date """
        username = 'user'
        rv = self.app.put(f'/hello/{username}', json={'dateOfBirth': '9999-99-99'})
        self.assertEqual(400, rv.status_code)

    @unittest.skip    
    def test_put_bad_username(self):
        """ test username must contain only letters """
        username = 'user111'
        rv = self.app.put(f'/hello/{username}', json={'dateOfBirth': '2019-07-31'})
        self.assertEqual(400, rv.status_code)

class DaysToBirthdayTestCase(unittest.TestCase):
    def setUp(self):
        self.user_date = '2000-03-01'

    @patch('flask_api.app.datetime', FakeDatetime)
    def test_days_to_birthday_yesterday(self):
        """ test days to birthday """
        today_date = datetime(2018, 3, 2)
        FakeDatetime.now = classmethod(lambda cls: today_date)
        result = _days_to_birthday(self.user_date)
        self.assertEqual(result, 364)
    
    @patch('flask_api.app.datetime', FakeDatetime)
    def test_days_to_birthday_today(self):
        """ test days to birthday today """
        today_date = datetime(2018, 3, 1)
        FakeDatetime.now = classmethod(lambda cls: today_date)
        result = _days_to_birthday(self.user_date)
        self.assertEqual(result, 0)

    @patch('flask_api.app.datetime', FakeDatetime)
    def test_days_to_birthday_leapyear(self):
        """ test days to birthday work correctly in 2020 leap year """
        today_date = datetime(2019, 3, 2)
        FakeDatetime.now = classmethod(lambda cls: today_date)
        result = _days_to_birthday(self.user_date)
        self.assertEqual(result, 365)