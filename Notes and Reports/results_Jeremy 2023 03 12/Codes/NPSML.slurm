#!/bin/bash
#SBATCH --job-name=ak68
#SBATCH --partition=commons
#SBATCH --ntasks=100
#SBATCH --ntasks-per-core=1
#SBATCH --mem-per-cpu=1000MB
#SBATCH --time=22:00:00
#SBATCH --output=out_%A.log

julia estimate.jl
