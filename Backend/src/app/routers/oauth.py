from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.security import OAuth2PasswordBearer, OAuth2PasswordRequestForm
from jose import JWTError, jwt
from datetime import datetime, timedelta, timezone
from typing import Annotated
from dotenv import load_dotenv
from passlib.context import CryptContext
from sqlalchemy.orm import Session , joinedload

from app.models.user import UserInDB as DBUserInDB, User as DBUser

from app.schemas.users import Token, TokenData, User

from app.db.database import get_db

from app.utils.literals import (
    EMAIL_NOT_FOUND_IN_TOKEN,
    INACTIVE_USER,
    INCORRECT_USER_OR_PASSWORD,
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    ERROR_500,
    PLEASE_LOGIN_AGAIN,
)
import os, bcrypt

load_dotenv()
SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
ACCESS_TOKEN_EXPIRE_MINUTES = int(os.getenv("ACCESS_TOKEN_EXPIRE_MINUTES"))

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="login")
oAuth2_router = APIRouter(tags=["OAuth"])
db_dependency = Annotated[Session,Depends(get_db)]

def get_user_inDB(email: str, db: db_dependency):
    user_in_db = db.query(DBUserInDB).join(DBUser).filter(DBUser.email == email).options(joinedload(DBUserInDB.user)).first()
    return user_in_db

def authenticate_user(email: str, password: str, db: db_dependency):
    user = get_user_inDB(email, db)
    password_byte_enc = password.encode('utf-8')
    if not user:
        return False
    hashed_pass_encoded = user.hashed_password.encode('utf-8')
    if not bcrypt.checkpw(password = password_byte_enc , hashed_password = hashed_pass_encoded):
        return False
    return user

def create_token(data: dict, expires_delta: timedelta | None = None):
    to_encode = data.copy()
    if expires_delta:
        expire = datetime.now(timezone.utc) + expires_delta
    else:
        expire = datetime.now(timezone.utc) + timedelta(minutes=15)
    to_encode.update({"exp": expire})
    encoded_jwt = jwt.encode(to_encode, SECRET_KEY, algorithm=ALGORITHM)
    return encoded_jwt

async def get_current_user(token: Annotated[str, Depends(oauth2_scheme)], db: db_dependency):
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail=PLEASE_LOGIN_AGAIN,
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email: str = payload.get("email")
        name: str = payload.get("name")
        disabled: bool = payload.get("disabled")
        if email is None:
            raise credentials_exception
        token_data = TokenData(email=email, name=name, disabled = disabled)
    except JWTError:
        raise credentials_exception
    
    email=token_data.email
    user = get_user_inDB(email, db)
    
    if user is None:
        raise credentials_exception
    
    return user

async def get_current_active_user(current_user: Annotated[User, Depends(get_current_user)]):
    if current_user.user.disabled:
        raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=INACTIVE_USER)
    return current_user

@oAuth2_router.post("/login", response_model=Token)
async def login_for_access_token(form_data: Annotated[OAuth2PasswordRequestForm, Depends()],db: db_dependency):

    user = authenticate_user(form_data.username, form_data.password, db)

    if not user:
        raise HTTPException(status_code=status.HTTP_401_UNAUTHORIZED, detail=INCORRECT_USER_OR_PASSWORD)
    
    user = db.query(DBUser).filter_by(id = user.user_id).first()
    access_token_expires = timedelta(hours=ACCESS_TOKEN_EXPIRE_MINUTES)
    access_token = create_token(data={"email": user.email, "name": user.name, "disabled": user.disabled}, expires_delta=access_token_expires)

    return {"access_token": access_token, "token_type": "bearer"}


@oAuth2_router.post("/refresh-token", response_model=Token)
def refresh_access_token(token: str):
    try:
        payload = jwt.decode(token, SECRET_KEY, algorithms=[ALGORITHM])
        email = payload.get("email")
        name = payload.get("name")
        disabled = payload.get("disabled")
        if email is None:
            raise JWTError(EMAIL_NOT_FOUND_IN_TOKEN)
        access_token_expires = timedelta(minutes=ACCESS_TOKEN_EXPIRE_MINUTES)
        new_token = create_token(data={"email": email, "name": name, "disabled": disabled}, expires_delta=access_token_expires)
        return {"access_token": new_token, "token_type": "bearer"}
    except JWTError as e:
        return None
    
