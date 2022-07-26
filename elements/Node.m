classdef Node < handle
    %NODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        num

        displ = struct
        constr

        loads = sym([0 0 0])
    end
    
    methods
        function obj = Node(constraint)
            %NODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.constr = constraint;
        end

        function obj = set_num(obj, num)
            obj.num = num;

            % Define general displacements
            u = evalin(symengine, strcat('u', num2str(num)));
            v = evalin(symengine, strcat('v', num2str(num)));
            t = evalin(symengine, strcat('t', num2str(num)));

            % Init struct
            obj.displ = struct(string(u), 0, string(v), 0, string(t), 0);
            
            % Add displacement if not constrained
            if ~contains(obj.constr, 'u')
                obj.displ.(string(u)) = u;
            end
            if ~contains(obj.constr, 'v')
                obj.displ.(string(v)) = v;
            end
            if ~contains(obj.constr, 't')
                obj.displ.(string(t)) = t;
            end
        end

        function obj = add_load(obj, load_vector)
            obj.loads = obj.loads + load_vector.';
        end
    end
end

