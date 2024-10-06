from fastapi import FastAPI
from fastapi.staticfiles import StaticFiles
from fastapi.middleware.cors import CORSMiddleware

from app.routers.users import user_router
from app.routers.oauth import oAuth2_router
from app.routers.projects import projects_router
from app.routers.plays import plays_router
from app.routers.matches import matches_router
from app.routers.statistics import statistics_router
from app.routers.requests import requests_router

from app.db.database import Base,engine

import uvicorn

app = FastAPI()

app.mount("/static", StaticFiles(directory="static"), name="static")

app.include_router(user_router)
app.include_router(oAuth2_router)
app.include_router(plays_router)
app.include_router(projects_router)
app.include_router(statistics_router)
app.include_router(matches_router)
app.include_router(requests_router)

def create_tables():
    Base.metadata.create_all(bind = engine)
    
create_tables() 

origins = [
    "*", 
]

app.add_middleware(
    CORSMiddleware,
    allow_origins=origins,
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)
#ARRANQUE
if __name__ == "__main__":
    uvicorn.run("main:app", host="0.0.0.0", port=8000, reload=True)