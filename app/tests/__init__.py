import os
import shutil
import unittest
import xmlrunner

class Run(unittest.TestCase):
    def run(self, suite):
        if os.path.isdir('test-reports'):
            shutil.rmtree('test-reports')
        tests = unittest.TestLoader().discover('tests')
        xmlrunner.XMLTestRunner(output='test-reports').run(tests)
