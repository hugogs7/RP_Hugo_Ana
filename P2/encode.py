import sys

def parse_grid(filename):
    try:
        with open(filename, 'r') as f:
            lines = [line.strip() for line in f if line.strip()]
    except FileNotFoundError:
        print(f"Error: File {filename} not found.")
        return

    rows = len(lines)
    cols = len(lines[0])

    print(f"rows({rows}).")
    print(f"cols({cols}).")

    for r, line in enumerate(lines):
        for c, char in enumerate(line):
            # Asumimos que la coordenada (0,0) es arriba-izquierda
            # Generamos celda valida siempre
            print(f"cell({r},{c}).")

            if char == '.':
                pass
            elif char == '#':
                print(f"building({r},{c}).")
            elif char == 'X':
                print(f"station({r},{c}).")
            elif char.islower(): # Pasajeros a, b, c...
                print(f"init(passenger,{char},{r},{c}).")
            elif char.isdigit(): # Taxis 1, 2...
                print(f"init(taxi,{char},{r},{c}).")
                # Asumimos que el taxi empieza vacio
            else:
                pass # Caracteres desconocidos

if __name__ == "__main__":
    if len(sys.argv) < 2:
        print("Usage: python encode.py <input_file>")
    else:
        parse_grid(sys.argv[1])