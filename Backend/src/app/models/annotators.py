from __future__ import annotations
from dataclasses import dataclass
from typing import Tuple, Optional, List, Dict

from app.models.custom_color import Color

import cv2, uuid, numpy as np

THICKNESS = 2

KNOWN_COLORS = {
    "RED": (0, 0, 255),
    "WHITE": (255, 255, 255),
    "BLUE": (255, 0, 0),
    "PINK": (255, 192, 203),
    "BLACK": (0, 0, 0),
    "GREEN": (0, 255, 0),
    "YELLOW": (0, 255, 255),
    "BROWN": (165, 42, 42)
}


color_spanish_to_english = {
    'ROJO': "RED",
    'BLANCO': "WHITE",
    'AZUL': "BLUE",
    'ROSA': "PINK",
    'NEGRO': "BLACK",
    'VERDE': "GREEN",
    'AMARILLO': "YELLOW",
    'MARRÓN': "BROWN"
}

@dataclass(frozen=True)
class VideoConfig:
    fps: float
    width: int
    height: int

# geometry utilities
@dataclass(frozen=True)
class Point:
    x: float
    y: float
    
    @property
    def int_xy_tuple(self) -> Tuple[int, int]:
        return int(self.x), int(self.y)

@dataclass(frozen=True)
class Rect:
    x: float
    y: float
    width: float
    height: float

    @property
    def min_x(self) -> float:
        return self.x
    
    @property
    def min_y(self) -> float:
        return self.y
    
    @property
    def max_x(self) -> float:
        return self.x + self.width
    
    @property
    def max_y(self) -> float:
        return self.y + self.height
        
    @property
    def top_left(self) -> Point:
        return Point(x=self.x, y=self.y)
    
    @property
    def bottom_right(self) -> Point:
        return Point(x=self.x + self.width, y=self.y + self.height)

    @property
    def bottom_center(self) -> Point:
        return Point(x=self.x + self.width / 2, y=self.y + self.height)

    @property
    def top_center(self) -> Point:
        return Point(x=self.x + self.width / 2, y=self.y)

    @property
    def center(self) -> Point:
        return Point(x=self.x + self.width / 2, y=self.y + self.height / 2)

    def to_dict(self):
            return {
                "x": self.x,
                "y": self.y,
                "width": self.width,
                "height": self.height
            }
# detection utilities
@dataclass
class Detection:
    id : str
    rect: Rect
    class_id: int
    class_name: str
    confidence: float
    abled: bool
    colors_list: Optional[List[str]] = None
    centers_list: Optional[List[(int,int)]] = None
    centers_minimap_list: Optional[List[(int,int)]] = None
    color: Optional[Color] = None
    tracker_id: Optional[int] = None

    @classmethod
    def from_results(cls, pred: np.ndarray, names: Dict[int, str]) -> List[Detection]:
        result = []
        for i in range(len(pred.cls)):
            x_min, y_min, x_max, y_max = pred.xyxy[i]
            rect = Rect(x=float(x_min), y=float(y_min), width=float(x_max - x_min), height=float(y_max - y_min))
            result.append(Detection(
                id =  str(uuid.uuid4()),
                rect=rect,
                class_id=int(pred.cls[i]),
                abled = True,
                centers_list = [],
                centers_minimap_list = [],
                colors_list=[names[int(pred.cls[i])]],
                class_name=names[int(pred.cls[i])],
                confidence=float(pred.conf[i])
            ))
        return result
    
    def update_color(self):
        if self.colors_list:
            
            color_counts = {}
            for color_str in self.colors_list:
                if color_counts[color_str]:
                    color_counts[color_str] += 1
                else:
                    color_counts[color_str] = 1
                    
            most_common_color = max(color_counts, key=color_counts.get)
            self.color = Color.from_string(most_common_color)
            
    def to_dict(self):
        return {
            "id": self.id,
            "rect": self.rect.to_dict(),
            "class_id": self.class_id,
            "class_name": self.class_name,
            "confidence": self.confidence,
            "abled": self.abled,
            "colors_list": self.colors_list,
            "centers_list": self.centers_list,
            "centers_minimap_list": self.centers_minimap_list,
            "color": self.color,
            "tracker_id": self.tracker_id
        }
        

def draw_filled_rect(image: np.ndarray, rect: Rect, color: Color) -> np.ndarray:
    cv2.rectangle(image, rect.top_left.int_xy_tuple, rect.bottom_right.int_xy_tuple, color.bgr_tuple, -1)
    return image

def draw_polygon(image: np.ndarray, countour: np.ndarray, color: Color, thickness: int = 2) -> np.ndarray:
    cv2.drawContours(image, [countour], 0, color.bgr_tuple, thickness)
    return image

def draw_filled_polygon(image: np.ndarray, countour: np.ndarray, color: Color) -> np.ndarray:
    cv2.drawContours(image, [countour], 0, color.bgr_tuple, -1)
    return image

def draw_line(image: np.ndarray, start_point: Tuple[int, int], end_point: Tuple[int, int], color: Color, thickness: int = 2) -> np.ndarray:
    return cv2.line(image, start_point, end_point, color.rgb_tuple, thickness)

