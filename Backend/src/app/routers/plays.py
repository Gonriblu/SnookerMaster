from fastapi import APIRouter, Depends, HTTPException, status
from fastapi.responses import FileResponse 
from sqlalchemy.orm import Session, joinedload
from typing import Annotated

from app.models.project import Project
from app.models.play import Play

from app.routers.oauth import  get_current_user

from app.schemas.users import User

from app.db.database import get_db

from app.utils.logger import configure_logging
from app.utils.literals import (
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    ERROR_500,
    PLAY_NOT_FOUND,
    VIDEO_NOT_FOUND,
    YOU_ARE_NOT_THE_OWNER
)

import os, logging


configure_logging()

plays_router = APIRouter(prefix="/plays",tags=["Plays"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[User, Depends(get_current_user)]


get_video_responses = {
    404: {'description': PLAY_NOT_FOUND},
    404: {'description': VIDEO_NOT_FOUND}
}
@plays_router.get("/get_video/{play_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_video_responses})
async def get_video(play_id: str, db: db_dependency):
    
    try:
        logging.info(f"Fetching video")
        play = db.query(Play).filter(Play.id == play_id).first()
        if not play:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAY_NOT_FOUND)
        
        video_path = f"{play.processed_video}"
        if not os.path.exists(video_path):
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=VIDEO_NOT_FOUND)

        logging.info(f"Fetched video")
        return FileResponse(video_path, media_type="video/mp4", filename=f"play_{play_id}.mp4")
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching video\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching video: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


@plays_router.get("/my_plays", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_my_plays(db: db_dependency, current_user: current_user, limit: int = None):
    try:
        logging.info(f"Fetching my plays")
        
        query = db.query(Play).join(Project).filter(
            Project.user_id == current_user.user.id).order_by(Play.creation_date.desc())
        
        if limit:
            query = query.limit(limit)
            
        plays = query.all()
        
        if not plays:
            return [] 
        
        logging.info(f"Found {len(plays)} plays")
        return plays
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error fetching my plays\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error fetching my plays: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


get_play_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PLAY_NOT_FOUND},
}
@plays_router.get("/{play_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_play_responses})
async def get_play(play_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching play")
        
        play = db.query(Play).filter(Play.id == play_id).options(joinedload(Play.project)).first()
        if not play:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAY_NOT_FOUND)
        
        if play.project.user_id != current_user.user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
            
        logging.info(f"Play found")
        return play
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error fetching play\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error fetching play: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


delete_play_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PLAY_NOT_FOUND},
}
@plays_router.delete("/{play_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **delete_play_responses})
async def delete_play(play_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Deleting play")
        
        play = db.query(Play).filter(Play.id == play_id).options(joinedload(Play.project)).first()
        if not play:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAY_NOT_FOUND)
        
        if play.project.user_id != current_user.user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
            
        db.delete(play)
        db.commit()
        logging.info(f"Play deleted seccessfully")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error deleting play\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error deleting play: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")
