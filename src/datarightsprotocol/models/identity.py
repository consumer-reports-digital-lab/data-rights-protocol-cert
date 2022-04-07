from typing import Optional
from pydantic import EmailStr,  validator
from enum import Enum

from datarightsprotocol.models.base import BaseModel


class IdentityClaims(str, Enum):
    """
    This class enumerates the fields which go in an IdentityPayload.
    """
    issuer = "iss"
    audience = "aud"
    subject = "sub"
    name_ = "name"
    email = "email"
    phone_number = "phone_number"
    address = "address"
    poa = "power_of_attorney"


class IdentityPayload(BaseModel):
    iss: str
    aud: str
    sub: Optional[str]

    name: Optional[str]

    email: Optional[EmailStr]
    email_verified: Optional[bool] = False

    phone_number: Optional[str]
    phone_number_verified: Optional[bool] = False

    address: Optional[str]
    address_verified: Optional[bool] = False
    
    power_of_attorney: Optional[str]

    def json(self, secret: Optional[str] = None) -> str:
        if secret is None:
            secret = os.environ["JWT_SECRET"]
        encoder = BaseModel.Config.json_encoders['IdentityPayload']
        return encoder(self, secret=secret)


    @validator('iss')
    def issuer_set(cls, v):
        if v is None:
            raise ValueError("Must set issuer claim")
        return v

    @validator('aud')
    def audience_set(cls, v):
        if v is None:
            raise ValueError("Must set audience claim")
        return v
