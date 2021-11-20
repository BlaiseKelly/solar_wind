# Comparison of Solar and Wind potential

Plot cumulative solar irradiation and average daily wind speed side by side for any country in Europe to see how solar and wind complement each other

## Why solar and wind

Solar and wind energy are the cheapest sources of electricity. They also complement each other very well. Generally  there is a lot more wind in the 4th and 1st Quarters of the year and a lot more sun in the 2nd and 3rd. When the weather is calm there are often fewer clouds meaning more sunlight reaches the ground.

## ECMWF

The ECMWF reanalysis datasets cover the entire world. They are a combination of Satellite and ground observations, modelled to provide a uniform and consistent dataset.

The two main useful datasets for meteo data are the ERA5-Land and ERA5 Pressure level. The ERA5-Land is only available over land and is gridded at a resolution of approximately 9km (varies depending on the exact latitude), but has fewer modelled parameters than the ERA5 pressure level data, which also covers multiple levels in the atmosphere, and is available for around 250 parameters, however, the resolution is approximately 30km, significantly less than the land.

Hourly 'solar surface radiation downwards' (ssrd) estimates for the year of 2020 were downloaded from the ERA5-Land dataset and the '10m u (u10) and v (v10)' components of wind from the ERA5 pressure level. Ssrd was summed for the day and the u and v components of wind were combined to give speed and direction for each hour. The speed was then averaged for each day.

### solar surface downward radiation (ssdr)
Total direct and diffuse solar radiation from the Sun that is incident on the Earth's surface (represented by this variable). To a reasonably good approximation, this is the model equivalent of what would be measured by a pyranometer (an instrument used for measuring solar radiation) at the surface. The data comes from the ECMWF as joules per square metre (J m-2) and is converted to watts per square metre (W m-2) by dividing by the accumulation period expressed in seconds. 

### wind speed at 10m
wind speed is derived from the 10m u (u10) and 10m v (v10) components of wind. U10 is the eastward component of the 10m wind. It is the horizontal speed of air moving towards the east, at a height of ten metres above the surface of the Earth, in metres per second. V10 is the northward component of the 10m wind. It is the horizontal speed of air moving towards the north, at a height of ten metres above the surface of the Earth, in metres per second.

ECMWF data is available to download for free from the Copernicus data store. The ecmwfr package provides functions to acheive this. However, these might take some getting used to if you are new to this resource. An example code for downloading the land and pressure level data is given in this repository https://github.com/BlaiseKelly/ecmwf_download
