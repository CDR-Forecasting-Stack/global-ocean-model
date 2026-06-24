module OutputSetup

using Oceananigans: JLD2Writer, NetCDFOutputWriter, AveragedTimeInterval

export configure_output!

function configure_output!(ocean, grid, pco2, CO₂_flux1, CO₂_flux2)

    # TODO: kind of weird that pco2 and fluxes are separate inputs to the fuction
    ocean_outputs = merge(
        ocean.model.tracers, 
        ocean.model.velocities, 
        pco2, 
        CO₂_flux1,
        CO₂_flux2
    )

    free_surface = ocean.model.free_surface.displacement

    #sea_ice_outputs = merge((h = sea_ice.model.ice_thickness,
    #                         ℵ = sea_ice.model.ice_concentration,
    #                         T = sea_ice.model.ice_thermodynamics.top_surface_temperature),
    #                         sea_ice.model.velocities)

    ocean.output_writers[:surface] = JLD2Writer(ocean.model, ocean_outputs;
                                                schedule = TimeInterval(1days),
                                                filename = "ocean_one_degree_surface_fields",
                                                indices = (:, :, grid.Nz),
                                                overwrite_existing = true)

    ocean.output_writers[:free_surface] = JLD2Writer(ocean.model, (; η = free_surface);
                                                    schedule = TimeInterval(1days),
                                                    filename = "ocean_one_degree_free_surface",
                                                    overwrite_existing = true)

    #sea_ice.output_writers[:surface] = JLD2Writer(sea_ice.model, sea_ice_outputs;
    #                                              schedule = TimeInterval(1days),
    #                                              filename = "sea_ice_one_degree_surface_fields",
    #                                              overwrite_existing = true)

    # Netcdf output
    ocean.output_writers[:surface] = NetCDFOutputWriter(
        ocean.model, ocean_outputs;
        filename = "ocean_one_degree_surface_fields.nc",
        schedule = AveragedTimeInterval(1days, window=1day),
        indices=(:, :, grid.Nz),
        overwrite_existing = true
        #array_type = Array{Float32}
    )

end

end