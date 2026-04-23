import random
import string
from fastapi import HTTPException
from app.core.messages.error_message import (
    TOO_MANY_VERIFICATION_REQUESTS,
    INVALID_VERIFICATION_CODE,
    EMAIL_SEND_FAILED
)
from app.core.messages.success_message import (
    VERIFICATION_CODE_SENT,
    EMAIL_VERIFIED
)
from app.core.redis import (
    set_redis_value,
    get_redis_value,
    delete_redis_value,
    increment_redis_value
)
from app.utils.email import send_verification_code_email

def generate_code(length: int = 6) -> str:
    """Generate a random numeric code."""
    return "".join(random.choices(string.digits, k=length))

async def request_verification_service(email: str) -> str:
    """
    Handle verification code request with rate limiting.
    Max 3 requests per 5 minutes using Redis.
    """
    rate_key = f"verification:rate:{email}"
    code_key = f"verification:code:{email}"
    
    # 1. Check rate limit
    count = await increment_redis_value(rate_key, expire=300)
    if count > 3:
        raise HTTPException(status_code=429, detail=TOO_MANY_VERIFICATION_REQUESTS)
    
    # 2. Generate and store code
    code = generate_code()
    await set_redis_value(code_key, code, expire=300)
    
    # 3. Send email
    sent = send_verification_code_email(email, code)
    if not sent:
        raise HTTPException(status_code=500, detail=EMAIL_SEND_FAILED)
        
    return VERIFICATION_CODE_SENT

async def verify_code_service(email: str, code: str) -> str:
    """
    Handle code verification using Redis.
    Code is automatically removed by Redis TTL if expired.
    One-time use is handled by deleting the key after successful verification.
    """
    code_key = f"verification:code:{email}"
    stored_code = await get_redis_value(code_key)
    
    if not stored_code:
        raise HTTPException(status_code=400, detail=INVALID_VERIFICATION_CODE)
        
    if stored_code != code:
        raise HTTPException(status_code=400, detail=INVALID_VERIFICATION_CODE)
        
    # Mark as used (delete from Redis)
    await delete_redis_value(code_key)
    
    return EMAIL_VERIFIED
