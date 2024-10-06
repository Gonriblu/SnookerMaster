from fastapi import APIRouter, Depends, HTTPException, Query, status
from sqlalchemy import or_
from sqlalchemy.orm import Session, joinedload
from datetime import datetime
from typing import Annotated

from app.models.match import Match
from app.models.join_request import RequestStatus, JoinRequest
from app.models.user import User as DBUser

from app.routers.oauth import  get_current_user

from app.schemas.matches import *
from app.schemas.users import User

from app.db.database import get_db

from app.utils.logger import configure_logging
from app.utils.literals import (
    CANT_ANSWER_THIS_REQUEST,
    CANT_DELETE_THIS_REQUEST,
    CANT_JOIN_YOUR_MATCH,
    INTERNAL_SERVER_ERROR,
    HTTP_EXCEPTION,
    ERROR_500,
    IT_IS_NOT_YOUR_MATCH,
    MATCH_ALREADY_HAS_TWO_PLAYERS,
    MATCH_NOT_FOUND,
    NOW_MUST_BE_BEFORE_MATCH_DATE,
    REQUEST_ALREADY_ANSWERED,
    REQUEST_NOT_FOUND,
    THERE_IS_AN_ACTIVE_REQUEST,
    USER_NOT_FOUND,
    YOU_CANT_MAKE_A_REQUEST_FOR_YOURSELF,
)

import uuid, logging


configure_logging()

requests_router = APIRouter(prefix="/requests",tags=["Requests"])
db_dependency = Annotated[Session, Depends(get_db)]
current_user = Annotated[User, Depends(get_current_user)]

@requests_router.get("/", status_code=status.HTTP_200_OK, responses= {**ERROR_500})
async def get_my_invitations(db: db_dependency, current_user: current_user, 
                           limit: int = Query(10, ge=1, le=100), offset: int = Query(0, ge=0)):
    
    try:
        logging.info(f"Fetching my requests")
        
        current_user_id = current_user.user.id
        
        # Query para todas las requests relacionadas con el usuario actual
        query = db.query(JoinRequest).filter(
            or_(
                JoinRequest.receiver_id == current_user_id,
                JoinRequest.inviter_id == current_user_id
            )
        ).options(
            joinedload(JoinRequest.match).joinedload(Match.local), 
            joinedload(JoinRequest.receiver), 
            joinedload(JoinRequest.inviter)
        ).order_by(
            JoinRequest.request_datetime.desc()
        )
        
        requests = query.all()
        
        # Inicializar listas para las categorías
        sent_requests = []
        received_requests = []

        # Recorrer la lista una vez para categorizar
        for req in requests:
            if req.inviter_id == current_user_id:
                sent_requests.append(req)
            elif req.receiver_id == current_user_id:
                received_requests.append(req)

        # Aplicar paginación a cada conjunto de resultados
        paginated_sent = sent_requests[offset:offset + limit]
        paginated_received = received_requests[offset:offset + limit]
        
        logging.info(f"Fetched my requests")
        return {
            "sent_requests": paginated_sent,
            "received_requests": paginated_received,
        }
    
    except HTTPException as http_exception:
        logging.error(f"Error fetching my requests\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        logging.error(f"Error fetching my requests: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


invite_responses = {
    400: {'description': THERE_IS_AN_ACTIVE_REQUEST},
    400: {'description': MATCH_ALREADY_HAS_TWO_PLAYERS},
    400: {'description': NOW_MUST_BE_BEFORE_MATCH_DATE},
    400: {'description': YOU_CANT_MAKE_A_REQUEST_FOR_YOURSELF},
    400: {'description': IT_IS_NOT_YOUR_MATCH},
    404: {'description': USER_NOT_FOUND},
    404: {'description': MATCH_NOT_FOUND},
}
@requests_router.post("/invite", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **invite_responses})
async def invite(data: Invite, db: db_dependency, current_user: current_user):
    
    try:    
        logging.info(f"Creating request")
        
        user = db.query(DBUser).filter(DBUser.id == data.user_id).first()
        if not user:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=USER_NOT_FOUND)
        
        match = db.query(Match).filter(Match.id == data.match_id).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)
    
        if match.local != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=IT_IS_NOT_YOUR_MATCH)
        
        if match.local == user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=YOU_CANT_MAKE_A_REQUEST_FOR_YOURSELF)
        
        if match.match_datetime < datetime.now():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOW_MUST_BE_BEFORE_MATCH_DATE)
            
        if match.visitor_id is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=MATCH_ALREADY_HAS_TWO_PLAYERS)
        
        existing_request = db.query(JoinRequest).filter(JoinRequest.match_id == match.id, 
                                                        JoinRequest.receiver_id == user.id, 
                                                        JoinRequest.request_status == RequestStatus.PENDING
                                                        ).first()
        if existing_request:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=THERE_IS_AN_ACTIVE_REQUEST)
        
        request = JoinRequest( 
                        id =str(uuid.uuid4()), 
                        inviter = current_user.user,
                        receiver = user,
                        match = match,
                        request_datetime = datetime.now()
        )
        db.add(request)
        db.commit()
        
        logging.info(f"Request created")
        return request
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating request\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating request: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


