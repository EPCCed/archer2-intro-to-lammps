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

### Mean-squared diplacement (MSD) and velocity autocorrelation functions (VACFs)

We'll now look at generating mean-squared displacements (MSDs) and velocity
autocorrelation functions (VACFs) using LAMMPS. Both of these are averaged
quantitiesm and we will calculate these using a `compute` command, and call
this command with a `fix ave/correlate` command.

The MSD is a measure of the average displacement that particles travel from
their origin position at some given time. The slope of the RDF is directly
proportional to the diffusion coefficient of the system.

```
compute        MSD all msd
fix            MSD_OUTPUT all ave/correlate 1 5000 5000 c_MSD[*] file msd_lj.out ave running
```

[comment]: # (never done MSD or time correlations, this needs some more explaining)
The `fix` is then taking a sample every time-step, and at time-steps divisible
by 5000 it calculates the time correlation and writes it down to file (so, we
get two values, at the start of the run, and end of the run).

And the final example is a velocity auto-correlation function

```
compute        VACF all vacf
fix            VACF_OUTPUT all ave/correlate 1 2500 5000 c_VACF[*] file vacf_lj.out ave running
```

[comment]: # (ditto from what I said about MSD)
Here the fix is taking 2500 samples from time-step 2501 to 5000.

The `dump` command allows to write trajectory files -- files that have the
coordinates (and sometimes other properties) of each particle at a regular
interval. These are important to create visual representations of the
evolution of the simulation (AKA molecular movies) or to allow for the
calculation of properties after the simulation is done, without the need to
re-run the simulation.

```
dump           2 all custom 1000 positions.lammpstrj id x y z vx vy vz
dump_modify    2 sort id
```

The `dump` command has id `2`, and will output information for `all` particles.
The style is `custom`, and will write to file `positions.lammpstrj` every
`1000` time-steps. The `custom` style is configurable, and we request that
each atom has the following properties written to file: atom `id`, positions
in the 3 directions, and velocity magnitudes in the 3 directions. The
`dump_modify` command makes sure that the atoms are written in order of `id`,
rather than in whatever order they happen to get calculated.

Finally, we tell LAMMPS to run this section (with the computes and fixes) for
`5000` time-steps.

```
run            5000
```

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
