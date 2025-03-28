# space-structure-fem
A symbolic and numerical finite element solver specifically optimized for the Space Structures course at Politecnico di Milano.  

This model is capable of:  

- Computing the stiffness matrix for beams with non-uniform stiffness properties.  
- Incorporating concentrated and distributed loads, prescribed displacements, and elastic supports.  
- Determining reaction forces and strain energy.  
- Recovering internal forces and local displacements along the beam.  
- Generating visual representations of the model and its deformed configuration, including relevant information such as displacements and node numbering.

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180617992-e8513fed-c429-469f-8b92-8529d0df06a2.png" width="600" />
</p>
<p align="center">
  <em>Figure 1. Example of a result produced by the model (see example 1).</em>
</p>

# Example
An example is presented below; the full version is available [here](examples/example_1.m).
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
# Disclaimer
```diff
- This software is intended to support, not replace, the student's own calculations.  
- The code may contain bugs or produce incorrect results.  
- The author assumes no responsibility for any errors or inaccuracies.  
- Use of the code is at the individual's own risk and discretion.
```

It is strongly recommended to frequently download the latest versions, as they may include bug fixes and new features.

# How to download
You can download the latest release [here](https://github.com/whitehole07/space-structure-fem/releases).

# How to import
Alternatively, you can import the project directly to MATLAB by following these steps:

1. From MATLAB, go to **New** > **Project** > **From Git**.
2. In the **Repository path** field, paste the following link: `https://github.com/whitehole07/space-structure-fem.git`.
3. Finally, click on **Retrieve**.

You are all set.

# How to use: Build the structure
This solver is based on three basic elements:
1. **Nodes**
2. **Beams**
3. **Springs**

After defining them, these elements are combined together to form a compound element, the **Structure**.


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
node = Node("u")    % only the horizontal movement is prevented
node = Node("uv")   % the horizontal and vertical movements are prevented

...

node = Node("uvt")  % all the movements are prevented
node = Node("")     % none of the movements is prevented
```

For a multi-node structure, the nodes can be collected in an array, this will be later referred to as **nodes array**:
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
* _**alpha**_, counter-clockwise angle between the horizon and the beam, starting from the first node in  _**nodes**_ (see Figure 2[^1]).

<p align="center">
  <img src="https://i.ibb.co/YTvPVkq/Kazam-screenshot-00000.png" width="400" />
</p>
<p align="center">
  <em>Figure 2. Adopted convention.</em>
</p>



Similarly, for a multi-beam structure, the beams can be collected in an array:
```MATLAB
beams = [Beam([1 2], l1, EA, 0, 330), Beam([3 4], l2, EA, 0, 180), ...]
```

## Spring definition
To define a spring the following syntax holds:

```MATLAB
spring = Spring(node_num, dir, stiff)
```

where:
* _**node_num**_, associated node's index in the nodes array;
* _**dir**_, spring orientation:
  - _u_,  horizontal;
  - _v_,  vertical;
  - _t_,  rotational. 
* _**stiff**_, spring stiffness, can be symbolical.

Springs can be collected in an array too, the code is omitted.

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
The methods available to apply loads to the structure are reported here.

## Concentrated loads
```MATLAB
str.add_concentrated_load(node_num, dir, load)
```

where:
* _**node_num**_, associated node's index in the nodes array;
* _**dir**_, load orientation:
  - _u_,  horizontal force;
  - _v_,  vertical force;
  - _t_,  torque. 
* _**load**_, load value, can be symbolical.

## Distributed loads
```MATLAB
str.add_distributed_load(beam_num, dir, load)
```

where:
* _**beam_num**_, associated beam's index in the beams array;
* _**dir**_, distributed load direction:
  - _axial_,  beam axial direction;
  - _transversal_, beam transversal direction.
* _**load**_, distributed load function, can be symbolical.

# Apply prescribed displacements
To apply a prescribed displacement the following method is available:

```MATLAB
str.add_prescribed_displacement(node_num, dir, displ)
```

where:
* _**node_num**_, associated node's position in the nodes array;
* _**dir**_, displacement direction:
  - _u_,  horizontal;
  - _v_,  vertical;
  - _t_,  rotation. 
* _**displ**_, prescribed displacement, can be symbolical.

# Solve problem
To solve the problem the following syntax can be used:

```MATLAB
str.solve(var, val)
```

where:
* _**var**_, array of symbolic variables used during the definition of the problem;
* _**val**_, array of respective values (same order).

Once the problem is solved, all the involved quantities are stored inside the **Structure** object. The latter can be retrieved from MATLAB's Command Window, all the accessible properties are visible:

```MATLAB

>> str

str = 

  Structure with properties:

        nodes: [...]  % Array of nodes
        beams: [...]  % Array of beams
      springs: [...]  % Array of springs
           kf: [...]  % Symbolic full stiffness matrix
           uf: [...]  % Symbolic full nodal displacements
           ff: [...]  % Symbolic full load array
           Rf: [...]  % Symbolic full reaction forces
       kf_num: [...]  % Numerical full stiffness matrix
       uf_num: [...]  % Numerical full nodal displacements
       ff_num: [...]  % Numerical full load array
       Rf_num: [...]  % Numerical full reaction forces
            k: [...]  % Symbolic reduced stiffness matrix
            u: [...]  % Symboluc solution for nodal displacements
            f: [...]  % Symbolic reduced load array
            R: [...]  % Symbolic reduced reaction forces
        k_num: [...]  % Numerical reduced stiffness matrix
        u_num: [...]  % Numerical solution for nodal displacements
        f_num: [...]  % Numerical reduced load array
        R_num: [...]  % Numerical reduced reaction forces
strain_energy: [...]  % Numerical strain energy
          var: [...]  % Array of symbolic variables
          val: [...]  % Array of values
```

To get the numerical solution for the nodal displacements:
```MATLAB
str.u_num
```
and similarly for the other properties.

Instead, single beam's stiffness matrix can be recovered from each beam object:
```MATLAB
str.beams(beam_num).k_cont_red % Beam contribution to global problem
```



# Post processing
Once the problem is solved, different post processing methods to recover derived quantities are available.

## Displacements
To recover the displacements at any point of a beam, expressed in the beam's local reference frame, the following method can be used:

```MATLAB
[u, v, t] = str.get_displ_local(beam_num, xi)
```

Instead, to recover the displacements expressed in the global reference frame:

```MATLAB
[u, v, t] = str.get_displ_global(beam_num, xi)
```

where:
* _**[u, v, t]**_, horizontal and vertical displacements and rotation;
* _**beam_num**_, associated beam's index in the beams array;
* _**xi**_, normalized position along the beam (xi = x/l), starting from the first node.

## Internal actions
To recover the internal actions at any point of a beam the following method can be used:

```MATLAB
[N, M] = str.get_internal_actions(beam_num, xi)
```

where:
* _**[N, M]**_, axial force and bending moment;
* _**beam_num**_, associated beam's index in the beams array;
* _**xi**_, normalized position along the beam (xi = x/l), starting from the first node.

# Other examples
Full examples are collected in the [example directory](examples).

[^1]: Credits to prof. Riccardo Vescovini, course of Space Structures at Politecnico di Milano.
