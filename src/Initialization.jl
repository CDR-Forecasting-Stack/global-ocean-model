module Initialization

using NumericalEarth: ECCO4Monthly, ECCO4DarwinMonthly, Metadatum

export initialize_ocean!

# TODO: set date correctly, it is in atmosphere right now
function initialize_ocean!(ocean, grid, date)

    # -----------------------------------------------------------------
    # initialization datasets
    # -----------------------------------------------------------------
    ecco   = ECCO4Monthly()
    darwin = ECCO4DarwinMonthly()
    
    # -----------------------------------------------------------------
    # ECCO fields
    # -----------------------------------------------------------------
    ecco_temperature           = Metadatum(:temperature; date, dataset=ecco)
    ecco_salinity              = Metadatum(:salinity; date, dataset=ecco)
    ecco_sea_ice_thickness     = Metadatum(:sea_ice_thickness; date, dataset=ecco)
    ecco_sea_ice_concentration = Metadatum(:sea_ice_concentration; date, dataset=ecco)

    # -----------------------------------------------------------------
    # Darwin
    # -----------------------------------------------------------------
    ecco_darwin_alk  = Metadatum(:alkalinity; date, dataset=darwin)
    ecco_darwin_dic  = Metadatum(:dissolved_inorganic_carbon; date, dataset=darwin)
    ecco_darwin_no3  = Metadatum(:nitrate; date, dataset=darwin)
    #ecco_darwin_po4  = Metadatum(:phosphate; date, dataset=darwin)
    #ecco_darwin_dop  = Metadatum(:dissolved_organic_phosphorus; date, dataset=darwin)
    #ecco_darwin_pop  = Metadatum(:particulate_organic_phosphorus; date, dataset=darwin)
    #ecco_darwin_fet  = Metadatum(:dissolved_iron; date, dataset=darwin)
    #ecco_darwin_sio2 = Metadatum(:dissolved_silicate; date, dataset=darwin)
    #ecco_darwin_02   = Metadatum(:dissolved_oxygen; date, dataset=darwin)

    # -----------------------------------------------------------------
    # Phytoplankton and Zooplankton
    # -----------------------------------------------------------------
    # initialize to really small value
    phytoplankton_seed_concentration = zeros(Float64, size(grid))
    phytoplankton_seed_concentration .= 0.001  # mmol N m⁻³

    # initialize to really small value
    zooplankton_seed_concentration = zeros(Float64, size(grid))
    zooplankton_seed_concentration .= 0.0002 # mmol N m⁻³

    set!(ocean.model, 
        T    = ecco_temperature,
        S    = ecco_salinity, 
        Alk1 = ecco_darwin_alk, 
        DIC1 = ecco_darwin_dic, 
        Alk2 = ecco_darwin_alk, 
        DIC2 = ecco_darwin_dic,
        NO₃  = ecco_darwin_no3,
        P    = phytoplankton_seed_concentration,
        Z    = zooplankton_seed_concentration)

end

end