library(raster)
library(lubridate)
library(dplyr)
library(ncdf4)
library(reshape2)
library(sf)
library(openair)
library(rnaturalearth)
library(rnaturalearthdata)
library(tmap)
library(birk)
library(magick)
library(pals)

##define coordinate systems
latlong = "+init=epsg:4326"
rdnew = "+init=epsg:28992" ## metres coordinate system - Dutch

## country of interest
countries <- c('united kingdom', 'denmark')
##loop through each country to generate raster
for (c in countries){

   ## import country shape file from rnaturalearth package
c_shp <- st_as_sf(ne_countries(country = c))
## buffer by 200km
c_sf <- c_shp %>%
  st_transform(rdnew) %>% 
  st_buffer(200000) %>% 
  st_transform(latlong)

## find max and min coordinates of buffered country shapefile
min_lon <- min(st_coordinates(c_sf)[,1])
max_lon <- max(st_coordinates(c_sf)[,1])
min_lat <- min(st_coordinates(c_sf)[,2])
max_lat <- max(st_coordinates(c_sf)[,2])

## loads in a raw netcdf file of ssrd downloaded from ecmwf that covers the countries specified
ssrd <- "surface_solar_radiation_downwards_2020.nc"
## open the file
ECMWF <- nc_open(ssrd)
##get latitude and longitude range from file
      lons <- ncvar_get(ECMWF, "longitude")
      lats <- ncvar_get(ECMWF, "latitude")
      ## find netcdf extent that matches country shape file
      lon_min <- which.closest(lons, min_lon)
      lon_max <- which.closest(lons, max_lon)
      lat_min <- which.closest(lats, min_lat)
      lat_max <- which.closest(lats, max_lat)
      
      ##determine how many latitude and longitude variables there are
      lat_n <- NROW(lats)
      lon_n <- NROW(lons)
## import all coordinates for country area
      longitude <- ncvar_get(ECMWF, "longitude", start = c(lon_min), count = c(lon_max-lon_min))
      latitude <- ncvar_get(ECMWF, "latitude", start = c(lat_max), count = c(lat_min-lat_max))
      ##create min x and y
      x_min <- min(longitude)
      x_max <- max(longitude)
      y_min <- min(latitude)
      y_max <- max(latitude)
      ##determine number of lat and lon points
      n_y <- NROW(latitude)
      n_x <- NROW(longitude)
      
      ##work out number of x and y cells
      res <- (x_max-x_min)/n_x
      res <- (y_max-y_min)/n_y
      
      ##create a data frame to setup polygon generation
      df <- data.frame(X = c(x_min, x_max, x_max, x_min), 
                       Y = c(y_max, y_max, y_min, y_min))
      
      ##generate a polygon of the area
      vgt_area <- df %>%
        st_as_sf(coords = c("X", "Y"), crs = latlong) %>%
        dplyr::summarise(data = st_combine(geometry)) %>%
        st_cast("POLYGON")
      
      ##import time stamps from netcdf
      thyme <- ncvar_get(ECMWF, "time")
      
      ##convert to POSIX - info given here https://confluence.ecmwf.int/display/CKB/ERA5%3A+data+documentation#ERA5:datadocumentation-Dateandtimespecification
      d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(thyme)
      
      ## determine the variable in the ECMWF file
      var <- names(ECMWF$var)
      
      ##create data frame of dates
      d8r <- data.frame(date = d8)
      ## ssrd data is cumulative so for the daily total we only need the value at the end of the day 23:00
      d8_df <- d8r %>%
  mutate(colsplit(date, " ", c("date", "hour")),
         row_d8 = seq(1:NROW(date))) %>% 
  filter(hour == "23:00:00")
      
      ##unique dates
      indz <- unique(d8_df$row_d8)
##list to populate
 all_rasts <- list()
 ##loop through each day, extract data and build a brick
 for (h in indz){
   
   D8 <- filter(d8_df, row_d8 == h)[,1]
   
   ##extract no2 variables for entire domain for 1 time step and altitude
   r1 <- ncvar_get(ECMWF, var, start = c(lon_min,lat_max,h), count = c(n_x,n_y,1))
   ##generate raster from it
   r1 <- t(r1)
   r <- raster(r1)
   ##define the extent
   bb <- extent(vgt_area)
   extent(r) <- bb
   r <- setExtent(r, bb,  keepres=FALSE)
   ##define the crs
   raster::crs(r) <- latlong
   a2 <- r
   ## to plot a smoother plot, the raster can be dissagragated, it will take longer to process and use more RAM
   #a2 <- raster::disaggregate(r, fact = 2, method = "bilinear")
   
   #To convert to watts per square metre (W m-2), the accumulated values should be divided by the accumulation period expressed in seconds
   a2 <- calc(a2, function(x) {x/(3600*24)})
   ## add to list
   all_rasts[[D8]] <- a2
   print(D8) ## print where up to
   flush.console()
   
 }
 ##combine all raster layers
 ssrd_brick <- brick(all_rasts)
 
## To write out the raster use the script below
writeRaster(ssrd_brick, filename=paste0("outputs/", c, "_ssrd.TIF"), format="GTiff", overwrite=TRUE,options=c("INTERLEAVE=BAND","COMPRESS=LZW"))

 ## WIND SPEED
 
v10 <- "10m_v_component_of_wind_2020.nc"
u10 <- "10m_u_component_of_wind_2020.nc"
 
 ECMWF_v <- nc_open(v10)
 ECMWF_u <- nc_open(u10)
 
 lons <- ncvar_get(ECMWF_v, "longitude")
 lats <- ncvar_get(ECMWF_v, "latitude")
 
 lon_min <- which.closest(lons, min_lon)
 lon_max <- which.closest(lons, max_lon)
 lat_min <- which.closest(lats, min_lat)
 lat_max <- which.closest(lats, max_lat)
 
 ##determine how many latitude and longitude variables there are
 lat_n <- NROW(lats)
 lon_n <- NROW(lons)
 
 longitude <- ncvar_get(ECMWF_v, "longitude", start = c(lon_min), count = c(lon_max-lon_min))
 latitude <- ncvar_get(ECMWF_v, "latitude", start = c(lat_max), count = c(lat_min-lat_max))
 ##create min x and y
 x_min <- min(longitude)
 x_max <- max(longitude)
 y_min <- min(latitude)
 y_max <- max(latitude)
 ##determine number of lat and lon points
 n_y <- NROW(latitude)
 n_x <- NROW(longitude)
 
 ##work out number of x and y cells
 res <- (x_max-x_min)/n_x
 res <- (y_max-y_min)/n_y
 
 ##create a data frame to setup polygon generation
 df <- data.frame(X = c(x_min, x_max, x_max, x_min), 
                  Y = c(y_max, y_max, y_min, y_min))
 
 ##generate a polygon of the area
 vgt_area <- df %>%
   st_as_sf(coords = c("X", "Y"), crs = latlong) %>%
   dplyr::summarise(data = st_combine(geometry)) %>%
   st_cast("POLYGON")
 
 thyme <- ncvar_get(ECMWF_v, "time")
 #d8 <- date(ymd_h(as.POSIXct(thyme, origin="1900-01-01 00:00")))
 d8 <- lubridate::ymd("1900-01-01") + lubridate::hours(thyme)
 
 var <- names(ECMWF_v$var)
 row_d8 <- seq(1:NROW(d8))
 
 d8r <- data.frame(date = d8)
 d8_df <- d8r %>%
   mutate(row_d8 = seq(1:NROW(date)),
          day = yday(date))
 
 dayz <- unique(d8_df$day)
 
 all_rasts <- list()

 for (d in dayz){
   
   df <- filter(d8_df, day == d)
   
   df_day <- colsplit(df$date, " ", c("date", "hour"))[,1]
   df_day <- df_day[1]
   
   indz <- unique(df$row_d8)
   
   each_day <- list()
 
 for (h in indz){
   
   
   D8 <- filter(df, row_d8 == h)[,1]
   
   ##extract no2 variables for entire domain for 1 time step and altitude
   u <- ncvar_get(ECMWF_u, "u10", start = c(lon_min,lat_max,h), count = c(n_x,n_y,1))
   ##generate raster from it
   ru <- t(u)
   ru <- raster(ru)
   ##define the extent
   bb <- extent(vgt_area)
   extent(ru) <- bb
   ru <- setExtent(ru, bb,  keepres=FALSE)
   ##define the crs
   raster::crs(ru) <- latlong
   
   ru <- raster::disaggregate(ru, fact = 2, method = "bilinear")
   
   u_xyz <- data.frame(rasterToPoints(ru))
   
   v <- ncvar_get(ECMWF_v, "v10", start = c(lon_min,lat_max,h), count = c(n_x,n_y,1))
   ##generate raster from it
   rv <- t(v)
   rv <- raster(rv)
   ##define the extent
   bb <- extent(vgt_area)
   extent(rv) <- bb
   rv <- setExtent(rv, bb,  keepres=FALSE)
   ##define the crs
   raster::crs(rv) <- latlong
   
   ##as wind data is lower resolution than ssdr we can dissagregate to smooth
   #rv <- raster::disaggregate(rv, fact = 5, method = "bilinear")
   rv <- raster::disaggregate(rv, fact = 2, method = "bilinear")
## convert to data frame to combine u and v components
   v_xyz <- data.frame(rasterToPoints(rv))
   
   u_xyz$v <- v_xyz$layer
   ## give header meaningful names
   names(u_xyz) <- c("x", "y", "u10", "v10")
   ## combine u and v elements to wind speed and direction and drop direction
   ws_wd <- u_xyz %>%
     mutate(wind_abs = sqrt(u10^2 + v10^2)) %>%
     mutate(wind_dir_trig_to = atan2(u10/wind_abs, v10/wind_abs)) %>% 
   mutate(wind_dir_trig_to_degrees = wind_dir_trig_to*180/pi) %>% 
   mutate(wind_dir_trig_from_degrees = wind_dir_trig_to_degrees + 180) %>% 
   mutate(wd = 90 - wind_dir_trig_from_degrees) %>% ##wind direction cardinal
   mutate(ws = sqrt(u10^2 + v10^2)) %>% 
     select(x, y, ws)
 ## convert back to raster
  wsr <- rasterFromXYZ(ws_wd, crs = latlong)
  ##to name list needs to be a raster
D8 <- as.character(D8)
  each_day[[D8]] <- wsr
  print(D8)
  flush.console()
  
 }
  ## average hourly values to full day
   day_brick <- brick(each_day)
   day_brick <- calc(day_brick, mean)
   
 all_rasts[[df_day]]  <- day_brick

 }
 
 ws_brick <- brick(all_rasts)
## If required write the raster out
writeRaster(ws_brick, filename=paste0('outputs/', c, "_ws.TIF"), format="GTiff", overwrite=TRUE,options=c("INTERLEAVE=BAND","COMPRESS=LZW"))
}