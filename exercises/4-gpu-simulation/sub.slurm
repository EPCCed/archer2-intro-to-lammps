#!/bin/bash

# Slurm job options (name, number of compute nodes, job time)
#SBATCH --job-name=lmp_ex2
#SBATCH --nodes=1
#SBATCH --gpus=1
#SBATCH --time=0:05:0

# The budget code of the project
#SBATCH --account=ta176
# Standard partition
#SBATCH --partition=gpu
# Short QoS since our runtime is under 20m
#SBATCH --qos=gpu-shd

# load the lammps module
module load lammps-gpu

# Set the number of threads to 1
#   This prevents any threaded system libraries from automatically
#   using threading.
export OMP_NUM_THREADS=1

# Launch the parallel job
srun --ntasks=1 --cpus-per-task=1 --hint=nomultithread --distribution=block:block \
lmp -k on g 1 -pk kokkos -sf kk -i in.lj_exercise -l log_gpu.$SLURM_JOB_ID
