from fastapi import APIRouter, HTTPException, status
from dotenv import load_dotenv
from ultralytics import YOLO
from typing import Generator

from app.models.annotators import BaseAnnotator, Detection, LineAnnotator, MarkerAnnotator, VideoConfig, assign_colors_to_balls_colour_model
from app.models.custom_color import Color

import shutil, math, cv2, os, uuid, numpy as np 

from app.utils.literals import (
    INTERNAL_SERVER_ERROR,
    NOT_POSSIBLE_TO_RECOGNISE_PLAY_OF_VIDEO,
    VIDEO_TOO_LONG,
)

load_dotenv()

SNOOKER_TABLE_MAP = os.getenv("SNOOKER_TABLE_MAP")
KEYPOINTS_MODEL_ROUTE = os.getenv("KEYPOINTS_MODEL_ROUTE")
COLOUR_BALL_MODEL_ROUTE = os.getenv("COLOUR_BALL_MODEL_ROUTE")
PLAYS_IMAGES_DIRECTORY = os.getenv("PLAYS_IMAGES_DIRECTORY")
PROCESSED_VIDEOS_DIRECTORY = os.getenv("PROCESSED_VIDEOS_DIRECTORY")

ball_colour_model = YOLO(COLOUR_BALL_MODEL_ROUTE)
keypoints_model = YOLO(KEYPOINTS_MODEL_ROUTE)

POCKETS = {
        "BottomLeft": [44, 1837],
        "BottomRight": [945, 1837],
        "MediumLeft": [44, 941],
        "MediumRight": [945, 941],
        "TopLeft": [44, 40],
        "TopRight": [945, 40]
    }

COLORS = {
            "RED": 'ROJO',
            "WHITE": 'BLANCO',
            "BLUE": 'AZUL',
            "PINK": 'ROSA',
            "BLACK": 'NEGRO',
            "GREEN": 'VERDE',
            "YELLOW": 'AMARILLO',
            "BROWN": 'MARRÓN'
        }

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

# PROCESS VIDEO
def generate_frames(video_file: str) -> Generator[np.ndarray, None, None]:
    video = cv2.VideoCapture(video_file)

    while video.isOpened():
        success, frame = video.read()

        if not success:
            break

        yield frame

    video.release()
  
def get_keypoints_info():
    
    #classes_names_dic = keypoints mapping in model
    keypoints_dict = {0:'BottomLeft', 1:'BottomRight',2:'IntersectionLeft',3:'IntersectionRight',4:'MediumLeft',5:'MediumRight',6:'SemicircleLeft',7:'SemicircleRight',8:'TopLeft',9:'TopRight'}
    #keypoints_map_pos = keypoints positions dictionary
    keypoints_coords = {
                        "BottomLeft":[44,1837],
                        "BottomRight":[945,1837],
                        "IntersectionLeft":[53,419],
                        "IntersectionRight":[934,419],
                        "MediumLeft":[44,941],
                        "MediumRight":[945,941],
                        "SemicircleLeft":[347,419],
                        "SemicircleRight":[639,419],
                        "TopLeft":[44,40],
                        "TopRight":[945,40]
                        }

    return keypoints_dict, keypoints_coords

