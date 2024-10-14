---
title: "Understanding the logfile"
teaching: 20
exercises: 0
questions:
- "What information does LAMMPS print to screen/logfile?"
- "What does that information mean?"
objectives:
- "Understand the information that LAMMPS prints to screen / writes to the logfile before, during, and after a simulation."
keypoints:
- "Thermodynamic information outputted by LAMMPS can be used to track whether a simulations is running OK."
- "Performance data at the end of a logfile can give us insights into how to make a simulation faster."
---

## Log file

The logfile is where we can find thermodynamic information of interest.
By default, LAMMPS will write to a file called `log.lammps`.
All info output to the terminal is replicated in this file.
We can change the name of the logfile by adding a `log` command to your script:

```
log     new_file_name.extension
```

We can change which file to write to multiple times during a simulation, and even `append` to a file if, for example,
we want the thermodynamic data separate from the logging of other assorted commands.
The thermodynamic data, which we setup with the `thermo` and `thermo_style` command, create the following (truncated) output:

```
    Step         Temp       TotEng       PotEng       KinEng        Press       Volume      Density
       0            1    -2.709841    -4.208341       1.4985   -2.6415761    1666.6667          0.6
     500   0.91083091   -2.6743978   -4.0392779    1.3648801   -0.1637597    1666.6667          0.6
    1000   0.96279851   -2.6272603   -4.0700139    1.4427536  -0.14422949    1666.6667          0.6
    1500   0.97878978   -2.6029892   -4.0697057    1.4667165  -0.11813628    1666.6667          0.6
    2000   0.93942595   -2.5817381   -3.9894679    1.4077298  -0.31689463    1666.6667          0.6
```

At the start, we get a header with the column names, and then a line for each time-step that's a multiple of the value we set `thermo` to.
In this example, we're running an NVT simulation, so we've fixed the number of particles, the volume and dimensions of the simulation box, and the temperature
-- we can see from the logfile that `Volume` and `Density` remain constant (but not `Temp`).
This would change if we used a different ensemble.
At the end of each `run` command, we get the analysis of how the simulation time is spent:

```
Loop time of 4.2033 on 128 procs for 50000 steps with 1000 atoms

Performance: 5138815.615 tau/day, 11895.407 timesteps/s
99.3% CPU use with 128 MPI tasks x 1 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 0.25206    | 0.29755    | 0.34713    |   4.5 |  7.08
Neigh   | 0.21409    | 0.22675    | 0.23875    |   1.2 |  5.39
Comm    | 2.9381     | 3.097      | 3.2622     |   4.6 | 73.68
Output  | 0.0041445  | 0.0049069  | 0.0052867  |   0.4 |  0.12
Modify  | 0.40665    | 0.53474    | 0.67692    |  10.0 | 12.72
Other   |            | 0.04237    |            |       |  1.01

Nlocal:         7.8125 ave          12 max           5 min
Histogram: 6 21 22 0 37 29 0 11 1 1
Nghost:        755.055 ave         770 max         737 min
Histogram: 2 6 4 18 23 20 30 13 7 5
Neighs:        711.773 ave        1218 max         392 min
Histogram: 8 14 24 15 31 22 11 1 0 2

Total # of neighbors = 91107
Ave neighs/atom = 91.107
Neighbor list builds = 4999
Dangerous builds = 4996
Total wall time: 0:00:04
```

The data shown here is very important to understand the computational performance of our simulation,
and we can it to help improve the speed at which our simulations run substantially.
The first line gives us the details of the last `run` command - how many seconds it took, on how many processes it ran on, how many time-steps, and how many atoms.
This can be useful to compare between different systems.

Then we get some benchmark information:

```
Performance: 5138815.615 tau/day, 11895.407 timesteps/s
99.3% CPU use with 128 MPI tasks x 1 OpenMP threads
```

This tells us how many time units per day, and how many time-steps per second we are running.
 It also tells us how much of the available CPU resources LAMMPS was able to use, and how many MPI tasks and OpenMP threads.

The next table shows a breakdown of the time spent on each task by the MPI library:

```
MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 0.25206    | 0.29755    | 0.34713    |   4.5 |  7.08
Neigh   | 0.21409    | 0.22675    | 0.23875    |   1.2 |  5.39
Comm    | 2.9381     | 3.097      | 3.2622     |   4.6 | 73.68
Output  | 0.0041445  | 0.0049069  | 0.0052867  |   0.4 |  0.12
Modify  | 0.40665    | 0.53474    | 0.67692    |  10.0 | 12.72
Other   |            | 0.04237    |            |       |  1.01
```

There are 8 possible MPI tasks in this breakdown:

 - `Pair` refers to non-bonded force computations
 - `Bond` includes all bonded interactions, (so angles, dihedrals, and impropers)
 - `Kspace` relates to long-range interactions (Ewald, PPPM or MSM)
 - `Neigh` is the construction of neighbour lists
 - `Comm` is inter-processor communication (AKA, parallelisation overhead)
 - `Output` is the writing of files (log and dump files)
 - `Modify` is the fixes and computes invoked by fixes
 - `Other` is everything else

Each category shows a breakdown of the least, average, and most amount of wall time any processor spent on each category
 -- large variability in this (calculated as `%varavg`) indicates a load imbalance (which can be caused by the atom distribution between processors not being optimal).
 The final column, `%total`, is the percentage of the loop time spent in the category.

> ## A rule-of-thumb for %total on each category
>   - `Pair`: as much as possible.
>   - `Neigh`: 10% to 30%.
>   - `Kspace`: 10% to 30%.
>   - `Comm`: as little as possible. If it's growing large, it's a clear sign that too many computational resources are being assigned to a simulation.
{: .callout}

The last line on every LAMMPS simulation will be the total wall time for the entire input script, no matter how many `run` commands it has:

```
Total wall time: 0:00:04
```

{% include links.md %}
