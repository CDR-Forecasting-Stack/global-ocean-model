module ForcingSetup

using Oceananigans: Forcing, nodes, Center

export build_alkalinity_forcing

function find_nearest_index(values::AbstractArray, target_value)
    return argmin(abs.(values .- target_value))
end

function alk_2dgauss_forcing(amplitude, i0, j0, k0, σi, σj, ti_days, tf_days)

    # TODO: seconds per day should be referenced from a constants files
    seconds_per_day = 86400
    ti = ti_days * seconds_per_day
    tf = tf_days * seconds_per_day

    @inline time_active(t) = (t >= ti) & (t <= tf)

    @inline gaussian_forcing_2d(i, j) =
        amplitude * exp(-((i - i0)^2 / (2σi^2) + (j - j0)^2 / (2σj^2)))

    @inline forcing(i, j, k, grid, clock, fields) =
        ifelse(time_active(clock.time),
            ifelse(k == k0, gaussian_forcing_2d(i, j), 0.0),
            0.0)

    return Forcing(forcing, discrete_form=true)
end

function build_alkalinity_forcing(grid;
                                  amplitude,
                                  lon,
                                  lat,
                                  sigma,
                                  ti,
                                  tf)


    xc, yc, _ = nodes(grid, Center(), Center(), Center())

    xc_cpu = Array(xc)
    yc_cpu = Array(yc)

    i0 = find_nearest_index(xc_cpu[:, 1], lon)
    j0 = find_nearest_index(yc_cpu[1, :], lat)
    k0 = grid.Nz

    alk_forcing = alk_2dgauss_forcing(amplitude, i0, j0, k0, sigma, sigma, ti, tf)

    forcing = (; Alk2=alk_forcing)

    return forcing
end

end