def delete_repeated_or_bad_detected_keypoints(prediction):
    conf = prediction.boxes.conf.cpu().numpy()              
    xywh = prediction.boxes.xywh.cpu().numpy()              
    cls = prediction.boxes.cls.cpu().numpy()              
    
    # Calculamos los centros de cada predicción
    centers = [(box[0], box[1]) for box in xywh]  # (center_x, center_y)
    
    positions_to_delete = []

    # Verificación de puntos duplicados
    for i, point_i in enumerate(cls):
        for j, point_j in enumerate(cls):
            if i == j or i in positions_to_delete or j in positions_to_delete:
                continue

            # Si los puntos son del mismo tipo
            if point_i == point_j:
                # Calcular la diferencia en las coordenadas x y y
                x_diff = abs(centers[i][0] - centers[j][0])
                y_diff = abs(centers[i][1] - centers[j][1])

                if x_diff > y_diff:  # Mayor diferencia en x
                    if point_i in [0, 4, 2, 6, 8]:  # Left points: BottomLeft, MediumLeft, IntersectionLeft, SemicircleLeft, TopLeft
                        if centers[i][0] > centers[j][0]:  # El punto más a la izquierda es el correcto
                            positions_to_delete.append(i)
                        else:
                            positions_to_delete.append(j)
                    elif point_i in [1, 5, 3, 7, 9]:  # Right points: BottomRight, MediumRight, IntersectionRight, SemicircleRight, TopRight
                        if centers[i][0] < centers[j][0]:  # El punto más a la derecha es el correcto
                            positions_to_delete.append(i)
                        else:
                            positions_to_delete.append(j)
                    else:
                        if conf[i] > conf[j]:
                            positions_to_delete.append(j)
                        else:
                            positions_to_delete.append(i)
                            
                else:  # Mayor diferencia en y
                    if point_i in [0, 1]:  # Bottoms
                        if centers[i][1] < centers[j][1]:  # El punto más abajo es el correcto
                            positions_to_delete.append(i)
                        else:
                            positions_to_delete.append(j)
                    elif point_i in [8, 9]:  # Tops
                        if centers[i][1] > centers[j][1]:  # El punto más arriba es el correcto
                            positions_to_delete.append(i)
                        else:
                            positions_to_delete.append(j)
                    else:
                        if conf[i] > conf[j]:
                            positions_to_delete.append(j)
                        else:
                            positions_to_delete.append(i)

    positions_to_delete = list(set(positions_to_delete))  # Eliminar duplicados
    positions_to_delete.sort(reverse=True) 
    
    if len(cls) > 4:
        low_conf_positions = [index for index, c in enumerate(conf) if c < 0.35]
        conf = np.delete(conf, low_conf_positions, axis=0)
        xywh = np.delete(xywh, low_conf_positions, axis=0)
        cls = np.delete(cls, low_conf_positions, axis=0)

    # Eliminar los puntos incorrectos
    conf = np.delete(conf, positions_to_delete, axis=0)
    xywh = np.delete(xywh, positions_to_delete, axis=0)
    cls = np.delete(cls, positions_to_delete, axis=0)
    
    return cls, xywh

def get_track_of_detections(previous_detections, ball_detections):
    
    new_previous_detections = []
    balls_and_detections = {}
    for ball_detection in ball_detections:
        balls_and_detections[ball_detection.id] = 0
    
    cont = len(ball_detections)
    
    while cont != 0 and (0 in balls_and_detections.values() or len(previous_detections) == len(new_previous_detections)):
        for ball_detection in ball_detections:
            if balls_and_detections[ball_detection.id] == 0:
                min_dist = float('inf')
                closest_previous_detection = None
                center = ball_detection.rect.center.int_xy_tuple
                for previous_detection in previous_detections:
                    previous_center = previous_detection.rect.center.int_xy_tuple
                    dist = math.sqrt((center[0] - previous_center[0]) ** 2 + (center[1] - previous_center[1]) ** 2)
                    if previous_detection.class_name != ball_detection.class_name:
                        dist += 200
                    if min_dist > dist:
                        min_dist = dist
                        closest_previous_detection = previous_detection

                existing = False
                if closest_previous_detection.tracker_id in balls_and_detections.values():
                    existing = True
                    index = None
                    for new_detection in new_previous_detections:
                        if closest_previous_detection.tracker_id == new_detection.tracker_id:
                            second_to_last_tuple, last_tuple = new_detection.centers_list[-2:]
                            previous_distance = math.sqrt((last_tuple[0] - second_to_last_tuple[0])**2 + (last_tuple[1] - second_to_last_tuple[1]) **2)
                                
                            if min_dist < previous_distance:
                                for key,value in balls_and_detections.items():
                                    if value == new_detection.tracker_id:
                                        balls_and_detections[key] = 0
                                        break
                                
                                balls_and_detections[ball_detection.id] = closest_previous_detection.tracker_id
                                index = new_previous_detections.index(new_detection)
                            break
                        
                    if index is not None:
                        detection_to_delete = new_previous_detections[index]
                        detection_to_delete.centers_list.pop()
                        del new_previous_detections[index]
                        
                        new_previous_detections.append(closest_previous_detection)
                        new_previous_detections[-1].abled = True
                        new_previous_detections[-1].rect = ball_detection.rect
                        new_previous_detections[-1].centers_list.append(ball_detection.rect.center.int_xy_tuple)
                                
                if existing is False:
                    balls_and_detections[ball_detection.id] = closest_previous_detection.tracker_id
                    new_previous_detections.append(closest_previous_detection)
                    new_previous_detections[-1].rect = ball_detection.rect
                    new_previous_detections[-1].abled = True
                    new_previous_detections[-1].centers_list.append(ball_detection.rect.center.int_xy_tuple)
            cont -=1 
    
    if len(previous_detections) > len(new_previous_detections):
        for previous_detection in previous_detections:
            if previous_detection.tracker_id not in balls_and_detections.values():
                previous_detection.abled = False
                new_previous_detections.append(previous_detection)

    return new_previous_detections

