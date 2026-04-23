from typing import List, Optional
from app.models.user import User, CommunityRoleModel, PersonalSettingsModel

async def create_user(user_data: dict) -> User:
    """Create a new user and return the inserted document."""
    user = User(**user_data)
    return await user.insert()

async def get_user_by_id(user_id: str) -> Optional[User]:
    """Return user by ID or None if not found."""
    return await User.find_one(User.id == user_id)

async def get_user_by_email(email: str) -> Optional[User]:
    """Return user by email or None if not found."""
    return await User.find_one(User.email == email)

async def get_user_by_username(username: str) -> Optional[User]:
    """Return user by username or None if not found."""
    return await User.find_one(User.username == username)

async def get_user_by_reset_token(token: str) -> Optional[User]:
    """Return user by reset token or None if not found."""
    return await User.find_one(User.reset_token == token)

async def list_users() -> List[User]:
    """Return all users."""
    return await User.find_all().to_list()

async def add_community_role(user_id: str, role_data: CommunityRoleModel) -> bool:
    """Add a community role to a user's joined_communities list."""
    user = await get_user_by_id(user_id)
    if not user:
        return False
    user.joined_communities.append(role_data)
    await user.save()
    return True

async def remove_community_role(user_id: str, community_id: str) -> bool:
    """Remove a community role from a user."""
    user = await get_user_by_id(user_id)
    if not user:
        return False
    user.joined_communities = [c for c in user.joined_communities if c.community_id != community_id]
    await user.save()
    return True

async def update_community_role(user_id: str, community_id: str, new_role: str) -> bool:
    """Update role for a specific community for a user."""
    user = await get_user_by_id(user_id)
    if not user:
        return False
    for c in user.joined_communities:
        if c.community_id == community_id:
            c.role = new_role
            break
    await user.save()
    return True

async def update_personal_settings(user_id: str, settings: PersonalSettingsModel) -> bool:
    """Update user's personal settings."""
    user = await get_user_by_id(user_id)
    if not user:
        return False
    user.personal_settings = settings
    await user.save()
    return True

async def update_avatar(user_id: str, avatar_url: Optional[str]) -> bool:
    """Update user's avatar URL."""
    user = await get_user_by_id(user_id)
    if not user:
        return False
    user.avatar_url = avatar_url
    await user.save()
    return True

async def update_user(user: User, data: dict) -> User:
    """Update user document with provided data."""
    
    for key, value in data.items():
        if hasattr(user, key):
            current_attr = getattr(user, key)
            
            # Eğer güncellenen alan bir Pydantic alt modeliyse (personal_settings gibi)
            if isinstance(current_attr, BaseModel) and isinstance(value, dict):
                # Mevcut ayarları koruyarak sadece gelen kısımları güncelle
                updated_sub_model = current_attr.model_copy(update=value)
                setattr(user, key, updated_sub_model)
            else:
                # Normal alanları (username, display_name vb.) direkt set et
                setattr(user, key, value)
    
    # Beanie burada nesnedeki tüm değişiklikleri DB'ye yazar
    return await user.save()

async def delete_user(user: User) -> bool:
    """Delete the user document."""
    await user.delete()
    return True
