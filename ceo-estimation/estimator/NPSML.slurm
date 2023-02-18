#!/bin/bash
#SBATCH --job-name=ak68
#SBATCH --partition=interactive
#SBATCH --ntasks=4
#SBATCH --ntasks-per-core=1
#SBATCH --mem-per-cpu=1000MB
#SBATCH --time=00:10:00
#SBATCH --output=out_%A.log
julia NPSML.jl
