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



```
velocity      all create 1.0 199085 mom no
```

```
timestep      0.005
```

```
thermo_style  custom step temp etotal pe ke press vol density
```
```
thermo        500
```

```
run_style     verlet
```

```
run           50000
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
