%% Clean up
clear
close all
clc

%% Config problem
% Variables
syms EA l1 l2 uapp vapp

%% Build structure
str = Structure([ ... 
    % Nodes
    Node("uv"), ...
    Node("v"), ...
    Node(""), ...
    Node("uv") ...

    ], [ ...          
    % Beams
    Beam([1 2], l1, EA, 0, 330), ...
    Beam([2 3], l1, EA, 0, 330), ...
    Beam([3 4], l2, EA, 0, 180), ...
    Beam([2 4], l1, EA, 0, 210) ...

    ] ...
);

%% Apply prescribed displacements
str.add_prescribed_displacement(3, "u", uapp);
str.add_prescribed_displacement(3, "v", vapp);

%% Solve problem
str.solve([EA l1 l2 uapp vapp], [1e6 1500 3000*cosd(30) 7 2]);

%% Plot solution
str.plot();



