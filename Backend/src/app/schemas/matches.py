from pydantic import BaseModel
from typing import Optional, Union
from datetime import datetime

class NewMatch(BaseModel):
    match_datetime: datetime
    latitude: float
    longitude: float
    formatted_location: str
    frames: int
    public: bool

class Result(BaseModel):
    match_id: str
    local_frames: int
    visitor_frames: int

class ConfirmResult(BaseModel):
    match_id: str
    agreed: bool
    local_frames: Optional[Union[int, None]] = None
    visitor_frames: Optional[Union[int, None]] = None
    
class Invite(BaseModel):
    match_id: str
    user_id: str
    
class MatchId(BaseModel):
    match_id: str

class RequestId(BaseModel):
    request_id: str