def get_video_writer(target_video_path: str, video_config: VideoConfig) -> cv2.VideoWriter:
    video_target_dir = os.path.dirname(os.path.abspath(target_video_path))
    os.makedirs(video_target_dir, exist_ok=True)
    return cv2.VideoWriter(
        target_video_path, 
        fourcc=cv2.VideoWriter_fourcc(*"mp4v"), 
        fps=video_config.fps, 
        frameSize=(video_config.width, video_config.height), 
        isColor=True
    )



def process_video(video_file):
    try:
        processed_video_path = os.path.join(PROCESSED_VIDEOS_DIRECTORY, f'{str(uuid.uuid4())}.mp4')
        
        snooker_table_map = cv2.imread(SNOOKER_TABLE_MAP)
        snooker_table_map_aspect_ratio = snooker_table_map.shape[1] / snooker_table_map.shape[0]  # height/width
        
        with open("temp_video.mp4", "wb") as buffer_file:
                shutil.copyfileobj(video_file.file, buffer_file)
        
        base_annotator = BaseAnnotator()
        marker_annotator = MarkerAnnotator(color=Color.from_hex_string('#FFFF00'))
        line_annotator = LineAnnotator()

        frame_iterator = iter(generate_frames(video_file="temp_video.mp4"))

        keypoints_dict, keypoints_coords = get_keypoints_info()
        
        #variables needed inside the loop
        frame_nbr = 0
        table_map_created = False
        video_writer_created = False
        first_video_processed = False
        previous_detections = None
        last_minimap_photo = None
        frames_without_detections = 0
        max_width = 1920
        max_height = 1080
        
        for frame in frame_iterator:
            if frames_without_detections > 10:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=NOT_POSSIBLE_TO_RECOGNISE_PLAY_OF_VIDEO)
            
            if frame_nbr > 450:
                raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail=VIDEO_TOO_LONG)
               
            frame_nbr+=1
            
            #reset tactical map
            snooker_table_map_copy = snooker_table_map.copy()
            
            #ball prediction
            ball_colour_prediction = ball_colour_model(frame)[0]
            if len(ball_colour_prediction.boxes)<1:
                frames_without_detections += 1
            
            #HOMOGRAPHY
            if (frame_nbr == 1 or not table_map_created):
                
                keypoints_prediciton = keypoints_model(frame)[0]
                if len(keypoints_prediciton.boxes)<1:
                    frames_without_detections += 1
            
                keypoints_cls, keypoints_bb_xywh = delete_repeated_or_bad_detected_keypoints(keypoints_prediciton)     # Detected field keypoints (x,y,w,h) bounding boxes and cls
                
                labels_k = list(keypoints_cls)                                                                  # Detected field keypoints labels list
                
                # Convert detected numerical labels to alphabetical labels
                detected_keypoints_labels = [keypoints_dict[i] for i in labels_k]
                
                # Extract detected field keypoints coordiantes on the current frame
                detected_keypoints_labels_src_pts = np.array([list(np.round(keypoints_bb_xywh[i][:2]).astype(int)) for i in range(keypoints_bb_xywh.shape[0])])
                
                # Get the detected field keypoints coordinates on the tactical map
                detected_keypoints_labels_dst_pts = np.array([keypoints_coords[i] for i in detected_keypoints_labels])
                
                if len(detected_keypoints_labels)>3:
                    # Always calculate homography matrix on the first frame or if it is not created in first frame if detected points > 3 
                    homog, _ = cv2.findHomography(detected_keypoints_labels_src_pts, detected_keypoints_labels_dst_pts)     # Calculate homography matrix
                    table_map_created = True
            
            if table_map_created:
                
                ball_detections = Detection.from_results(pred=ball_colour_prediction.boxes, names=ball_colour_prediction.names)
                
                keypoints_detections = Detection.from_results(pred=keypoints_prediciton.boxes, names=keypoints_prediciton.names)

                if not first_video_processed:
                    cont = 1
                    for ball_detection in ball_detections:
                        ball_detection.tracker_id = cont
                        ball_detection.centers_list.append(ball_detection.rect.center.int_xy_tuple)
                        cont += 1 
                    previous_detections = ball_detections
                    first_video_processed = True
                else:
                    previous_detections = get_track_of_detections(previous_detections, ball_detections)
                
                if 'homog' in locals():
                    
                    # Transform ball coordinates from frame plane to tactical map plance using the calculated Homography matrix
                    pred_dst_pts = []                                                           # Initialize balls tactical map coordiantes list
                    for detection in previous_detections:                                       # Loop over balls frame coordiantes
                        pt = np.array(detection.rect.center.int_xy_tuple)
                        pt = np.append(np.array(pt), np.array([1]), axis=0)                     # Covert to homogeneous coordiantes
                        dest_point = np.matmul(homog, np.transpose(pt))                         # Apply homography transofrmation
                        dest_point = dest_point/dest_point[2]                                   # Revert to 2D-coordiantes
                        pred_dst_pts.append(list(np.transpose(dest_point)[:2]))                 # Update players tactical map coordiantes list
                        detection.centers_minimap_list.append(list(np.transpose(dest_point)[:2]))
                    pred_dst_pts = np.array(pred_dst_pts)
                    

                ball_colours = assign_colors_to_balls_colour_model(previous_detections)
                
                i=0
                for detection in previous_detections:
                    if detection.abled == True:
                        ball_colour = ball_colours[detection.id]
                        if ball_colour is not None:
                            colour = Color(ball_colour[0],ball_colour[1],ball_colour[2])
                            
                            if 'homog' in locals():
                                snooker_table_map_copy = cv2.circle(snooker_table_map_copy, (int(pred_dst_pts[i][0]), int(pred_dst_pts[i][1])), radius=15, color=colour.rgb_tuple , thickness=-1)
                                snooker_table_map_copy = line_annotator.annotate_minimap( image = snooker_table_map_copy, detections = previous_detections )
                    i+=1
                    
                last_minimap_photo = snooker_table_map_copy
                
                annotated_image = frame.copy()
                annotated_image = base_annotator.annotate( image = annotated_image, detections = previous_detections )
                annotated_image = marker_annotator.annotate( image = annotated_image, detections = keypoints_detections )
                annotated_image = line_annotator.annotate( image = annotated_image, detections = previous_detections )
                
                # Combine annotated frame and tactical map in one image with colored border separation
                annotated_image=cv2.copyMakeBorder(annotated_image, 40, 10, 10, 10, cv2.BORDER_CONSTANT, value= [255,255,255])
                snooker_table_map_copy = cv2.copyMakeBorder(snooker_table_map_copy, 70, 50, 10, 10, cv2.BORDER_CONSTANT, value= [255,255,255]) 
                
                snooker_table_map_copy = cv2.resize(snooker_table_map_copy, (int(annotated_image.shape[0] * snooker_table_map_aspect_ratio), annotated_image.shape[0]))         
                
                final_img = cv2.hconcat((annotated_image, snooker_table_map_copy)) 

                # Obtener las dimensiones actuales de la imagen
                height, width = final_img.shape[:2]
                aspect_ratio = width / height

                # Redimensionar manteniendo la relación de aspecto
                if width > max_width or height > max_height:
                    if aspect_ratio > 1:
                        # La imagen es más ancha que alta, ajustar al ancho máximo
                        new_width = max_width
                        new_height = int(max_width / aspect_ratio)
                    else:
                        # La imagen es más alta que ancha, ajustar a la altura máxima
                        new_height = max_height
                        new_width = int(max_height * aspect_ratio)

                    # Redimensionar la imagen
                    final_img = cv2.resize(final_img, (new_width, new_height))
    
                if not video_writer_created:
                    final_img_width = final_img.shape[1]
                    final_img_height = final_img.shape[0]
                    
                    cap = cv2.VideoCapture("temp_video.mp4")
        
                    fps = int(cap.get(cv2.CAP_PROP_FPS))
                    video_config = VideoConfig(width=final_img_width, height=final_img_height, fps=fps)
                    cap.release()
                    video_writer =  get_video_writer(target_video_path=processed_video_path, video_config=video_config)
                    video_writer_created = True
                
                video_writer.write(final_img)
                    
        video_writer.release()
        os.remove("temp_video.mp4")
        
        if last_minimap_photo is not None:
            
            photo_path = os.path.join(PLAYS_IMAGES_DIRECTORY, f'{str(uuid.uuid4())}.png')
            cv2.imwrite(photo_path, snooker_table_map_copy)

        detections_serializable = [d.to_dict() for d in previous_detections]
        
        return detections_serializable, photo_path, processed_video_path

    except HTTPException as http_exception:
        raise http_exception

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")


