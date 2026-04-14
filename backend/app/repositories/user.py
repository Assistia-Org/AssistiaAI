from beanie import PydanticObjectId
from backend.app.models.user import User
from backend.app.schemas.user import UserUpdate


async def create_user(data: dict) -> User:
    """Create a new user in the database."""
    user = User(**data)
    return await user.insert()


async def get_user_by_id(user_id: str) -> User | None:
    """Retrieve a user by its ID."""
    return await User.get(PydanticObjectId(user_id))


async def get_user_by_email(email: str) -> User | None:
    """Retrieve a user by its email."""
    return await User.find_one(User.email == email)


async def list_users() -> list[User]:
    """List all users."""
    return await User.find_all().to_list()


async def update_user(user: User, data: UserUpdate) -> User:
    """Update a user's fields."""
    update_data = data.model_dump(exclude_unset=True)
    if "password" in update_data:
        # Note: Password hashing should be handled in service layer
        # But for repository, we just map what we get.
        pass
    for key, value in update_data.items():
        setattr(user, key, value)
    return await user.save()


async def delete_user(user: User) -> None:
    """Delete a user."""
    await user.delete()
