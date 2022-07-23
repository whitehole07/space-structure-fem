%% Clean up
clear
close all
clc

%% Config problem
% Variables
syms l1 l2 EJ1 EA1 EA2 q

%% Build structure
str = Structure([ ... 
    % Nodes
    Node("uvt"), ...
    Node(""), ...
    Node("uvt"), ...
    Node("uv") ...

    ], [ ...          
    % Beams
    Beam([1 2], l1, EA1, EJ1, 0), ...
    Beam([2 3], l1, EA1, EJ1, 0), ...
    Beam([2 4], l2, EA2, 0, 210) ...

    ] ...
);

%% Apply loads
str.add_distributed_load(2, "v", q);

%% Solve problem
str.solve([l1 l2 EJ1 EA1 EA2 q], [1000 1000/cosd(30) 1e12 1e6 1e8 10]);

%% Plot solution
str.plot()


