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

[comment]: # (add image w/ login/compute nodes and filesystem explanation)
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

## Advanced input commands

LAMMPS has a very powerful suite for calculating, and outputing all kinds of physical properties during the simulation.
Calculations are most often under a `compute` command, and then the output is handled by a `fix` command.
As an example, we will now see three examples, but there are (at the time of writing) over 150 different `compute` commands with many options each).

The first is a Radial Distribution Function, _g_(_r_), describes how the density of a particles varies as a function of the distance to the reference particle, compared with an uniform distribution (that is, at r → ∞, _g_(_r_) → 1).
Briefly, the `compute` command below, named `RDF` and applied to the atom-group `all`, is a compute of style `rdf`, with 150 bins for the RDF histogram, with a `cutoff` at 3.5σ.
There are optional parameters for calculating RDFs between specific pairs (or groups of pairs) of atom types, see the manual for more information.

```
compute        RDF all rdf 150 cutoff 3.5
fix            RDF_OUTPUT all ave/time 25 100 5000 c_RDF[*] file rdf_lj.out mode vector
```

The compute command is instantaneous, that is, they calculate the values for the current timestep, but that doesn't mean they calculate quantities every timestep.
A compute only calculates quantities when needed, _i.e._, when called by another command.
In this case, the `fix ave/time` command, that averages a quantity over time, and outputs it over a long timescale.
The parameters are: `RDF_OUTPUT` is the name of the fix, `all` is the group of particles it applies to, `ave/time` is the style of fix (there are many others).
Then, the group of three numbers `25 100 5000` are the `Nevery`, `Nrepeat`, `Nfreq` arguments.
These can be quite tricky to understand, as they interplay with eachother.
`Nfreq` is how often a value is written to file, `Nrepeat` is how many sets of values we want to average over (number of samples), and `Nevery` is how many timesteps in between samples.
So, for example, an `Nevery` of 2, with `Nrepeat` of 3, and `Nfreq` of 100 means that at every timestep multiple of 100, there will be an average written to file, that was calculated by taking 3 samples, 2 timesteps appart -- _i.e._, timesteps 96, 98, and 100 are averaged, and the average is written to file, and the same at timesteps 196, 198, and 200, etc.
In this case, we take a sample every 25 timesteps, 100 times, and output at timestep number 5000 -- so from timestep 2500 to 5000, sampling every 25 timesteps.
This means that `Nfreq` must be a multiple of `Nevery`, and `Nevery` must be non-zero even if `Nrepeat = 1`.
The following argument, `c_RDF[*]`, is the quantity to be averaged over.
The beggining `c_` indicates this is a compute ID, and the `[*]` wildcard in conjunction with `mode vector` makes the fix calculate the average for all the columns in the compute ID.
Finally, the `file rdf_lj.out` argument tells LAMMPS where to write the data to.
This file looks something like this:

```
# Time-averaged data for fix RDF_OUTPUT
# TimeStep Number-of-rows
# Row c_RDF[1] c_RDF[2] c_RDF[3]
105000 150
1 0.0116667 0 0
2 0.035 0 0
3 0.0583333 0 0
4 0.0816667 0 0
5 0.105 0 0
6 0.128333 0 0
...
```

Since version 4May2022 of LAMMPS, writing to YAML files support was added.
To write a YAML file, just change the extension accordingly `file rdf_lj.yaml`.
The file will then be in YAML format:

```
# Time-averaged data for fix RDF_OUTPUT_YAML
# TimeStep Number-of-rows
# Row c_RDF[1] c_RDF[2] c_RDF[3]
---
keywords: ['c_RDF[1]', 'c_RDF[2]', 'c_RDF[3]', ]
data:
  105000:
  - [0.011666666666666691, 0, 0, ]
  - [0.035000000000000045, 0, 0, ]
  - [0.05833333333333334, 0, 0, ]
...
```

The next example calculates the mean-squared displacement of a group of atoms (in this case, `all`).

```
compute        MSD all msd
fix            MSD_OUTPUT all ave/correlate 1 5000 5000 c_MSD[*] file msd_lj.out ave running
```

[comment]: # (never done MSD or time correlations, this needs some more explaining)
The `fix` is then taking a sample every timestep, and at timesteps divisible by 5000 it calculates the time correlation and writes it down to file (so, we get two values, at the start of the run, and end of the run).

And the final example is a velocity auto-correlation function

```
compute        VACF all vacf
fix            VACF_OUTPUT all ave/correlate 1 2500 5000 c_VACF[*] file vacf_lj.out ave running
```

[comment]: # (ditto from what I said about MSD)
Here the fix is taking 2500 samples from timestep 2501 to 5000.

The `dump` command allows to write trajectory files -- files that have the coordinates (and sometimes other properties) of each particle at a regular interval.
These are important to create visual representations of the evolution of the simulation (AKA molecular movies) or to allow for the calculation of properties after the simulation is done, without the need to re-run the simulation.

```
dump           2 all custom 1000 positions.lammpstrj id x y z vx vy vz
dump_modify    2 sort id
```

The `dump` command has id `2`, and will output information for `all` particles.
The style is `custom`, and will write to file `positions.lammpstrj` every `1000` timesteps.
The `custom` style is configurable, and we request that each atom has the following properties written to file: atom `id`, positions in the 3 directions, and velocity magnitudes in the 3 directions.
The `dump_modify` command makes sure that the atoms are written in order of `id`, rather than in whatever order they happen to get calculated.

Finally, we tell LAMMPS to run this section (with the computes and fixes) for `5000` timesteps.

```
run            5000
```

To allow the continuation of the simulation (with the caveat that it must continue to run in the same number of cores as it was), we can create a restart file:
This binary file contains information about system topology, force-fields, but not about computes, fixes, etc, these need to be re-defined in a new input file.

```
write_restart  restart2.lj.equil
```

An, arguably, better solution is to write a data file, which not only is a text file, but can then be used without restrictions in a different hardware configuration, or even LAMMPS version.

```
write_data  lj.equil.data
```

## Variables and loops

LAMMPS input scripts can be quite complex, and it can be useful to run the same script many times with only a small difference (for example, temperature).
For this reason, LAMMPS have implemented variables and loops -- but this doesn't mean that we can only use variables *with* loops.

A variable in LAMMPS is defined with the keyword `variable`, then a `name`, and then style and arguments, for example:

```
variable temperature equal 1.0
```

There are several styles (see the manual), but of note are `delete`, `index`, `loop`, and `equal`.
`equal` is the workhorse of the styles, and it can set a variable to a number, thermo keywords, math operators or functions, among other things.
`delete` unsets a variable.
`loop` and `index` are simular, with the difference that `loop` accepts an integer / range, while `index` accepts a list of strings.

To use a variable later in the script, just prepend a dollar sign, like so:

```
fix     1 all nvt temp $temperature $temperature 5.0
```

Example of loop:

```
variable a loop 10
label loop
dump 1 all atom 100 file.$a
run 10000
undump 1
next a
jump SELF loop
```

and of `index`:

```
variable d index run1 run2 run3 run4 run5 run6 run7 run8
label loop
shell cd $d
read_data data.polymer
run 10000
shell cd ..
clear
next d
jump SELF
```



1h30-ish
more topics:

- vmd visualization (maybe better as a demonstration?)
- other packages - ovito, mdanalysis, pylat, packmol, topotools
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


{: .callout}

{% include links.md %}
