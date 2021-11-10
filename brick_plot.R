library(raster)
library(dplyr)
library(tmap)
library(sf)
library(magick)
library(pals)

##define coordinate systems
latlong = "+init=epsg:4326"

## read in raster brick of ECMWF ssr values
ssr_brick <- readRDS("data/united kingdom_ssrd.RDS")
ssr_brick <- brick(ssr_brick)

ssr_brick <- brick("grid.tif")

namez <- gsub("X", "", names(ssr_brick))
names(ssr_brick) <- gsub("X", "", names(ssr_brick))
namez <- names(ssr_brick)

xyz <- ssr_brick@extent
crs_xyz <- ssr_brick@crs

plot(ssrd)
## define url with Europe coastline
europe_url <- 'https://www.eea.europa.eu/data-and-maps/data/eea-coastline-for-analysis-1/gis-data/europe-coastline-shapefile/at_download/file'
##download
download.file(europe_url, destfile ='temp/eu.zip', mode='wb')
## unzip
unzip(zipfile = 'temp/eu.zip', exdir = 'temp/eu.shp')

europe_shp <- st_read('temp/eu.shp') %>% 
   st_transform(crs_xyz)

UK <- st_crop(europe_shp, xyz)

rad_bks <- seq(from = 0, to = 400, by = 20)

rad_pal <- pals::jet(NROW(rad_bks))

wind_bks <- seq(from = 0, to = 20, by = 1)

wind_pal <- pals::jet(NROW(wind_bks))

## generate plot
 tm_ssr <- tm_shape(sb) +
   tm_raster(palette = rad_pal, breaks = rad_bks)+
   tm_layout(legend.outside = TRUE, frame = FALSE)+
   tm_facets(nrow = 1, ncol = 1)

## generate gif
tmap_animation(tm_ssr, filename = "plots/dk_ssr.gif", delay = 50)
 ## movie plot - useful for moving forwards and backwards and to specific dates
 tmap_animation(tm_ssr, filename = paste0('plots/dk_ssr.mp4'), width=1200, height = 800, fps = 2, outer.margins = 0)
 
 
 ## read in raster brick of ECMWF ssr values
 ws_brick <- brick("denmark_ws.tif")
 

 tm_ws <- tm_shape(ws_brick) +
   tm_raster(palette = wind_pal, breaks = wind_bks)+
   tm_layout(legend.outside = TRUE)+
   tm_facets(nrow = 1, ncol = 1)+
    tm_shape(UK)+
    tm_lines()
 
 tmap_animation(tm_ws, filename = "plots/dk_ws.gif", delay = 50)
 tmap_animation(tm_ws, filename = paste0(c_sf$iso_a2, "_ws.mp4"), width=1200, height = 800, fps = 2, outer.margins = 0)
 
 save(ws_brick, ssr_brick, file = "bricks.RData")

 
 g1 <- image_read(paste0("plots/dk_ssr.gif"))
 g2 <- image_read(paste0("plots/dk_ws.gif"))

 new_gif <- image_append(c(g1[1], g2[1]), stack = FALSE)
 for(i in 2:366){
   combined <- image_append(c(g1[i], g2[i]), stack = FALSE)
   new_gif <- c(new_gif, combined)
 }
 
magick::image_write_gif(new_gif, paste0("dk_both.gif"))

