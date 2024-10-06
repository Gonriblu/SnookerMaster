from fastapi import APIRouter, Depends, File, HTTPException, UploadFile, status
from fastapi.responses import JSONResponse
from typing import Annotated
from datetime import timedelta, datetime
from dotenv import load_dotenv
from email.mime.multipart import MIMEMultipart
from email.mime.text import MIMEText
from sqlalchemy.orm import Session

from app.models.user import Genre, User as DBUser, UserInDB as DBUserInDB
from app.models.codes import RegisterCode, PasswordCode

from app.routers.oauth import  get_current_user, create_token, authenticate_user

from app.schemas import users

from app.db.database import get_db

from app.utils.logger import configure_logging
from app.utils.literals import (
    ALREADY_CONFIRMED_EMAIL,
    ALREADY_REGISTERED_EMAIL,
    BAD_PASSWORD,
    CODE_HAS_EXPIRED,
    CODE_NOT_FOUND,
    INCORRECT_PASSWORD,
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    ERROR_500,
    INVALID_CODE,
    NOT_AUTHORIZED,
    PASSWORD_DOESNT_MATCH,
    USER_NOT_FOUND,
)

import os, re, random, string, uuid, smtplib, bcrypt, logging


configure_logging()
load_dotenv()

SECRET_KEY = os.getenv("SECRET_KEY")
ALGORITHM = os.getenv("ALGORITHM")
TOKEN_EXPIRATION = int(os.getenv("TOKEN_EXPIRATION"))
PROFILE_IMAGES_DIRECTORY = os.getenv("PROFILE_IMAGES_DIRECTORY")

user_router = APIRouter(prefix="/users",tags=["Users"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[users.User, Depends(get_current_user)]

# GET USER BY EMAIL
def get_user_by_email(email:str, db: db_dependency):
    find_user = db.query(DBUser).filter(DBUser.email == email).first()
    return find_user

def generate_random_code(length=8):
    characters = string.ascii_letters + string.digits
    codigo = ''.join(random.choice(characters) for i in range(length))
    return codigo


# REGISTER NEW USER
new_user_responses = {
    400: {'description': BAD_PASSWORD},
    400: {'description': ALREADY_REGISTERED_EMAIL},
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/sign", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **new_user_responses})
async def new_user(user: users.UserRegister, db: db_dependency):
    try:
        logging.info(f"Creating user")
        
        already_registered_email = get_user_by_email(user.email, db)
        
        if already_registered_email:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=ALREADY_REGISTERED_EMAIL)

        logging.info(f"Validating password")
        if not validate_password(user.password):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=BAD_PASSWORD)
        
        salt = bcrypt.gensalt()
        hashed_password = bcrypt.hashpw(user.password.encode('utf-8'), salt).decode('utf-8')
        
        user_data = user.model_dump(exclude_unset=True, exclude={"password"})
        
        db_user = DBUser(id=str(uuid.uuid4()), disabled = True, **user_data)
        db.add(db_user)
        
        db_userInDB = DBUserInDB(user = db_user, hashed_password = hashed_password)
        db.add(db_userInDB)
        
        code = generate_random_code()
        register_code = RegisterCode(code = code, code_datetime = datetime.now(), user = db_user)
        db.add(register_code)
                
        logging.info(f"Sending email")
        send_email_to_confirm_registration(db_user,code)
        
        db.commit()
        db.refresh(db_userInDB)
        
        logging.info(f"User created")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


confirm_email_responses = {
    400: {'description': CODE_HAS_EXPIRED},
    404: {'description': CODE_NOT_FOUND},
}
@user_router.post("/confirm_email", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **confirm_email_responses})
async def confirm_email(data: users.RegisterCode, db: db_dependency):
    try:
        logging.info(f"Confirming email")
        user = db.query(DBUser).filter(DBUser.email == data.email).first()
        db_code = db.query(RegisterCode).filter(RegisterCode.user_id == user.id).first()
        
        if not db_code:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=CODE_NOT_FOUND)
                
        if datetime.now() - db_code.code_datetime <= timedelta(minutes=30):
            if data.code == db_code.code:
                user.disabled = False
                db.delete(db_code)
                db.add(user)
                db.commit()
        else:
            db.delete(db_code)
            db.commit()
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CODE_HAS_EXPIRED)
        
        logging.info(f"Email confirmed")
        return 'email confirmado'
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error confirming email\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error confirming email: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


