from sqlalchemy import JSON, DateTime, ForeignKey, Column, String, Integer, Float, Boolean
from sqlalchemy.orm import relationship

from app.db.database import Base


class Play(Base):
    __tablename__= "plays"
    
    id = Column(String(36), nullable=False, index= True, primary_key=True)
    photo = Column(String(255), nullable=True)
    processed_video = Column(String(255), nullable=True)
    angle = Column(Integer, nullable=False)
    distance = Column(Float, nullable=False)
    success = Column(Boolean, nullable=False)
    first_color_ball = Column(String(10), nullable=False)
    second_color_ball = Column(String(10), nullable=False)
    pocket = Column(String(36), nullable=False)
    creation_date = Column(DateTime, nullable=False)
    ball_paths = Column(JSON, nullable=True) 
    
    project_id = Column(String(36), ForeignKey('projects.id'), nullable=False)
    project = relationship("Project", back_populates="plays")
    
    def get_statistics(self):
        return self.angle, self.distance, self.success, self.second_color_ball
    
