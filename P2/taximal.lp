% --- STATIC KNOWLEDGE (ALWAYS AVAILABLE) ---
#program always.

% Movimientos relativos (fila, columna)
dir(u, -1, 0).
dir(d, 1, 0).
dir(l, 0, -1).
dir(r, 0, 1).

% Definimos los agentes basados en el init
% Al ponerlo en #program always, estas verdades existen en todos los pasos de tiempo
is_taxi(T) :- init(taxi, T, _, _).
is_passenger(P) :- init(passenger, P, _, _).
building(R,C) :- building(R,C).
station(R,C) :- station(R,C).
cell(R,C) :- cell(R,C).

% --- INITIAL STATE ---
#program initial.

% Posicion inicial de taxis
at(T, R, C) :- init(taxi, T, R, C).

% Posicion inicial de pasajeros
at(P, R, C) :- init(passenger, P, R, C).

% --- DYNAMIC STATE ---
#program dynamic.

% 1. GENERACION DE ACCIONES
% Cada taxi debe realizar exactamente una accion por turno
1 { o(move(T,D)) : dir(D,_,_); o(pick(T)); o(drop(T)); o(wait(T)) } 1 :- is_taxi(T).

% 2. EFECTOS DE MOVIMIENTO
% Calcular destino potencial
dest(T, R+DR, C+DC) :- o(move(T,D)), 'at(T, R, C), dir(D, DR, DC).

% Efecto: El taxi esta en el destino si se mueve
at(T, R, C) :- dest(T, R, C).

% Restriccion: No moverse fuera del mapa
:- dest(T, R, C), not cell(R, C).

% Restriccion: No moverse a un edificio
:- dest(T, R, C), building(R, C).

% 3. EFECTOS DE PICK (Recoger)
% Efecto: El pasajero esta a bordo del taxi T
on_board(P, T) :- o(pick(T)), 'at(T, R, C), 'at(P, R, C).

% Restriccion Pick: No recoger si no hay pasajero
:- o(pick(T)), 'at(T, R, C), not 'at(_, R, C).

% Restriccion Pick: Un taxi solo puede llevar un pasajero a la vez
% Si ya tenia alguien a bordo, no puede hacer pick
:- o(pick(T)), 'on_board(_, T).

% 4. EFECTOS DE DROP (Dejar)
% Efecto: El pasajero esta en la posicion actual del taxi
at(P, R, C) :- o(drop(T)), 'at(T, R, C), 'on_board(P, T).

% Restriccion Drop: No hacer drop si no lleva a nadie
:- o(drop(T)), not 'on_board(_, T).

% 5. INERCIA (Frame Axioms)
c_at(Obj) :- o(drop(_)), 'on_board(Obj, _).
c_at(T) :- o(move(T,_)).
c_at(P) :- o(pick(_)), 'at(P,_,_).
c_board(P) :- o(drop(_)), 'on_board(P,_).
c_board(P) :- o(pick(_)), 'at(P,_,_).

% Reglas de persistencia
at(Obj, R, C) :- 'at(Obj, R, C), not c_at(Obj).
on_board(P, T) :- 'on_board(P, T), not c_board(P).

% --- CONSTRAINTS (Restricciones del Problema) ---

% 1. Colision de Taxis
:- at(T1, R, C), at(T2, R, C), T1 < T2, is_taxi(T1), is_taxi(T2).

% 2. Colision de Humanos (Pasajeros o Taxi con pasajero)
human_at(R, C) :- at(P, R, C), is_passenger(P).
human_at(R, C) :- at(T, R, C), on_board(_, T).

:- human_at(R, C), #count{X : at(X, R, C), is_passenger(X); Y : at(Y, R, C), on_board(_, Y)} > 1.

% Colision especifica: Taxi cargado entrando en celda con pasajero
:- at(T, R, C), on_board(_, T), at(P, R, C), is_passenger(P).

% 3. Intercambio (Swap)
:- o(move(T1, r)), o(move(T2, l)), 'at(T1, R, C), 'at(T2, R, C+1).
:- o(move(T1, d)), o(move(T2, u)), 'at(T1, R, C), 'at(T2, R+1, C).

% --- GOAL STATE ---
#program final.

% Definimos condicion de exito para cada pasajero
goal(P) :- at(P, R, C), station(R, C).

% El objetivo global es que no falte ningun pasajero por llegar
:- is_passenger(P), not goal(P).

#show o/1.