def draw_ellipse(image: np.ndarray, tracker_id:str,rect: Rect, color: Color, thickness: int = 2) -> np.ndarray:
    cv2.ellipse(
        image,
        center=rect.bottom_center.int_xy_tuple,
        axes=(int(rect.width), int(0.35 * rect.width)),
        angle=0.0,
        startAngle=-45,
        endAngle=235,
        color=color.rgb_tuple,
        thickness=thickness,
        lineType=cv2.LINE_4
    )
    cv2.putText(image, str(tracker_id), rect.bottom_center.int_xy_tuple, cv2.FONT_HERSHEY_SIMPLEX, 0.7, color.bgr_tuple, thickness, 2, False)
    
    return image

# base annotator
@dataclass
class BaseAnnotator:
    thickness: int = THICKNESS

    def annotate(self, image: np.ndarray, detections: List[Detection]) -> np.ndarray:
        annotated_image = image.copy()
        ball_colours = assign_colors_to_balls_colour_model(detections)
        for detection in detections:
            if detection.abled is True:
                ball_color = ball_colours[detection.id]
                #color = Color(255,255,255)
                color = Color(ball_color[0],ball_color[1],ball_color[2])
                annotated_image = draw_ellipse(
                    image=image,
                    rect=detection.rect,
                    tracker_id = detection.tracker_id,
                    color=color,
                    thickness=self.thickness
                )
        return annotated_image

@dataclass
class LineAnnotator:
    thickness: int = THICKNESS

    def annotate(self, image: np.ndarray, detections: List[Detection]) -> np.ndarray:
        annotated_image = image.copy()
        ball_colours = assign_colors_to_balls_colour_model(detections)
        for detection in detections:
            previous_point = None
            ball_color = ball_colours[detection.id]
            color = Color(ball_color[0], ball_color[1], ball_color[2])
            for center in detection.centers_list:
                if previous_point is not None:
                    annotated_image = draw_line(
                        image=annotated_image,
                        start_point=previous_point,
                        end_point=center,
                        thickness=self.thickness,
                        color=color)
                previous_point = center
        return annotated_image

    def annotate_minimap(self, image: np.ndarray, detections: List[Detection]) -> np.ndarray:
        annotated_image = image.copy()
        ball_colours = assign_colors_to_balls_colour_model(detections)
        for detection in detections:
            previous_point = None
            ball_color = ball_colours[detection.id]
            color = Color(ball_color[0], ball_color[1], ball_color[2])
            for center in detection.centers_minimap_list:
                if previous_point is not None:
                    annotated_image = draw_line(
                        image=annotated_image,
                        start_point=previous_point,
                        end_point=(int(center[0]),int(center[1])),
                        thickness=self.thickness,
                        color=color)
                previous_point = (int(center[0]),int(center[1]))
        return annotated_image
    
    def annotate_from_ball_info(self, image: np.ndarray, color: str, centers: List[(float,float)], isFinallyDisabled: bool ) -> np.ndarray:
        annotated_image = image.copy()
        
        color_in_english = color_spanish_to_english[color]
        ball_color = KNOWN_COLORS[color_in_english] 
        rgb_color = Color(ball_color[0], ball_color[1], ball_color[2])
        
        previous_point = None
        for center in centers:
            
            if previous_point is not None:
                annotated_image = draw_line(
                    image=annotated_image,
                    start_point=previous_point,
                    end_point=(int(center[0]),int(center[1])),
                    thickness=self.thickness,
                    color=rgb_color)

            previous_point = (int(center[0]),int(center[1]))
        
        annotated_image = cv2.circle(annotated_image, (int(centers[0][0]), int(centers[0][1])), radius=15, color=rgb_color.rgb_tuple , thickness=3)
        if not isFinallyDisabled:
            annotated_image = cv2.circle(annotated_image, (int(centers[-1][0]), int(centers[-1][1])), radius=15, color=rgb_color.rgb_tuple , thickness=-1)
        
        return annotated_image

MARKER_CONTOUR_THICKNESS = 2
MARKER_WIDTH = 20
MARKER_HEIGHT = 20
MARKER_MARGIN = 10
MARKER_CONTOUR_COLOR = Color.from_hex_string('#FFFF00')

def calculate_marker(anchor: Point) -> np.ndarray:
    x, y = anchor.int_xy_tuple
    return(np.array([
        [x - MARKER_WIDTH // 2, y - MARKER_HEIGHT - MARKER_MARGIN],
        [x, y - MARKER_MARGIN],
        [x + MARKER_WIDTH // 2, y - MARKER_HEIGHT - MARKER_MARGIN]
    ]))


def draw_marker(image: np.ndarray, anchor: Point, color: Color) -> np.ndarray:
    possession_marker_countour = calculate_marker(anchor=anchor)
    image = draw_filled_polygon(
        image=image, 
        countour=possession_marker_countour, 
        color=color)
    image = draw_polygon(
        image=image, 
        countour=possession_marker_countour, 
        color=MARKER_CONTOUR_COLOR,
        thickness=MARKER_CONTOUR_THICKNESS)
    return image


def assign_colors_to_balls_colour_model(detections):

    balls_dict = {}

    for detection in detections:
        color_name = detection.class_name.upper()
        if color_name in KNOWN_COLORS:
            balls_dict[detection.id] = KNOWN_COLORS[color_name]
        else:
            balls_dict[detection.id] = None
            
    return balls_dict

@dataclass
class MarkerAnnotator:

    color: Color

    def annotate(self, image: np.ndarray, detections: List[Detection]) -> np.ndarray:
        annotated_image = image.copy()
        for detection in detections:
            annotated_image = draw_marker(
                image=image, 
                anchor=detection.rect.top_center,
                color=self.color)
        return annotated_image
    
