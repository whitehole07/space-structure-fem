classdef Spring < handle
    %NODE Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        node_num

        stiff
        dir
    end
    
    methods
        function obj = Spring(node_num, dir, stiff)
            %NODE Construct an instance of this class
            %   Detailed explanation goes here
            obj.node_num = node_num; obj.dir = dir; obj.stiff = stiff;
        end
    end
end

