%% Clean up
clear
close all
clc

%% Config problem
% Variables
syms l1 l2 EJ1 EJ2 w q

%% Build structure
str = Structure([ ... 
    % Nodes
    Node("uvt"), ...
    Node(""), ...
    Node("ut"), ...

    ], [ ...          
    % Beams
    Beam([1 2], l1, 0, EJ1, 0), ...
    Beam([2 3], l2, 0, EJ2, 0), ...

    ] ...
);

%% Apply loads
str.add_distributed_load(2, "transversal", q);

%% Apply prescribed displacements
str.add_prescribed_displacement(2, "v", w);

%% Solve problem
str.solve([l1 l2 EJ1 EJ2 w q], [1000 1500 1e12 1e11 3 10]);

%% Plot solution
str.plot();


