import os
from setuptools import setup
try: # pip >= v10.x
    from pip._internal.req import parse_requirements
    from pip._internal.download import PipSession
except ImportError:
    from pip.req import parse_requirements
    from pip.download import PipSession

from flask_api.version import __version__

# Ref: http://alexanderwaldin.github.io/packaging-python-project.html
def read_requirements():
    '''parses requirements from requirements.txt'''
    reqs_path = os.path.join(os.getcwd(), 'requirements.txt')
    install_reqs = parse_requirements(reqs_path, session=PipSession())
    reqs = [str(ir.req) for ir in install_reqs]
    return reqs

# Ref: http://alexanderwaldin.github.io/packaging-python-project.html
def read_test_requirements():
    '''parses requirements from test_requirements.txt'''
    reqs_path = os.path.join(os.getcwd(), 'test_requirements.txt')
    install_reqs = parse_requirements(reqs_path, session=PipSession())
    reqs = [str(ir.req) for ir in install_reqs]
    return reqs

## TODO: enable bdist_wheel
setup(
    name='flask_api_demo',
    version=__version__,
    packages=['flask_api'],
    include_package_data=True,
    test_suite='tests.Run.run',
    install_requires=read_requirements(),
    tests_require=read_test_requirements()
)