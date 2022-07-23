classdef Structure < handle
    %STRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = public)
        % General problem
        nodes
        beams
        springs

        % Generalized vectors
        u_gen

        % Symbolical solution
        k
        f
        u

        % Numerical solution
        k_num
        f_num
        u_num

        % Post processing
        var
        val
    end

    properties(Access = private)
        prescribed_displ = []
    end
    
    methods
        function obj = Structure(nodes, beams, springs)
            %STRUCTURE Construct an instance of this class
            %   Detailed explanation goes here

            % Make nodes
            for i = 1:length(nodes); nodes(i).set_num(i); end
            obj.nodes = nodes;

            % Make beams
            for i = 1:length(beams)
                nodes_i = [nodes(beams(i).nodes(1)) nodes(beams(i).nodes(2))];
                beams(i).nodes = nodes_i;

                % Generate stiffness matrix
                beams(i).gen_stiff_mattrix();
            end
            obj.beams = beams;

            % Assembly of general problem
            obj.assembly();

            % Add springs
            if nargin >=3
                obj.add_springs(springs);
                obj.springs = springs;
            end

            % Check nodes, removes unused displacements
            obj.check_nodes();
        end

        function obj = check_nodes(obj)
            deleted = 0;
            for i = 1:length(obj.u_gen)
                if ~any(obj.k(i-deleted, :) ~= 0) && ~any(obj.k(:, i-deleted) ~= 0) % If row and column is zero
                    % Remove associated displacement
                    obj.k(i-deleted, :) = []; obj.k(:, i-deleted) = [];
                    obj.u_gen(i-deleted) = [];
                    deleted = deleted + 1;
                end
            end
        end

        function obj = assembly(obj)
            % Symbolical reduced displacements vector
            for i = 1:length(obj.nodes)
                for j = 1:3 % number of displacements per node
                    if obj.nodes(i).displ(j) ~= 0
                        % Add displacement
                        obj.u_gen = [obj.u_gen; obj.nodes(i).displ(j)];
                    end
                end
            end

            % Assemble FEM contribution for every beam
            obj.k = sym(zeros(length(obj.u_gen), length(obj.u_gen)));
            for i = 1:length(obj.beams) 
                obj.beams(i).gen_fem_stiff_matrix(obj.u_gen);
                obj.k = obj.k + obj.beams(i).k_cont;
            end
        end

        function obj = load_assembly(obj)
            % Assembly loads
            obj.f = sym(zeros(length(obj.u_gen), 1));
            for i = 1:length(obj.nodes)
                % Build pointer vector
                pointer = zeros(1, 3);
                for j = 1:3 % every displacement
                    index = find(obj.u_gen==obj.nodes(i).displ(j));
                    if index
                        pointer(j) = index;
                    else
                        pointer(j) = 0;
                    end
                end
                
                % Add contribution
                for j = 1:3 % pointer length
                    if pointer(j)
                        obj.f(pointer(j)) = obj.f(pointer(j)) + obj.nodes(i).loads(j).';
                    end
                end
            end
        end

        function obj = add_distributed_load(obj, beam_num, dir, load)
            syms x
            switch dir
                case "u"
                    load = [load 0 0 load 0 0];
                case "v"
                    load = [0 load load 0 load load];
            end
            
            % Compute forces at nodes
            N = obj.beams(beam_num).N();
            fn = int(N.' .* load.', x, [0 obj.beams(beam_num).l]);

            % Update nodes
            obj.beams(beam_num).nodes(1).add_load(fn(1:3));
            obj.beams(beam_num).nodes(2).add_load(fn(4:6));
        end

        function obj = add_concentrated_load(obj, node_num, dir, load)
            switch dir
                case "u"
                    fn = [load 0 0];
                case "v"
                    fn = [0 load 0];
                case "t"
                    fn = [0 0 load];
            end

            % Update node
            obj.nodes(node_num).add_load(fn);
        end

        function obj = add_prescribed_displacement(obj, node_num, dir, displ)
            % Update displacement
            switch dir
                case "u"
                    replaced = obj.nodes(node_num).displ(1);
                    obj.nodes(node_num).displ(1) = displ;
                case "v"
                    replaced = obj.nodes(node_num).displ(2);
                    obj.nodes(node_num).displ(2) = displ;
                case "t"
                    replaced = obj.nodes(node_num).displ(3);
                    obj.nodes(node_num).displ(3) = displ;
            end
            
            % Global index
            global_index = find(obj.u_gen==replaced);

            % Replace
            obj.u_gen(global_index) = displ;

            % Add original displacement number to list of prescribed displacements
            obj.prescribed_displ = [obj.prescribed_displ global_index];
        end

        function obj = add_springs(obj, springs)
            for i = 1:length(springs)
                % Update displacement
                switch springs(i).dir
                    case "u"
                        displ = obj.nodes(springs(i).node_num).displ(1);
                    case "v"
                        displ = obj.nodes(springs(i).node_num).displ(2);
                    case "t"
                        displ = obj.nodes(springs(i).node_num).displ(3);
                end
    
                % Find in global displacements
                index = find(obj.u_gen==displ);
                
                % Add contribution
                if index
                    obj.k(index, index) = obj.k(index, index) + springs(i).stiff;
                end
            end
        end

        function obj = femsolve(obj)
            k_pre = obj.k; f_pre = obj.f; u_pre = obj.u_gen;
            % Remove prescribed rows
            for i = 1:length(obj.prescribed_displ)
                % Remove row
                k_pre(obj.prescribed_displ(i) - (i-1), :) = [];
                f_pre(obj.prescribed_displ(i) - (i-1)) = [];
                u_pre(obj.prescribed_displ(i) - (i-1)) = [];
            end

            % Compute remaining displacements
            u_rem = solve(k_pre * obj.u_gen == f_pre, u_pre);

            % Assemble final displacement
            if isstruct(u_rem)
                obj.u = subs(obj.u_gen, u_pre, struct2cell(u_rem));
            else
                obj.u = subs(obj.u_gen, u_pre, u_rem);
            end
        end

        function obj = solve(obj, var, val)
            % Set variable and values
            obj.var = var; obj.val = val;

            % Assemble loads
            obj.load_assembly();
            
            % Symbolical solution
            obj.femsolve();

            % Numerical solution
            obj.k_num = vpa(subs(obj.k, var, val), 4);
            obj.f_num = vpa(subs(obj.f, var, val), 4);
            obj.u_num = vpa(subs(obj.u, var, val), 4);
        end

        function [u, v, t] = get_displ_global(obj, beam_num, xi)
            % Replace displacements
            [u_loc, v_loc, t_loc] = obj.get_displ_local(beam_num, xi);

            % Get displacement in global coordinates
            beam = obj.beams(beam_num); T = beam.get_T();
            u_vect = T(1:3, 1:3).' * [u_loc; v_loc; t_loc];
            
            % Unpack
            u = u_vect(1); v = u_vect(2); t = u_vect(3);
        end

        function [u, v, t] = get_displ_local(obj, beam_num, xi)
            syms x
            beam = obj.beams(beam_num); node = beam.nodes; l = beam.l;

            % Get T and M
            T = beam.get_T();
            N = beam.N(); dN = diff(N);
            M = [ ...
                N(1) 0     0     N(4) 0     0
                0    N(2)  N(3)  0    N(5)  N(6)
                0    dN(2) dN(3) 0    dN(5) dN(6)
                ];

            % Replace displacements
            u_glo = subs([node(1).displ.'; node(2).displ.'], obj.u_gen, obj.u_num);

            % Check null displacements
            for i = 1:length(u_glo)
                if isSymType(u_glo(i), "variable"); u_glo(i) = 0; end
            end

            % Get displacement in global coordinates
            u_vect = subs(subs(M, x, xi*l) * T * u_glo, obj.var, obj.val);
            
            % Unpack
            u = u_vect(1); v = u_vect(2); t = u_vect(3);
        end

        function plot(obj)
            % Check if plot available
            if isempty(obj.u_num)
                error("Plot unavailable, structure must be solved first.")
            end

            % Matrix of node coordinates
            ncoords = zeros(length(obj.nodes), 2);

            figure("Position", [100 100 1000 700]);
            for i = 1:length(obj.beams)
                % Array of local x
                xi = linspace(0, subs(obj.beams(i).l, obj.var, obj.val), 2);

                % Coordinates
                xb = ncoords(obj.beams(i).nodes(1).num, 1) + xi*cosd(obj.beams(i).alpha);
                yb = ncoords(obj.beams(i).nodes(1).num, 2) + xi*sind(obj.beams(i).alpha);

                % Update node coordinates
                ncoords(obj.beams(i).nodes(2).num, :) = [xb(end) yb(end)];

                % Plot beam
                plot(xb, yb, 'linewidth', 3)
                hold on
                grid on
            end

            % Plot deformed structure
            for i = 1:length(obj.beams)
                % Beam length
                l = subs(obj.beams(i).l, obj.var, obj.val);

                % Array of normalized x
                n = 5; xbc = zeros(1, n); ybc = zeros(1, n); j = 1;
                for xi = linspace(0, 1, n)
                    % Coordinate
                    xb = ncoords(obj.beams(i).nodes(1).num, 1) + l*xi*cosd(obj.beams(i).alpha);
                    yb = ncoords(obj.beams(i).nodes(1).num, 2) + l*xi*sind(obj.beams(i).alpha);
    
                    % Deformed
                    [xbd, ybd, ~] = obj.get_displ_global(i, xi);

                    % Deformed coordinate
                    xbc(j) = xb+xbd; ybc(j) = yb+ybd;
                    j = j + 1;
                end
                plot(xbc, ybc, 'r-', 'linewidth', 0.5)
            end
            
            % Reference length
            ref = max(max(ncoords) - min(ncoords));

            % Plot nodes
            plot(ncoords(:, 1), ncoords(:, 2), '.', 'Markersize', 25)
            text(ncoords(:, 1)-(ref/40), ncoords(:, 2)-(ref/40), ...
                strcat('#', string(num2cell(1:length(obj.nodes)))), "HorizontalAlignment", "center");

            % Add displacements
            for i = 1:length(obj.nodes)
                if obj.nodes(i).displ(1) ~= 0 && any(ismember(obj.u_gen, obj.nodes(i).displ(1)))
                    quiver(ncoords(i, 1), ncoords(i, 2), ref/10, 0, ...
                        'off', 'color', 'black')

                    text(ncoords(i, 1)+(ref/20), ncoords(i, 2)-(ref/60), ...
                        string(obj.nodes(i).displ(1)), "HorizontalAlignment", "center");
                end
                if obj.nodes(i).displ(2) ~= 0 && any(ismember(obj.u_gen, obj.nodes(i).displ(2)))
                    quiver(ncoords(i, 1), ncoords(i, 2), 0, ref/10, ...
                        'off', 'color', 'black')

                    h = text(ncoords(i, 1)-(ref/60), ncoords(i, 2)+(ref/20), ...
                        string(obj.nodes(i).displ(2)), "HorizontalAlignment", "center");
                    set(h,'Rotation',90);
                end
                if obj.nodes(i).displ(3) ~= 0 && any(ismember(obj.u_gen, obj.nodes(i).displ(3)))
                    plot(ncoords(i, 1), ncoords(i, 2), 'kx', 'Markersize', 15)
                    plot(ncoords(i, 1), ncoords(i, 2), 'ko', 'Markersize', 15)

                    text(ncoords(i, 1)+(ref/40), ncoords(i, 2)+(ref/40), ...
                        string(obj.nodes(i).displ(3)), "HorizontalAlignment", "center");
                end
            end

            % Add legend
            legend([strcat('Beam #', string(num2cell(1:length(obj.beams)))), "Deformed"], 'location', 'best')

            % Add details
            title("Structure Modelled")
            xlabel("x [m]")
            ylabel("y [m]")
            axis equal
        end
    end
end

