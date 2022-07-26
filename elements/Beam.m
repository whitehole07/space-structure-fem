classdef Beam < handle
    %BEAM Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        % Nodes
        nodes
        
        % Properties
        l
        EA
        EJ
        alpha
        
        % Local
        k_loc
        k_loc_red

        % Global
        k_glo
        k_glo_red
        
        % FEM contribution
        k_cont_full
        k_cont_red
    end
    
    methods
        function obj = Beam(nodes, l, EA, EJ, alpha)
            %BEAM Construct an instance of this class
            %   Detailed explanation goes here
            arguments
                nodes
                l
                EA
                EJ
                alpha (1, 1) double = NaN
            end
            
            obj.nodes = nodes;
            obj.l = l;
            obj.EA = EA; obj.EJ = EJ;
            obj.alpha = alpha;
        end

        function obj = gen_stiff_mattrix(obj)
            % Retrieve global and local stiffness matrix
            obj.k_loc = obj.get_k_loc();
            obj.k_glo = obj.get_k_glo();

            % Retrieve reduced global and local stiffness matrix
            k_loc_redi = obj.k_loc; k_glo_redi = obj.k_glo;
            for i = 1:2 % nodes
                displ = struct2array(obj.nodes(i).displ);
                for j = 1:3 % displacements per node
                    if displ(j) == 0
                        % Remove row and column associated
                        k_loc_redi((j + 3*(i-1)), :) = zeros(1, 6);
                        k_loc_redi(:, (j + 3*(i-1))) = zeros(6, 1);
                        
                        k_glo_redi((j + 3*(i-1)), :) = zeros(1, 6);
                        k_glo_redi(:, (j + 3*(i-1))) = zeros(6, 1);
                    end
                end
            end
            obj.k_loc_red = k_loc_redi; obj.k_glo_red = k_glo_redi;          
        end

        function k_fem = gen_fem_stiff_matrix(obj, u_fem)
            % FEM contribution 
            % (shaped to be summed with other contributions in order to get
            % the assmbled global matrix)

            % Build pointer vector
            pointer = zeros(1, 6);
            for i = 1:2 % every node
                nodal_displ = str2sym(fieldnames(obj.nodes(i).displ));
                for j = 1:3 % every displacement
                    index = find(u_fem==nodal_displ(j));
                    if index
                        pointer((j + 3*(i-1))) = index;
                    else
                        pointer((j + 3*(i-1))) = 0;
                    end
                end
            end

            % Buld FEM contribution
            k_fem = sym(zeros(length(u_fem), length(u_fem)));
            for i = 1 : 6 % pointer length
                for j = 1 : 6 % pointer length
                    if pointer(i) && pointer(j)
                        k_fem(pointer(i), pointer(j)) = obj.k_glo(i, j);
                    end
                end
            end
        end

        function N = N(obj)
            syms x

            % Adimensional position
            xi = x/obj.l;

            % Shape functions
            Nu1 = 1 - xi;
            Nv1 = 1 - 3*xi^2 + 2*xi^3;
            Nt1 = obj.l * (-xi + 2*xi^2 - xi^3);
            Nu2 = xi;
            Nv2 = 3*xi^2 - 2*xi^3;
            Nt2 = obj.l * (xi^2 - xi^3);

            % Assembly
            N = [Nu1 Nv1 Nt1 Nu2 Nv2 Nt2];
        end

        function k = get_k_loc(obj)
            syms x

            % Disassemble N
            N = obj.N();
            NEA = diff([N(1) 0 0 N(4) 0 0], x);
            NEJ = diff([0 N(2) N(3) 0 N(5) N(6)], 2, x);

            % Compute K matrix
            k = int( ...
                (NEA.' * obj.EA * NEA) + ...
                (NEJ.' * obj.EJ * NEJ), ...
                x, [0 obj.l]);
        end

        function T = get_T(obj)
            alphai = obj.alpha;

            T = [ ...
     cosd(alphai), sind(alphai), 0,             0,            0, 0
    -sind(alphai), cosd(alphai), 0,             0,            0, 0
                0,            0, 1,             0,            0, 0
                0,            0, 0,  cosd(alphai), sind(alphai), 0
                0,            0, 0, -sind(alphai), cosd(alphai), 0
                0,            0, 0,             0,            0, 1];
        end

        function k = get_k_glo(obj)
            T = obj.get_T();
            k = T.' * obj.get_k_loc() * T;
        end
    end
end

