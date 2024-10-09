from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload
from datetime import datetime, timezone
from typing import Annotated

from app.models.user import User as DBUser
from app.models.match import Match

from app.routers.oauth import  get_current_user

from app.schemas.matches import *
from app.schemas.users import User

from app.db.database import get_db

from app.utils.logger import configure_logging
from app.utils.literals import (
    CANT_JOIN_YOUR_MATCH,
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    INVALID_FRAMES_SUM,
    LATITUDE_AND_LONGITUD_MUST_BE_PROVIDED,
    MATCH_ALREADY_HAS_TWO_PLAYERS,
    MATCH_NOT_FOUND,
    MATCH_ALREADY_PLAYED,
    CANT_DELETE_MATCH,
    DATE_MUST_BE_AFTER_NOW,
    NOT_YOUR_MATCH,
    ERROR_500
)

import uuid, logging


configure_logging()

matches_router = APIRouter(prefix="/matches",tags=["Matches"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[User, Depends(get_current_user)]


get_all_matches_responses = {
    400: {'description': LATITUDE_AND_LONGITUD_MUST_BE_PROVIDED}
}
@matches_router.get("/", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_all_matches_responses})
async def get_all_matches(db: db_dependency, current_user: current_user, 
                           public: bool = None,
                           min_datetime: datetime = None, max_datetime: datetime = None,
                           min_frames: int = None, max_frames: int = None,
                           local_max_elo: float = None, local_min_elo: float = None,
                           latitude: float = None, longitude: float = None, open: bool = None,
                           sort_by: str = None, sort_direction: str = None,
                           limit: int = Query(10, ge=1, le=100), offset: int = Query(0, ge=0)):
    
    try:
        logging.info(f"Fetching matches")
        
        if (latitude is not None and longitude is None) or (latitude is None and longitude is not None):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=LATITUDE_AND_LONGITUD_MUST_BE_PROVIDED)
        
        if min_datetime is None:
            min_datetime = datetime.now()

        if min_datetime < datetime.now():
            min_datetime = datetime.now()
        
        query = db.query(Match).join(DBUser, Match.local_id == DBUser.id).filter(
                                        Match.public == public if public is not None else True,
                                        Match.frames <= max_frames if max_frames is not None else True,
                                        Match.frames >= min_frames if min_frames is not None else True,
                                        Match.match_datetime >= min_datetime if min_datetime is not None else True,
                                        Match.match_datetime <= max_datetime if max_datetime is not None else True,
                                        DBUser.elo <= local_max_elo if local_max_elo is not None else True,
                                        DBUser.elo >= local_min_elo if local_min_elo is not None else True,
                                        Match.visitor_id == None if open else True,
                                        Match.local_id != current_user.user.id,
                                        Match.cancelled == False,
                                        )
        if sort_by and sort_direction:
            if sort_direction.lower() == "asc":
                query = query.order_by(getattr(Match, sort_by).asc())
            elif sort_direction.lower() == "desc":
                query = query.order_by(getattr(Match, sort_by).desc())
        
        matches = query.all()
        
        if latitude is not None and longitude is not None:
            matches_with_distances = [(match, match.calculate_distance(latitude, longitude)) for match in matches]
            matches_with_distances.sort(key=lambda x: x[1] if x[1] is not None else float('inf'))
            matches = [match for match, _ in matches_with_distances]
        
        data_length = len(matches)
        start_index = offset
        end_index = min(offset + limit, data_length)
        
        data = [match.to_dict(latitude, longitude) for match in matches[start_index:end_index]]
        
        logging.info(f"Found {data_length} matches")
        return data, data_length
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching matches\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching matches: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


@matches_router.get("/my_matches", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_my_matches(db: db_dependency, current_user: current_user, 
                           sort_by: str = None, sort_direction: str = None,
                           limit: int = Query(10, ge=1, le=100), offset: int = Query(0, ge=0)):
    
    try:
        logging.info(f"Fetching my matches")
        
        query = db.query(Match).filter(or_(
                                        Match.visitor_id == current_user.user.id,
                                        Match.local_id == current_user.user.id)
                                        )
        if sort_by and sort_direction:
            if sort_direction.lower() == "asc":
                query = query.order_by(getattr(Match, sort_by).asc())
            elif sort_direction.lower() == "desc":
                query = query.order_by(getattr(Match, sort_by).desc())
        
        matches = query.all()
        
        data_length = len(matches)
        start_index = offset
        end_index = min(offset + limit, data_length)
        
        data = [match.to_dict() for match in matches[start_index:end_index]]
        
        logging.info(f"Found {data_length} matches")
        return data, data_length
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching my matches\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching my matches: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


get_match_responses = {
    404: {'description': MATCH_NOT_FOUND}
}
@matches_router.get("/{match_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_match_responses})
async def get_match(match_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching match")
        
        match = db.query(Match).filter(Match.id == match_id
                                       ).options(joinedload(Match.local),
                                                 joinedload(Match.visitor)).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)
            
        logging.info(f"Successfully fetched match")
        return match.to_dict(with_last_matches_info = True)
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching match\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching match: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


delete_match_responses = {
    400: {'description': CANT_DELETE_MATCH},
    400: {'description': MATCH_ALREADY_PLAYED},
    404: {'description': MATCH_NOT_FOUND},
}
@matches_router.delete("/{match_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **delete_match_responses})
async def delete_match(match_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Deleting match")
        
        current_user_id = current_user.user.id
        
        match = db.query(Match).filter(Match.id == match_id).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)
            
        if current_user_id != match.local_id and current_user_id != match.visitor_id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_DELETE_MATCH)
           
        if match.match_datetime < datetime.now():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=MATCH_ALREADY_PLAYED)
        
        if match.visitor_id and match.local_id:
            match.cancelled = True
        else:
            db.delete(match)
            
        db.commit()
        
        logging.info(f"Successfully deleted match")
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error deleting match\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error deleting match: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


new_match_responses = {
    404: {'description': MATCH_NOT_FOUND},
}
@matches_router.post("/new", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **new_match_responses})
async def new_match(data: NewMatch, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Creating match with data: {data}")
        
        if data.match_datetime.tzinfo is None:
            data.match_datetime = data.match_datetime.replace(tzinfo=timezone.utc)
            
        if data.match_datetime < datetime.now(timezone.utc):
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=DATE_MUST_BE_AFTER_NOW)
            
        new_match = Match(
                        id =str(uuid.uuid4()), 
                        **data.model_dump(),
                        local = current_user.user)
                    
        db.add(new_match)
        db.commit()
        
        logging.info(f"Successfully created match")
        return new_match
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating match\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating match: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


