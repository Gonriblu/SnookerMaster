from fastapi import APIRouter, Depends, HTTPException, status
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
    PROJECT_NOT_FOUND,
    YOU_ARE_NOT_THE_OWNER
)

import logging


configure_logging()

statistics_router = APIRouter(prefix="/statistics",tags=["Statistics"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[User, Depends(get_current_user)]


@statistics_router.get("/my_general_statistics", status_code=status.HTTP_200_OK,  responses= {**ERROR_500})
async def my_general_statistics(db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching my general statistics")
        
        return current_user.user.get_statistics()
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching my general statistics\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching my general statistics: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


project_statistics_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND}
}
@statistics_router.get("/projects/{project_id}", status_code=status.HTTP_200_OK,  responses= {**ERROR_500, **project_statistics_responses})
async def project_statistics(project_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching project statistics")
        
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        if project.user != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
        
        return project.get_statistics()
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching project statistics\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching project statistics: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


play_statistics_responses = {
    400: {'description': PLAY_NOT_FOUND},
    404: {'description': PROJECT_NOT_FOUND}
}
@statistics_router.get("/plays/{play_id}", status_code=status.HTTP_200_OK,  responses= {**ERROR_500, **play_statistics_responses})
async def play_statistics(play_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching play statistics")
        play = db.query(Play).filter(Play.id == play_id).options(joinedload(Play.project)).first()
        if not play:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PLAY_NOT_FOUND)
        
        if play.project.user_id != current_user.user.id:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
        
        return play.get_statistics()
        
    except HTTPException as http_exception:
        logging.error(f"Error fetching play statistics\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching play statistics: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")
