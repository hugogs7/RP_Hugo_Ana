% si se pone el always aquí  se queda en solving

% =========================================================
% BLOQUE 1: BASE (Datos puros)
% =========================================================
% Al no poner #program, esto es 'base'. Se carga una vez y es global.

rows(4).
cols(9).

% Mapa
cell(R,C) :- R=0..3, C=0..8.
building(1,1). building(1,2). building(1,3). building(1,4).
building(1,5). building(1,6). building(1,7).
building(2,1). building(2,7).
station(1,8). station(2,4).

% si se pone el always aquí  se queda en solving, no entiendo por que
#program always.

% Datos de la instancia (Agentes)
init(passenger,a,0,4).
init(passenger,b,0,6).
init(taxi,1,2,0).
init(taxi,2,3,6).

% =========================================================
% BLOQUE 2: ALWAYS (Conocimiento Estático)
% =========================================================

% Direcciones
dir(u, -1, 0). dir(d, 1, 0).
dir(l, 0, -1). dir(r, 0, 1).


%idealmente el always tendría que estar aquí, pero se resuelve en dos pasos, quizas es porque a los is_... no le pusimos inercia, pero debería 
%generarse en cada paso al estar init en base. sera que el base no se aplica en todos los pasos?

% PROYECCIONES (La clave para que no fallen los checks)
% Leemos los datos del 'base' y creamos predicados visibles en todo momento
is_taxi(T)      :- init(taxi, T, _, _).
is_passenger(P) :- init(passenger, P, _, _).
is_cell(R,C)    :- cell(R,C).
is_building(R,C):- building(R,C).
is_station(R,C) :- station(R,C).

% =========================================================
% BLOQUE 3: INITIAL (t=0)
% =========================================================
#program initial.

% Colocamos a los agentes en el mapa usando los datos base
at(T, R, C) :- init(taxi, T, R, C).
at(P, R, C) :- init(passenger, P, R, C).

% =========================================================
% BLOQUE 4: DYNAMIC (t > 0)
% =========================================================
#program dynamic.

%esto parece tener el mismo problema que el always, probablemente se trate de reglas muy estrictas o hay algun conflicto de restricciones en nuestro programa

% % is_taxi: lo del pasado implica lo del futuro
% is_taxi(T)      :- 'is_taxi(T).

% % is_passenger
% is_passenger(P) :- 'is_passenger(P).

% % is_cell
% is_cell(R,C)    :- 'is_cell(R,C).

% % is_building
% is_building(R,C):- 'is_building(R,C).

% % is_station
% is_station(R,C) :- 'is_station(R,C).



% --- GENERADOR ---
% Como is_taxi esta en 'always', el generador funciona en cada paso
1 { o(move(T,D)) : dir(D,_,_); 
    o(pick(T)); 
    o(drop(T)); 
    o(wait(T)) } 1 :- is_taxi(T).

% --- MOVIMIENTO ---
target(T, R+DR, C+DC) :- o(move(T,D)), 'at(T, R, C), dir(D, DR, DC).

% Restricciones fisicas
:- target(T, R, C), not is_cell(R,C).
:- target(T, R, C), is_building(R,C).

% Efecto Movimiento
at(T, R, C) :- target(T, R, C).

% --- PICK (Recoger) ---
% Efecto:
on_board(P, T) :- o(pick(T)), 'at(T, R, C), 'at(P, R, C). 

% Precondiciones
% Debe haber alguien !!!! aqui hay q hacer q el q este sea un humano, no puede ser un taxi
:- o(pick(T)), 'at(T, R, C), not 'at(_, R, C).
% Taxi debe estar vacio
:- o(pick(T)), 'on_board(_, T).                

% --- DROP (Soltar) ---
% Efecto
at(P, R, C) :- o(drop(T)), 'at(T, R, C), 'on_board(P, T).

% Precondiciones
:- o(drop(T)), not 'on_board(_, T).

% --- WAIT ---
at(T, R, C) :- o(wait(T)), 'at(T, R, C).

% --- INERCIA (CORREGIDA) ---
% Aqui estaba error logico anterior. 
% Solo cambia el pasajero que esta DONDE el taxi hace pick.

% 1. Pasajero sube al taxi (desaparece del suelo)
c_at(P) :- o(pick(T)), 'at(T, R, C), 'at(P, R, C).

% 2. Pasajero baja del taxi (aparece en suelo) !!!no estas indicando que el pasajero que baja es el que estaba a bordo del taxi
c_at(Obj) :- o(drop(_)), 'on_board(Obj, _).

% 3. Taxi se mueve (cambia de sitio)
c_at(T) :- o(move(T,_)).

% 4. Cambios de estado a bordo !!!!aqui no esta indicando que el taxi del on board es el mismo que hace pick/drop
c_board(P) :- o(drop(_)), 'on_board(P,_).
c_board(P) :- o(pick(T)), 'at(T, R, C), 'at(P, R, C).

% Reglas de persistencia
at(Obj, R, C)  :- 'at(Obj, R, C), not c_at(Obj).
on_board(P, T) :- 'on_board(P, T), not c_board(P).

% --- RESTRICCIONES DE COLISIÓN ---

% Taxis chocando !!!por eso al cambiar program always a antes de los init da insatisfable, pq asegura los is_taxi siempre, y al parecer si esta en base no
% y esto realmente es taxis en la misma celda, habria que prohibir que intercambien posiciones tambien (lo hago despues)
:- at(T1, R, C), at(T2, R, C), T1 < T2, is_taxi(T1), is_taxi(T2).

% Humanos en la misma celda (Pasajero+Pasajero, Pasajero+TaxiOcupado)
has_human(R,C) :- at(P, R, C), is_passenger(P).
has_human(R,C) :- at(T, R, C), on_board(_, T).

%revisar si lo de dentro del count va bien
:- has_human(R, C), 
   #count{ X : at(X, R, C), is_passenger(X); 
           Y : at(Y, R, C), on_board(_, Y) } > 1.

% Taxi ocupado no puede pisar a pasajero
:- at(T, R, C), on_board(_, T), at(P, R, C), is_passenger(P).

% Intercambio (Swap) el intercambio q mencione antes
:- o(move(T1, r)), o(move(T2, l)), 'at(T1, R, C), 'at(T2, R, C+1).
:- o(move(T1, d)), o(move(T2, u)), 'at(T1, R, C), 'at(T2, R+1, C).

finished(P) :- at(P, R, C), is_station(R, C).


% =========================================================
% BLOQUE 5: FINAL (Objetivo)
% =========================================================
#program final.

% Como is_station y is_passenger estan en 'always', aqui son visibles. !!!esto no se deberia poner en always para q lo revise cada vez?
%finished(P) :- at(P, R, C), is_station(R, C).

% Objetivo: Prohibido que quede alguien sin terminar
:- is_passenger(P), not finished(P).

#show o/1.
#show is_taxi/1.
