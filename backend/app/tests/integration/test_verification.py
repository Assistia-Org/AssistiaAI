import pytest
import httpx
from app.core.redis import get_redis_value, set_redis_value
from app.core.messages.success_message import VERIFICATION_CODE_SENT, EMAIL_VERIFIED
from app.core.messages.error_message import TOO_MANY_VERIFICATION_REQUESTS, INVALID_VERIFICATION_CODE

pytestmark = pytest.mark.asyncio

async def test_request_verification_success(
    async_client: httpx.AsyncClient,
    monkeypatch
) -> None:
    """Test requesting verification code successfully (mocking mail dispatch)."""
    # Mock send_verification_code_email to always return True
    monkeypatch.setattr(
        "app.services.verification_service.send_verification_code_email",
        lambda email, code: True
    )

    req_data = {"email": "fresh_email@example.com"}
    response = await async_client.post(
        "/api/v1/verification/request",
        json=req_data
    )
    assert response.status_code == 200
    assert response.json() == VERIFICATION_CODE_SENT

    # Verify code was stored in Redis
    code_key = f"verification:code:fresh_email@example.com"
    stored_code = await get_redis_value(code_key)
    assert stored_code is not None
    assert len(stored_code) == 6

async def test_request_verification_rate_limit(
    async_client: httpx.AsyncClient,
    monkeypatch
) -> None:
    """Test that requesting verification code more than 3 times triggers rate limiting."""
    monkeypatch.setattr(
        "app.services.verification_service.send_verification_code_email",
        lambda email, code: True
    )

    email = "limit_email@example.com"
    req_data = {"email": email}

    # Request 3 times (allowed)
    for _ in range(3):
        res = await async_client.post("/api/v1/verification/request", json=req_data)
        assert res.status_code == 200

    # 4th request (rate limited)
    res_4th = await async_client.post("/api/v1/verification/request", json=req_data)
    assert res_4th.status_code == 429
    assert res_4th.json()["detail"] == TOO_MANY_VERIFICATION_REQUESTS

async def test_verify_code_success(
    async_client: httpx.AsyncClient
) -> None:
    """Test verifying a correct code successfully."""
    email = "verify_success@example.com"
    code_key = f"verification:code:{email}"
    
    # Directly set verification code in Redis
    await set_redis_value(code_key, "999999", expire=100)

    verify_data = {"email": email, "code": "999999"}
    response = await async_client.post(
        "/api/v1/verification/verify",
        json=verify_data
    )
    assert response.status_code == 200
    assert response.json() == EMAIL_VERIFIED

    # Verify code was deleted after use (one-time use check)
    stored = await get_redis_value(code_key)
    assert stored is None

async def test_verify_code_failure(
    async_client: httpx.AsyncClient
) -> None:
    """Test that verifying with invalid/expired code fails."""
    email = "verify_fail@example.com"

    verify_data = {"email": email, "code": "123456"}
    response = await async_client.post(
        "/api/v1/verification/verify",
        json=verify_data
    )
    assert response.status_code == 400
    assert response.json()["detail"] == INVALID_VERIFICATION_CODE
