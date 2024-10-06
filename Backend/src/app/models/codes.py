from sqlalchemy import ForeignKey, Column, String, DateTime
from sqlalchemy.orm import relationship

from app.db.database import Base


class RegisterCode(Base):
    __tablename__= "register_codes"
    code = Column(String(8))
    code_datetime = Column(DateTime, nullable=False)

    user_id = Column(String(36), ForeignKey('users.id'),primary_key = True)
    user = relationship("User", back_populates="register_codes")


class PasswordCode(Base):
    __tablename__= "pass_codes"
    code = Column(String(8))
    code_datetime = Column(DateTime, nullable=False)

    user_id = Column(String(36), ForeignKey('users.id'),primary_key = True)
    user = relationship("User", back_populates="pass_codes")   
    