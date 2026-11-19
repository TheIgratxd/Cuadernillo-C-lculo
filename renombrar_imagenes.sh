
#!/usr/bin/env bash
set -euo pipefail

# Ejecutar desde la raíz del proyecto:
# ./renombrar_imagenes.sh

IMG_DIR="imagenes"
TEX="Cuadernillo_resuelto.tex"

python3 - "$IMG_DIR" "$TEX" <<'PY'
from pathlib import Path
import re
import shutil
import sys

img_dir = Path(sys.argv[1])
tex_file = Path(sys.argv[2])

# Formato: (nombre_original, nombre_nuevo, posicion_de_grafica)

mapping = [
    # TEMA 1 - Dominio y rango
    ("Screenshot 2026-09-08 213732.png", "tema1_1_a.png", 1),
    ("Screenshot 2026-09-08 215257.png", "tema1_1_b.png", 2),
    ("Screenshot 2026-09-08 215454.png", "tema1_1_c.png", 3),
    ("Screenshot 2026-09-08 220048.png", "tema1_1_d.png", 4),
    ("Screenshot 2026-09-08 220302.png", "tema1_1_e.png", 5),

    # TEMA 1 - Dominio
    ("Screenshot 2026-09-08 235238.png", "tema1_2_a.png", 6),
    ("Screenshot 2026-09-08 221041.png", "tema1_2_b.png", 7),
    ("Screenshot 2026-09-08 222023.png", "tema1_2_c.png", 8),
    ("Screenshot 2026-09-08 221456.png", "tema1_2_d.png", 9),
    ("Screenshot 2026-09-08 222134.png", "tema1_2_e.png", 10),

    # TEMA 2 - Funciones constantes
    ("Screenshot 2026-09-15 191553.png", "tema2_constantes.png", 16),

    # TEMA 2 - Funciones lineales
    ("Screenshot 2026-09-15 194922.png", "tema2_lineales_1.png", 17),
    ("Screenshot 2026-09-15 195049.png", "tema2_lineales_2.png", 18),
    ("Screenshot 2026-09-15 195148.png", "tema2_lineales_3.png", 19),

    # TEMA 2 - Funciones cuadráticas
    ("Screenshot 2026-09-15 195746.png", "tema2_cuadraticas_1.png", 20),
    ("Screenshot 2026-09-15 200103.png", "tema2_cuadraticas_2.png", 21),
    ("Screenshot 2026-09-15 200532.png", "tema2_cuadraticas_3.png", 22),

    # TEMA 2 - Polinomios de grado superior
    ("Screenshot 2026-09-15 203318.png", "tema2_polinomios_1.png", 23),
    ("Screenshot 2026-09-15 203536.png", "tema2_polinomios_2.png", 24),

    # TEMA 2 - Funciones racionales
    ("Screenshot 2026-09-15 203708.png", "tema2_racionales_1.png", 25),
    ("Screenshot 2026-09-15 204417.png", "tema2_racionales_2.png", 26),

    # TEMA 2 - Funciones radicales
    ("Screenshot 2026-09-15 204700.png", "tema2_radicales_1.png", 27),
    ("Screenshot 2026-09-15 205105.png", "tema2_radicales_2.png", 28),

    # TEMA 2 - Funciones exponenciales
    ("Screenshot 2026-09-15 211800.png", "tema2_exponenciales_1.png", 29),
    ("Screenshot 2026-09-15 212116.png", "tema2_exponenciales_2.png", 30),

    # TEMA 2 - Funciones logarítmicas
    ("Screenshot 2026-09-15 212558.png", "tema2_logaritmicas_1.png", 31),
    ("Screenshot 2026-09-15 212742.png", "tema2_logaritmicas_2.png", 32),

    # TEMA 2 - Funciones trigonométricas
    ("Screenshot 2026-09-15 213240.png", "tema2_trigonometricas_1.png", 33),
    ("Screenshot 2026-09-15 215007.png", "tema2_trigonometricas_2.png", 34),
    ("Screenshot 2026-09-15 215922.png", "tema2_trigonometricas_inversas.png", 35),

    # TEMA 3 - Transformaciones
    ("Screenshot 2026-09-08 232632.png", "tema3_transformaciones_parabola.png", 36),
    ("Screenshot 2026-09-08 234204.png", "tema3_transformaciones_raiz.png", 37),

    # TEMA 4 - Límites
    ("Screenshot 2026-11-07 232504.png", "tema4_limites_ejercicio_1.png", 38),
]

# Comprobaciones previas
if not img_dir.is_dir():
    sys.exit(f"ERROR: No existe la carpeta {img_dir}")

if not tex_file.is_file():
    sys.exit(f"ERROR: No existe {tex_file}")

missing = [
    old for old, new, pos in mapping
    if not (img_dir / old).is_file()
]

existing = [
    new for old, new, pos in mapping
    if (img_dir / new).exists()
]

if missing:
    print("ERROR: No se encontraron estas imágenes:")
    for name in missing:
        print(" -", name)
    sys.exit(1)

if existing:
    print("ERROR: Ya existen algunos nombres de destino:")
    for name in existing:
        print(" -", name)
    sys.exit(1)

content = tex_file.read_text(encoding="utf-8")

if r"\begin{document}" not in content:
    sys.exit("ERROR: No se encontró el inicio del documento.")

# Solo contar las llamadas a grafica dentro del documento.
body_start = content.index(r"\begin{document}")
body = content[body_start:]

matches = list(re.finditer(r"\\grafica\b", body))

max_position = max(pos for old, new, pos in mapping)

if len(matches) < max_position:
    sys.exit(
        f"ERROR: Se esperaban al menos {max_position} espacios "
        f"de gráfica, pero solo hay {len(matches)}."
    )

# Posición de gráfica -> nombre de imagen.
replacements = {
    pos: new for old, new, pos in mapping
}

counter = 0

def replace_graph(match):
    global counter
    counter += 1

    if counter not in replacements:
        return match.group(0)

    filename = replacements[counter]

    return (
        r"\begin{center}" + "\n"
        r"\includegraphics[width=0.86\textwidth]"
        + "{imagenes/" + filename + "}\n"
        r"\end{center}"
    )

new_body = re.sub(
    r"\\grafica\b",
    replace_graph,
    body
)

# Crear respaldo antes de modificar el archivo.
backup = tex_file.with_suffix(tex_file.suffix + ".bak")

if backup.exists():
    sys.exit(f"ERROR: Ya existe el respaldo {backup}. No se modificó nada.")

shutil.copy2(tex_file, backup)

# Renombrar las imágenes.
for old, new, pos in mapping:
    (img_dir / old).rename(img_dir / new)

# Actualizar las referencias en LaTeX.
tex_file.write_text(
    content[:body_start] + new_body,
    encoding="utf-8"
)

print("\n========================================")
print(" PROCESO COMPLETADO")
print("========================================")
print(f"Imágenes renombradas: {len(mapping)}")
print(f"Referencias insertadas: {len(mapping)}")
print(f"Espacios de gráfica restantes: {counter - len(mapping)}")
print(f"Archivo actualizado: {tex_file}")
print(f"Respaldo original: {backup}")
print("========================================")
PY
