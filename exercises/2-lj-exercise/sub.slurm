#!/bin/bash

#SBATCH --job-name=lmp_lj
#SBATCH --nodes=1
#SBATCH --time=0:20:0

#SBATCH --account=ta100
#SBATCH --partition=standard
#SBATCH --qos=short

module load lammps/23_Jun_2022

export OMP_NUM_THREADS=1

srun -n 1 --cpus-per-task=1 lmp -i in.lj_exercise -l log.$SLURM_JOB_ID