send_confirm_email_responses = {
    400: {'description': ALREADY_CONFIRMED_EMAIL},
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/new/confirm_email", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **send_confirm_email_responses})
async def send_other_confirmation_email(data: users.Email, db: db_dependency):
    try:
        logging.info(f"Sending email")
        
        user = get_user_by_email(data.email, db)
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
        
        db_code = db.query(RegisterCode).filter(RegisterCode.user_id == user.id).first()
        
        if db_code:
            db.delete(db_code)
        
        code = generate_random_code()
        register_code = RegisterCode(code = code, code_datetime = datetime.now(), user = user)
        db.add(register_code)
            
        if user.disabled == True:
            send_email_to_confirm_registration(user)
        else:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=ALREADY_CONFIRMED_EMAIL)
        
        db.commit()
        logging.info(f"Email sent")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error sending email\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error sending email: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# ADD PROFILE PHOTO
add_profile_photo_responses = {
    401: {'description': NOT_AUTHORIZED},
    404: {'description': USER_NOT_FOUND},
}
@user_router.patch("/profile_photo/me", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **add_profile_photo_responses})
async def update_profile_photo(db: db_dependency, current_user: current_user, photo: UploadFile = File(...)):
    try:
        logging.info(f"Updating photo")
        user = get_user_by_email(current_user.user.email, db)
        
        if not user:
            raise HTTPException(status_code = status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
        
        if user.id != current_user.user.id:
            raise HTTPException(status_code = status.HTTP_401_UNAUTHORIZED, detail=NOT_AUTHORIZED)  
        
        photo_path = os.path.join(PROFILE_IMAGES_DIRECTORY, f'{user.email}.png')
        
        if os.path.exists(photo_path):
            os.remove(photo_path)  
        
        with open(photo_path, "wb") as image_file:
            image_file.write(photo.file.read())
            
        user.profile_photo = f'static/profile_images/{user.email}.png'
        
        db.add(user)
        db.commit()
        db.refresh(user)
        
        logging.info(f"Photo updated")
        return user
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error updating photo\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error updating photo: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# GET THE ENUMERATES
@user_router.get("/genres", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_user_genres():
    return [type.value for type in Genre]


# DELETE LOGGED USER
delete_logged_user_responses = {
    401: {'description': NOT_AUTHORIZED},
    404: {'description': USER_NOT_FOUND},
}
@user_router.delete("/delete/me", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **delete_logged_user_responses})
async def delete_user(db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Deleting my user")
        user = get_user_by_email(current_user.user.email, db)
        
        if not user:
            raise HTTPException(status_code = status.HTTP_400_BAD_REQUEST, detail=USER_NOT_FOUND) 
         
        if user.id != current_user.user_id:
            raise HTTPException(status_code = status.HTTP_401_UNAUTHORIZED, detail=NOT_AUTHORIZED)  
        
        db.delete(user)
        db.commit()
        logging.info(f"User deleted")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error deleting user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error deleting user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# DISABLE USER
disable_user_responses = {
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/disable", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **disable_user_responses})
async def disable_user(data: users.Email, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Disabling user")
        user = get_user_by_email(data.email, db)
        
        if not user:
            raise HTTPException(status_code = status.HTTP_400_BAD_REQUEST, detail=USER_NOT_FOUND) 
         
        user.disabled = True
        
        db.commit()
        db.refresh(user)
        
        logging.info(f"User disabled")
        return user
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error disabling user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error disabling user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# UPDATE LOGGED USER
update_logged_user_responses = {
    401: {'description': NOT_AUTHORIZED},
    404: {'description': USER_NOT_FOUND},
}
@user_router.patch("/update/me", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **update_logged_user_responses})
async def update_user(new_user: users.UserUpdate, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Updating user")
        db_user = get_user_by_email(current_user.user.email, db)
        
        if not db_user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
        
        if db_user.id != current_user.user_id:
            raise HTTPException(status_code = status.HTTP_401_UNAUTHORIZED, detail=NOT_AUTHORIZED)  
        
        user_data = new_user.model_dump(exclude_unset=True)
        
        for key, value in user_data.items():
            setattr(db_user, key, value)
        
        db.add(db_user)
        db.commit()
        db.refresh(db_user)
        
        logging.info(f"User updated")
        return db_user
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error updating user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error updating user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# GET ALL USERS
@user_router.get("/", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_all_users(db: db_dependency, current_user: current_user):
    try: 
        logging.info(f"Fetching users")
        data = db.query(DBUser).all()
        
        logging.info(f"Fetched {len(data)} users")
        return data
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching users\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching users: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# RETRIEVE PASSWORD
retrieve_pass_responses = {
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/send_code_reset_pass", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **retrieve_pass_responses})
async def send_email_to_retrieve_pass(data: users.Email, db: db_dependency):
    try: 
        logging.info(f"Sending email")
        
        user = db.query(DBUser).filter(DBUser.email == data.email).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
        
        existing_code = db.query(PasswordCode).filter(PasswordCode.user_id == user.id).first()
        if existing_code:
            db.delete(existing_code)
        
        code = generate_random_code()
        pass_code = PasswordCode(code = code, code_datetime = datetime.now(), user = user)
        db.add(pass_code)
        
        subject = "Recuperación de contraseña"
        body = f'''Hola {user.name} {user.surname}, ha solicitado recuperar su contraseña.
                <br><br>Este es tu código para recuperar tu contraseña: {code}.'''
        
        send_email_to_retrieve_pass(data.email,subject,body)
        db.commit()
        
        logging.info(f"Sent email")
        return {'status': 200}
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error sending email\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error sending email: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


check_pass_code_responses = {
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/check_pass_code", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **check_pass_code_responses})
async def check_pass_code(data: users.ConfirmValidCode, db: db_dependency):
    try: 
        logging.info(f"Checking code")
        
        user = db.query(DBUser).filter(DBUser.email == data.email).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
        exisisting_code = db.query(PasswordCode).filter(PasswordCode.code == data.code, PasswordCode.user_id == user.id).first()
        if exisisting_code:
            if datetime.now() - exisisting_code.code_datetime <= timedelta(minutes=30):
                return 'valid'
            else:
                db.delete(exisisting_code)
                db.commit()
                return 'invalid'
        else:
            return 'invalid'
            
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error checking code\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error checking code: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


reset_pass_responses = {
    400: {'description': BAD_PASSWORD},
    400: {'description': PASSWORD_DOESNT_MATCH},
    400: {'description': INVALID_CODE},
    404: {'description': CODE_NOT_FOUND},
    404: {'description': USER_NOT_FOUND},
}
@user_router.post("/reset_pass", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **reset_pass_responses})
async def reset_pass(data: users.NewPassword, db: db_dependency):
    try: 
        logging.info(f"Resetting password")

        user = db.query(DBUser).filter(DBUser.email == data.email).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)  
            
        exisisting_code = db.query(PasswordCode).filter(PasswordCode.code == data.code, PasswordCode.user_id == user.id).first()
        if exisisting_code:
            if datetime.now() - exisisting_code.code_datetime > timedelta(minutes=30):
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=INVALID_CODE)  
                
            db.delete(exisisting_code)
        else:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=CODE_NOT_FOUND)  
            
        if data.new_pass != data.confirmation_pass:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=PASSWORD_DOESNT_MATCH)
            
        logging.info(f"Validating password")
        if not validate_password(data.new_pass):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=BAD_PASSWORD)
            
        salt = bcrypt.gensalt()
        new_hashed_password = bcrypt.hashpw(data.new_pass.encode('utf-8'), salt).decode('utf-8')
        
        password = db.query(DBUserInDB).filter(DBUserInDB.user_id == user.id).first()
        password.hashed_password = new_hashed_password
        db.add(password)
        
        db.commit()
        logging.info(f"Password reseted successfully")
        
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error resetting password\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error resetting password: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


change_pass_responses = {
    400: {'description': BAD_PASSWORD},
    400: {'description': INCORRECT_PASSWORD},
}
@user_router.post("/change_pass", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **change_pass_responses})
def change_password(pass_data: users.ChangePassword, db: db_dependency, current_user: current_user):
    try: 
        logging.info(f"Changing password")
        
        logging.info(f"Validating password")
        if not validate_password(pass_data.new_pass):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=BAD_PASSWORD)
            
        user = authenticate_user(current_user.user.email, pass_data.old_pass, db)
        if user is False:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=INCORRECT_PASSWORD)
            
        salt = bcrypt.gensalt()
        new_hashed_password = bcrypt.hashpw(pass_data.new_pass.encode('utf-8'), salt).decode('utf-8')
        
        user_in_db = db.query(DBUserInDB).filter(DBUserInDB.user_id == current_user.user.id).first()
        user_in_db.hashed_password = new_hashed_password
        db.add(user_in_db)
        db.commit()
    
        logging.info(f"Password changed successfully")
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error changing password\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error changing password: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")

