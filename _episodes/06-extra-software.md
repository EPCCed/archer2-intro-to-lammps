---
title: "Additional software"
teaching: 30
exercises: 0
questions:
- "What other software can I use to prepare input files, and topology files?"
- "How can I post-process my data?"
objectives:
- "Understand how to enhance the workflow around LAMMPS simulations."
keypoints:
- "Packmol can be used to pack multiple of the same type of molecules into one topology file."
- "MDAnalisys is a powerful python library to read, process, and create LAMMPS files."
---


## GPU acceleration

LAMMPS has the capability to use GPUs to accelerate the calculations needed to run a simulation, but the program needs to be compiled with the correct parameters for this option to be available.
Furthermore, LAMMPS can exploit multiple GPUs on the same system, although the performance scaling depends heavily on the particular system.
As always, we recommend that each user should run benchmarks for their particular use-case to ensure that they are getting performance benefits.
While not every LAMMPS force field or fix is available for GPU, a vast majority are, and more are added with each new version.
Check the LAMMPS documentation for GPU compatibility with a specific command.

To use the GPU accelerated commands, you will need to be an extra flag when calling the LAMMPS binary: `-pk gpu <number_of_gpus_to_use>`.
You will also need to add the `\gpu` suffix to all the styles intended to be accelerated this way or,
alternatively, you can use the `-sf gpu` flag to append the `\gpu` suffix to all styles that support it (though this is at your own risk).
So, for example, if ARCHER2 had GPUs, you would change the `srun` line from:

```
srun lmp -i in.ethanol -l log.$SLURM_JOB_ID
```

to:

```
srun lmp -pk gpu 1 -sf gpu -i in.ethanol -l log.$SLURM_JOB_ID
```

This will run LAMMPS on a single GPU, as well as making use of any MPI tasks and OMP threads that you had defined in your Slurm submission script.

## Visualisation

One of the most widely used 3D visualisation tools is [VMD (Visual Molecular Dynamics)](https://www.ks.uiuc.edu/Research/vmd/).
This is a licensed software (with free licenses for academic use), with executables available for Linux, MacOS (x86\_64 and ARM), and Windows.

There are many plugins that extend the base functionalities, and more plugins/scripts can be created using `tcl/tk` language.

One of the main plugins, that comes with the base installation, is TopoTools, and it is incredibly useful for interfacing with LAMMPS,
as it allows to read and write LAMMPS data and trajectory files.

## Other software

Other useful software includes:
- packmol: creates initial configuration for MD simulations by packing molecules
- ovito: an open source (basic version) MD/MC visualisation tool
- mdanalysis: an OO python library to interface with MD simulations for post-processing
- pylat: python LAMMPS analysis tools

{% include links.md %}