request_join_responses = {
    400: {'description': THERE_IS_AN_ACTIVE_REQUEST},
    400: {'description': MATCH_ALREADY_HAS_TWO_PLAYERS},
    400: {'description': CANT_JOIN_YOUR_MATCH},
    400: {'description': NOW_MUST_BE_BEFORE_MATCH_DATE},
    404: {'description': MATCH_NOT_FOUND},
}
@requests_router.post("/request-join", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **request_join_responses})
async def request_join(data: MatchId, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Requesting to join match")
        
        match = db.query(Match).filter(Match.id == data.match_id).first()
        if not match:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=MATCH_NOT_FOUND)

        if current_user.user == match.local:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_JOIN_YOUR_MATCH)
            
        if match.match_datetime < datetime.now():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOW_MUST_BE_BEFORE_MATCH_DATE)
            
        if match.visitor_id is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=MATCH_ALREADY_HAS_TWO_PLAYERS)
        
        existing_request = db.query(JoinRequest).filter(JoinRequest.match_id == match.id, 
                                                        JoinRequest.receiver_id == match.local_id, 
                                                        JoinRequest.request_status == RequestStatus.PENDING
                                                        ).first()
        if existing_request:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=THERE_IS_AN_ACTIVE_REQUEST)
        
        request = JoinRequest( 
                        id =str(uuid.uuid4()), 
                        inviter = current_user.user,
                        receiver_id = match.local_id, 
                        match = match, 
                        request_datetime = datetime.now()
        )
        db.add(request)
        db.commit()
        
        logging.info(f"Request made successfully")
        return request
    
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error creating request\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error creating request: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


accept_responses = {
    400: {'description': MATCH_ALREADY_HAS_TWO_PLAYERS},
    400: {'description': NOW_MUST_BE_BEFORE_MATCH_DATE},
    400: {'description': REQUEST_ALREADY_ANSWERED},
    400: {'description': CANT_ANSWER_THIS_REQUEST},
    404: {'description': REQUEST_NOT_FOUND},
}
@requests_router.patch("/accept", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **accept_responses})
async def accept_request(data: RequestId, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Accepting request")
        
        request = db.query(JoinRequest).filter(JoinRequest.id == data.request_id).options(joinedload(JoinRequest.match)).first()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=REQUEST_NOT_FOUND)
        
        if request.receiver != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_ANSWER_THIS_REQUEST)
           
        if request.request_status != RequestStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=REQUEST_ALREADY_ANSWERED)
            
        if request.match.match_datetime < datetime.now():
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOW_MUST_BE_BEFORE_MATCH_DATE)
            
        if request.match.visitor_id is not None:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=MATCH_ALREADY_HAS_TWO_PLAYERS)
        
        if request.match.local == request.inviter:
            request.match.visitor = request.receiver
            request.match.local_start_match_elo = request.inviter.elo
            request.match.visitor_start_match_elo = request.receiver.elo
        else:
            request.match.visitor = request.inviter
            request.match.local_start_match_elo = request.receiver.elo
            request.match.visitor_start_match_elo = request.inviter.elo
        
        request.request_status = RequestStatus.ACCEPTED
        
        db.query(JoinRequest).filter(JoinRequest.match_id == request.match_id, 
                                    JoinRequest.id != request.id
                                    ).update({JoinRequest.request_status: RequestStatus.REJECTED}, synchronize_session=False)
        

        db.commit()
        db.refresh(request)
        
        logging.info(f"Request accepted")
        return request
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error accepting request\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error accepting request: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


reject_responses = {
    400: {'description': REQUEST_ALREADY_ANSWERED},
    400: {'description': CANT_ANSWER_THIS_REQUEST},
    404: {'description': REQUEST_NOT_FOUND},
}
@requests_router.patch("/reject", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **reject_responses})
async def reject_request(data: RequestId, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Rejecting request")
        
        request = db.query(JoinRequest).filter(JoinRequest.id == data.request_id
                                               ).options(joinedload(JoinRequest.match)).first()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=REQUEST_NOT_FOUND)
        
        if request.receiver != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_ANSWER_THIS_REQUEST)
           
        if request.request_status != RequestStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=REQUEST_ALREADY_ANSWERED)
            
        request.request_status = RequestStatus.REJECTED
        
        db.commit()
        db.refresh(request)
        
        logging.info(f"Rejecting request")
        return request
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error rejecting request\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error rejecting request: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


delete_responses = {
    400: {'description': REQUEST_ALREADY_ANSWERED},
    400: {'description': CANT_DELETE_THIS_REQUEST},
    404: {'description': REQUEST_NOT_FOUND},
}
@requests_router.delete("/{request_id}", status_code=status.HTTP_200_OK, responses= {**ERROR_500, **delete_responses})
async def delete_request(request_id:str, db: db_dependency, current_user: current_user):
    
    try:            
        logging.info(f"Deleting request")
        request = db.query(JoinRequest).filter(JoinRequest.id == request_id).first()
        if not request:
            raise HTTPException(status_code=status.HTTP_404_NOT_FOUND, detail=REQUEST_NOT_FOUND)
        
        if request.inviter != current_user.user:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=CANT_DELETE_THIS_REQUEST)
           
        if request.request_status != RequestStatus.PENDING:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=REQUEST_ALREADY_ANSWERED)
            
        db.delete(request)
        db.commit()
        logging.info(f"Request deleted")
        
    except HTTPException as http_exception:
        db.rollback()
        logging.error(f"Error deleting request\nError: {HTTP_EXCEPTION}: {http_exception.detail}")
        raise http_exception
    
    except Exception as e:
        db.rollback()
        logging.error(f"Error deleting request: {str(e)}")
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")

