from io import BytesIO
from fastapi import APIRouter, Depends, File, Form, HTTPException, UploadFile, status
from fastapi.responses import StreamingResponse
from app.db.database import get_db
from sqlalchemy.orm import Session, joinedload
from typing import Annotated
from datetime import datetime
from dotenv import load_dotenv

from app.models.annotators import LineAnnotator
from app.models.project import Project, Pocket
from app.models.play import Play

from app.routers.oauth import  get_current_user

from app.schemas.users import User

from app.utils.video_process import process_statistics, process_video

from app.utils.logger import configure_logging
from app.utils.literals import (
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    ERROR_500,
    NOT_POSSIBLE_TO_RECOGNISE_PLAY_OF_VIDEO,
    PROJECT_NOT_FOUND,
    VIDEO_TOO_LONG,
    YOU_ARE_NOT_THE_OWNER
)

import cv2, uuid, os, logging


configure_logging()
load_dotenv()

PROJECT_IMAGES_DIRECTORY = os.getenv("PROJECT_IMAGES_DIRECTORY")
SNOOKER_TABLE_MAP = os.getenv("SNOOKER_TABLE_MAP")

projects_router = APIRouter(prefix="/projects",tags=["Projects"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[User, Depends(get_current_user)]


@projects_router.post("/new", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def new_project(db: db_dependency, current_user: current_user, name: str = Form(...), description:str = Form(...), photo: UploadFile = File(...)):
    try:
        logging.info(f"Creating project")
        
        photo_path = os.path.join(PROJECT_IMAGES_DIRECTORY, f'{str(uuid.uuid4())}.png')
        
        with open(photo_path, "wb") as image_file:
            image_file.write(photo.file.read())

        new_project = Project(id =str(uuid.uuid4()), creation_date = datetime.now(), photo = photo_path, name = name, description = description, user = current_user.user)
        db.add(new_project)
        db.commit()
        
        logging.info(f"Project created")
        return new_project
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating project\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating project: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


update_project_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.patch("/update", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **update_project_responses})
async def update_project(
    db: db_dependency, current_user: current_user, project_id: str = Form(...),
    name: str = Form(None), description: str = Form(None), photo: UploadFile = File(None)):
    
    try:
        logging.info(f"Updating project")
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        if project.user != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
        
        if photo:
            if project.photo and os.path.exists(project.photo):
                os.remove(project.photo)
                
            new_photo_path = os.path.join(PROJECT_IMAGES_DIRECTORY, f'{str(uuid.uuid4())}.png')
            
            with open(new_photo_path, "wb") as image_file:
                image_file.write(photo.file.read())
            
            project.photo = new_photo_path
        if name:
            project.name = name
        if description:
            project.description = description
        
        db.commit()
        db.refresh(project)
        
        logging.info(f"Project updated")
        return project
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error updating project\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error updating project: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


@projects_router.get("/my_projects", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_my_projects(db: db_dependency, current_user: current_user, limit: int = None):
    try:
        logging.info(f"Fetching projects")
        
        query = db.query(Project).filter(Project.user == current_user.user).order_by(Project.creation_date.desc())
        if limit:
            query = query.limit(limit)
            
        projects = query.all()
        
        if not projects:
            return []
            
        logging.info(f"Fetched {len(projects)} projects")
        return projects
        
    except HTTPException as http_exception:
        logging.error(f"Error fetching my projects\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching my projects: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


get_project_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.get("/{project_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_project_responses})
async def get_project(project_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching project")
        
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        if project.user != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
            
        return project.get_project_details()
        
    except HTTPException as http_exception:
        logging.error(f"Error fetching project\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching project: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


delete_project_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.delete("/delete/{project_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **delete_project_responses})
async def delete_project(project_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Deleting project")
        
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        if project.user != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
        
        logging.info(f"Deleting plays")
        for play in project.plays:
            db.delete(play)
            
        db.delete(project)
        db.commit()
        logging.info(f"Project deleted")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error deleting project\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error deleting project: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


get_plays_of_project_responses = {
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.get("/{project_id}/plays", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **get_plays_of_project_responses})
async def get_plays_of_project(project_id:str, db: db_dependency, current_user: current_user):
    try:
        logging.info(f"Fetching plays")
        
        if project_id == 'All':
            plays = db.query(Play).join(Project).filter(Project.user_id == current_user.user.id).all()
            if not plays:
                return []
            return plays
        
        else:
            project = db.query(Project).filter(Project.id == project_id).options(joinedload(Project.plays)).first()
            if not project:
                raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
            
            if project.user != current_user.user:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
                
            if not project.plays:
                return []
                
        logging.info(f"Fetched {len(project.plays)} plays")
        return project.plays
        
    except HTTPException as http_exception:
        logging.error(f"Error fetching plays\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching plays: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


creating_play_responses = {
    400: {'description': NOT_POSSIBLE_TO_RECOGNISE_PLAY_OF_VIDEO},
    400: {'description': VIDEO_TOO_LONG},
    400: {'description': YOU_ARE_NOT_THE_OWNER},
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.post("/{project_id}/new_play", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **creating_play_responses})
async def new_play(project_id:str, db: db_dependency, current_user: current_user, video_file: UploadFile = File(...), pocket: Pocket = Form(...)):
    try:
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        if project.user != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_ARE_NOT_THE_OWNER)
            
        video_info, photo_path, processed_video_path = process_video(video_file)
        
        distance, angle, first_color_ball, second_color_ball, success, ball_paths = process_statistics(video_info, pocket)
        
        new_play = Play(id =str(uuid.uuid4()), 
                        project = project, 
                        photo = photo_path, 
                        angle = angle, 
                        distance = distance, 
                        processed_video = processed_video_path,
                        success = success, 
                        first_color_ball = first_color_ball, 
                        second_color_ball = second_color_ball, 
                        pocket = pocket.value, 
                        ball_paths = ball_paths, 
                        creation_date = datetime.now())
        
        db.add(new_play)
        db.commit()
        return distance, angle, first_color_ball, second_color_ball, success
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating play\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating play: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


create_minimap_responses = {
    404: {'description': PROJECT_NOT_FOUND},
}
@projects_router.get("/{project_id}/create_minimap", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **create_minimap_responses})
async def create_minimap(project_id:str, db: db_dependency):
    try:
        logging.info(f"Creating minimap")
        
        project = db.query(Project).filter(Project.id == project_id).first()
        if not project:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=PROJECT_NOT_FOUND)
        
        max_width = 1920
        max_height = 1080

        snooker_table_map = cv2.imread(SNOOKER_TABLE_MAP)
        height, width = snooker_table_map.shape[:2]
        aspect_ratio = width / height
        
        line_annotator = LineAnnotator()
        
        for play in project.plays:
            snooker_table_map = line_annotator.annotate_from_ball_info(snooker_table_map, play.first_color_ball, play.ball_paths["first_ball_path"], False)
            snooker_table_map = line_annotator.annotate_from_ball_info(snooker_table_map, play.second_color_ball, play.ball_paths["second_ball_path"], play.success)

        if width > max_width or height > max_height:
            if aspect_ratio > 1:
                new_width = max_width
                new_height = int(max_width / aspect_ratio)
            else:
                new_height = max_height
                new_width = int(max_height * aspect_ratio)

        final_img = cv2.resize(snooker_table_map, (new_width, new_height))

        _, img_encoded = cv2.imencode('.png', final_img)
        img_bytes = BytesIO(img_encoded.tobytes())

        logging.info(f"Mnimap created")
        return StreamingResponse(img_bytes, media_type="image/png")

    except HTTPException as http_exception:
        logging.error(f"Error creating minimap\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error creating minimap: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")
