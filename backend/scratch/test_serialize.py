import asyncio
import json
import uuid
from datetime import datetime
from pydantic import EmailStr

from app.schemas.base import ResponseEnvelope
from app.schemas.user import AuthResponse, UserResponse
from app.models.user import UnitSystem

def main():
    user_resp = UserResponse(
        id=uuid.uuid4(),
        email="chaudharyyash103c@gmail.com",
        name="Yash chaudhary",
        avatar_url=None,
        unit_system=UnitSystem.METRIC,
        created_at=datetime.utcnow(),
        updated_at=None
    )
    
    auth_resp = AuthResponse(
        access_token="mock_access_token",
        refresh_token="mock_refresh_token",
        user=user_resp
    )
    
    envelope = ResponseEnvelope(
        success=True,
        data=auth_resp,
        message="Google sign-in successful."
    )
    
    # Dump to JSON
    json_str = envelope.model_dump_json()
    print("Serialized JSON:")
    print(json.dumps(json.loads(json_str), indent=2))

if __name__ == "__main__":
    main()
