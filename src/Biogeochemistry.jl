module BiogeochemistrySetup

using Oceananigans: FieldBoundaryConditions
using OceanBioME: LOBSTER, CarbonateSystem
using OceanBioME.Models.GasExchangeModel: CarbonDioxideGasExchangeBoundaryCondition

export build_bgc

function build_bgc(grid)

    bgc = LOBSTER(
        grid;
        carbonate_system = CarbonateSystem(2)
    )

    # -----------------------------------------------------------------
    # TODO: make these a little more descriptive instead of "flux1 and 2"
    # ALK2 is the one that is forced, see Forcing.jl
    # -----------------------------------------------------------------
    CO₂_flux1 =
        CarbonDioxideGasExchangeBoundaryCondition(
            water_concentration =
                CarbonDioxideConcentration(
                    DIC = :DIC1,
                    Alk = :Alk1
                )
        )

    CO₂_flux2 =
        CarbonDioxideGasExchangeBoundaryCondition(
            water_concentration =
                CarbonDioxideConcentration(
                    DIC = :DIC2,
                    Alk = :Alk2
                )
        )

    bcs = (
        DIC1 = FieldBoundaryConditions(top = CO₂_flux1),
        DIC2 = FieldBoundaryConditions(top = CO₂_flux2)
    )

    # -----------------------------------------------------------------
    # calculate pCO2
    # TODO: this should be pulled out maybe and its own function
    # -----------------------------------------------------------------
    function pco2_kfo(i, j, k, grid, cc, fields)
        @inbounds begin
            DIC = fields.DIC1[i, j, k]
            Alk = fields.Alk1[i, j, k]
            T = fields.T[i, j, k]
            S = fields.S[i, j, k]
        end

        return cc(; DIC, Alk, T, S)
    end

    pco2 = KernelFunctionOperation{Center, Center, Center}(pco2_kfo, grid, CarbonChemistry(), (; DIC1, Alk1, T, S))

    return bgc, bcs, pco2, CO₂_flux1, CO₂_flux2
end

end