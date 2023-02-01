---
title: "An introduction to Molecular Dynamics"
teaching: 20
exercises: 30
questions:
---


# What is LAMMPS?

LAMMPS (Large-scale Atomic/Molecular Massively Parallel Simulator) is a versatile classical molecular dynamics software package developed by Sandia National Laboratories and by its wide user-base.

It can be downloaded from [https://lammps.sandia.gov/download.html](https://lammps.sandia.gov/download.html)

Everything we are covering today (and a lot of other info) can be found in the [LAMMPS User Manual](https://lammps.sandia.gov/doc/Manual.html)


# Running LAMMPS on ARCHER2

ARCHER2 uses a module system. In general, you can run LAMMPS on ARCHER2 by using the LAMMPS module:

```bash
ta058js@ln03:~> module avail lammps

------------------- /work/y07/shared/archer2-lmod/apps/core -------------------
   lammps/29_Sep_2021

```

Running `module load lammps` will set up your environment to use LAMMPS.
For this course, we will be using certain LAMMPS packages that are not included in the central module.
We have built a version of LAMMPS that can be accessed by ensuring that the following commands are run prior to executing your LAMMPS command.

```bash
module load PrgEnv-gnu
module load cray-python

export LAMMPS_DIR=/work/ta058/shared/lammps_build/
export PATH=${PATH}:${LAMMPS_DIR}/bin
export LD_LIBRARY_PATH=${LD_LIBRARY_PATH}:${LAMMPS_DIR}/lib64
export PYTHONPATH=${PYTHONPATH}:${LAMMPS_DIR}/lib/python3.8/site-packages
```

The build instructions for this version are described in the next section of the course.

Once your environment is set up, you will have access to the `lmp` LAMMPS executable.
Note that you will only be able to run this on a single core on the ARCHER2 login node.


## Submitting a job to the compute nodes

To run LAMMPS on multiple cores/nodes, you will need to submit a job to the ARCHER2 compute nodes.
The compute nodes do not have access to the landing `home` filesystem -- this filesystem is to store useful/important information.
On ARCHER2, when submitting jobs to the compute nodes, make sure that you are in your `/work/ta058/ta058/<username>` directory.

For this course, we have prepared a number of exercises.
You can get a copy of these exercises by running (make sure to run this from `/work`):

[comment]: # (change to intro link)
```bash
svn checkout https://github.com/EPCCed/archer2-advanced-use-of-lammps/trunk/exercises
```

[comment]: # (change exercise names and file names)
Once this is downloaded, please  `cd exercises/1-performance-exercise/`.
In this directory you will find three files:

  - `sub.slurm` is a Slurm submission script -- this will let you submit jobs to the compute nodes.
    Initially, it will run a single core job, but we will be editing it to run on more cores.
  - `in.ethanol` is the LAMMPS input script that we will be using for this exercise.
    This script is meant to run a small simulation of 125 ethanol molecules in a periodic box.
  - `data.ethanol` is a LAMMPS data file for a single ethanol molecule.
    This template will be copied by the `in.lammps` file to generate our simulation box.


# What is Molecular Dynamics

Molecular Dynamics is, simply, the application of Newtown's laws of motion to systems of particles that can range in size from atoms, course-grained moieties, entire molecules, or even grains of sand.
In practical terms, any MD software follows the same basic steps:

  1. Take the initial positions of the particles in the simulation box and calculate the total force that apply to each particle, using the chosen force-field.
  2. Use the calculated forces to calculate the acceleration to add to each particle;
  3. Use the acceleration to calculate the new velocity of each particle;
  4. Use the the new velocity of each particle, and the defined time-step, to calculate a new position for each particle.

With the new particle positions, the cycle continues, one very small time-step at a time.

[comment]: # (make image better)
{% include figure.html url="" max-width="80%" file="/fig/2_MD-primer/MD.png" alt="How MD Works" %}

With this in mind, we can take a look at a very simple example of a LAMMPS input file, `in.lj`, and discuss each command -- and their related concepts -- one by one.
The order that the commands appear in **can** be important, depending on the exact details.
Always refer to the LAMMPS manual to check.


## Simulation setup

The first thing we have to do is chose a style of units.
This can be achieved by the `units` command:

```
units         lj
```

[comment]: # (link?)
LAMMPS has several different unit styles, useful in different types of simulations.
In this example, we are using `lj`, or Lennard-Jones units.
These are dimentionless units, that are defined on the LJ potential parameters.
They are computationally advantageous because they're usually close to unity, and required less precise (lower number of bits) floating point variables -- which in turn reduced the memory requirements, and increased calculation speed.

The next line defines what style of `atoms` (LAMMPS's terminology is for particle) to use.

```
atom_style    atomic
```

This impacts on what attributes each atom has associated with it -- this cannot be changed during a simulation
Every style stores: coordinates, velocities, atom IDs, and atom types.
The `atomic` style doesn't add any further attributes.

We then choose 3 dimentions.

```
dimension     3
```

LAMMPS is also capable of simulating two-dimentional systems.

The boundary command sets the styles for the boudaries for the simulation box.

```
boundary      p p p
```

Each of the three letters after the keyword corresponds to a direction (x, y, z), and `p` means that the selected boundary is to be periodic.
Other boundary conditions are available (fixed, shrink-wrapped, and shrink-wrapped with minimum).


{% include figure.html url="" max-width="80%" file="/fig/2_MD-primer/PBC.png" alt="Periodic Boundary Conditions" %}

Periodic boundary conditions allow the approximation of an infinite system by simulating only a small part, a unit-cell.
The most common shapes of (3D) unit-cell is cuboidal, but any shape that completely tesselates 3D space can be used.
The topology of PBCs is such that a particle leaving one side of the unit cell, it reappears on the other side.
A 2D map with PBC could be perfectly mapped to a torus.

Another key aspect of using PBCs is the use of **minimum-image convention** for calculating interactions between particles.
This guarantees that each particle interacts only with the closest *image* of another particle, no matter with unit-cell (the original simulation box or one of the periodic images) it belongs to.


The lattice command defines a set of points in space, where sc is simple cubic.

```
lattice       sc 0.60
```

In this case, because we are working in LJ units, the number `0.60` refers to the LJ density `ρ*`.

The region command defines a geometric region in space.

```
region        region1 block 0 10 0 10 0 10
```

The arguments are `region1`, a name we give to the region, `block`, the type of region (cuboid), and the numbers are the low and high values for x, y, and z.

We then create a box with one atom type, using the region we defined previously

```
create_box    1 region1
```

And finally, we create the atoms in the box, using the box and lattice previously created

```
create_atoms  1 box
```

The final result is a box like this:

{% include figure.html url="" max-width="80%" file="/fig/2_MD-primer/lattice.png" alt="Lattice" %}



## Inter-particle interactions

Now that we have initial positions for our particles in a simulation box, we have to define how they will interact with each-other.

The first line in this section defines the style of interaction our particles will use.

```
pair_style  lj/cut 3.5
```

In this case, Lennard-Jones interactions, cut at 3.5 Å.
Cutting the interactions at a certain distance (as oppposed to calculating interactions up to an 'infinite' distance, drastically reduces the computation time.
This approximation is only valid because the LJ potential is assymptotic to zero at high *d* distance between particles.

[comment]: # (side by side?)
{% include figure.html url="" max-width="80%" file="/fig/2_MD-primer/dist.png" alt="Distance between particles" %}

{% include figure.html url="" max-width="80%" file="/fig/2_MD-primer/lj_potential.png" alt="Lennard-Jones potential" %}

To make sure there is no discontinuity at the cutoff point, we can shift the potential.
This subtracts the value of the potential at the cutoff point (which should be very low) from the entire function, making the energy at the cutoff equal to zero.

```
pair_modify shift yes
```

Next we set the LJ parameters for the interactions between atom types `1` and `1` (the only we have, there can be more), ε, the maximum depth of the energy well, and σ, the zero-crossing distance for the potential.
Note that these are both relative to the non-shifted potential.

```
pair_coeff  1 1 1.0 1.0
```

Finally, we set the mass of atom type 1 to 1.0 units

```
mass        1 1.0
```

There are many other characteristics that may be needed for a given simulation.
For example, LAMMPS has functions to simulate bonds, angles, dihedrals, impropers, and more.



## Neighbour lists

To improve simulation performance, and because we are truncating interactions at a certain distance, we can keep a list of particles that are close to each other (under a neighbour cutoff distance).
This reduces the number of comparisons needed per timestep, at the cost of a small amount of memory.

{% include figure.html url="" max-width="80%" file="/fig/2_MD-primera/cutoff.png" alt="Neighbour lists" %}

So we can add a 0.3σ distance to our neight cutoff, above the LJ cutoff, so a total of 3.8σ.
The `bin` keyword refers to the algorithm used to build the list, `bin` is the best performing one for systems with homogenous sizes of particles.

```
neighbor        0.3 bin
```

However, these lists need to be updated periodically, essentially more often than it takes for a particle to move neighbour_cutoff - LJ_cutoff.
This is what the next command does.
The `delay` parameter sets the minimum number of timesteps that need to pass since the last neighbour list rebuild for LAMMPS to even consider rebuilding it again.
The `every` parameter tells LAMMPS to attempt to build the neighbour list if `number_time_step mod every = 0` -- by default, the rebuild will only be triggered if an atom has moved more than half the neighbour skin distance (the 0.3 above)

```
neigh_modify    delay 10 every 1
```

## Simulation parameters


Now that we set up the initial conditions for the simulation, and changed some settings to make sure it runs a bit faster, all that is left is telling LAMMPS exactly how we want the simulation to be.
This includes, but is not limited to, what ensemble to use (and which particles to apply it to), how bit is the timestep, how many timesteps we want to simulate, what properties we want as output, and how often.

The `fix` command has myriad options, most of them related to 'setting' certain properties at a value, or in an interval of values for one, all, or some particles in the simulation.

The first keywords are always `ID` -- a name to reference the fix by, and `group-ID` -- which particles to apply the command to.
The most common option for the second keyword is `all`.

```
fix     1 all nvt temp 1.00 1.00 5.0
```

Then we have the styles plus the arguments.
In the case above, the style is `nvt`, and the arguments are the temperatures at the start and end of the simulation run (`Tstart` and `Tstop`), and the temperature damping parameter (`Tdamp`), in time units.
[comment]: # (A Nose-Hoover thermostat will not work well for arbitrary values of Tdamp. If Tdamp is too small, the temperature can fluctuate wildly; if it is too large, the temperature will take a very long time to equilibrate. A good choice for many models is a Tdamp of around 100 timesteps. Note that this is NOT the same as 100 time units for most units settings.)

Another example of what a `fix` can do, is set a property (in this case, momentum), to a certain value:

```
fix     LinMom all momentum 50 linear 1 1 1 angular
```

This zeroes the linear momenta of all particles in all directions, as well as the angular momentum.

## Final setup


Although we created a number of particles in a box, if we were to run a simulation, not much would happen, because these particles do not have any starting velocities.
To change this, we use the `velocity` command, which generates an ensemble of velocities for the particles in the chosen group (in this case, `all`):

[comment]: # (JS says gaussian in video, but default is uniform)
```
velocity      all create 1.0 199085 mom no
```

The arguments after the `create` stype are the _temperature_ and _seed number_.
The `mom no` keyword/value pair prevents LAMMPS from zero-ing the linear momenta from the system.
[comment]: # (this seems to be opposite what we want, according to video)

Then we set the size of the timestep, in whatever units we have chosen for this simulation -- in this case, LJ units.

```
timestep      0.005
```

The size of the timestep is a careful juggling of speed vs. accuracy.
A small timestep guarantees that no particle interactions are missing, at the cost of a lot of computation time.
A large timestep allows for simulations that probe effects at long time scales, but risks a particle moving so much in each timestep, that some interactions are missed -- in extreme cases, some particles can 'fly' right through each other.
The 'happy medium' depends on the system type, size, and temperature, and can be estimated from the average diffusion of the particles.

The next line sets what thermodynamic information we want LAMMPS to output to the terminal and the log file.

```
thermo_style  custom step temp etotal pe ke press vol density
```

There are several default styles, and the `custom` style allows for full customization of which fields and in which order to write them.
To choose how often to write these fields, the command is:

```
thermo        500
```

To force LAMMPS to use the verlet algorithm (rather than the default velocity-verlet), we use:

```
run_style     verlet
```

And finally, we choose how many timesteps (**not time-units**) to run the simulation for:

```
run           50000
```


## Log file

The logfile is where we can find thermodynamic information of interest.
By default, the log file name that lammps creates, and which to it writes all the info that shows on the terminal, is `log.lammps`.
To change that, we could use the command:

```
log     new_file_name.extension
```

We can change which file to write to multiple times during a simulation, and even `append` to a file, for example, if we want the thermodynamic data separate from the logging of other assorted commands.
The thermodynamic data, which we setup with the `thermo` and `thermo_style` command, create the following (truncated) output:


```
    Step         Temp       TotEng       PotEng       KinEng        Press       Volume      Density
       0            1    -2.709841    -4.208341       1.4985   -2.6415761    1666.6667          0.6
     500   0.91083091   -2.6743978   -4.0392779    1.3648801   -0.1637597    1666.6667          0.6
    1000   0.96279851   -2.6272603   -4.0700139    1.4427536  -0.14422949    1666.6667          0.6
    1500   0.97878978   -2.6029892   -4.0697057    1.4667165  -0.11813628    1666.6667          0.6
    2000   0.93942595   -2.5817381   -3.9894679    1.4077298  -0.31689463    1666.6667          0.6
```

At the start, we get a header with the column names, and then a line for each timestep that's a multiple of the value we set `thermo` to.
In this example, because we're running an NVT simulation, both the simulation box volume, and the particle density are constant, but using other ensembles that would change.
At the end of each `run` command, we get the analysis of how the simulation time is spent:

```
Loop time of 16.0334 on 64 procs for 50000 steps with 1000 atoms

Performance: 1347185.752 tau/day, 3118.486 timesteps/s
96.6% CPU use with 8 MPI tasks x 8 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 5.6085     | 5.9415     | 6.2714     |   7.9 | 37.06
Neigh   | 1.3986     | 1.4617     | 1.5038     |   2.9 |  9.12
Comm    | 6.5302     | 6.7545     | 7.0383     |   6.1 | 42.13
Output  | 0.016128   | 0.0197     | 0.032095   |   3.5 |  0.12
Modify  | 1.278      | 1.6491     | 1.8464     |  16.7 | 10.29
Other   |            | 0.2068     |            |       |  1.29

Nlocal:        125.000 ave         133 max         114 min
Histogram: 1 0 0 2 1 1 0 0 0 3
Nghost:        1354.12 ave        1389 max        1322 min
Histogram: 1 0 1 2 1 0 0 2 0 1
Neighs:        8567.38 ave        9781 max        7536 min
Histogram: 1 1 2 0 1 0 0 2 0 1

Total # of neighbors = 68539
Ave neighs/atom = 68.539000
Neighbor list builds = 4999
Dangerous builds = 4995
```

The data here presented is very important, and can help you substantially improve the speed at which your simulations run.
The first line gives us the details of the last `run` command - how many seconds it took, on how many processes it ran on, how many timesteps, and how many atoms.
This can be useful to compare between different systems.

Then we get some benchmark information:

```
Performance: 1347185.752 tau/day, 3118.486 timesteps/s
96.6% CPU use with 8 MPI tasks x 8 OpenMP threads
```

How many time units per day / how many timesteps per second.
And how much of the available CPU resources LAMMPS was able to use, with how many MPI tasks and OpenMP threads.

The next table shows a breakdown of the time spent on each task by the MPI library.

```
MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 5.6085     | 5.9415     | 6.2714     |   7.9 | 37.06
Neigh   | 1.3986     | 1.4617     | 1.5038     |   2.9 |  9.12
Comm    | 6.5302     | 6.7545     | 7.0383     |   6.1 | 42.13
Output  | 0.016128   | 0.0197     | 0.032095   |   3.5 |  0.12
Modify  | 1.278      | 1.6491     | 1.8464     |  16.7 | 10.29
Other   |            | 0.2068     |            |       |  1.29
```

The `Pair` line refers to non-bonded force computations, `Bond` includes all bonded interactions, including angles, dihedrals, and impropers, `Kspace` relates to long-range interactions (Ewald, PPPM or MSM), `Neigh` is the contruction of neighbour lists, Comm is inter-processor communication (AKA, parallelization overhead), `Output` is the writing of files (log and dump files), `Modify` is the fixes and computes invoked by fixes, and `Other` is everything else.
Each category shows a breakdown of the least, average, and most amount of wall time any processor spent on each category -- large variability in this (calculated as %varavg) could show that the atom distribution between processors is not optimal.
The final column, %total, is the percentage of the loop time spent in the category.

A rule-of-thumb for %total on each category is:
  - `Pair`: as much as possible.
  - `Neigh`: 10% to 30%.
  - `Kspace`: 10% to 30%.
  - `Comm`: as little as possible. If it's growing large, it's a clear sign that too many computational resources are being assigned to a simulation.

The last line on every LAMMPS simulation will be the total wall time for the entire input script, no matter how many `run` commands it has:

```
Total wall time: 0:00:16
```

## `Fix`es and `Compute`s



1h30-ish
more topics:

- logfile
- fix numbers
- dump command and file
- vmd visualization
- other packages - ovito, mdanalysis, pylat, packmol, topotools
- MSC, RDF, VACF
- variables



[comment]: # (move whole file somewhere else?)
```
LAMMPS (29 Sep 2021 - Update 2)
  using 8 OpenMP thread(s) per MPI task
####################################
# Example LAMMPS input script      #
# for a simple Lennard Jones fluid #
####################################

####################################
# 1) Set up simulation box
#   - We set a 3D periodic box
#   - Our box has 10x10x10 atom
#     positions, evenly distributed
#   - The atom starting sites are
#     separated such that the box
#     density is 0.6
####################################

units         lj
atom_style    atomic
dimension     3
boundary      p p p

lattice       sc 0.60
Lattice spacing in x,y,z = 1.1856311 1.1856311 1.1856311
region        region1 block 0 10 0 10 0 10
create_box    1 region1
Created orthogonal box = (0.0000000 0.0000000 0.0000000) to (11.856311 11.856311 11.856311)
  2 by 2 by 2 MPI processor grid
create_atoms  1 box
Created 1000 atoms
  using lattice units in orthogonal box = (0.0000000 0.0000000 0.0000000) to (11.856311 11.856311 11.856311)
  create_atoms CPU = 0.003 seconds

####################################
# 2) Define interparticle interactions
#   - Here, we use truncated & shifted LJ
#   - All atoms of type 1 (in this case, all atoms)
#     have a mass of 1.0
####################################

pair_style  lj/cut 3.5
pair_modify shift yes
pair_coeff  1 1 1.0 1.0
mass        1 1.0

####################################
# 3) Neighbour lists
#   - Each atom will only consider neighbours
#     within a distance of 3.8 of each other
#   - The neighbour lists are recalculated
#     every timestep
####################################

neighbor        0.3 bin
neigh_modify    delay 10 every 2

####################################
# 4) Define simulation parameters
#   - We fix the temperature and
#     linear and angular momenta
#     of the system
#   - We run with fixed number (n),
#     volume (v), temperature (t)
####################################

fix     LinMom all momentum 50 linear 1 1 1 angular
fix     1 all nvt temp 1.00 1.00 5.0
#fix    1 all npt temp 1.0 1.0 25.0 iso 1.5150 1.5150  10.0

####################################
# 5) Final setup
#   - Define starting particle velocity
#   - Define timestep
#   - Define output system properties (temp, energy, etc.)
#   - Define simulation length
####################################

velocity      all create 1.0 199085 mom no

timestep      0.005

thermo_style  custom step temp etotal pe ke press vol density
thermo        500

run_style     verlet

run           50000
Neighbor list info ...
  update every 2 steps, delay 10 steps, check yes
  max neighbors/atom: 2000, page size: 100000
  master list distance cutoff = 3.8
  ghost atom cutoff = 3.8
  binsize = 1.9, bins = 7 7 7
  1 neighbor lists, perpetual/occasional/extra = 1 0 0
  (1) pair lj/cut, perpetual
      attributes: half, newton on
      pair build: half/bin/atomonly/newton
      stencil: half/bin/3d
      bin: standard
Per MPI rank memory allocation (min/avg/max) = 9.306 | 9.306 | 9.306 Mbytes
Step Temp TotEng PotEng KinEng Press Volume Density
       0            1    -2.709841    -4.208341       1.4985   -2.6415761    1666.6667          0.6
     500   0.91083091   -2.6743978   -4.0392779    1.3648801   -0.1637597    1666.6667          0.6
    1000   0.96279851   -2.6272603   -4.0700139    1.4427536  -0.14422949    1666.6667          0.6
    1500   0.97878978   -2.6029892   -4.0697057    1.4667165  -0.11813628    1666.6667          0.6
    2000   0.93942595   -2.5817381   -3.9894679    1.4077298  -0.31689463    1666.6667          0.6
    2500   0.98989793   -2.5426159    -4.025978    1.4833621  -0.21388375    1666.6667          0.6
    3000   0.99092654   -2.5075332   -3.9924366    1.4849034 -0.090395612    1666.6667          0.6
    3500    1.0066489   -2.4982269   -4.0066902    1.5084633 -0.077231277    1666.6667          0.6
    4000    1.0048304   -2.4910482   -3.9967866    1.5057383 -0.063325317    1666.6667          0.6
    4500    1.0242239   -2.4981649   -4.0329644    1.5347995  -0.22270505    1666.6667          0.6
    5000    1.0100446   -2.5004621   -4.0140138    1.5135518  -0.20163921    1666.6667          0.6
    5500   0.98129739   -2.4988101   -3.9692842    1.4704741 -0.034802309    1666.6667          0.6
    6000   0.99147314    -2.486528   -3.9722505    1.4857225 -0.064489376    1666.6667          0.6
    6500   0.97945543   -2.4630647   -3.9307787     1.467714 -0.041378709    1666.6667          0.6
    7000   0.99499258   -2.4487808   -3.9397772    1.4909964 -0.093811981    1666.6667          0.6
    7500    1.0277165    -2.448077   -3.9881102    1.5400332  -0.14716961    1666.6667          0.6
    8000    1.0020983   -2.4568316   -3.9584759    1.5016443 -0.013690964    1666.6667          0.6
    8500    1.0106688   -2.4811626   -3.9956498    1.5144872  -0.19509292    1666.6667          0.6
    9000   0.98688574   -2.5103599   -3.9892082    1.4788483 -0.097524776    1666.6667          0.6
    9500    0.9783801   -2.5521127   -4.0182153    1.4661026  -0.18024761    1666.6667          0.6
   10000   0.92575618   -2.6075577   -3.9948033    1.3872456  -0.32843094    1666.6667          0.6
   10500   0.94124065   -2.6245156   -4.0349647    1.4104491  -0.16551782    1666.6667          0.6
   11000    0.9584401   -2.6049813   -4.0412038    1.4362225   -0.1065528    1666.6667          0.6
   11500   0.98845297   -2.5687789   -4.0499757    1.4811968  -0.17864943    1666.6667          0.6
   12000   0.98588315   -2.5453655   -4.0227114    1.4773459  -0.19041353    1666.6667          0.6
   12500    1.0198408   -2.5271074   -4.0553388    1.5282315  -0.22635865    1666.6667          0.6
   13000    1.0103819   -2.5199613   -4.0340185    1.5140573  -0.23085321    1666.6667          0.6
   13500   0.99116275   -2.5112791   -3.9965365    1.4852574   -0.1251822    1666.6667          0.6
   14000    1.0074329   -2.5100108   -4.0196491    1.5096383  -0.38796855    1666.6667          0.6
   14500     1.006875   -2.4931339   -4.0019361    1.5088022  -0.19684389    1666.6667          0.6
   15000    1.0074173   -2.4792517   -3.9888665    1.5096148 -0.023416844    1666.6667          0.6
   15500    1.0169607   -2.4695572   -3.9934728    1.5239156 -0.062938656    1666.6667          0.6
   16000    1.0189476   -2.4765888   -4.0034817    1.5268929 -0.094746625    1666.6667          0.6
   16500   0.99545783   -2.4941593   -3.9858528    1.4916936 -0.080389317    1666.6667          0.6
   17000   0.99903729   -2.5144196    -4.011477    1.4970574  -0.22548397    1666.6667          0.6
   17500   0.96412351   -2.5456594   -3.9903984    1.4447391  0.042475002    1666.6667          0.6
   18000   0.97202734   -2.5796861   -4.0362691     1.456583  -0.25246206    1666.6667          0.6
   18500   0.97103686   -2.5925057   -4.0476045    1.4550987  -0.29585989    1666.6667          0.6
   19000   0.96088414   -2.5645067   -4.0043916    1.4398849  -0.22722527    1666.6667          0.6
   19500   0.95309405   -2.5237472   -3.9519587    1.4282114  -0.15497449    1666.6667          0.6
   20000    1.0117939    -2.500082   -4.0162551    1.5161731 -0.088936094    1666.6667          0.6
   20500    1.0134791   -2.4819574   -4.0006558    1.5186984  -0.14212934    1666.6667          0.6
   21000    1.0119635   -2.4858174   -4.0022446    1.5164273  -0.11951089    1666.6667          0.6
   21500   0.97862285   -2.4946907    -3.961157    1.4664663   -0.1265713    1666.6667          0.6
   22000   0.98887866   -2.4875116   -3.9693463    1.4818347  -0.11687708    1666.6667          0.6
   22500   0.99721991    -2.474157    -3.968491     1.494334  -0.14927086    1666.6667          0.6
   23000   0.98705517   -2.4579436   -3.9370458    1.4791022 0.0086972965    1666.6667          0.6
   23500    1.0141843   -2.4480582   -3.9678135    1.5197552  -0.12036053    1666.6667          0.6
   24000    1.0294177   -2.4455931   -3.9881755    1.5425824 -0.060820019    1666.6667          0.6
   24500    1.0375479   -2.4523793   -4.0071448    1.5547655 -0.031832321    1666.6667          0.6
   25000    1.0318477   -2.4684848   -4.0147086    1.5462238  -0.22989989    1666.6667          0.6
   25500     1.019944   -2.5089494   -4.0373355    1.5283861  -0.11974876    1666.6667          0.6
   26000   0.96602462   -2.5731197   -4.0207076    1.4475879 -0.065787607    1666.6667          0.6
   26500    0.9390189   -2.6169561   -4.0240759    1.4071198  -0.25403657    1666.6667          0.6
   27000   0.93839357   -2.6251658   -4.0313486    1.4061828  -0.32746416    1666.6667          0.6
   27500   0.95331828   -2.5796776    -4.008225    1.4285474  -0.16990894    1666.6667          0.6
   28000   0.99785869   -2.5457729   -4.0410642    1.4952912  -0.12629002    1666.6667          0.6
   28500      1.00264   -2.5364664   -4.0389225    1.5024561  -0.18451717    1666.6667          0.6
   29000   0.99530019   -2.5172341   -4.0086915    1.4914573  -0.22066215    1666.6667          0.6
   29500    0.9839226   -2.4959073   -3.9703153     1.474408  -0.12033832    1666.6667          0.6
   30000   0.99325541   -2.4728823   -3.9612755    1.4883932 -0.0048169871    1666.6667          0.6
   30500    1.0285438   -2.4568129   -3.9980857    1.5412728  -0.26467681    1666.6667          0.6
   31000    1.0590888   -2.4557379   -4.0427824    1.5870445  -0.18447338    1666.6667          0.6
   31500    1.0164847   -2.4800373   -4.0032395    1.5232023  -0.22645999    1666.6667          0.6
   32000   0.99080711   -2.5119737   -3.9966982    1.4847245   -0.1265037    1666.6667          0.6
   32500   0.94510815    -2.546002   -3.9622466    1.4162446 -0.063690018    1666.6667          0.6
   33000   0.96563254   -2.5804015   -4.0274019    1.4470004  -0.28293171    1666.6667          0.6
   33500   0.96232138   -2.5969955   -4.0390341    1.4420386  -0.32986956    1666.6667          0.6
   34000   0.97909543   -2.5845543   -4.0517288    1.4671745  -0.18834515    1666.6667          0.6
   34500   0.99040568   -2.5411619   -4.0252848    1.4841229   -0.1634422    1666.6667          0.6
   35000    1.0071587   -2.5131607   -4.0223881    1.5092273  -0.35539432    1666.6667          0.6
   35500    1.0121755   -2.4933789    -4.010124     1.516745  -0.25514604    1666.6667          0.6
   36000    1.0099296   -2.4776894   -3.9910689    1.5133795 -0.039293043    1666.6667          0.6
   36500    1.0117648   -2.4760682   -3.9921977    1.5161295 -0.069723947    1666.6667          0.6
   37000    1.0086079   -2.4843474   -3.9957463    1.5113989  -0.27645342    1666.6667          0.6
   37500   0.99340122   -2.4959011   -3.9845128    1.4886117  -0.27730419    1666.6667          0.6
   38000   0.97740779   -2.5021772   -3.9668228    1.4646456  -0.12781668    1666.6667          0.6
   38500    1.0154991   -2.4867624   -4.0084878    1.5217254 -0.062357868    1666.6667          0.6
   39000    1.0030633   -2.4569116   -3.9600019    1.5030903  -0.04908502    1666.6667          0.6
   39500    1.0377885   -2.4341681   -3.9892942    1.5551261  0.016953104    1666.6667          0.6
   40000    1.0061732   -2.4367237   -3.9444743    1.5077506 0.0025093913    1666.6667          0.6
   40500    1.0257736   -2.4668125   -4.0039342    1.5371217 -0.033146207    1666.6667          0.6
   41000   0.99731569   -2.5124453   -4.0069229    1.4944776  -0.29221179    1666.6667          0.6
   41500   0.98434804   -2.5689267   -4.0439723    1.4750455  -0.17128806    1666.6667          0.6
   42000   0.96706482   -2.6134345   -4.0625811    1.4491466  -0.21438059    1666.6667          0.6
   42500   0.97383648    -2.635163   -4.0944569     1.459294  -0.22682797    1666.6667          0.6
   43000   0.95963228   -2.6125799   -4.0505889     1.438009  -0.23970972    1666.6667          0.6
   43500   0.98853201   -2.5388115   -4.0201267    1.4813152  -0.16619677    1666.6667          0.6
   44000   0.98793299   -2.5174544    -3.997872    1.4804176  -0.20721969    1666.6667          0.6
   44500   0.99676817   -2.5019089    -3.995566    1.4936571 -0.074597226    1666.6667          0.6
   45000   0.99746765   -2.4974955   -3.9922008    1.4947053 -0.081597864    1666.6667          0.6
   45500     1.014651   -2.4849706   -4.0054252    1.5204546  -0.14683595    1666.6667          0.6
   46000    1.0157122   -2.4845279   -4.0065727    1.5220447  -0.11731195    1666.6667          0.6
   46500     1.006211   -2.4895868    -3.997394    1.5078072 -0.086182393    1666.6667          0.6
   47000    1.0095968   -2.4923775   -4.0052583    1.5128807  -0.13670296    1666.6667          0.6
   47500    1.0019937    -2.492081   -3.9935686    1.5014876 -0.018030502    1666.6667          0.6
   48000    1.0089638   -2.4966741   -4.0086064    1.5119323  -0.31263487    1666.6667          0.6
   48500    1.0147705   -2.4867265   -4.0073602    1.5206337  -0.14497921    1666.6667          0.6
   49000    1.0261125   -2.4779895   -4.0156192    1.5376297  -0.22294716    1666.6667          0.6
   49500   0.98703023   -2.4853156   -3.9643804    1.4790648 -0.026615225    1666.6667          0.6
   50000    1.0031671   -2.4845102   -3.9877561     1.503246 -0.077383309    1666.6667          0.6
Loop time of 16.0334 on 64 procs for 50000 steps with 1000 atoms

Performance: 1347185.752 tau/day, 3118.486 timesteps/s
96.6% CPU use with 8 MPI tasks x 8 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 5.6085     | 5.9415     | 6.2714     |   7.9 | 37.06
Neigh   | 1.3986     | 1.4617     | 1.5038     |   2.9 |  9.12
Comm    | 6.5302     | 6.7545     | 7.0383     |   6.1 | 42.13
Output  | 0.016128   | 0.0197     | 0.032095   |   3.5 |  0.12
Modify  | 1.278      | 1.6491     | 1.8464     |  16.7 | 10.29
Other   |            | 0.2068     |            |       |  1.29

Nlocal:        125.000 ave         133 max         114 min
Histogram: 1 0 0 2 1 1 0 0 0 3
Nghost:        1354.12 ave        1389 max        1322 min
Histogram: 1 0 1 2 1 0 0 2 0 1
Neighs:        8567.38 ave        9781 max        7536 min
Histogram: 1 1 2 0 1 0 0 2 0 1

Total # of neighbors = 68539
Ave neighs/atom = 68.539000
Neighbor list builds = 4999
Dangerous builds = 4995
Total wall time: 0:00:16
```


[comment]: # (move whole file somewhere else?)
```
####################################
# Example LAMMPS input script      #
# for a simple Lennard Jones fluid #
####################################

####################################
# 1) Set up simulation box
#   - We set a 3D periodic box
#   - Our box has 10x10x10 atom 
#     positions, evenly distributed
#   - The atom starting sites are
#     separated such that the box
#     density is 0.6
####################################

units         lj
atom_style    atomic
dimension     3
boundary      p p p

lattice       sc 0.60
region        region1 block 0 10 0 10 0 10
create_box    1 region1
create_atoms  1 box

####################################
# 2) Define interparticle interactions
#   - Here, we use truncated & shifted LJ
#   - All atoms of type 1 (in this case, all atoms)
#     have a mass of 1.0
####################################

pair_style  lj/cut 3.5
pair_modify shift yes
pair_coeff  1 1 1.0 1.0
mass        1 1.0

####################################
# 3) Neighbour lists
#   - Each atom will only consider neighbours
#     within a distance of 3.8 of each other
#   - The neighbour lists are recalculated
#     every timestep
####################################

neighbor        0.3 bin
neigh_modify    delay 10 every 1

####################################
# 4) Define simulation parameters
#   - We fix the temperature and 
#     linear and angular momenta
#     of the system 
#   - We run with fixed number (n),
#     volume (v), temperature (t)
####################################

fix     LinMom all momentum 50 linear 1 1 1 angular
fix     1 all nvt temp 1.00 1.00 5.0
#fix    1 all npt temp 1.0 1.0 25.0 iso 1.5150 1.5150  10.0

####################################
# 5) Final setup
#   - Define starting particle velocity
#   - Define timestep
#   - Define output system properties (temp, energy, etc.)
#   - Define simulation length
####################################

velocity      all create 1.0 199085 mom no

timestep      0.005

thermo_style  custom step temp etotal pe ke press vol density
thermo        500

run_style     verlet

run           50000
```


# advanced lammps course stuff (for reference)

The `in.ethanol` LAMMPS input that we are using for this exercise is an 
easily edited benchmark script used within EPCC to test system performance. 
The intention of this script is to be easy to edit and alter when running on 
very varied core/node counts. By editing the `X_LENGTH`, `Y_LENGTH`, and 
`Z_LENGTH` variables, you can increase the box size substantially. As to the 
choice of molecule, we wanted something small and with partial charges -- 
ethanol fits both of those.
{: .callout}

To submit your first job on ARCHER2, please run:

```bash
sbatch sub.slurm
```

You can check the progress of your job by running `squeue -u ${USER}`. Your 
job state will go from `PD` (pending) to `R` (running) to `CG` (cancelling). 
Once your job is complete, it will have produced a file called 
`slurm-####.out` -- this file contains the STDOUT and STDERR produced by your 
job.

The job will also produce a LAMMPS log file `log.out`. In this file, you will 
find all of the thermodynamic outputs that were specified in the LAMMPS 
`thermo_style`, as well as some very useful performance information! After 
every `run` is complete, LAMMPS outputs a series of information that can be 
used to better understand the behaviour of your job.

```
Loop time of 197.21 on 1 procs for 10000 steps with 1350 atoms

Performance: 4.381 ns/day, 5.478 hours/ns, 50.707 timesteps/s
100.0% CPU use with 1 MPI tasks x 1 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 68.063     | 68.063     | 68.063     |   0.0 | 34.51
Bond    | 5.0557     | 5.0557     | 5.0557     |   0.0 |  2.56
Kspace  | 5.469      | 5.469      | 5.469      |   0.0 |  2.77
Neigh   | 115.22     | 115.22     | 115.22     |   0.0 | 58.43
Comm    | 1.4039     | 1.4039     | 1.4039     |   0.0 |  0.71
Output  | 0.00034833 | 0.00034833 | 0.00034833 |   0.0 |  0.00
Modify  | 1.8581     | 1.8581     | 1.8581     |   0.0 |  0.94
Other   |            | 0.139      |            |       |  0.07

Nlocal:        1350.00 ave        1350 max        1350 min
Histogram: 1 0 0 0 0 0 0 0 0 0
Nghost:        10250.0 ave       10250 max       10250 min
Histogram: 1 0 0 0 0 0 0 0 0 0
Neighs:        528562.0 ave      528562 max      528562 min
Histogram: 1 0 0 0 0 0 0 0 0 0

Total # of neighbors = 528562
Ave neighs/atom = 391.52741
Ave special neighs/atom = 7.3333333
Neighbor list builds = 10000
Dangerous builds not checked
Total wall time: 0:05:34
```

The ultimate aim is always to get your simulation to run in a sensible amount 
of time. This often simply means trying to optimise the final value ("Total 
wall time"), though some people care more about optimising efficiency (wall 
time multiplied by core count). In this lesson, we will be focusing on what 
we can do to improve these.

## Increasing computational resources

The first approach that most people take to increase the speed of their 
simulations is to increase the computational resources. If your system can 
accommodate this, doing this can sometimes lead to "easy" improvements. 
However, this usually comes at an increased cost (if running on a system for 
which compute is charged) and does not always lead to the desired results.

In your first run, LAMMPS was run on a single core. For a large enough system, 
increasing the number of cores used should reduce the total run time. In your 
`sub.slurm` file, you can edit the `-n #` in the line:

```bash
srun --exact -n 1 lmp -i in.ethanol -l log.out
```

to run on more cores. An ARCHER2 node has 128 cores, so you could potential 
run on up to 128 cores.


> ## Quick benchmark
>
> As a first exercise, fill in the table below.
> 
>  |Number of cores| Walltime | Performance (ns/day) |
>  |---------------|----------|----------------------|
>  |   1  | | | |
>  |   2  | | | |
>  |   4  | | | |
>  |   8  | | | |
>  |  16  | | | |
>  |  32  | | | |
>  |  64  | | | |
>  | 128  | | | |
>
> Do you spot anything unusual in these run times? If so, can you explain this 
> strange result?
> 
> > ## Solution
> > 
> > The simulation takes almost the same amount of time when running on a 
> > single core as when running on two cores. A more detailed look into the 
> > `in.ethanol` file will reveal that this is because the simulation box is 
> > not uniformly packed.
> > 
> {: .solution}
{: .challenge}

> ## Note
> Here are only considering MPI parallelisation -- LAMMPS offers the option 
> to run using joint MPI+OpenMP (more on that later), but for the exercises 
> in this lesson, we will only be considering MPI.
{: .callout}

## Domain decomposition

In the previous exercise, you will (hopefully) have noticed that, while the 
simulation run time decreases overall as the core count is increased, the 
run time was the same when run on one processor as it was when run on two 
processors. This unexpected behaviour (for a truly strong-scaling system, you 
would expect the simulation to run twice as fast on two cores as it does on a 
single core) can be explained by looking at our starting simulation 
configuration and understanding how LAMMPS handles domain decomposition.

In parallel computing, domain decomposition describes the methods used to 
split calculations across the cores being used by the simulation. How domain 
decomposition is handled varies from problem to problem. In the field of 
molecular dynamics (and, by extension, withing LAMMPS), this decomposition is 
done through spatial decomposition -- the simulation box is split up into a 
number of blocks, with each block being assigned to their own core.

By default, LAMMPS will split the simulation box into a number of equally 
sized blocks and assign one core per block. The amount of work that a given 
core needs to do is directly linked to the number of atoms within its part of 
the domain. If a system is of uniform density (i.e. if each block contains 
roughly the same number of particles), then each core will do roughly the same 
amount of work and will take roughly the same amount of time to calculate 
interactions and move their part of the system forward to the next timestep. 
If, however, your system is not evenly distributed, then you run the risk of 
having a number of cores doing all of the work while the rest sit idle.

The system we have been simulating looks like this at the start of the 
simulation:

{% include figure.html url="" max-width="80%" file="/fig/2_performance/start_sim_box.jpg" alt="Starting system configuration" %}

As this is a system of non-uniform density, the default domain decomposition 
will not produce the desired results.

LAMMPS offers a number of methods to distribute the tasks more evenly across 
the processors. If you expect the distribution of atoms within your simulation 
to remain constant throughout the simulation, you can use a `balance` command 
to run a one-off rebalancing of the simulation across the cores at the start 
of your simulation. On the other hand, if you expect the number of atoms per 
region of your system to fluctuate (e.g. as is common in evaporation), you may 
wish to consider recalculating the domain decomposition every few timesteps 
with the dynamic `fix balance` command.

For both the static, one-off `balance` and the dynamic `fix balance` commands, 
LAMMPS offers two methods of load balancing -- the "grid-like" `shift` method 
and the "tiled" `rcb` method. The diagram below helps to illustrate how these 
work.

{% include figure.html url="" max-width="80%" file="/fig/2_performance/balance.jpg" alt="LAMMPS balance methods" %}

> ## Using better domain decomposition
> 
> In your `in.ethanol` file, uncomment the `fix balance` command and rerun 
> your simulations. What do you notice about the runtimes? We are using the 
> dynamic load balancing command -- would the static, one-off `balance` 
> command be effective here?
> 
> > ## Solution
> > 
> > The runtimes decrease significantly when running with dynamic load 
> > balancing. In this case, static load balancing would not work as the 
> > ethanol is still expanding to fill the simulation box. Once the ethanol 
> > is evenly distributed within the box, you can remove the dynamic load 
> > balancing.
> {: .solution}
{: .challenge}

> ## Playing around with dynamic load balancing
> 
> In the example, the `fix balance` is set to be recalculated every 1,000 
> timesteps. How does the runtime vary as you change this value? I would 
> recommend trying 10, 100, and 10,000.
> 
> > ## Solution
> > 
> > The simulation time can vary drastically depending on how often 
> > rebalancing is carried out. When using dynamic rebalancing, there is an 
> > important trade-off between the time gained from rebalancing and the cost 
> > involved with recalculating the load balance among cores.
> > 
> {: .solution}
{: .challenge}

You can find more information about how LAMMPS handles domain decomposition in 
the LAMMPS manual [balance](https://docs.lammps.org/balance.html) and 
[fix balance](https://docs.lammps.org/fix_balance.html) sections.

## Considering neighbour lists

Let's take another look at the profiling information provided by LAMMPS:

```
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 68.063     | 68.063     | 68.063     |   0.0 | 34.51
Bond    | 5.0557     | 5.0557     | 5.0557     |   0.0 |  2.56
Kspace  | 5.469      | 5.469      | 5.469      |   0.0 |  2.77
Neigh   | 115.22     | 115.22     | 115.22     |   0.0 | 58.43
Comm    | 1.4039     | 1.4039     | 1.4039     |   0.0 |  0.71
Output  | 0.00034833 | 0.00034833 | 0.00034833 |   0.0 |  0.00
Modify  | 1.8581     | 1.8581     | 1.8581     |   0.0 |  0.94
Other   |            | 0.139      |            |       |  0.07
```

This output can provide us with a lot of valuable information about where our 
simulation is taking a long time, and can help us assess where we can save 
time. In general, when running a new simulation on a multi-core system, three of 
these values are worth particular attention (though all will tell you where 
your system is spending most of its time):

  - `Pair` indicates how much time is spent calculating pairwise particle
    interactions. Ideally, when running a sensible system in a sensible 
    fashion, timings will be dominated by this.
  - `Neigh` will let you know how much time is being spent building up 
    neighbour lists. As a rule of thumb, this should be in the 10-30% region.
  - `Kspace` will let you know how much time is being spent calculating 
    long-ranged interactions. Like with `Neigh`, this should be in the 10-30% 
    range.
  - `Comm` lets you know how much time is spent in communication between 
    cores. This should never dominate simulation times and, if it does, this 
    is the most obvious sign that too many computational recources are being 
    assigned to run the simulation.

In the example above, we notice that the majority of the time is spent 
in the `Neigh` section -- e.g. a lot of time is spent calculating neighbour 
lists. Neighbour lists are a common method for speeding up simulations with 
short-ranged particle-particle interactions. Most interactions are based on 
interparticle distance and traditionally the distance between every particle 
and every other particle would need to be calculated every timestep (this is 
an O(N^2) calculation!). Neighbour lists are a way to reduce this to an ~O(N) 
calculation for truncated short-ranged interactions. Instead of considering 
all interactions between every particle in a system, you can generate a list 
of all particles within the truncation cutoff plus a little bit more. 
Depending on the size of that "little bit more" and the details of your 
system, you can work out how quickly a particle that is not in this list can 
move to be within the short-ranged interaction cutoff. With this time, you can 
work out how frequently you need to update this list.

{% include figure.html url="" max-width="80%" file="/fig/2_performance/neigh_list.jpg" alt="Neighbour lists explained" %}

Doing this reduces the number of times that all interparticle distances need 
to be calculated: every few timestep, the interparticle distances for all 
particle pairs are calculated to generate the neighbour list for each 
particle; and in the interim, only the interparticle distances for particles 
within a neighbour list need be calculated (as this is a much smaller 
proportion of the full system, this greatly reduces the total number of 
calculations).

If we dig a bit deeper into our `in.ethanol` LAMMPS input file, we will notice 
the following lines:

```
variable        NEIGH_TIME  equal      1    # neigh_modify every x dt
...
neigh_modify    delay 0 every ${NEIGH_TIME} check no
```

These lines together indicate that LAMMPS is being instructed to rebuild the 
full neighbour list every timestep (so this is not a very good use of 
neighbour lists).

> ## Changing neighbour list update frequency
> 
> Change the `NEIGH_TIME` variable to equal 10. How does this affect the 
> simulation runtime?
> 
> Now change the `NEIGH_TIME` variable to equal 1000. What happens now?
{: .challenge}

Neighbour lists only give physical solutions when the update time is less than 
the time it would take for a particle outwith the neighbour cutoff to get to 
within the short-ranged interaction cutoff. If this happens, the results 
generated by the simulation become questionable at best and, in the worst 
case, LAMMPS will crash.

You can estimate the frequency at which you need to rebuild neighbour lists by 
running a quick simulation with neighbour list rebuilds every timestep:

```
neigh_modify    delay 0 every 1 check yes
```

and looking at the resultant LAMMPS neighbour list information in the log file 
generated by that run.

```
Total # of neighbors = 1313528
Ave neighs/atom = 200.20241
Ave special neighs/atom = 7.3333333
Neighbor list builds = 533
Dangerous builds = 0
```

The `Neighbor list builds` tells you how often neighbour lists needed to be 
rebuilt. If you know how many timesteps your short simulation ran for, you can 
estimate the frequency at which you need to calculate neighbour lists by 
working out how many steps there are per rebuild on average. Provided that 
your update frequency is less than or equal to that, you should see a speed up.

In this secion, we only considered changing the frequency of updating 
neighbour lists. Two other factors that contribute to the time taken 
to calculate neighbour lists are the `pair_style` cutoff distance and the 
`neighbor` skin distance. Decreasing either of these will reduce the number of 
particles within the neighbour cutoff distance, thereby decreasing the number 
of interactions being calculated each timestep. However, decreasing these will 
mean that lists need to be rebuilt more frequently -- it's always a fine 
balance.

You can find more information in the LAMMPS manual about 
[neighbour lists](https://docs.lammps.org/Developer_par_neigh.html) and the 
[neigh_modify](https://docs.lammps.org/neigh_modify.html) command.

## Some further tips

### Fixing bonds and angles

A lot of interesting system involve simulating particles bonded into 
molecules. In a lot of classical atomistic systems, some of these bonds 
fluctuate significantly and at high frequencies while not causing much 
interesting physics (thing e.g. carbon-hydrogen bonds in a hydrocarbon chain). 
As the timestep is restricted by the fastest-moving part of a simulation, the 
frequency of fluctuation of these bonds restricts the length of the timestep 
that can be used in the simulation. Using longer timesteps results in longer 
"real time" effects being simulated for the same amount of compute power, so 
being restricted to a shorter timestep because of "boring" bonds can be 
frustrating.

LAMMPS offers two methods of restricting these bonds (and their associated 
angles): the `SHAKE` and `RATTLE` fixes. Using these fixes will ensure that 
the desired bonds and angles are reset to their equilibrium length every 
timestep. An additional constraint is applied to these atoms to ensure that 
they can still move while keeping the bonds and angles as specified. This is 
especially useful for simulating fast-moving bonds at higher timesteps.

You can find more information about this in the 
[LAMMPS manual](https://docs.lammps.org/fix_shake.html)

### Hybrid MPI+OpenMP runs

When looking at the LAMMPS profiling information, we briefly mentioned that 
the proportion of time spent calculating `Kspace` should fall within the 
10-30% region. `Kspace` can often come to dominate the time profile when 
running with a large number of MPI ranks. This is a result of the way that 
LAMMPS handles the decomposition of k-space across multiple MPI ranks.

One way to overcome this problem is to run your simulation using hybrid 
MPI+OpenMP. To do this, you must ensure that you have compiled LAMMPS with the 
`OMP` package. On ARCHER2, you can edit the `sub.slurm` file that you have been 
using to include the following:

```bash
export OMP_NUM_THREADS=2
srun --tasks-per-node=64 --cpus-per-task=2 --exact \
      lmp -sf omp -i in.ethanol -l ${OMP_NUM_THREADS}_log.out 
```

Setting the variable `OMP_NUM_THREADS` will let LAMMPS know how many OpenMP 
threads will be used in the simulation. Setting `--tasks-per-node` and 
`--cpus-per-task` will ensure that Slurm assigns the correct number of MPI 
ranks and OpenMP threads to the executable. Setting the LAMMPS `--sf omp` flag 
will result in LAMMPS using the `OMP` version of any command in your LAMMPS 
input script.

Running hybrid jobs efficiently can add a layer of complications, and a number 
of additional considerations must be taken into account to ensure the desired 
results. Some of these are:

  - The product of the values assigned to `--tasks-per-node` and 
    `--cpus-per-task`should be less than or equal to the number of cores on a 
    node (on ARCHER2, that number is 128 cores).
  - You should try to restrict the number of OpenMP threads per MPI task to 
    fit on a single socket. For ARCHER2, the sockets (processors) are so large 
    that they have been subdivided into a number of NUMA regions. Each ARCHER2 
    node has 8 NUMA regions, each of which has 16 cores. Therefore, for an 
    efficient LAMMPS run, you would not want to use more than 16 OpenMP 
    processes per MPI tasl.
  - In a similar vein to the above, you also want to make sure that your 
    OpenMP threads are kept within a single NUMA region -- spanning across 
    multiple NUMA regions will decrease the performance (significantly).

These are only some of the things to bear in mind when considering using 
hybrid MPI+OpenMP to speed up k-space calculations. 

> ## Using `verlet/split` instead
>
> Another way to decrease the amount of compute being used by k-space 
> calculations is to use the `run_style verlet/split` command -- this 
> lets you split your force calculations across two partitions of cores. Using 
> this would let you define the partitions (and the amount of computational 
> resources assigned to this partition) on which long-ranged k-space 
> interactions are calculated.
> 
> You can find out more about this in the 
> [LAMMPS manual](https://docs.lammps.org/run_style.html)
{: .callout}

{% include links.md %}