# PROCESS STATISTICS
def calculate_distance(point1, point2):
    return math.sqrt((point1[0] - point2[0])**2 + (point1[1] - point2[1])**2)

def calculate_if_is_pocket_the_closest(point, pockets, given_pocket):
    closest_pocket = None
    min_distance = float('inf')
    
    for pocket_name, pocket_coords in pockets.items():
        distance = calculate_distance(point, pocket_coords)
        if distance < min_distance:
            min_distance = distance
            closest_pocket = pocket_name
            
    return closest_pocket == given_pocket.value

def calculate_real_distance(center1, center2):
    # Define real-world and minimap dimensions
    real_distance_vertical = 3.56  # meters
    real_distance_horizontal = 1.78  # meters
    minimap_height_px = 1882  # pixels
    minimap_width_px = 990  # pixels

    # Calculate the ratios
    vertical_ratio = real_distance_vertical / minimap_height_px
    horizontal_ratio = real_distance_horizontal / minimap_width_px
 
    # Calculate the distance between the two centers in pixels
    dx = center2[0] - center1[0]
    dy = center2[1] - center1[1]
    distance_px = math.sqrt(dx**2 + dy**2)

    # Convert the distance from pixels to meters using the average of the ratios
    real_distance = distance_px * (vertical_ratio + horizontal_ratio) / 2

    return real_distance

