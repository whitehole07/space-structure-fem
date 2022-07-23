%% Clean up
clear
close all
clc

%% Config problem
% Variables
syms l EA1 EA2 EA3 k1 k2 uapp x

%% Build structure
str = Structure([ ... 
    % Nodes
    Node(""), ...
    Node(""), ...
    Node("") ...

    ], [ ...          
    % Beams
    Beam([1 2], l, EA1 + (EA2 - EA1)*(x/l), 0, 0), ...
    Beam([2 3], l, EA3, 0, 0), ...

    ], [ ...
    % Springs
    Spring(1, "u", k1), ...
    Spring(3, "u", k2) ...
    
]);

%% Apply prescribed displacements
str.add_prescribed_displacement(2, "u", uapp);

%% Solve problem
str.solve([l EA1 EA2 EA3 k1 k2 uapp], [750 5e6 2e6 3e6 8e3 4e3 5]);

%% Plot solution
str.plot()


