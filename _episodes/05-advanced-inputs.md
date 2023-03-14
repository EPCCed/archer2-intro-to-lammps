---
title: "Advanced input and output commands"
teaching: 20
exercises: 30
questions:
- "How do I calculate a property every N time-steps?"
- "How do I write a calculated property to file?"
- "How can I use variables to make my input files easier to change?"
objectives:
- "Understand the use of `compute`, `fix`, and variables."
keypoints:
- "Using `compute` and `fix` commands, it's possible to calculate myriad properties during a simulation."
- "Variables make it easier to script several simulations."
---

## Advanced input commands

LAMMPS has a very powerful suite for calculating, and outputting all kinds of
physical properties during the simulation. Calculations are most often under a
[compute command](https://docs.lammps.org/computes.html), and then the output
is handled by a [fix command](https://docs.lammps.org/fixes.html). We will now
look at three examples, but there are (at the time of writing) over 150
different `compute` commands with many options each.

### LAMMPS trajectory files

We can output information about a group of particles in our system by using
the LAMMPS `dump` command. In this example, we will be outputting the particle
positions, but you can output many other attributes, such as particle
velocities, types, angular momentum, etc. The list of attributes (and examples
of `dump` commands) can be found in the
[relevant LAMMPS manual page](https://docs.lammps.org/dump.html).

If we look at the starting input script in
`exercises/3-advanced-inputs-exercise/in.lj_start`, we find that the following
command has been added:

```bash
dump            1 all custom 100 nvt.lammpstrj id type x y z vx vy vz
dump_modify     1 sort id
```

The `dump` command defines the properties that we want to output, and how
frequently we want these output. In this case, we have set the ID of the
`dump` command to `1` (we could have used any name/number and it would still
work). We want to output properties for `all` particles in our system. We've
set the output type to `custom` to have better control of what's being output
-- there are default `dump` options but `custom` is generally the one that
gets used. We'll be outputting every `100` time-steps to a file called
`nvt.lammpstrj` -- a `*.lammpstrj` file can be recognised by some
post-processing and post-analysis tools as a LAMMPS trajectory/dump file, and
can save some time down the line. Finally, we name the properties we want to
output -- in this case, we want to output the particle ID, type, (x,y,z)
components of position, and the (x, y, z) components of velocity.

We've added a `dump_modify` command to get LAMMPS to sort the output by ID
order -- we tell the `dump_modify` command which `dump` command we'd like to
sort by giving the dump-ID (in this case, our `dump` command had an ID of `1`).
We then specify how we want to modify this `dump` command -- we want to `sort`
it by ID, but there are many more options (that you can find in the
[LAMMPS manual](https://docs.lammps.org/dump_modify.html)).

The output `nvt.lammpstrj` file looks like this:

```
ITEM: TIMESTEP
100000
ITEM: NUMBER OF ATOMS
8000
ITEM: BOX BOUNDS pp pp pp
0.0000000000000000e+00 4.3088693800637678e+01
0.0000000000000000e+00 4.3088693800637678e+01
0.0000000000000000e+00 4.3088693800637678e+01
ITEM: ATOMS id type x y z vx vy vz
1 1 37.8488 34.4941 42.367 -0.288953 -0.71502 -0.690526
2 1 8.70692 28.34 10.3539 -1.23763 -0.708975 -1.07684
3 1 14.2888 33.2234 10.3076 -0.717269 0.696605 0.669823
4 1 2.31473 26.109 36.5071 -1.93238 -1.09695 1.34787
5 1 42.0214 26.0015 20.3317 -0.767786 0.693569 -0.0684248
6 1 7.36511 39.4736 37.7819 0.011605 0.376106 -0.680507
```

The lines with `ITEM:` let you know what is output on the next lines (so
`ITEM: TIMESTEP` lets you know that the next line will tell you the time-step
for this frame -- in this case, 100,000). A LAMMPS trajectory file will
usually contain the time-step, number of atoms, and information on box bounds
before outputting the information we'd requested.

### Radial distribution functions (RDFs)

First, we will look at the Radial Distribution Function (RDF), _g_(_r_). This
describes how the density of a particles varies as a function of the distance
to a reference particle, compared with a uniform distribution (that is, at r →
∞, _g_(_r_) → 1). We can make LAMMPS compute the RDF by adding the following
lines to our input script:

```
compute        RDF all rdf 150 cutoff 3.5
fix            RDF_OUTPUT all ave/time 25 100 5000 c_RDF[*] file rdf_lj.out mode vector
```

We've named this `compute` command `RDF` and are applying it to the
atom-group `all`. The compute is of style `rdf`, and we have set it to have
with 150 bins for the RDF histogram (e.g. there are 150 discrete distances at
which atoms can be placed). We've set a maximum cutoff of 3.5σ, above which we
stop considering particles.

Compute commands are instantaneous -- they calculate the values for
the current time-step, but that doesn't mean they calculate quantities every
time-step. A compute only calculates quantities when needed, _i.e._, when
called by another command. In this case, we will use our compute with the
`fix ave/time` command, that averages a quantity over time, and outputs it
over a long timescale.

Our `fix ave/time` has the following parameters:
 - `RDF_OUTPUT` is the name of the fix, `all` is the group of particles it
   applies to.
 - `ave/time` is the style of fix (there are many others).
 - The group of three numbers `25 100 5000` are the `Nevery`, `Nrepeat`,
   `Nfreq` arguments. These can be quite tricky to understand, as they
   interplay with each other.
     - `Nfreq` is how often a value is written to file.
     - `Nrepeat` is how many sets of values we want to average over (number of
       samples)
     - `Nevery` is how many time-steps in between samples.
     - `Nfreq` must be a multiple of `Nevery`, and `Nevery` must be non-zero
       even if `Nrepeat = 1`.
     - So, for example, an `Nevery` of 2, with `Nrepeat` of 3, and `Nfreq` of
       100 means that at every time-step multiple of 100, there will be an
       average written to file, that was calculated by taking 3 samples, 2
       time-steps apart. Time-steps 96, 98, and 100 are averaged, and the
       average is written to file. Likewise at time-steps 196, 198, and 200,
       etc.
     - In this case, we take a sample every 25 time-steps, 100 times, and
       output at time-step number 5000 -- so from time-step 2500 to 5000,
       sampling every 25 time-steps.
 - `c_RDF[*]`, is the compute that we want to average over time. `c_` defines
   that we're wanting to use a compute, and `RDF` is our compute name. The
   `[*]` wildcard in conjunction with `mode vector` makes the fix calculate the
   average for all the columns in the compute ID.
 - The `file rdf_lj.out` argument tells LAMMPS where to write the data to.

For this command, the file looks something like this:

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

> ## RDFs at different densities
>
> How does the RDF change as you vary the system density? We've been running
> with a density of 0.8. How does the RDF change if we increase the density to
> 1.2? And if we reduce it to 0.1?
>
> > ## Solution
> >
> > At a reduced temperature of T* = 1.0, a Lennard-Jones system with a reduced
> > density ρ* = 0.8 is in liquid state. At ρ* = 1.2, the system is in solid
> > state, and at ρ* = 0.0025, the system is a gas. The RDFs are different for
> > each of these phases.
> >
> {: .solution}
{: .challenge}

> ## YAML output
>
> Since version 4May2022 of LAMMPS, writing to YAML files support was added.
> To write a YAML file, just change the extension accordingly `file rdf_lj.yaml`.
> The file will then be in YAML format:
>
> ```
> # Time-averaged data for fix RDF_OUTPUT_YAML
> # TimeStep Number-of-rows
> # Row c_RDF[1] c_RDF[2] c_RDF[3]
> ---
> keywords: ['c_RDF[1]', 'c_RDF[2]', 'c_RDF[3]', ]
> data:
>   105000:
>   - [0.011666666666666691, 0, 0, ]
>   - [0.035000000000000045, 0, 0, ]
>   - [0.05833333333333334, 0, 0, ]
> ...
> ```
{: .callout}

### Mean-squared diplacement (MSD)

The mean-squared displacement (MSD) is a measure of the average displacement
that particles travel from their origin position at some given time. The slope
of the RDF is directly proportional to the diffusion coefficient of the
system. As with the RDF, we will require a `compute` command and a `fix` command
to call that `compute`:

```
compute        MSD all msd
fix            MSD_OUTPUT all ave/correlate 1 50000 50000 c_MSD[4] file msd_lj.out ave running
```

As before, the `compute` command has a name (MSD), a group to which it applies
(all), and a type (msd).

We're using `fix ave/correlate` command to calculate how the total unwrapped
squared displacement of every particle in the system changes throughout the
simulation. This works in a very similar way to the `fix ave/time` command
that we used before. For this, we define the following parameters:
  - The fix name (`MSD_OUTPUT`).
  - The group of particles to which this applies (all particles).
  - The type of fix (`ave/correlate`).
  - The `Nevery`, `Nrepeat`, and `Nfreq` values -- here, we want to calculate
    the correlation every timestep throughout the simulation.
  - The `compute` command that's being averaged (as before, we use `c_` to
    define that we need a `compute`, and give the ID of the `compute` command).
  - The ouput type and name (`file msd_lj.out`).
  - The style of correlation being used -- here, we're taking a running average
    of the MSD.

Confusingly, if we set this command to run for the entire simulation, LAMMPS
will output the MSD at the start of the simulation (when particles have not
moved at all, and the MSD will be 0) and once more at the end of the
simulation. As a result, the start of the output `msd_lj.out` file is not very
informative:

```
# Time-correlated data for fix MSD_OUTPUT
# Timestep Number-of-time-windows
# Index TimeDelta Ncount c_MSD[4]*c_MSD[4]
0 50000
1 0 1 0
2 1 0 0.0
3 2 0 0.0
4 3 0 0.0
5 4 0 0.0
6 5 0 0.0
7 6 0 0.0
8 7 0 0.0
9 8 0 0.0
10 9 0 0.0
...
```

Additionally, we're only interested in the final part of the `msd_lj.out` file.
To get the output we're interested in, we'll run:

```bash
tail -n 50000 msd_lj.out > msd_end.out
```

Then, we can plot the final output MSD using e.g. `gnuplot`:
  - The first column tells you which timestep this was output for.
  - The second column is the amount of simulation time since the simulation
    start (for a Lennard-Jones system, these are the same as time-steps).
  - The third column tells you how many times this value was averaged over.
  - The fourth column tells you the mean squared displacement for your system.

> ## Outputting a velocity autocorrelation function (optional)
>
> It's possible to use a similar approach to calculate the velocity
> autocorrelation function of a system. Try to use the `compute vacf` and
> `fix ave/correlate` commands to output the velocity autocorrelation function.
>
> > ## Solution
> >
> > You should be able to get a VACF with:
> >
> > ```
> > compute        VACF all vacf
> > fix            VACF_OUTPUT all ave/correlate 1 25000 50000 c_VACF[*] file vacf_lj.out ave running
> > ```
> >
> {: .solution}
{: .challenge}


### Restart files

To allow the continuation of the simulation (with the caveat that it must
continue to run in the same number of cores as was originally used), we can
create a restart file:

This binary file contains information about system topology, force-fields, but
not about computes, fixes, etc, these need to be re-defined in a new input
file.

You can write a restart file with the command:

```
write_restart  restart2.lj.equil
```

An arguably better solution is to write a data file, which not only is a text
file, but can then be used without restrictions in a different hardware
configuration, or even LAMMPS version.

```
write_data  lj.equil.data
```

You can use a restart or data file to start/restart a simulation by using a
`read` command. For example:

```bash
read_restart restart2.lj.equil
```

will read in our restart file and use that final point as the starting point
of our new simulation.

Similarly:

```bash
read_data lj.equil.data
```

will do the same with the data file we've output (or any other data file).

## Variables and loops

LAMMPS input scripts can be quite complex, and it can be useful to run the
same script many times with only a small difference (for example, temperature).
For this reason, LAMMPS have implemented variables and loops -- but this
doesn't mean that we can only use variables *with* loops.

A variable in LAMMPS is defined with the keyword `variable`, then a `name`,
and then style and arguments, for example:

```
variable temperature equal 1.0
```

There are several [variable styles](https://docs.lammps.org/variable.html). Of
particular note are:
 - `equal` is the workhorse of the styles, and it can set a variable to a
    number, `thermo` keywords, maths operators or functions, among other things.
 - `delete` unsets a variable.
 - `loop` and `index` are similar, and will result in the variable changing to
   the next value in a list every time a `next` command is seen. The
   difference that `loop` accepts an integer or range, while `index` accepts a
   list of strings.

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

> ## LAMMPS Rerun
>
> LAMMPS allows us to take already generated trajectory (`dump`) files, and do
> a re-run of the `simulation`, but allowing to calculate new properties.
> In this exercise, you will run a LJ simulation, outputting the trajectory as
> `nvt.lammpstrj` and, then, re-run the trajectory and calculate a RDF.
> 
> What differences do you see in runtime, and output between the two inputs?
> How can you quickly plot the RDF, to check if your re-run was successful?
> 
> > ## Solution
> > 
> > A full run takes around 1m, while the re-run takes less 20 seconds. This
> > effect would be even more evident on larger simulations. Re-runs are,
> > comparatively, much faster than proper simulations.
> > 
> > To quickly plot the RDF, you can load gnuplot with `module load gnuplot`
> > and, assuming your ssh session was started with X forwarding, you can
> > start gnuplot with the `gnuplot` command, and plot the RDF with:
> > `plot 'rdf_lj.out' using 2:3`.
> > 
> > 
> {: .solution}
{: .challenge}

{% include links.md %}