def get_random_token(user:DBUser):
   
    access_token_expires = timedelta(minutes=TOKEN_EXPIRATION)
    reset_token = create_token(data={"email": user.email, "name": str(user.name), "active": user.disabled}, expires_delta=access_token_expires)

    return reset_token
   
   
# GET AN USER BY EMAIL
get_user_responses = {
    404: {'description': USER_NOT_FOUND},
}
@user_router.get("/{email}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_user_responses})
async def get_user(email:str, db: db_dependency, current_user: current_user):
    try: 
        logging.info(f"Fetching user")
        
        user = get_user_by_email(email,db)
        
        if not user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=USER_NOT_FOUND) 
         
        logging.info(f"User fetched")
        return user
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# GET LOGGED USER
get_logged_user_responses = {
    404: {'description': USER_NOT_FOUND},
}
@user_router.get("/get/me", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_logged_user_responses})
async def get_my_user(db: db_dependency, current_user: current_user):
    try: 
        logging.info(f"Fetching user")
        
        user = get_user_by_email(current_user.user.email, db)

        if not user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=USER_NOT_FOUND)  

        logging.info(f"User fetched")
        return user.to_dict(True)
        
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching my user\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching my user: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# SEND EMAIL TO CONFIRM REGISTRATION
def send_email_to_confirm_registration(user: DBUser, code: str):
    try:
        # load credentials from .env
        load_dotenv()

        sender_email = os.getenv('EMAIL_USER')
        sender_password = os.getenv('EMAIL_PASSWORD') 
        smtp_server = os.getenv('SMTP_SERVER')
        smtp_port = os.getenv('SMTP_PORT')
        
        subject = "Confirmación de correo"
        body = f'''Hola {user.name}, has solicitado registrate en Snooker Master.
                \n Accede a la siguiente url para confirmar tu correo. 
                <br><br>Este es tu código para confirmar tu correo {code}</a>
                \n Este enlace dejará de funcionar en 30 minutos.'''

        message = MIMEMultipart()
        message["From"] = sender_email
        message["To"] = user.email
        message["Subject"] = subject

        message.attach(MIMEText(body, "plain"))

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            text = message.as_string()
            server.sendmail(sender_email, user.email, text)

            return JSONResponse(content={"message": "Email sent successfully"}, status_code=200)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al enviar el correo: {str(e)}")  

