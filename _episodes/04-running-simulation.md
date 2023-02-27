---
title: "Running a simulation and understanding the logfile"
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
By default, the log file name that LAMMPS creates, and which to it writes all the info that shows on the terminal, is `log.lammps`.
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

At the start, we get a header with the column names, and then a line for each time-step that's a multiple of the value we set `thermo` to.
In this example, because we're running an NVT simulation, both the simulation box volume, and the particle density are constant, but using other ensembles that would change.
At the end of each `run` command, we get the analysis of how the simulation time is spent:

```
Loop time of 9.55046 on 64 procs for 50000 steps with 1000 atoms

Performance: 2261671.288 tau/day, 5235.350 timesteps/s
99.1% CPU use with 64 MPI tasks x 1 OpenMP threads

MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 0.59231    | 0.65362    | 0.71353    |   3.8 |  6.84
Neigh   | 0.27723    | 0.28862    | 0.30129    |   1.2 |  3.02
Comm    | 7.6539     | 7.8774     | 8.1735     |   5.8 | 82.48
Output  | 0.0033658  | 0.0042377  | 0.0044533  |   0.3 |  0.04
Modify  | 0.44529    | 0.68461    | 0.89407    |  16.2 |  7.17
Other   |            | 0.04201    |            |       |  0.44

Nlocal:         15.625 ave          20 max          13 min
Histogram: 6 11 12 0 21 6 0 4 2 2
Nghost:        859.953 ave         872 max         851 min
Histogram: 2 7 11 13 8 14 3 2 2 2
Neighs:        1424.08 ave        1824 max        1135 min
Histogram: 5 7 11 11 8 10 3 2 3 4

Total # of neighbors = 91141
Ave neighs/atom = 91.141
Neighbor list builds = 4999
Dangerous builds = 4996
Total wall time: 0:00:09
```

The data here presented is very important, and can help you substantially improve the speed at which your simulations run.
The first line gives us the details of the last `run` command - how many seconds it took, on how many processes it ran on, how many time-steps, and how many atoms.
This can be useful to compare between different systems.

Then we get some benchmark information:

```
Performance: 2261671.288 tau/day, 5235.350 timesteps/s
99.1% CPU use with 64 MPI tasks x 1 OpenMP threads
```

How many time units per day / how many time-steps per second.
And how much of the available CPU resources LAMMPS was able to use, with how many MPI tasks and OpenMP threads.

The next table shows a breakdown of the time spent on each task by the MPI library.

```
MPI task timing breakdown:
Section |  min time  |  avg time  |  max time  |%varavg| %total
---------------------------------------------------------------
Pair    | 0.59231    | 0.65362    | 0.71353    |   3.8 |  6.84
Neigh   | 0.27723    | 0.28862    | 0.30129    |   1.2 |  3.02
Comm    | 7.6539     | 7.8774     | 8.1735     |   5.8 | 82.48
Output  | 0.0033658  | 0.0042377  | 0.0044533  |   0.3 |  0.04
Modify  | 0.44529    | 0.68461    | 0.89407    |  16.2 |  7.17
Other   |            | 0.04201    |            |       |  0.44
```

The `Pair` line refers to non-bonded force computations, `Bond` includes all bonded interactions, including angles, dihedrals, and impropers, `Kspace` relates to long-range interactions (Ewald, PPPM or MSM), `Neigh` is the construction of neighbour lists, Comm is inter-processor communication (AKA, parallelisation overhead), `Output` is the writing of files (log and dump files), `Modify` is the fixes and computes invoked by fixes, and `Other` is everything else.
Each category shows a breakdown of the least, average, and most amount of wall time any processor spent on each category -- large variability in this (calculated as %varavg) could show that the atom distribution between processors is not optimal.
The final column, %total, is the percentage of the loop time spent in the category.

> ## A rule-of-thumb for %total on each category
>   - `Pair`: as much as possible.
>   - `Neigh`: 10% to 30%.
>   - `Kspace`: 10% to 30%.
>   - `Comm`: as little as possible. If it's growing large, it's a clear sign that too many computational resources are being assigned to a simulation.
{: .callout}

The last line on every LAMMPS simulation will be the total wall time for the entire input script, no matter how many `run` commands it has:

```
Total wall time: 0:00:09
```

{% include links.md %}
