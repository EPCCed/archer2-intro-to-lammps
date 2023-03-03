#!/bin/bash

# Slurm job options (name, number of compute nodes, job time)
#SBATCH --job-name=lmp_py
#SBATCH --nodes=1
#SBATCH --time=0:20:0

# The budget code of the project
#SBATCH --account=ta100
# Standard partition
#SBATCH --partition=standard
# Short QoS since our runtime is under 20m
#SBATCH --qos=short

# load the lammps module
module load lammps/23_Jun_2022

# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1

# Launch the parallel job
#   Using `-n` CPUs, change it to test different numbers
srun -n 1 --cpus-per-task=1 lmp -i in.ethanol -l log.${SLURM_NTASKS}cpus.${SLURM_JOB_ID}
