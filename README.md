# space-structure-fem
Simple two-dimensional FE solver optimized for the Politecnico di Milano's Space Structure exam.

<p align="center">
  <img src="https://i.ibb.co/vzY181n/ex1.png" width="550" height="400" />
</p>
<p align="center">
  <em>Figure 1. Example of result produced by the model (see example 1).</em>
</p>

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

> node = Node(constraint)


where:
* _**constraint**_ is a string


## Beam definition
To define a beam the following syntax holds:

> beam = Beam(nodes, l, EA, EJ, alpha)


where:
* _**nodes**_ is an array cointaining the reference numbers of the beam's nodes, in ascending order (e.g. [1 3])

# Applying loads

# Applying prescribed displacements
