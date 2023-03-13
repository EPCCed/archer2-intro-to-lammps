---
title: "An introduction to LAMMPS on ARCHER2"
teaching: 30
exercises: 20
questions:
- "What is LAMMPS?"
- "How do I run jobs in ARCHER2?"
objectives:
- "Understand what LAMMPS is."
- "Learn how to launch jobs on ARCHER2 using the slurm batch system."
- "Run a LAMMPS benchmark exercise to see how benchmarking can help improve code performance."
keypoints:
- "LAMMPS is a versatile software used in a wide range of subjects to run classical molecular dynamics simulations."
- "Running jobs on ARCHER2 requires a submission to the Slurm batch system using specific account, budget, queue, and qos keywords."
- "Adding more cores is not always the most effective way of increasing performance."
---


## What is LAMMPS?

LAMMPS (Large-scale Atomic/Molecular Massively Parallel Simulator) is a versatile classical molecular dynamics software package developed by Sandia National Laboratories and by its wide user-base.

It can be downloaded from [https://lammps.sandia.gov/download.html](https://lammps.sandia.gov/download.html)

Everything we are covering today (and a lot of other info) can be found in the [LAMMPS User Manual](https://lammps.sandia.gov/doc/Manual.html)


## Running LAMMPS on ARCHER2

ARCHER2 uses a module system. In general, you can run LAMMPS on ARCHER2 by using the LAMMPS module:

```bash
user@ln01:~> module spider lammps
--------------------------------------------------------------------------------------------
  lammps:
--------------------------------------------------------------------------------------------
     Versions:
        lammps/13_Jun_2022
        lammps/23_Jun_2022
        lammps/29_Sep_2021
     Other possible modules matches:
        cpl-lammps  cpl-openfoam-lammps

--------------------------------------------------------------------------------------------
  To find other possible module matches execute:

      $ module -r spider '.*lammps.*'

--------------------------------------------------------------------------------------------
  For detailed information about a specific "lammps" package (including how to load the modules) use the module's full name.
  Note that names that have a trailing (E) are extensions provided by other modules.
  For example:

     $ module spider lammps/29_Sep_2021
--------------------------------------------------------------------------------------------
```

Running `module load lammps` will set up your environment to use LAMMPS.
For this course, we will be using certain LAMMPS packages that are not included in the central module.
We have built a version of LAMMPS that can be accessed by ensuring that the following commands are run prior to executing your LAMMPS command.

```bash
module load lammps/23_Jun_2022
```

Once your environment is set up, you will have access to the `lmp` LAMMPS executable.
Note that you will only be able to run this on a single core on the ARCHER2 login node.


### Submitting a job to the compute nodes

To run LAMMPS on multiple cores/nodes, you will need to submit a job to the ARCHER2 compute nodes.
The compute nodes do not have access to the landing `home` file system -- this file system is to store useful/important information.

{% include figure.html url="" max-width="60%" file="/fig/2_MD-primer/archer2_architecture.png" alt="ARCHER2 architecture" %}

On ARCHER2, when submitting jobs to the compute nodes, make sure that you are in your `/work/ta100/ta100/<username>` directory, as the `/home` file system is not accessible to the compute nodes.

For this course, we have prepared a number of exercises.
You can get a copy of these exercises by running (make sure to run this from `/work`):

[comment]: # (change to intro link)
```bash
svn checkout https://github.com/EPCCed/archer2-intro-to-lammps/
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

> ## Why ethanol?
> 
> The `in.ethanol` LAMMPS input that we are using for this exercise is an 
> easily edited benchmark script used within EPCC to test system performance. 
> The intention of this script is to be easy to edit and alter when running on 
> very varied core/node counts. By editing the `X_LENGTH`, `Y_LENGTH`, and 
> `Z_LENGTH` variables, you can increase the box size substantially. As to the 
> choice of molecule, we wanted something small and with partial charges -- 
> ethanol seemed to fit both of those.
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
Loop time of 476.073 on 1 procs for 10000 steps with 6561 atoms

Performance: 1.815 ns/day, 13.224 hours/ns, 21.005 timesteps/s
100.0% CPU use with 1 MPI tasks x 1 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 152.27     | 152.27     | 152.27     |   0.0 | 31.98
Bond    | 21.617     | 21.617     | 21.617     |   0.0 |  4.54
Kspace  | 24.884     | 24.884     | 24.884     |   0.0 |  5.23
Neigh   | 273.91     | 273.91     | 273.91     |   0.0 | 57.53
Comm    | 2.0977     | 2.0977     | 2.0977     |   0.0 |  0.44
Output  | 0.000598   | 0.000598   | 0.000598   |   0.0 |  0.00
Modify  | 0.90765    | 0.90765    | 0.90765    |   0.0 |  0.19
Other   |            | 0.39       |            |       |  0.08

Nlocal:           6561 ave        6561 max        6561 min
Histogram: 1 0 0 0 0 0 0 0 0 0
Nghost:           8066 ave        8066 max        8066 min
Histogram: 1 0 0 0 0 0 0 0 0 0
Neighs:    1.29863e+06 ave 1.29863e+06 max 1.29863e+06 min
Histogram: 1 0 0 0 0 0 0 0 0 0

Total # of neighbors = 1298629
Ave neighs/atom = 197.93157
Ave special neighs/atom = 7.3333333
Neighbor list builds = 10000
Dangerous builds not checked
Total wall time: 0:08:45
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

[comment]: # (does this command still need the --exact flag?)
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


{% include links.md %}
