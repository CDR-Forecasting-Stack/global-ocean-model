#!/bin/bash
#SBATCH --job-name=climaocean
#SBATCH --accoun=pi_me586
#SBATCH --ntasks=1
#SBATCH --time=1:00:00
#SBATCH --nodes 1
#SBATCH --mem 15G
#SBATCH --partition day

module purge
module load miniconda/24.9.2 
module load Julia/1.11.4-linux-x86_64

#---------------------------------------------------------
# if true, this will instantiste the project
# set to true only if the project is not instantiated yet
# this will only need to be done once
#---------------------------------------------------------

INSTANTIATE=false

#---------------------------------------------------------
# path to simulation you want to run
#---------------------------------------------------------

SIMULATION=/nfs/roberts/project/pi_me586/${USER}/clima-test/simulation.jl

#---------------------------------------------------------
# this is path where where Project.toml is
# note: do not put Project.toml at end of the path
#---------------------------------------------------------

PROJECT=/nfs/roberts/project/pi_me586/${USER}/clima-test/

#---------------------------------------------------------
# this is where all downloaded file will live
# will make scratch directory if does not already exist
#---------------------------------------------------------

DEPOT_PATH=/nfs/roberts/scratch/pi_me586/${USER}/julia_depot
export JULIA_DEPOT_PATH=${DEPOT_PATH}

#-------------------------------------------
# this contains ECCO credentials
# your ~/.ecco-credentials 
# should contain only these two lines:
#
# export ECCO_USERNAME=your-username
# export ECCO_PASSWORD=your-password
#-------------------------------------------

source /nfs/roberts/home/${USER}/.ecco-drive  

#-------------------------------------------
# instantiates packages
# should only have to run this once
#-------------------------------------------

if ${INSTANTIATE}; then
    julia --project="${PROJECT}" -e "using Pkg; Pkg.instantiate()"
fi

wait

#-------------------------------------------
# runs the actual simulation
#-------------------------------------------

julia --project=${PROJECT} ${SIMULATION}

