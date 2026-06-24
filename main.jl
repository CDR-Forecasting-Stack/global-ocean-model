# =====================================================================
#
# Entry point for a global ocean simulation with realistic bathymetry 
# 
# Closures:
#   -   the "Gent-McWilliams" `IsopycnalSkewSymmetricDiffusivity`.
#
# Forcing:
#   -   ERA5 Reanalysis
#
# Initialization:
#   -   temperature, salinity, sea ice concentration, and sea ice thickness
#       from the ECCO state estimate.
#   -   BGC from ECCO Darwin model
#
# =====================================================================

# initialization of MPI needs to happen at the start of the script
using MPI
MPI.Init()

@info "Import necesary modules ..."

using Oceananigans
using NumericalEarth
using OceanBioME

using NumericalEarth.EarthSystemModels.InterfaceComputations
using NumericalEarth.DataWrangling.ERA5: ERA5PrescribedAtmosphere, ERA5PrescribedRadiation, ERA5HourlySingleLevel
using CDSAPI
using Oceananigans.Units
using Oceananigans.DistributedComputations
using OceanBioME.Models.GasExchangeModel: CarbonDioxideConcentration
using Dates
using Printf
using Statistics
using CUDA
using CUDA: @allowscalar, device!

# ---------------------------------------------------------------------
# computing architecture
# ---------------------------------------------------------------------

@info "Setup computing architecture ..."

comm = MPI.COMM_WORLD
rank = MPI.Comm_rank(comm)

arch = Distributed(
    GPU(); 
    partition = Partition(y = DistributedComputations.Equal()), 
    synchronized_communication = true
)

@info CUDA.device(), rank
@info arch 

# ---------------------------------------------------------------------
# include source files
# ---------------------------------------------------------------------
include("src/Grid.jl")
include("src/Biogeochemistry.jl")
include("src/Forcing.jl")
include("src/Closures.jl")
include("src/Atmosphere.jl")
include("src/Initialization.jl")
include("src/Output.jl")

using .GridSetup
using .BiogeochemistrySetup
using .ForcingSetup
using .ClosureSetup
using .AtmosphereSetup
using .Initialization
using .OutputSetup

# dates to run the simulation
dates = DateTime(2000,1,1):Month(1):DateTime(2005,12,31)

grid = build_grid(arch)

bgc, bcs, pco2, CO₂_flux1, CO₂_flux2 = build_bgc(grid)

forcing = build_alkalinity_forcing(
    grid;
    amplitude = 1.0, # amplitude of the release
    lon       = 236.5425, # longitude location of release
    lat       = 48.1292,  # latitude location of release
    sigma     = 5.0, # standard deviation of the patch (in pixels)
    ti        = 1.0, # day to start release
    tf        = 2.0. # day to end release
)

closure = build_closure()

atmosphere, radiation = build_atmosphere(arch, dates)

ocean = ocean_simulation(
    grid;
    closure,
    forcing,
    biogeochemistry = bgc,
    boundary_conditions = bcs
)

initialize_ocean!(ocean, grid, first(dates))

coupled_model = OceanOnlyModel(
        ocean;
        atmosphere,
        radiation
    )

simulation = Simulation(
        coupled_model;
        Δt = 20minutes,
        stop_time = 365days
    )

configure_output!(ocean, grid, pco2, CO₂_flux1, CO₂_flux2)

run!(simulation)