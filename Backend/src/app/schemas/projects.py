from pydantic import BaseModel
from typing import Optional, Union

class UpdateProject(BaseModel):
    id :str
    name: Optional[Union[str, None]] = None
    description:Optional[Union[str, None]] = None