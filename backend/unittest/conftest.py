import pytest
from unittest.mock import AsyncMock, MagicMock

@pytest.fixture
def mock_user():
    class MockUser:
        def __init__(self):
            self.id = "60d5ec49f1b2c8b1f8e4e1a1"
            self.username = "testuser"
            self.display_name = "Test User"
            self.email = "test@test.com"
            self.is_verified = True
            self.roles = []
            self.hashed_password = "hashed_mock"
            from datetime import datetime
            self.created_at = datetime.now()
            self.updated_at = datetime.now()
    return MockUser()

@pytest.fixture
def mock_logger(mocker):
    # Mock the central logger
    return mocker.patch("app.core.logger.logger", new_callable=AsyncMock)
