import sys
import os

# Add the current directory to the python path so it can find the 'app' package
sys.path.insert(0, os.path.dirname(__file__))

from a2wsgi import ASGIMiddleware
from app.main import app

# Passenger looks for a variable named 'application'
application = ASGIMiddleware(app)
