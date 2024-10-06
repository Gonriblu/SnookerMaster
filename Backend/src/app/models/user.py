from sqlalchemy import Float, ForeignKey, Column, String, Boolean, Date, Enum
from sqlalchemy.orm import relationship
from enum import Enum as SchemaEnum
from statistics import mean, stdev
from collections import defaultdict

from app.db.database import Base


class Genre(SchemaEnum):
    MALE = "Hombre"
    FEMALE = "Mujer"
    OTHER = "Otro"


class User(Base):
    __tablename__= "users"
    id = Column(String(36), nullable=False, index=True, primary_key=True)
    email = Column(String(36), nullable=False, index=True, unique=True)
    name = Column(String(36), nullable=False)
    surname = Column(String(36), nullable=True)
    born_date = Column(Date, nullable=True)
    genre = Column(Enum(Genre), nullable=True, default=Genre.OTHER)
    profile_photo = Column(String(255), nullable=True)
    elo = Column(Float, nullable=False, default=1.0)
    disabled = Column(Boolean, nullable=False)
    
    hashed_password = relationship("UserInDB", back_populates="user", cascade="all,delete")
    
    register_codes = relationship("RegisterCode", back_populates="user", cascade="all,delete")
    pass_codes = relationship("PasswordCode", back_populates="user", cascade="all,delete")
    
    projects = relationship("Project", back_populates="user", cascade="all,delete")
    
    local_matches = relationship("Match", foreign_keys="[Match.local_id]", back_populates="local")
    visitor_matches = relationship("Match", foreign_keys="[Match.visitor_id]", back_populates="visitor")
    
    done_requests = relationship("JoinRequest", foreign_keys="[JoinRequest.inviter_id]", back_populates="inviter")
    received_requests = relationship("JoinRequest", foreign_keys="[JoinRequest.receiver_id]", back_populates="receiver")
    
    def get_last_matches_info(self):
        # Filtrar los partidos completados donde ambos resultados están acordados
        completed_matches = [match for match in self.local_matches if match.local_result_agreed and match.visitor_result_agreed]
        completed_matches.extend([match for match in self.visitor_matches if match.local_result_agreed and match.visitor_result_agreed])

        # Verificar la cantidad de partidos completados
        total_completed_matches = len(completed_matches)

        # Si tiene menos de 5 partidos, devolver None
        if total_completed_matches < 5:
            return None

        # Ordenar todos los partidos del usuario por fecha, de más reciente a más antiguo
        sorted_matches = sorted(completed_matches, key=lambda match: match.match_datetime)

        # Procesar el número de partidos según la cantidad disponible, con un máximo de 10
        num_matches_to_process = min(total_completed_matches, 10)
        matches_to_process = sorted_matches[-num_matches_to_process:]

        # Diccionario para almacenar la información
        matches_info = {}
        for i, match in enumerate(matches_to_process, start=1):
            if match.local_id == self.id:  # Si el usuario es local
                won = match.local_frames > match.visitor_frames
                start_elo = match.local_start_match_elo
                end_elo = match.local_end_match_elo
            else:  # Si el usuario es visitante
                won = match.visitor_frames > match.local_frames
                start_elo = match.visitor_start_match_elo
                end_elo = match.visitor_end_match_elo

            # Añadir la información al diccionario
            matches_info[i] = {
                "won": won,
                "start_elo": start_elo,
                "end_elo": end_elo,
                "match_datetime": match.match_datetime
            }

        return matches_info
 
    def to_dict(self, with_last_matches_info = False):
        return {
            'id': self.id,
            'email': self.email,
            'name': self.name,
            'surname': self.surname,
            'born_date': self.born_date,
            'genre': self.genre,
            'profile_photo': self.profile_photo,
            'elo': self.elo,
            'last_matches_info': self.get_last_matches_info() if with_last_matches_info else None
        }
        
    def get_statistics(self):
        all_plays = [play for project in self.projects for play in project.plays]
        
        if not all_plays:
            return {}
        
        angles = [play.angle for play in all_plays]
        distances = [play.distance for play in all_plays]
        successes = [play.success for play in all_plays]

        color_stats = defaultdict(lambda: {'count': 0, 'successes': 0, 'angles': [], 'distances': []})

        for play in all_plays:
            color_stats[play.second_color_ball]['count'] += 1
            if play.success:
                color_stats[play.second_color_ball]['successes'] += 1
            color_stats[play.second_color_ball]['angles'].append(play.angle)
            color_stats[play.second_color_ball]['distances'].append(play.distance)

        stats = {
            'total_plays': len(all_plays),
            'success_rate': round((sum(successes) / len(all_plays) * 100) if len(all_plays) > 0 else 0),
            'angle_mean': round(mean(angles) if angles else 0),
            'angle_min': round(min(angles) if angles else 0),
            'angle_max': round(max(angles) if angles else 0),
            'angle_stdev': round(stdev(angles) if len(angles) > 1 else 0),
            'distance_mean': round(mean(distances) if distances else 0),
            'distance_min': round(min(distances) if distances else 0),
            'distance_max': round(max(distances) if distances else 0),
            'distance_stdev': round(stdev(distances) if len(distances) > 1 else 0),
            'success_count': sum(successes),
            'fail_count': len(all_plays) - sum(successes),
            'angle_mean_success': round(mean([play.angle for play in all_plays if play.success]) if sum(successes) > 0 else 0),
            'distance_mean_success': round(mean([play.distance for play in all_plays if play.success]) if sum(successes) > 0 else 0),
            'color_stats': {}
        }

        for color, data in color_stats.items():
            stats['color_stats'][color] = {
                'count': data['count'],
                'success_rate': round(data['successes'] / data['count'] if data['count'] > 0 else 0),
                'angle_mean': round(mean(data['angles']) if data['angles'] else 0),
                'distance_mean': round(mean(data['distances']) if data['distances'] else 0),
                'angle_stdev': round(stdev(data['angles']) if len(data['angles']) > 1 else 0),
                'distance_stdev': round(stdev(data['distances']) if len(data['distances']) > 1 else 0),
            }

        return stats

    
class UserInDB(Base):
    __tablename__= "hashed_passwords"
    hashed_password = Column(String(80))

    user_id = Column(String(36), ForeignKey('users.id'),primary_key = True)
    user = relationship("User", back_populates="hashed_password")

    
class UsedTokens(Base):
    __tablename__= "used_tokens"
    token = Column(String(255), primary_key = True)