# SEND EMAIL TO RETRIEVE PASSWORD
def send_email_to_retrieve_pass(to: str, subject: str, body: str):
    try:
        # load credentials from .env
        load_dotenv()

        sender_email = os.getenv('EMAIL_USER')
        sender_password = os.getenv('EMAIL_PASSWORD') 
        smtp_server = os.getenv('SMTP_SERVER')
        smtp_port = os.getenv('SMTP_PORT')

        message = MIMEMultipart()
        message["From"] = sender_email
        message["To"] = to
        message["Subject"] = subject

        message.attach(MIMEText(body, "plain"))

        with smtplib.SMTP(smtp_server, smtp_port) as server:
            server.starttls()
            server.login(sender_email, sender_password)
            text = message.as_string()
            server.sendmail(sender_email, to, text)

            return JSONResponse(content={"message": "Email sent successfully"}, status_code=200)
    except Exception as e:
        raise HTTPException(status_code=500, detail=f"Error al enviar el correo: {str(e)}")  
    
# MAKE SURE IS A VALID PASSWORD (must be 8 characters min and have one uppercase letter, one lowercase letter, one number and one special character.)
def validate_password(password: str) -> bool:
    # Validate length 
    if len(password) < 8:
        return False
    
    # Validate lower and uppercase letter
    if not re.search(r'[a-z]', password) or not re.search(r'[A-Z]', password):
        return False
    
    # Validate digit
    if not re.search(r'\d', password):
        return False
    
    # Validate special character
    if not re.search(r'[!@#$%^&*()_+=\-[\]{};:\'",.<>?]', password):
        return False
    
    return True

 