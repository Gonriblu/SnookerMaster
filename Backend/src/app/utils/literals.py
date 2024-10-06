INTERNAL_SERVER_ERROR = 'Error interno del servidor.'
HTTP_EXCEPTION = 'HTTPException'
ERROR_500 = {
    500: {'description': INTERNAL_SERVER_ERROR}
}
# OAUTH
INCORRECT_USER_OR_PASSWORD = "Usuario o contraseña incorrecta"
EMAIL_NOT_FOUND_IN_TOKEN = "No se ha encontrado un email en el token"
INACTIVE_USER = "Usuario inactivo"
PLEASE_LOGIN_AGAIN = "Por favor, vuelva a iniciar sesión."

# USERS
USER_NOT_FOUND = "Usuario no encontrado"
ALREADY_REGISTERED_EMAIL = "Email ya registrado"
ALREADY_CONFIRMED_EMAIL = "Email ya confirmado"
BAD_PASSWORD = "La contraseña debe tener al menos 8 caracteres, una minúscula, una mayúscula, un número y un caracter especial"
INCORRECT_PASSWORD = "Contraseña incorrecta"
PASSWORD_DOESNT_MATCH = "Las contraseñas no coinciden"
CODE_NOT_FOUND = "Código no encontrado"
INVALID_CODE = "Código no válido"
CODE_HAS_EXPIRED = "El código ha caducado"
NOT_AUTHORIZED = "No autorizado"

# MATCHES
LATITUDE_AND_LONGITUD_MUST_BE_PROVIDED = "Si se proporciona latitud, también debe proporcionarse longitud y viceversa."
MATCH_NOT_FOUND = 'Partida no encontrada'
CANT_DELETE_MATCH = "No puedes borrar este partido"
MATCH_ALREADY_PLAYED = "Partido ya jugado"
DATE_MUST_BE_AFTER_NOW = "La fecha tiene que ser mayor a la actual"
INVALID_FRAMES_SUM = "La suma de los frames no coincide con la del partido"
NOT_YOUR_MATCH = "No has participado en este partido"
MATCH_ALREADY_HAS_TWO_PLAYERS = "Ya hay un visitante"
CANT_JOIN_YOUR_MATCH = "No puedes unirte a tu partido"

# PROJECTS
PROJECT_NOT_FOUND = "Proyecto no encontrado"
YOU_ARE_NOT_THE_OWNER = "No eres el propietario"
NOT_POSSIBLE_TO_RECOGNISE_PLAY_OF_VIDEO = "No es posible reconocer la jugada del video."
VIDEO_TOO_LONG = "Video demasiado largo."

# PLAYS
PLAY_NOT_FOUND = "Jugada no encontrada"
VIDEO_NOT_FOUND = "Video no encontrado"

# REQUESTS
REQUEST_NOT_FOUND = "Invitación no encontrada"
CANT_DELETE_THIS_REQUEST = "No puedes borrar esta invitación"
CANT_ANSWER_THIS_REQUEST = "No puedes responder a esta invitación"
REQUEST_ALREADY_ANSWERED = "Invitación ya respondida"
THERE_IS_AN_ACTIVE_REQUEST = "Ya hay una invitacion activa"
NOW_MUST_BE_BEFORE_MATCH_DATE = "La fecha actual es mayor a la fecha de la partida"
IT_IS_NOT_YOUR_MATCH = "No es tu partida"
YOU_CANT_MAKE_A_REQUEST_FOR_YOURSELF = "No puedes invitarte a ti mismo"