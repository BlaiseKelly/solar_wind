library(raster)
library(dplyr)
library(tmap)
library(sf)
library(magick)
library(pals)
library(lubridate)

##define coordinate systems
latlong = "+init=epsg:4326"

## define url with Europe coastline
europe_url <- 'https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-1/gis-data/europe-coastline-shapefile/at_download/file'
##download
download.file(europe_url, destfile ='temp/eu.zip', mode='wb')
## unzip
unzip(zipfile = 'temp/eu.zip', exdir = 'temp/eu.shp')
unlink("temp/eu.zip")
europe_shp <- st_read('temp/eu.shp')

## choose co
countries <- c('united kingdom', 'denmark')

for (c in countries){

## read in raster brick of ECMWF ssr values
ssr_brick <- brick(paste0("outputs/", c, "_ssrd.tif"))

#find the date of the model from a previously defined variable
yr <- "2020"
##define the year start date
start_date <- paste0(yr, "-01-01")

##define the year end date
end_date <- paste0(yr, "-12-31")

##create a data frame for the full year
Kre8_D8 <- data.frame(date = seq(
   from=as.POSIXct(start_date, tz="UTC"),
   to=as.POSIXct(end_date, tz="UTC"),
   by="day"
)  )

## replace name with dates
names(ssr_brick) <- paste("day of year ", Kre8_D8$date)

## get raster extent to crop coastline
xyz <- ssr_brick@extent
## extract crs also for crop
crs_xyz <- ssr_brick@crs

## change crs of shape file to match raster
europe_shp <- st_transform(europe_shp, crs_xyz)
## crop to country
coast <- st_crop(europe_shp, xyz)
##define breaks for ssdr
rad_bks <- seq(from = 0, to = 400, by = 20)
## define palette ssdr
rad_pal <- pals::jet(NROW(rad_bks))
## define breaks for wind speeds
wind_bks <- seq(from = 0, to = 20, by = 1)
## define palette for wind speed
wind_pal <- pals::jet(NROW(wind_bks))

## generate plot
 tm_ssr <- tm_shape(ssr_brick) +
   tm_raster(palette = rad_pal, breaks = rad_bks, title = 'solar irradiation (W/m2)')+
   tm_layout(legend.outside = TRUE, title = ' Total daily',
             panel.labels = Kre8_D8$date, 
             panel.label.color = 'white', panel.label.bg.color = 'black')+
   tm_facets(nrow = 1, ncol = 1)

## generate gif
tmap_animation(tm_ssr, filename = paste0("plots/", c, "_ssr.gif"), delay = 60)
 ## movie plot - useful for moving forwards and backwards and to specific dates
 tmap_animation(tm_ssr, filename = paste0('plots/',c, '_ssr.mp4'), width=1200, height = 800, fps = 2, outer.margins = 0)

 ## read in raster brick of ECMWF ssr values
 ws_brick <- brick(paste0("outputs/", c, "_ws.tif"))

 ## name days from date file
 names(ws_brick) <- paste("day of year ", Kre8_D8$date)
 
 ## create tmap of raster and shape file
 tm_ws <- tm_shape(ws_brick) +
   tm_raster(palette = wind_pal, breaks = wind_bks, title = 'wind speed (m/s)')+
   tm_layout(legend.outside = TRUE, panel.labels = Kre8_D8$date, title = 'Average daily',
             panel.label.color = 'white', panel.label.bg.color = 'black')+
   tm_facets(nrow = 1, ncol = 1)+
    tm_shape(coast)+
    tm_lines()
 
 ## gif output - package gifski has to be installed. Tmap will load automatically once done.
 tmap_animation(tm_ws, filename = paste0("plots/", c, "_ws.gif"), delay = 60)
 ## MP4 video output. Package av has to be installed. Tmap will load automatically once done.
 tmap_animation(tm_ws, filename = paste0("plots/", c, "_ws.mp4"), width=1200, height = 800, fps = 2, outer.margins = 0)
## read back in the output gifs to combine side by side on one plot
 g1 <- image_read(paste0("plots/", c, "_ssr.gif"))
 g2 <- image_read(paste0("plots/",c, "_ws.gif"))
##create first frame
 new_gif <- image_append(c(g1[1], g2[1]), stack = FALSE)
 ##loop through to assemble the gif frame by frame
 for(i in 2:366){
   combined <- image_append(c(g1[i], g2[i]), stack = FALSE)
   new_gif <- c(new_gif, combined)
 }
 ## write the output
magick::image_write_gif(new_gif,delay = 0.5, paste0("plots/", c, "_both.gif"))

}

