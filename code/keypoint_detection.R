install.packages("opencv")
install.packages("magick")
library(opencv)
library(magick)
library(raster)

setwd("/Users/joannacorimanya/Desktop/KU/Classes/machine_learning/final_project")
# Load the image
img_path <- "/Users/joannacorimanya/Desktop/KU/Classes/machine_learning/final_project/Monoplotting/Bald Lake/img/140_2024/take3.JPG"
image <- image_read(img_path)

# Convert to OpenCV format
opencv_img <- ocv_read(img_path)

# Perform keypoint detection using FAST
keypoints_fast <- ocv_keypoints(
  image = opencv_img,
  method = "FAST",
    threshold = 40,
    nonmaxSuppression = TRUE,
    type = "TYPE_9_16" # Choose between TYPE_9_16, TYPE_7_12, TYPE_5_8
  )

# Display the image with features
plot(keypoints_fast)
# Convert to dataframe
keypoints_fast<-as.data.frame(keypoints_fast)

# Save keypoints to a CSV file
write.csv(keypoints_fast, "data/keypoints.csv", row.names = FALSE)

##Keypoint detection on DEM


# Read DEM as a raster
dem <- raster("/Users/joannacorimanya/Desktop/KU/Classes/machine_learning/final_project/Monoplotting/Bald Lake/dtm/Uintas_DEM.tif")
# Normalize DEM to 0-255
dem_normalized <- (dem - minValue(dem)) / (maxValue(dem) - minValue(dem)) * 255

# Convert to raster and save as PNG
dem_image_path <- "dem_image.png"
png(dem_image_path)
plot(as.raster(dem_normalized))  # Save as a raster image
dev.off()
# Read the normalized DEM as an OpenCV image
opencv_img <- ocv_read(dem_image_path)

# Perform keypoint detection using FAST
keypoints_fast <- ocv_keypoints(
  image = opencv_img,
  method = "FAST",
  threshold = 40,
  nonmaxSuppression = TRUE,
  type = "TYPE_9_16" # Choose between TYPE_9_16, TYPE_7_12, TYPE_5_8
)
plot(keypoints_fast)
# Convert to dataframe
keypoints_fast<-as.data.frame(keypoints_fast)

# Save keypoints to a CSV file
write.csv(keypoints_fast, "data/dem_keypoints.csv", row.names = FALSE)

