---
title: "An introduction to LAMMPS and Molecular Dynamics"
teaching: 50
exercises: 20
questions:
- "What is LAMMPS?"
- "How do I run jobs in ARCHER2?"
- "What are molecular dynamics simulations?"
objectives:
- "Understand what LAMMPS is, how to launch jobs on ARCHER2 using the slurm batch system, and what molecular simulations are."
keypoints:
- "LAMMPS is a versatile software used in a wide range of subjects to run classical molecular dynamics simulations."
- "Running jobs on ARCHER2 requires a submission to the Slurm batch system using specific account, budget, queue, and qos keywords."
- "Molecular dynamics simulations are a method to analyse the physical movement of a system of many particles that are allowed to interact."
---


## What is LAMMPS?

LAMMPS (Large-scale Atomic/Molecular Massively Parallel Simulator) is a versatile classical molecular dynamics software package developed by Sandia National Laboratories and by its wide user-base.

It can be downloaded from [https://lammps.sandia.gov/download.html](https://lammps.sandia.gov/download.html)

Everything we are covering today (and a lot of other info) can be found in the [LAMMPS User Manual](https://lammps.sandia.gov/doc/Manual.html)


## Running LAMMPS on ARCHER2

ARCHER2 uses a module system. In general, you can run LAMMPS on ARCHER2 by using the LAMMPS module:

```bash
---------------------------------------------------------------------------------------------------------------------------
     Versions:
        lammps/13_Jun_2022
        lammps/23_Jun_2022
        lammps/29_Sep_2021

---------------------------------------------------------------------------------------------------------------------------
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


### Submitting a job to the compute nodes

To run LAMMPS on multiple cores/nodes, you will need to submit a job to the ARCHER2 compute nodes.
The compute nodes do not have access to the landing `home` file system -- this file system is to store useful/important information.

{% include figure.html url="" max-width="60%" file="/fig/2_MD-primer/archer2_architecture.png" alt="ARCHER2 architecture" %}

On ARCHER2, when submitting jobs to the compute nodes, make sure that you are in your `/work/ta058/ta058/<username>` directory, as the `/home` file system is not accessible to the compute nodes.

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


## What is Molecular Dynamics

Molecular Dynamics is, simply, the application of Newton's laws of motion to systems of particles that can range in size from atoms, course-grained moieties, entire molecules, or even grains of sand.
In practical terms, any MD software follows the same basic steps:

  1. Take the initial positions of the particles in the simulation box and calculate the total force that apply to each particle, using the chosen force-field.
  2. Use the calculated forces to calculate the acceleration to add to each particle;
  3. Use the acceleration to calculate the new velocity of each particle;
  4. Use the the new velocity of each particle, and the defined time-step, to calculate a new position for each particle.

With the new particle positions, the cycle continues, one very small time-step at a time.

[comment]: # (make image better)
{% include figure.html url="" max-width="60%" file="/fig/2_MD-primer/MD.png" alt="How MD Works" %}

With this in mind, we can take a look at a very simple example of a LAMMPS input file, `in.lj`, and discuss each command -- and their related concepts -- one by one.
The order that the commands appear in **can** be important, depending on the exact details.
Always refer to the LAMMPS manual to check.

{% include links.md %}
