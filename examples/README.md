# Examples

## [Example 1](example_1.m)
### Problem[^1]
<img align="right" width="400" src="https://user-images.githubusercontent.com/34631826/180618466-290702de-18da-4a70-b40d-7ace485f05af.png">

- l<sub>1</sub> = 1500 mm
- α = 30 deg
- EA = 1 x 10<sup>6</sup> N
- u<sub>app</sub> = 7 mm
- v<sub>app</sub> = 2 mm

### Solution
The problem is modelled as follows:

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180618430-b14794f4-1ec9-4881-b9b4-8f01d58718de.png" width="400" />
</p>
<p align="center">
  <em>Figure 1. Modelled problem.</em>
</p>

From the structure properties the nodal displacements can be recovered: 
```
u2 = 1.948 mm
u3 = 7 mm
v3 = 2 mm
```

## [Example 2](example_2.m)
### Problem[^1]
<img align="right" width="400" src="https://user-images.githubusercontent.com/34631826/180619369-f132ac54-8633-4dc5-a92a-6a029d194293.png">

- l<sub>1</sub> = 1000 mm
- α = 30 deg
- EJ<sub>1</sub> = 1 x 10<sup>12</sup> Nmm<sup>2</sup>
- EA<sub>1</sub> = 1 x 10<sup>6</sup> N
- EA<sub>2</sub> = 1 x 10<sup>8</sup> N
- q = 10 N/mm

### Solution
The problem is modelled as follows:

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180619452-c66895b2-0328-4d19-a407-13404646d8bc.png" width="400" />
</p>
<p align="center">
  <em>Figure 2. Modelled problem.</em>
</p>

From the structure properties the nodal displacements can be recovered: 
```
u2 = -0.1136 mm
v2 =  0.2029 mm
t2 = -0.0001042 deg
```

## [Example 3](example_3.m)
### Problem[^1]
<img align="right" width="400" src="https://user-images.githubusercontent.com/34631826/180619597-bb5176fb-16db-4b34-a64e-bb6cc09a69e8.png">

- EA<sub>1</sub> = 5 x 10<sup>6</sup> N
- EA<sub>2</sub> = 2 x 10<sup>6</sup> N
- EA<sub>3</sub> = 3 x 10<sup>6</sup> N
- l = 750 mm
- k<sub>1</sub> = 8 x 10<sup>3</sup> N/mm
- k<sub>2</sub> = 4 x 10<sup>3</sup> N/mm
- u<sub>app</sub> = 5 mm

### Solution
The problem is modelled as follows:

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180619637-5c52f82e-58e8-41b1-b6a1-c3e341815fd6.png" width="400" />
</p>
<p align="center">
  <em>Figure 3. Modelled problem.</em>
</p>

From the structure properties the nodal displacements can be recovered: 
```
u1 = 1.842 mm
u2 = 5 mm
u3 = 2.5 mm
```

## [Example 4](example_4.m)
### Problem[^1]
<img align="right" width="400" src="https://user-images.githubusercontent.com/34631826/180619854-addddffa-f207-4114-b55b-2e47624da719.png">

- l<sub>1</sub> = 1000 mm
- l<sub>2</sub> = 1500 mm
- EJ<sub>1</sub> = 1 x 10<sup>12</sup> Nmm<sup>2</sup>
- EJ<sub>2</sub> = 1 x 10<sup>11</sup> Nmm<sup>2</sup>
- w = 3 mm
- q = 10 N/mm

### Solution
The problem is modelled as follows:

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180619979-a78a8d85-0c6e-4cf7-9b00-b355e7d2fc19.png" width="400" />
</p>
<p align="center">
  <em>Figure 4. Modelled problem.</em>
</p>

From the structure properties the nodal displacements can be recovered: 
```
v2 =  3 mm
t2 = -0.00627 deg
v3 =  28.8 mm
```

Similary, the reaction force associated to the prescribed displacements is stored in `str.R_num`:

```
Rv2 = -16622.95 N
```

## [Example 5](example_5.m)
### Problem[^1]
<img align="right" width="300" src="https://user-images.githubusercontent.com/34631826/180620115-cf352c1c-d039-4021-be35-a4a1cedcd62d.png">

- l<sub>1</sub> = 1000 mm
- l<sub>2</sub> = 200 mm
- a = 100 mmm
- b = 10 mm
- E = 72 GPa
- P = 5 x 10<sup>4</sup> N

### Solution
The problem is modelled as follows:

<p align="center">
  <img src="https://user-images.githubusercontent.com/34631826/180620197-f48b22e9-f3af-4e37-9022-7de9fd9e8a4e.png" width="400" />
</p>
<p align="center">
  <em>Figure 5. Modelled problem.</em>
</p>

From the structure properties the nodal displacements can be recovered: 
```
u2 =  0 mm
v2 =  3.513 mm
t2 = -0.005269 deg
u3 =  0 mm
v3 =  1.693 mm
t3 = -0.002539 deg
```

Similary, the vertical reaction force in node #5 is stored in `str.R_num`:

```
Rv5 = -40629.76 N
```

[^1]: Credits to prof. Riccardo Vescovini, course of Space Structures at Politecnico di Milano.
