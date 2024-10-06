from sqlalchemy import DateTime, ForeignKey, Column, String, Enum
from sqlalchemy.orm import relationship
from enum import Enum as SchemaEnum

from app.db.database import Base


class RequestStatus(SchemaEnum):
    PENDING = "Pendiente"
    ACCEPTED = "Aceptada"
    REJECTED = "Rechazada"


class JoinRequest(Base):
    __tablename__= "join_requests"
    
    id = Column(String(36), nullable=False, index= True, primary_key=True)
    request_status = Column(Enum(RequestStatus), nullable=False, default=RequestStatus.PENDING)
    request_datetime = Column(DateTime, nullable=False)
    
    inviter_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    inviter = relationship("User",  foreign_keys=[inviter_id], back_populates="done_requests")
    
    receiver_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    receiver = relationship("User",  foreign_keys=[receiver_id], back_populates="received_requests")
    
    match_id = Column(String(36), ForeignKey('matches.id'), nullable=True)
    match = relationship("Match", back_populates="requests")
    

