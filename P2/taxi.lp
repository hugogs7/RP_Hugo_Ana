% % ======================================
% % ALWAYS: dominio estático 4x9, objetos
% % ======================================

#program always.

% % Celdas 4x9: filas 0..3, columnas 0..8
% cell(R,C) :- R = 0..3, C = 0..8.

% % Edificios
% building(1,1). building(1,2). building(1,3). building(1,4).
% building(1,5). building(1,6). building(1,7).
% building(2,1). building(2,7).

% % Taxis y pasajeros
% taxi(1).  taxi(2).
% passenger(a). passenger(b).

% % Estaciones
% station(2,4).
% station(1,8).

% % Direcciones de movimiento
% dir(u,-1, 0).
% dir(d, 1, 0).
% dir(l, 0,-1).
% dir(r, 0, 1).

% Definir opuestos (para optimización 2)
opp(u,d). opp(d,u). opp(l,r). opp(r,l).


% % =========================
% % INITIAL: estado t = 0
% % =========================

% #program initial.

% % Posiciones iniciales de taxis
% at(1,2,0).
% at(2,3,6).

% % Posiciones iniciales de pasajeros
% at(a,0,4).
% at(b,0,6).

% on_board(P,T) es falso por defecto (taxis vacíos)


% =========================
% DYNAMIC: acciones y efectos
% =========================

#program dynamic.

% -------------------------
% Generador de acciones
% -------------------------

% Cada taxi hace EXACTAMENTE una acción por paso
1 {
    move(T,D) : dir(D,_,_);
    pick(T);
    drop(T);
    wait(T)
} 1 :- taxi(T).

% -------------------------
% Movimiento de los taxis
% -------------------------

% Celda objetivo de un taxi si se mueve
target(T,R2,C2) :-
    move(T,D),
    'at(T,R1,C1),
    dir(D,DR,DC),
    R2 = R1 + DR,
    C2 = C1 + DC.

% No salirse del mapa
:- target(T,R,C), not cell(R,C).

% No entrar en edificios
:- target(T,R,C), building(R,C).

% Efecto del movimiento
at(T,R,C) :- target(T,R,C).

% Flag: taxi T se ha movido en este paso
moved(T) :- move(T,_).

% Inercia de posición de taxis:
% si T no se mueve, se queda donde estaba
at(T,R,C) :-
    'at(T,R,C),
    taxi(T),
    not moved(T).

% -------------------------
% PICK (coger pasajero)
% -------------------------

% Pasajero y taxi juntos en el estado anterior
can_pick(T) :-
    taxi(T),
    passenger(P),
    'at(T,R,C),
    'at(P,R,C),
    not 'on_board(P,T),
    not 'on_board(_,T).   % taxi estaba vacío

% Precondición: no se puede pick(T) si no hay pasajero adecuado
:- pick(T), not can_pick(T).

% Efecto: pasajero P pasa a estar dentro de T
on_board(P,T) :-
    pick(T),
    passenger(P),
    'at(T,R,C),
    'at(P,R,C).

% -------------------------
% DROP (soltar pasajero)
% -------------------------

% Precondición: no se puede drop(T) si no llevaba a nadie
:- drop(T), not 'on_board(_,T).

% Efecto: pasajero aparece en la casilla del taxi
at(P,R,C) :-
    drop(T),
    'on_board(P,T),
    'at(T,R,C).

% -------------------------
% Inercia de pasajeros
% -------------------------

% Un pasajero cambia de posición si sube o baja
changed_pos(P) :- pick(T),  passenger(P), 'at(P,R,C), 'at(T,R,C).
changed_pos(P) :- drop(T), 'on_board(P,T).

% Inercia de posición de pasajeros en el suelo
at(P,R,C) :-
    'at(P,R,C),
    passenger(P),
    not changed_pos(P).

% Cambio del estado "a bordo"
changed_board(P) :- pick(T),  passenger(P), 'at(P,R,C), 'at(T,R,C).
changed_board(P) :- drop(T), 'on_board(P,T).

