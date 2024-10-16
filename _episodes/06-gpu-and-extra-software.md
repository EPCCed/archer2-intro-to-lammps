---
title: "GPU Acceleration and Additional software"
teaching: 30
exercises: 0
questions:
- "How can I make my simulations faster using GPUs?"
- "What other software can I use to prepare input files, and topology files?"
- "How can I post-process my data?"
objectives:
- "Learning how to run LAMMPS simulations using GPU accelarators."
- "Understand how to enhance the workflow around LAMMPS simulations."
keypoints:
- "LAMMPS has two packages (GPU and KOKKOS) that can make simulations run faster using accelerator cards."
- "Packmol can be used to pack multiple of the same type of molecules into one topology file."
- "MDAnalisys is a powerful python library to read, process, and create LAMMPS files."
---


## GPU acceleration

LAMMPS has the capability to use GPUs to accelerate the calculations needed to run a simulation,
but the program needs to be compiled with the correct parameters for this option to be available.
Furthermore, LAMMPS can exploit multiple GPUs on the same system, although the performance scaling depends heavily on the particular system.
As always, we recommend that each user should run benchmarks for their particular use-case to ensure that they are getting performance benefits.
While not every LAMMPS force field or fix is available for GPU, a vast majority are, and more are added with each new version.
Check the LAMMPS documentation for GPU compatibility with a specific command.

There are two main LAMMPS packages that add GPU acceleration: `GPU` and `KOKKOS`.
The differences are many, including which `fixes` and `computes` are implemented for each package (as always, consult the manual),
but the main difference is the underlying framework used in each.
The flags needed for each are also different, we have some examples of each below.

ARCHER2 has the `lammps-gpu` module, which has lammps compiled with KOKKOS.
Due to the model of AMD GPUs and compiler/driver versions available, it hasn't been possible to compile LAMMPS with the `GPU` package.
Cirrus, a Tier2 HPC system also hosted at EPCC, has a `lammps-gpu` module installed with the `GPU` package.

### KOKKOS package

In `exercises/4-gpu-simulation` you can find the Lennard-Jones input file used in exercise 2, with a larger number of atoms,
and a slurm script that loads the `lammps-gpu` module, and runs the simulation on a GPU.

The main differences are some of the `#SBATCH` lines, where we now have to set the number of GPUs to request, and use a different partition/qos combo:

```bash
...
#SBATCH --nodes=1
#SBATCH --gpus=1
...
#SBATCH --partition=gpu
#SBATCH --qos=gpu-shd

```

and the `srun` line, where we have to set the number of tasks, CPUS, the hints, and the distribution (slurm won't allow this on the `#SBATCH` lines),
as well as adding the `KOKKOS`-specific flags `-k on g 1 -pk kokkos -sf kk`


```bash
srun --ntasks=1 --cpus-per-task=1 --hint=nomultithread --distribution=block:block \
lmp -k on g 1 -pk kokkos -sf kk -i in.lj_exercise -l log_gpu.$SLURM_JOB_ID
```

The `-k on g 1` flag tells `KOKKOS` to use 1 GPU, and `-sf kk` adds the `\kk` suffic to all styles that support it.


### GPU package

To use the GPU accelerated commands, you would need to be an extra flag when calling the LAMMPS binary: `-pk gpu <number_of_gpus_to_use>`.
You will also need to add the `\gpu` suffix to all the styles intended to be accelerated this way or,
alternatively, you can use the `-sf gpu` flag to append the `\gpu` suffix to all styles that support it (though this is at your own risk).

For example, if you were to run exercise 4 on Cirrus, you could change the line:

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
