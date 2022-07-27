classdef Structure < handle
    %STRUCTURE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties(Access = public)
        % General problem
        nodes
        beams
        springs

        % Full problem - symbolical
        kf
        uf
        ff
        Rf

        % Full problem - numerical
        kf_num
        uf_num
        ff_num
        Rf_num

        % Reduced problem - symbolical
        k
        u
        f
        R

        % Reduced problem - numerical
        k_num
        u_num
        f_num
        R_num

        % Post processing
        var
        val
    end

    properties(Access = private)
        prescribed_displ = []
    end
    
    methods(Access = public)
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

            % Full problem assembly
            obj.full_assembly();

            % Assembly of general problem
            obj.red_assembly();

            % Add springs
            if nargin >=3
                obj.add_springs(springs);
                obj.springs = springs;
            end

            % Check nodes, removes unused displacements
            obj.check_nodes();
        end

        function add_distributed_load(obj, beam_num, dir, load)
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

        function add_concentrated_load(obj, node_num, dir, load)
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

        function add_prescribed_displacement(obj, node_num, dir, displ)
            % Replaced displacement
            replaced = obj.nodes(node_num).displ.(strcat(dir, num2str(node_num)));

            % Replace in node
            obj.nodes(node_num).displ.(strcat(dir, num2str(node_num))) = displ;

            % Replace
            obj.uf.(string(replaced)) = displ;
            obj.u.(string(replaced)) = displ;

            % Add original displacement number to list of prescribed displacements
            obj.prescribed_displ = [obj.prescribed_displ string(replaced)];
        end

        function add_springs(obj, springs)
            for i = 1:length(springs)
                % Update displacement
                displ = obj.nodes(springs(i).node_num).displ.( ...
                    strcat(springs(i).dir, num2str(springs(i).node_num)));
    
                % Find in global displacements - full
                index_full = find(struct2array(obj.uf)==displ);

                % Find in global displacements - red
                index_red = find(struct2array(obj.u)==displ);
                
                % Add contribution
                if index_full
                    obj.kf(index_full, index_full) = ...
                    obj.kf(index_full, index_full) + springs(i).stiff;
                end
                if index_red
                    obj.k(index_red, index_red) = ...
                    obj.k(index_red, index_red) + springs(i).stiff;
                end
            end
        end
  
        function solve(obj, var, val)
            % Set variable and values
            obj.var = var; obj.val = val;

            % Assemble loads - Full
            obj.ff = obj.load_assembly(str2sym(fieldnames(obj.uf)));

            % Assemble loads - Reduced
            obj.f = obj.load_assembly(str2sym(fieldnames(obj.u)));
            
            % Symbolical solution
            obj.femsolve();
            obj.get_reactions();

            % Numerical solution - Full
            obj.kf_num = vpa(subs(obj.kf, var, val), 4);
            obj.ff_num = vpa(subs(obj.ff, var, val), 4);
            
            obj.uf_num = obj.uf;
            for i = string(cell2mat(fieldnames(obj.uf)))'
                obj.uf_num.(i) = vpa(subs(obj.uf.(i), var, val), 4);
                obj.Rf_num.(strcat("R", i)) = vpa(subs(obj.Rf.(strcat("R", i)), var, val), 10);
            end

            % Numerical solution - Reduced
            obj.k_num = vpa(subs(obj.k, var, val), 4);
            obj.f_num = vpa(subs(obj.f, var, val), 4);
            
            obj.u_num = obj.u;
            for i = string(cell2mat(fieldnames(obj.u)))'
                obj.u_num.(i) = vpa(subs(obj.u.(i), var, val), 4);
            end
            for i = string(cell2mat(fieldnames(obj.R)))'
                obj.R_num.(i) = vpa(subs(obj.R.(i), var, val), 10);
            end

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
            N = beam.N(); dN = diff(N, x);
            M = [ ...
                N(1) 0     0     N(4) 0     0
                0    N(2)  N(3)  0    N(5)  N(6)
                0    dN(2) dN(3) 0    dN(5) dN(6)
                ];

            % Replace displacements
            displ1 = str2sym(fieldnames(node(1).displ));
            displ2 = str2sym(fieldnames(node(2).displ));

            u_glo = subs([displ1; displ2], ...
                str2sym(fieldnames(obj.uf_num)), struct2array(obj.uf_num).');

            % Check null displacements
            for i = 1:length(u_glo)
                if isSymType(u_glo(i), "variable"); u_glo(i) = 0; end
            end

            % Get displacement in global coordinates
            u_vect = subs(subs(M, x, xi*l) * T * u_glo, obj.var, obj.val);
            
            % Unpack
            u = u_vect(1); v = u_vect(2); t = u_vect(3);
        end

        function [N, M] = get_internal_actions(obj, beam_num, xi)
            syms x

            % Init variables
            beam = obj.beams(beam_num); node = beam.nodes; l = beam.l;
            EA = beam.EA; EJ = beam.EJ;

            % Get T, N and H
            T = beam.get_T();
            dN = diff(beam.N(), x); dN2 = diff(beam.N(), x, 2);
            H = [ ...
                EA*dN(1) 0          0          EA*dN(4) 0          0
                0        EJ*dN2(2)  EJ*dN2(3)  0        EJ*dN2(5)  EJ*dN2(6)
                ];
            
            % Global displacements
            displ1 = str2sym(fieldnames(node(1).displ));
            displ2 = str2sym(fieldnames(node(2).displ));

            u_glo = subs([displ1; displ2], ...
                str2sym(fieldnames(obj.uf_num)), struct2array(obj.uf_num).');

            % Check null displacements
            for i = 1:length(u_glo)
                if isSymType(u_glo(i), "variable"); u_glo(i) = 0; end
            end

            % Get displacement in local coordinates
            u_local = T * u_glo;

            % Internal actions
            int_act = subs(subs(H, x, xi*l) * u_local, obj.var, obj.val);

            % Unpack
            N = vpa(int_act(1), 10); M = vpa(int_act(2), 10);
        end

        function plot(obj)
            % Check if plot available
            if isempty(obj.u_num)
                error("Plot unavailable, structure must be solved first.")
            end

            % Matrix of node coordinates
            ncoords = zeros(length(obj.nodes), 2);

            % Node hierarchy
            node_hierarchy = zeros(length(obj.nodes), 2);
            for j = 1:length(obj.nodes)
                for y = obj.beams
                    if any(obj.nodes(j) == y.nodes)
                        node_hierarchy(j, :) = [j, node_hierarchy(j, 2) + 1];
                    end
                end
            end
            node_hierarchy = sortrows(node_hierarchy, 2, 'descend');
            
            % Determine node position, loop through combinations, considering hierarchy
            for nn1 = node_hierarchy(:, 1)'
                for nn2 = node_hierarchy(:, 1)'
                    % Permutation order doesn't matter
                    if find(node_hierarchy(:, 1)==nn2) <= find(node_hierarchy(:, 1)==nn1)
                        continue
                    end
                    % Find beam according to hierarchy
                    found = false;
                    for i = obj.beams
                        beam_num = find(obj.beams==i);
                        if all([i.nodes(1).num, i.nodes(2).num] == [nn1, nn2])
                            angle = i.alpha; found = true;
                            break
                        elseif all([i.nodes(1).num, i.nodes(2).num] == [nn2, nn1])
                            angle = 180 + i.alpha; found = true;
                            break 
                        end
                    end
                    
                    % If beam doesn't exist
                    if ~found
                        continue
                    end

                    % Beam length
                    l = subs(obj.beams(beam_num).l, obj.var, obj.val);
    
                    % Coordinates
                    x_end = ncoords(nn1, 1) + l*cosd(angle);
                    y_end = ncoords(nn1, 2) + l*sind(angle);
    
                    % Update node coordinates
                    ncoords(nn2, :) = [x_end y_end];
                end
            end
            
            % Plot
            figure("Position", [100 100 1000 700]);
            for i = 1:length(obj.beams)
                % Coordinates
                x = [ncoords(obj.beams(i).nodes(1).num, 1), ncoords(obj.beams(i).nodes(2).num, 1)];
                y = [ncoords(obj.beams(i).nodes(1).num, 2), ncoords(obj.beams(i).nodes(2).num, 2)];

                % Plot beam
                plot(x, y, 'linewidth', 3)
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
                    x_end = ncoords(obj.beams(i).nodes(1).num, 1) + l*xi*cosd(obj.beams(i).alpha);
                    y_end = ncoords(obj.beams(i).nodes(1).num, 2) + l*xi*sind(obj.beams(i).alpha);
    
                    % Deformed
                    [xbd, ybd, ~] = obj.get_displ_global(i, xi);

                    % Deformed coordinate
                    xbc(j) = x_end+xbd; ybc(j) = y_end+ybd;
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
                displ = string(cell2mat(fieldnames(obj.nodes(i).displ)));
                value = struct2array(obj.nodes(i).displ);
                u_used = string(cell2mat(fieldnames(obj.u)));

                if value(1) ~= 0 && any(ismember(u_used, displ(1)))
                    quiver(ncoords(i, 1), ncoords(i, 2), ref/10, 0, ...
                        'off', 'color', 'black')

                    text(ncoords(i, 1)+(ref/20), ncoords(i, 2)-(ref/60), ...
                        string(displ(1)), "HorizontalAlignment", "center");
                end
                if value(2) ~= 0 && any(ismember(u_used, displ(2)))
                    quiver(ncoords(i, 1), ncoords(i, 2), 0, ref/10, ...
                        'off', 'color', 'black')

                    h = text(ncoords(i, 1)-(ref/60), ncoords(i, 2)+(ref/20), ...
                        string(displ(2)), "HorizontalAlignment", "center");
                    set(h,'Rotation',90);
                end
                if value(3) ~= 0 && any(ismember(u_used, displ(3)))
                    plot(ncoords(i, 1), ncoords(i, 2), 'kx', 'Markersize', 15)
                    plot(ncoords(i, 1), ncoords(i, 2), 'ko', 'Markersize', 15)

                    text(ncoords(i, 1)+(ref/40), ncoords(i, 2)+(ref/40), ...
                        string(displ(3)), "HorizontalAlignment", "center");
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

    methods(Access = private) 
        function check_nodes(obj)
            % Unpack structure
            u_value = struct2array(obj.u); u_field = fieldnames(obj.u);

            % Re-init u
            obj.u = struct;

            % Loop
            deleted = 0;
            for i = 1:length(u_value)
                if ~any(obj.k(i-deleted, :) ~= 0) && ~any(obj.k(:, i-deleted) ~= 0) % If row and column is zero
                    % Remove associated displacement
                    obj.k(i-deleted, :) = []; obj.k(:, i-deleted) = [];
                    deleted = deleted + 1;

                    % Set to zero in full problem
                    obj.uf.(u_field{i}) = 0;
                else
                    % Re-assembly of u
                    obj.u.(u_field{i}) = u_value(i);
                end
            end
        end

        function full_assembly(obj)
            % Build displacements and reaction forces
            obj.uf = struct; obj.Rf = obj.uf;
            for i = 1:length(obj.nodes)
                for j = strcat(["u", "v", "t"], num2str(obj.nodes(i).num)) % every displacement    
                    % Assembly
                    obj.uf.(j) = obj.nodes(i).displ.(j);
                    obj.Rf.(strcat("R", j)) = str2sym(strcat('R', j));
                end
            end

            % Build stiffness matrix
            obj.kf = sym(zeros(length(fieldnames(obj.uf)), length(fieldnames(obj.uf))));
            for i = 1:length(obj.beams)
                % Generate and save contribution
                k_fem = obj.beams(i).gen_fem_stiff_matrix(str2sym(fieldnames(obj.uf)));
                obj.beams(i).k_cont_full = k_fem;
                
                % Update global matrix
                obj.kf = obj.kf + obj.beams(i).k_cont_full;
            end
        end

        function red_assembly(obj)
            % Symbolical reduced displacements vector
            obj.u = obj.uf;
            for i = 1:length(obj.nodes)
                for j = strcat(["u", "v", "t"], num2str(obj.nodes(i).num)) % every displacement
                    if obj.nodes(i).displ.(j) == 0
                        % Remove field
                        obj.u = rmfield(obj.u, j);
                    end
                end
            end

            % Build stiffness matrix
            % Assemble FEM contribution for every beam
            u_array = struct2array(obj.u);
            obj.k = sym(zeros(length(u_array), length(u_array)));
            for i = 1:length(obj.beams)
                % Generate and save contribution
                k_fem = obj.beams(i).gen_fem_stiff_matrix(u_array);
                obj.beams(i).k_cont_red = k_fem;
                
                % Update global matrix
                obj.k = obj.k + obj.beams(i).k_cont_red;
            end
        end

        function f_fem = load_assembly(obj, u_fem)
            % Assembly loads
            f_fem = sym(zeros(length(u_fem), 1));
            for i = 1:length(obj.nodes)
                % Build pointer vector
                pointer = zeros(1, 3);
                y = 1;
                for j = str2sym(strcat(["u", "v", "t"], num2str(obj.nodes(i).num))) % every displacement
                    index = find(u_fem==j);
                    if index
                        pointer(y) = index;
                    else
                        pointer(y) = 0;
                    end
                    y = y + 1;
                end
                
                % Add contribution
                for j = 1:3 % pointer length
                    if pointer(j)
                        f_fem(pointer(j)) = f_fem(pointer(j)) + obj.nodes(i).loads(j).';
                    end
                end
            end
        end
        
        function femsolve(obj)
            k_pre = obj.k; f_pre = obj.f; u_pre = struct2array(obj.u);
            % Remove prescribed rows
            for i = 1:length(obj.prescribed_displ)
                index = find(str2sym(fieldnames(obj.u))==obj.prescribed_displ(i));
                % Remove row
                k_pre(index - (i-1), :) = [];
                f_pre(index - (i-1)) = [];
                u_pre(index - (i-1)) = [];
            end

            % Compute remaining displacements
            u_rem = solve(k_pre * struct2array(obj.u).' == f_pre, u_pre);

            % Assemble final displacement
            if isstruct(u_rem)
                for i = u_pre
                    obj.u.(string(i)) = u_rem.(string(i));
                    obj.uf.(string(i)) = u_rem.(string(i));
                end
            else
                obj.u.(string(u_pre)) = u_rem;
                obj.uf.(string(u_pre)) = u_rem;
            end
        end
       
        function get_reactions(obj)
            % Init variables
            k_r = obj.kf; u_r = struct2array(obj.uf).';
            f_r = obj.ff; obj.R = obj.Rf;

            % Loop through equations to remove null-reaction equations
            deleted = 0;
            for i = 1:length(obj.nodes)
                displ = obj.nodes(i).displ;
                dof = strcat(["u", "v", "t"], num2str(obj.nodes(i).num));
                for y = 1:3
                    % Recover dof
                    j = dof(y);

                    if displ.(j) ~= 0
                        if ~isempty(obj.prescribed_displ)
                            if j == obj.prescribed_displ
                                continue
                            end
                        end

                        % Set to zero - Full
                        obj.Rf.(strcat("R", j)) = 0;
    
                        % Remove field - red
                        obj.R = rmfield(obj.R, strcat("R", j));
    
                        % Remove row
                        k_r((y + 3*(i-1))-deleted, :) = [];
                        f_r((y + 3*(i-1))-deleted) = [];

                        % Update deleted
                        deleted = deleted + 1;
                    end
                end
            end

            % Solve problem
            R_s = solve(k_r*u_r - f_r == struct2array(obj.R).', struct2array(obj.R).');

            % Assemble final displacement
            fields = string(cell2mat(fieldnames(obj.R))).';
            if isstruct(R_s)
                for i = fields
                    obj.R.(i) = R_s.(i);
                    obj.Rf.(i) = R_s.(i);
                end
            else
                obj.R.(fields) = R_s;
                obj.Rf.(fields) = R_s;
            end
        end
    end
end

