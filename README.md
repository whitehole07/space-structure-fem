# space-structure-fem
Simple symbolical FE solver optimized for the Politecnico di Milano's Space Structure course.

<p align="center">
  <img src="https://i.ibb.co/vzY181n/ex1.png" width="550" height="400" />
</p>
<p align="center">
  <em>Figure 1. Example of result produced by the model (see example 1).</em>
</p>

# Example
An example is reported hereafter, see the full example [here](examples/example_1.m).
```MATLAB
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
```

# How to import
1. From MATLAB, go to **New** > **Project** > **From Git**.
2. In the **Repository path** field, paste the following link: `https://github.com/whitehole07/space-structure-fem.git`.
3. Finally, click on **Retrieve**.

You are all set.

# Building the structure
This solver is based on three basic elements:
1. **Nodes**
2. **Beams**
3. **Springs**

After defining them, these elements are combined together to form a compund element, the **Structure**.


## Node definition
To define a node the following syntax holds:

```MATLAB
node = Node(constraint)
```

where:
* _**constraint**_, string cointaining the letters associated to the constrained degrees of freedom (order doesn't matter):
  - _u_,  if the horizontal displacement is prevented;
  - _v_,  if the vertical displacement is prevented;
  - _t_,  if the rotation is prevented. 

For example:
```MATLAB
node = Node("u")    % if only the horizontal movement is prevented
node = Node("uv")   % if the horizontal and vertical movements are prevented

...

node = Node("uvt")  % if all the movements are prevented
node = Node("")     % if none of the movements is prevented
```

For a multi-node structure, the nodes can be collected in an array, this will be referred to as **nodes array**:
```MATLAB
nodes = [Node("uvt"), Node(""), Node("uv"), ...]
```


## Beam definition
To define a beam the following syntax holds:

```MATLAB
beam = Beam(nodes, l, EA, EJ, alpha)
```

where:
* _**nodes**_, array cointaining the position in the nodes array of the beam's nodes, in ascending order (e.g. [1, 3]);
* _**l**_, beam length, can be symbolical;
* _**EA**_, beam axial stiffness function, can be symbolical;
* _**EJ**_, beam bending stiffness function, can be symbolical;
* _**alpha**_, counter-clockwise angle between the horizon and the beam, starting from the first node in  _**nodes**_.

Similarly, for a multi-beam structure, the beams can be collected in an array:
```MATLAB
beams = [Beam([1 2], l1, EA, 0, 330), Beam([3 4], l2, EA, 0, 180), Beam([2 4], l1, EA, 0, 210), ...]
```

## Spring definition
To define a spring the following syntax holds:

```MATLAB
spring = Spring(node_num, dir, stiff)
```

where:
* _**node_num**_, associated node position in the nodes array;
* _**dir**_, spring orientation:
  - _u_,  if horizontal;
  - _v_,  if vertical;
  - _t_,  if torsional. 
* _**stiff**_, spring stiffness, can be symbolical.

Also springs can be collected in an array, code is omitted.

## Structure definition
The structure can now be assembled, the following syntax holds:
```MATLAB
str = Structure(nodes, beams, springs)
```

For example:
```MATLAB
nodes = [Node(""), Node(""), Node("")]
beams = [Beam([1 2], l, EA1 + (EA2 - EA1)*(x/l), 0, 0), Beam([2 3], l, EA3, 0, 0)]
springs = [Spring(1, "u", k1), Spring(3, "u", k2)]

str = Structure(nodes, beams, springs)

% or

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
])
```

# Apply loads

## Concentrated loads
```MATLAB
str.add_concentrated_load(node_num, dir, load)
```

where:
* _**node_num**_, associated node position in the nodes array;
* _**dir**_, load orientation:
  - _u_,  if horizontal force;
  - _v_,  if vertical vorce;
  - _t_,  if torque. 
* _**load**_, load value, can be symbolical.

## Distributed loads
```MATLAB
str.add_distributed_load(beam_num, dir, load)
```

where:
* _**beam_num**_, associated beam position in the beams array;
* _**dir**_, distributed load direction:
  - _u_,  if horizontal;
  - _v_,  if vertical.
* _**load**_, distributed load function, can be symbolical.

# Apply prescribed displacements
```MATLAB
str.add_prescribed_displacement(node_num, dir, displ)
```

where:
* _**node_num**_, associated node position in the nodes array;
* _**dir**_, displacement direction:
  - _u_,  if horizontal;
  - _v_,  if vertical;
  - _t_,  if rotation. 
* _**displ**_, prescribed displacement, can be symbolical.
