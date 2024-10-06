from sqlalchemy import ForeignKey, Column, String, DateTime
from sqlalchemy.orm import relationship
from statistics import mean, stdev
from collections import defaultdict
from enum import Enum
from app.db.database import Base

class Pocket(Enum):
    BOTTOM_LEFT = "BottomLeft"
    BOTTOM_RIGHT = "BottomRight"
    MEDIUM_LEFT = "MediumLeft"
    MEDIUM_RIGHT = "MediumRight"
    TOP_LEFT = "TopLeft"
    TOP_RIGHT = "TopRight"
    
class Project(Base):
    __tablename__= "projects"
    
    id = Column(String(36), nullable=False, index= True, primary_key=True)
    name = Column(String(50), nullable=False)
    photo = Column(String(255), nullable=False)
    creation_date = Column(DateTime, nullable=False)
    description = Column(String(255), nullable=True)
    
    user_id = Column(String(36), ForeignKey('users.id'), nullable=False)
    user = relationship("User", back_populates="projects")
    
    plays = relationship("Play", back_populates="project")
    
    def get_project_details(self):
        return {
            'id': self.id,
            'name':self.name,
            'photo': self.photo,
            'description': self.description,
            'creation_date': self.creation_date.date(),
            'total_plays': len(self.plays),
            'plays': self.plays
        }
    
    def get_statistics(self):
        
        if not self.plays:
            return {}
        
        plays = self.plays

        angles = [play.angle for play in plays]
        distances = [play.distance for play in plays]
        successes = [play.success for play in plays]

        color_stats = defaultdict(lambda: {'count': 0, 'successes': 0, 'angles': [], 'distances': []})

        for play in plays:
            color_stats[play.second_color_ball]['count'] += 1
            if play.success:
                color_stats[play.second_color_ball]['successes'] += 1
            color_stats[play.second_color_ball]['angles'].append(play.angle)
            color_stats[play.second_color_ball]['distances'].append(play.distance)

        stats = {
            'total_plays': len(plays),
            'success_rate': round(sum(successes) / len(plays) * 100, 2),
            'angle_mean': round(mean(angles), 2),
            'angle_min': round(min(angles), 2),
            'angle_max': round(max(angles), 2),
            'angle_stdev': round(stdev(angles), 2) if len(angles) > 1 else 0,
            'distance_mean': round(mean(distances), 2),
            'distance_min': round(min(distances), 2),
            'distance_max': round(max(distances), 2),
            'distance_stdev': round(stdev(distances), 2) if len(distances) > 1 else 0,
            'success_count': sum(successes),
            'fail_count': len(plays) - sum(successes),
            'angle_mean_success': round(mean([play.angle for play in plays if play.success]), 2) if sum(successes) > 0 else 0,
            'distance_mean_success': round(mean([play.distance for play in plays if play.success]), 2) if sum(successes) > 0 else 0,
            'color_stats': {}
        }

        for color, data in color_stats.items():
            stats['color_stats'][color] = {
                'count': data['count'],
                'success_rate': round(data['successes'] / data['count'], 2) if data['count'] > 0 else 0,
                'angle_mean': round(mean(data['angles']), 2) if data['angles'] else 0,
                'distance_mean': round(mean(data['distances']), 2) if data['distances'] else 0,
                'angle_stdev': round(stdev(data['angles']), 2) if len(data['angles']) > 1 else 0,
                'distance_stdev': round(stdev(data['distances']), 2) if len(data['distances']) > 1 else 0,
            }


        return stats
    
