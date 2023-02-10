---
title: "Running a simulation and understanding the logfile"
teaching: 20
exercises: 30
questions:
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
The first line gives us the details of the last `run` command - how many seconds it took, on how many processes it ran on, how many time-steps, and how many atoms.
This can be useful to compare between different systems.

Then we get some benchmark information:

```
Performance: 1347185.752 tau/day, 3118.486 timesteps/s
96.6% CPU use with 8 MPI tasks x 8 OpenMP threads
```

How many time units per day / how many time-steps per second.
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
Total wall time: 0:00:16
```

{% include links.md %}
