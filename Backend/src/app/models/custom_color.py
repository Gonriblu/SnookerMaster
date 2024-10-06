from __future__ import annotations
from dataclasses import dataclass
from typing import Tuple

@dataclass(frozen=True)
class Color:
    r: int
    g: int
    b: int
        
    @property
    def bgr_tuple(self) -> Tuple[int, int, int]:
        return self.b, self.g, self.r

    @property
    def rgb_tuple(self) -> Tuple[int, int, int]:
        return self.r, self.g, self.b
    
    @classmethod
    def from_hex_string(cls, hex_string: str) -> Color:
        r, g, b = tuple(int(hex_string[1 + i:1 + i + 2], 16) for i in (0, 2, 4))
        return Color(r=r, g=g, b=b)
    
    @classmethod
    def from_string(cls, color: str) -> Color:
        
        known_colors = {
        "ROJO": (0, 0, 255),
        "BLANCO": (255, 255, 255),
        "AZUL": (255, 0, 0),
        "ROSA": (255, 192, 203),
        "NEGRO": (0, 0, 0),
        "VERDE": (0, 255, 0),
        "AMARILLO": (255, 255, 0),
        "MARRON": (165, 42, 42)
        }
        
        color_string_upper = color.upper() 
        if color_string_upper in known_colors:
            r, g, b = known_colors[color_string_upper]
            return Color(r=r, g=g, b=b)