post_result_responses = {
    400: {'description': INVALID_FRAMES_SUM},
    400: {'description': NOT_YOUR_MATCH},
    404: {'description': MATCH_NOT_FOUND},
}
@matches_router.post("/result", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **post_result_responses})
async def result(data: Result, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Setting result: {data}")
        match = db.query(Match).filter(Match.id == data.match_id
                                       ).options(joinedload(Match.local),
                                                 joinedload(Match.visitor)).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)
            
        if data.local_frames + data.visitor_frames != match.frames: 
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=INVALID_FRAMES_SUM)
        
        if current_user.user == match.local:
            match.local_result_agreed = True
        elif current_user.user == match.visitor:
            match.visitor_result_agreed = True
        else: 
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOT_YOUR_MATCH)
            
        match.local_frames = data.local_frames
        match.visitor_frames = data.visitor_frames
        
        db.commit()
        db.refresh(match)
        
        logging.info(f"Result setted successfully")
        return match
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error setting result\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error setting result: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


confirm_result_responses = {
    400: {'description': INVALID_FRAMES_SUM},
    400: {'description': NOT_YOUR_MATCH},
    404: {'description': MATCH_NOT_FOUND},
}
@matches_router.post("/confirm_result", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **confirm_result_responses})
async def confirm_result(data: ConfirmResult, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Confirming result: {data}")
        
        logged_user = current_user.user
        match = db.query(Match).filter(Match.id == data.match_id
                                       ).options(joinedload(Match.local),
                                                 joinedload(Match.visitor)).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)

        if data.agreed:
            K = 0.45

            local_elo = match.local_start_match_elo
            visitor_elo = match.visitor_start_match_elo

            elo_difference = visitor_elo - local_elo
            
            expected_local_win_prob = 1 / (1 + 10 ** (elo_difference / 10))
            
            if match.local_frames > match.visitor_frames:
                local_result = 1
                visitor_result = 0
            else:
                local_result = 0
                visitor_result = 1
            
            new_local_elo = match.local.elo + K * (local_result - expected_local_win_prob)
            new_visitor_elo = match.visitor.elo + K * (visitor_result - (1 - expected_local_win_prob))
            
            final_local_elo = min(max(new_local_elo, 1.0), 10.0)
            final_visitor_elo = min(max(new_visitor_elo, 1.0), 10.0)
            
            match.local.elo = final_local_elo
            match.visitor.elo = final_visitor_elo
            
            match.local_end_match_elo = final_local_elo
            match.visitor_end_match_elo = final_visitor_elo
            
            if logged_user == match.local:
                match.local_result_agreed = True
            elif logged_user == match.visitor:
                match.visitor_result_agreed = True
            else: 
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOT_YOUR_MATCH)
        else:
             
            if data.local_frames + data.visitor_frames != match.frames: 
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=INVALID_FRAMES_SUM)
            
            match.local_frames = data.local_frames
            match.visitor_frames = data.visitor_frames
            
            if logged_user == match.local:
                match.local_result_agreed = True
                match.visitor_result_agreed = False
            elif logged_user == match.visitor:
                match.local_result_agreed = False
                match.visitor_result_agreed = True
            else: 
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOT_YOUR_MATCH)
            
        db.commit()
        db.refresh(match)
        
        logging.info(f"Result confirmed")
        return match
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error confirming result\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error confirming result: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


join_with_qr_responses = {
    400: {'description': CANT_JOIN_YOUR_MATCH},
    400: {'description': MATCH_ALREADY_HAS_TWO_PLAYERS},
    404: {'description': MATCH_NOT_FOUND},
}
@matches_router.post("/join_with_qr" , status_code=status.HTTP_200_OK, responses= {**ERROR_500, **join_with_qr_responses})
async def join_with_qr(data: MatchId, db: db_dependency, current_user: current_user):
    
    try:     
        logging.info(f"Joining match")
        
        logged_user = current_user.user
               
        match = db.query(Match).filter(Match.id == data.match_id
                                       ).options(joinedload(Match.local),
                                                 joinedload(Match.visitor)).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)
            
        if logged_user == match.local:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_JOIN_YOUR_MATCH)
        
        if match.visitor != None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=MATCH_ALREADY_HAS_TWO_PLAYERS)
            
        match.visitor = logged_user     
        match.local_start_match_elo = match.local.elo
        match.visitor_start_match_elo = logged_user.elo   
        
        db.commit()
        db.refresh(match)
        
        logging.info(f"Joined successfully")
        return match
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error joining match\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error joining match: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")

