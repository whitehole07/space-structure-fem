# space-structure-fem
Simple two-dimensional FE solver optimized for the Politecnico di Milano's Space Structure exam.

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
* _**constraint**_ is a string cointaining the letters associated to the constrained degrees of freedom (order doesn't matter):
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

For a multi-nodal structure, the nodes can be collected in an array, for instance:
```MATLAB
nodes = [Node("uvt"), Node(""), Node("uv"), ...]
```


## Beam definition
To define a beam the following syntax holds:

```MATLAB
beam = Beam(nodes, l, EA, EJ, alpha)
```

where:
* _**nodes**_ is an array cointaining the reference numbers of the beam's nodes, in ascending order (e.g. [1 3])

# Apply loads

# Apply prescribed displacements
