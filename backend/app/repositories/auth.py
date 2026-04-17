from app.models.user import User

async def get_user_by_email(email: str) -> User | None:
    """Find a user by email for authentication purposes."""
    return await User.find_one(User.email == email)
