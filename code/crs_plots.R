#Code #2 in R 
#This code is made to plot the pixel points above the original photo. 

#Structure 
#1. Libraries 
#2. Working directory 
#3. Initial objects 
#4. Assign CRS 
#5. Plots 
#5.1 Pixel points above historical photo
#5.2 Pixel points above DEM

#1. Libraries
#library(sf)
#library(raster)
#library(sp)
#library(ggplot2)
#library(jpeg)
#library(viridis)
#library(dplyr)
#install.packages("ggtext")
#library(ggtext) 
#library(grid)
#library(gridExtra)

#2. Working directory 
setwd("...") #Set here your working directory

#3. Initial Objects 
# Load the image (as a background for visualization)
img <- readJPEG(".../140_2024/take3.JPG")

# Image dimensions for ggplot background
raster_dims <- dim(img)
xmin <- 0
xmax <- raster_dims[2]  # Image width
ymin <- 0
ymax <- raster_dims[1]  # Image height

# Load the DEM raster
dem <- raster("...Uintas_DEM.tif")

#4. Assign CRS 
crs(dem) <- CRS("+proj=utm +zone=12 +datum=WGS84")

# Convert DEM to points for ggplot visualization
dem_points <- rasterToPoints(dem, spatial = TRUE)
dem_df <- as.data.frame(dem_points)
colnames(dem_df) <- c("x", "y", "elevation")

# Load pixel coordinates CSV
pixel_coords <- read.csv("data/matches.csv")

# Convert CSV to sf object
spatial_points <- st_as_sf(pixel_coords, coords = c("img_x", "img_y"), 
                           crs = 26912)

# Transform spatial points to match DEM CRS if necessary
spatial_points <- st_transform(spatial_points, crs = st_crs(dem))

# Extract coordinates for labeling
spatial_points_coords <- st_coordinates(spatial_points)
spatial_points <- cbind(as.data.frame(spatial_points), 
                        spatial_points_coords)

#5. Plots 
#5.1 Pixel points above historical photo
ggplot() +
  # DEM background
  geom_raster(data = dem_df, aes(x = x, y = y, fill = elevation)) +
  scale_fill_viridis_c() +
  # Overlay image without alpha
  annotation_raster(img, xmin = xmin, xmax = xmax, ymin = ymin, 
                    ymax = ymax) +
  # Overlay spatial points
  geom_point(data = spatial_points, aes(x = X, y = Y), color = "red",
             size = 3) +
  # Add labels to points
  geom_text(data = spatial_points, aes(x = X, y = Y, 
                                       label = paste0("(", round(X, 1), 
                                                      ", ", round(Y, 1), ")")), 
            color = "white", size = 3, vjust = -1) +
  # Themes and labels
  theme_minimal() +
  labs(title = "Spatial Points on DEM with Image Overlay",
       x = "Longitude",
       y = "Latitude") +
  coord_sf()


# Define image dimensions
img_width <- dim(img)[2]
img_height <- dim(img)[1]

# Load the CSV with pixel points
pixel_coords <- read.csv("data/matches.csv")

# Convert the CSV to an sf object with image coordinates
spatial_points <- st_as_sf(pixel_coords, coords = c("img_x", "img_y"),
                           crs = NA)

# Extract coordinates into a data frame and adjust y-axis
coords_df <- as.data.frame(st_coordinates(spatial_points)) %>%
  rename(pixel_x = X, pixel_y = Y) %>%  # Rename to avoid duplicates
  mutate(img_y = img_height - pixel_y)  # Flip Y coordinates


coords_df <- bind_cols(
  pixel_coords %>% select(-img_x, -img_y),  
  coords_df
)


#saving the plot 

my_plot <- ggplot() +
  # Add the image as a raster layer
  annotation_raster(img, xmin = 0, xmax = img_width, ymin = 0, 
                    ymax = img_height) +
  # Add the pixel points
  geom_point(data = coords_df, aes(x = pixel_x, y = img_y), 
             color = "red", size = 3) +
  # Add labels to the points (optional)
  geom_text(data = coords_df, 
            aes(x = pixel_x, y = img_y, label = paste0("(", 
                                                       round(pixel_x, 1),
                                                       ", ", round(img_y, 1), 
                                                       ")")), 
            color = "white", size = 3, vjust = -1) +
  # Set the aspect ratio to match the image
  coord_fixed(ratio = 1) +
  theme_minimal() +
  labs(title = "Pixel Points Overlayed on Image",
       x = "Image X",
       y = "Image Y")

ggsave("pixel_points_overlay.png", plot = my_plot, width = 8, height = 6, 
       dpi = 300)
#5. Plots 
#5.2 Pixel points above DEM
points <- read.csv(".../coord1.csv")

# Convert CSV to an sf object
points_sf <- st_as_sf(points, coords = c("X", "Y"), crs = 26912)
polygon_coords <- rbind(
  c(542164.32, 4523489.91),  # Replace with your point coordinates
  c(541793.01, 4525406.67),
  c(544015.88, 4525871.11),
  c(544122.85, 4523334.02),
  c(542164.32, 4523489.91)  # Close the polygon
)
polygon_sf <- st_polygon(list(polygon_coords)) %>%
  st_sfc(crs = 26912) %>%
  st_sf()
dem_cropped <- crop(dem, polygon_sf)
dem_cropped <- mask(dem_cropped, as(polygon_sf, "Spatial"))
plot(dem_cropped)
#add GIS 
#utm details 
geoemtry <- read.csv(".../geometry.csv")
geometry_sf <- st_as_sf(geometry, coords = c("x", "y"), crs = 32612)
plot(dem, main = "DEM with Control Points")

# Add the points on top of the DEM
plot(geometry_sf["id"], add = TRUE, col = "red", pch = 16, cex = 1.5)
#save the plot 

pic140 <- read.csv(".../pic140.csv")
pic140_sf <- st_as_sf(pic140, coords = c("x", "y"), crs = 32612)
plot(pic140_sf["id"], add = TRUE, col = "blue", pch = 16, cex = 1.5)

dev.off()

#Creating a close up for the DEM's plot

# Buffer distance 
buffer_distance <- 9000  

# Create a buffer around all points
points_buffer <- st_buffer(st_union(geometry_sf), dist = buffer_distance)

# Crop the DEM using the buffer's extent
dem_circular <- mask(crop(dem, st_bbox(points_buffer)), as(points_buffer,
                                                           "Spatial"))

# Plot the DEM with the circular zoom and points
plot(dem_circular, main = "DEM with Circular Buffer Around Control Points")
plot(st_geometry(points_buffer), add = TRUE, border = "blue", lwd = 2)  
plot(geometry_sf["id"], add = TRUE, col = "red", pch = 16, cex = 0.5)  
#End of code 
