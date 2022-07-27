%% Clean up
clear
close all
clc

%% Config problem
% Variables
syms l1 l2 a b E P

%% Build structure
str = Structure([ ... 
    % Nodes
    Node("uvt"), ...
    Node(""), ...
    Node(""), ...
    Node("uvt"), ...
    Node("uv"), ...

    ], [ ...          
    % Beams
    Beam([1 2], l1, E*a^2, E*(a^4)/12, 0), ...
    Beam([2 3], l2, E*b^2, 0, 270), ...
    Beam([3 4], l1, E*a^2, E*(a^4)/12, 180), ...
    Beam([3 5], l2, E*b^2, 0, 270) ...
    ] ...
);

%% Apply loads
str.add_concentrated_load(2, "v", P);

%% Solve problem
str.solve([l1 l2 a b E P], [1000 300 100 10 72e3 5e4]);

%% Plot solution
str.plot();