def distance_between_points(p1, p2):
    return math.sqrt((p2[0] - p1[0])**2 + (p2[1] - p1[1])**2)

def calculate_angle(center1, center2, keypoint):

    center_pocket = POCKETS[keypoint.value]
    
    # Calcula las distancias entre los puntos
    a = distance_between_points(center1, center2)        # Distancia entre C1 y C2
    b = distance_between_points(center2, center_pocket)  # Distancia entre C2 y K
    c = distance_between_points(center1, center_pocket)  # Distancia entre C1 y K
    
    # Evitar división por cero en casos de precisión numérica
    if a == 0 or b == 0:
        return 0

    # Calcula el coseno del ángulo en C2 usando el Teorema del Coseno
    cos_angle_c2 = (a**2 + b**2 - c**2) / (2 * a * b)
    
    # Asegurar que el coseno esté en el rango válido [-1, 1] por precisión numérica
    cos_angle_c2 = max(-1, min(1, cos_angle_c2))
    
    # Convertir el coseno en un ángulo en radianes
    rad_angle_c2 = math.acos(cos_angle_c2)
    
    # Convertir el ángulo de radianes a grados
    grad_angle_c2 = math.degrees(rad_angle_c2)
    
    return 180 - grad_angle_c2

def process_statistics(video_info, pocket):
    
    try:

        mov_in_frame = []
        for detection in video_info:
            centers_list = detection['centers_minimap_list']
            first_center = None
            prev_center = None
            step = 5  # Paso de 5 para comparar con el centro 5 posiciones más adelante
            
            for index, center in enumerate(centers_list):
                # Asegurarse de que hay al menos 5 centros más adelante
                if index + step < len(centers_list):
                    next_center = centers_list[index + step]  # Centro a 5 posiciones más adelante
                    
                    # Comparar el centro actual con el siguiente centro (5 posiciones más adelante)
                    if prev_center is not None:
                        dist = math.sqrt((next_center[0] - prev_center[0])**2 + (next_center[1] - prev_center[1])**2)
                        
                        if dist > 30:
                            mov_in_frame.append((index, dist, detection['tracker_id'], detection['class_name'], first_center, detection['abled'], centers_list))
                            break
                        
                        prev_center = center
                    else:
                        first_center = center
                        prev_center = center
                else:
                    # No hay suficiente centros para hacer la comparación, salir del bucle
                    break
    
        if len(mov_in_frame) < 2:
            raise HTTPException(status_code=status.HTTP_400_BAD_REQUEST, detail="No ha sido posible analizar el video, revisa la calidad.")
        
        order_list = sorted(mov_in_frame, key=lambda x: x[0])
        first_ball_center = order_list[0][4]
        second_ball_center = order_list[1][4]
        
        first_color_ball = COLORS[order_list[0][3].upper()]
        second_color_ball = COLORS[order_list[1][3].upper()]
        
        ball_paths = {
            "first_ball_path": order_list[0][6],
            "second_ball_path": order_list[1][6],
        }
        
        is_pocket_the_closest = calculate_if_is_pocket_the_closest(order_list[1][6][-1], POCKETS, pocket)
        success = not order_list[1][5] and is_pocket_the_closest
        
        distance =  calculate_real_distance(first_ball_center, second_ball_center)
        angle =  calculate_angle(first_ball_center, second_ball_center, pocket)
    
        return distance, angle, first_color_ball, second_color_ball, success, ball_paths
    
    except HTTPException as http_exception:
        raise http_exception

    except Exception as e:
        raise HTTPException(status_code=status.HTTP_500_INTERNAL_SERVER_ERROR, detail=f"{INTERNAL_SERVER_ERROR}:{str(e)}")
  
