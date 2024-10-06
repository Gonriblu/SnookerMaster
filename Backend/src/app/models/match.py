from sqlalchemy import Boolean, DateTime, ForeignKey, Column, String, Integer, Float
from sqlalchemy.orm import relationship

from app.db.database import Base

import numpy as np

class Match(Base):
    __tablename__= "matches"
    
    id = Column(String(36), nullable=False, index= True, primary_key=True)
    match_datetime = Column(DateTime, nullable=False)
    cancelled = Column(Boolean, nullable=False, default=False)
    public = Column(Boolean, nullable=False)
    latitude = Column(Float, nullable=False)
    longitude = Column(Float, nullable=False)
    formatted_location = Column(String(255), nullable=False)
    frames = Column(Integer, nullable=False)
    local_frames = Column(Integer, nullable=True)
    visitor_frames = Column(Integer, nullable=True)
    local_start_match_elo = Column(Float, nullable=True)
    visitor_start_match_elo = Column(Float, nullable=True)
    local_end_match_elo = Column(Float, nullable=True)
    visitor_end_match_elo = Column(Float, nullable=True)
    local_result_agreed = Column(Boolean, nullable=False, default = False)
    visitor_result_agreed = Column(Boolean, nullable=False, default = False)
    
    local_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    local = relationship("User", foreign_keys=[local_id],  back_populates="local_matches")
    
    visitor_id = Column(String(36), ForeignKey('users.id'), nullable=True)
    visitor = relationship("User", foreign_keys=[visitor_id],  back_populates="visitor_matches")
    
    requests = relationship("JoinRequest", back_populates="match")
    
    def calculate_distance(self, latitude, longitude):
        
        if latitude is None or longitude is None:
            return None
        R = 6371  # Radio de la Tierra en kilómetros
        lat1 = np.radians(latitude)
        lon1 = np.radians(longitude)
        lat2 = np.radians(self.latitude)
        lon2 = np.radians(self.longitude)
        
        dlat = lat2 - lat1
        dlon = lon2 - lon1
        
        a = np.sin(dlat / 2) ** 2 + np.cos(lat1) * np.cos(lat2) * np.sin(dlon / 2) ** 2
        c = 2 * np.arctan2(np.sqrt(a), np.sqrt(1 - a))
        return R * c
    
    def format_distance(self, latitude, longitude):
        
        distance_km = self.calculate_distance(latitude, longitude)
        if distance_km is None:
            return None
        elif distance_km < 1:
            return f"{int(distance_km * 1000)} m"
        elif distance_km < 10:
            return f"{distance_km:.1f} km"
        else:
            return f"{int(distance_km)} km"
    
    def to_dict(self, latitude=None, longitude=None, with_last_matches_info = None):
        return {
            'id': self.id,
            'match_datetime': self.match_datetime,  
            'public': self.public,
            'cancelled': self.cancelled,
            'formatted_location': self.formatted_location,
            'frames': self.frames,
            'local_frames': self.local_frames,
            'local_start_match_elo': self.local_start_match_elo,
            'visitor_frames': self.visitor_frames,
            'visitor_start_match_elo': self.visitor_start_match_elo,
            'local_end_match_elo': self.local_end_match_elo,
            'visitor_end_match_elo': self.visitor_end_match_elo,
            'local_result_agreed': self.local_result_agreed,
            'visitor_result_agreed': self.visitor_result_agreed,
            'local': self.local.to_dict(with_last_matches_info),
            'visitor': self.visitor.to_dict(with_last_matches_info) if self.visitor is not None else None,
            'distance': self.format_distance(latitude, longitude) if latitude and longitude else None
        }
        
