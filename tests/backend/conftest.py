import os
import pytest

from backend.extensions import db
from backend.app import create_app


@pytest.fixture(scope="session")
def app():
    os.environ["DATABASE_URL"] = "sqlite:///:memory:"
    application = create_app()
    application.config.update({
        "TESTING": True,
    })
    with application.app_context():
        db.create_all()
    yield application
    with application.app_context():
        db.drop_all()


@pytest.fixture()
def client(app):
    return app.test_client()