% Inercia de on_board
on_board(P,T) :-
    'on_board(P,T),
    not changed_board(P).


% =========================
% RESTRICCIONES
% =========================

% 1) Dos taxis no pueden estar en la misma celda
:- at(T1,R,C), at(T2,R,C),
   taxi(T1), taxi(T2), T1 < T2.

% 2) Personas en celdas:
%    - pasajero en el suelo
%    - taxi con alguien dentro
has_person(R,C) :- at(P,R,C), passenger(P).
has_person(R,C) :- at(T,R,C), taxi(T), on_board(_,T).

% No puede haber dos personas en la misma celda
:- has_person(R,C),
   #count {
     P : at(P,R,C), passenger(P);
     T : at(T,R,C), taxi(T), on_board(_,T)
   } > 1.

% 3) Prohibir swap de taxis contiguos

% Horizontal: T1 en (R,C), T2 en (R,C+1), se cruzan
:- move(T1,r), move(T2,l),
   'at(T1,R,C), 'at(T2,R,C+1),
   taxi(T1), taxi(T2), T1 < T2.

% Vertical: T1 en (R,C), T2 en (R+1,C), se cruzan
:- move(T1,d), move(T2,u),
   'at(T1,R,C), 'at(T2,R+1,C),
   taxi(T1), taxi(T2), T1 < T2.

% =========================
% Restricción Temporal usando &tel y constraints
%    "Es ilegal hacer picking(P,T) ahora, si PREVIAMENTE (<) ocurrió ALGUNA VEZ (<?) picking(P,T)"
picking(P,T) :- 
    pick(T), 
    passenger(P), 
    'at(T,R,C), 
    'at(P,R,C).

% 1. Predicado de Memoria: picked_before(P,T)
% Significado: Es verdad si el par (P,T) fue recogido en algún paso anterior.

% Caso A: Lo acabamos de recoger en el estado inmediatamente anterior
picked_before(P,T) :- 'picking(P,T).

% Caso B: Persistencia (Si ya lo habíamos recogido antes, seguimos recordándolo)
picked_before(P,T) :- 'picked_before(P,T).

% Restricción
% No se puede recoger (picking) a alguien si ya figura como "recogido antes" (picked_before)
:- picking(P,T), picked_before(P,T).

% 2. Restricción Temporal usando &tel
%    "Es ilegal hacer picking(P,T) ahora, si PREVIAMENTE (<) ocurrió ALGUNA VEZ (<?) picking(P,T)"
% :- picking(P,T), &tel { < <? picking(P,T) }.

% =========================
% OTRA OPTIMIZACIÓN (2)

% Restricción: No hacer un movimiento D si en el paso anterior (<) hiciste el opuesto (OD)
% Se lee: Es ilegal mover T hacia D si antes te moviste hacia OD y OD es opuesto a D.
% No siempre sirve para optimizar, ya que a veces esquivar otro taxi es necesario. No cuenta como paso
% si recoge o suelta a alguien por el medio o si espera.
:- move(T, D), opp(D, OD), &tel { < move(T, OD) }.

% OPTIMIZACIÓN 3: Espera justificada
% Un taxi solo puede hacer wait(T) si tiene un taxi adyacente
% (Si está solo en el campo, debería moverse, no esperar).

adj_taxi(T) :- taxi(T), taxi(T2), T != T2,
               'at(T,R1,C1), 'at(T2,R2,C2),
               |R1-R2| + |C1-C2| == 1.

% Prohibido esperar si NO tienes un taxi adyacente
:- wait(T), not adj_taxi(T).


% =========================
% FINAL: objetivo
% =========================

#program final.

% Un pasajero ha terminado si está en estación y fuera de taxi
finished(P) :-
    passenger(P),
    at(P,R,C),
    station(R,C),
    not on_board(P,_).

% Objetivo: todos los pasajeros terminan
:- passenger(P), not finished(P).

% Mostrar solo acciones
#show move/2.
#show pick/1.
#show drop/1.
#show wait/1.