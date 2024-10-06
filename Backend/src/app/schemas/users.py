from pydantic import BaseModel
from typing import Optional, Union
from datetime import date
from app.models.user import Genre

class User(BaseModel):
    id: str
    email: str
    name: str
    surname:str
    born_date: date
    genre: Genre
    disabled: bool

class UserInDB(User):
    hashed_password: str

class Email(BaseModel):
    email: str

class RegisterCode(BaseModel):
    email: str
    code: str

class Login(BaseModel):
    username: str
    password: str

class NewPassword(BaseModel):
    email:str
    code:str
    new_pass: str
    confirmation_pass : str

class ConfirmValidCode(BaseModel):
    email:str
    code:str
    
class ChangePassword(BaseModel):
    old_pass: str
    new_pass : str

class UserRegister(BaseModel):
    email: str
    name: str
    surname:str
    born_date: Optional[Union[date, None]] = None
    genre: Optional[Union[Genre, None]] = None
    password: str

class RegisterDeviceToken(BaseModel):
    device_token: str

class UserUpdate(BaseModel):
    email: Union[str, None] = None
    name: Union[str, None] = None
    surname:Union[str, None] = None
    born_date: Union[date, None] = None
    genre: Union[Genre, None] = None
    disabled: Union[bool, None] = None

class Token(BaseModel):
    access_token: str
    token_type: str

class TokenData(BaseModel):
    name: str | None = None     
    email: str | None = None     
    disabled: bool | None = None     

