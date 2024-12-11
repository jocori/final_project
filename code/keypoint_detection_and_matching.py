import cv2
import numpy as np
import pandas as pd
import os
from matplotlib import pyplot as plt

# Set up relative paths
project_dir = "/Users/joannacorimanya/Desktop/KU/Classes/machine_learning/final_project"
img_path = os.path.join(project_dir, "Monoplotting", "Bald Lake", "img", "140_2024", "take3.jpg")
print(img_path)
dem_path = os.path.join(project_dir, "Monoplotting", "Bald Lake", "dtm", "Uintas_DEM.tif")
output_keypoints_img = os.path.join(project_dir, "data", "keypoints.csv")
output_keypoints_dem = os.path.join(project_dir, "data", "dem_keypoints.csv")
dem_image_path = os.path.join(project_dir, "data", "dem_image.png")

# Ensure output directories exist
if not os.path.exists(os.path.join(project_dir, "data")):
    os.makedirs(os.path.join(project_dir, "data"))

# Load the image
image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)

# Perform keypoint detection using FAST
fast = cv2.FastFeatureDetector_create(threshold=40, nonmaxSuppression=True, type=cv2.FAST_FEATURE_DETECTOR_TYPE_9_16)
keypoints_img = fast.detect(image, None)

# Draw keypoints on the image
image_with_keypoints = cv2.drawKeypoints(image, keypoints_img, None, color=(255, 0, 0))
plt.imshow(image_with_keypoints)
plt.title("Image Keypoints")
plt.show()

# Convert keypoints to a dataframe and save as CSV
keypoints_img_df = pd.DataFrame([{
    "x": kp.pt[0],
    "y": kp.pt[1],
    "size": kp.size,
    "angle": kp.angle,
    "response": kp.response,
    "octave": kp.octave,
    "class_id": kp.class_id
} for kp in keypoints_img])
keypoints_img_df.to_csv(output_keypoints_img, index=False)

# Keypoint detection on DEM
# Read DEM as a raster
dem = cv2.imread(dem_path, cv2.IMREAD_GRAYSCALE)

# Normalize DEM to 0-255
dem_normalized = cv2.normalize(dem, None, alpha=0, beta=255, norm_type=cv2.NORM_MINMAX, dtype=cv2.CV_8U)

# Save normalized DEM as PNG
cv2.imwrite(dem_image_path, dem_normalized)

# Perform keypoint detection on DEM using FAST
keypoints_dem = fast.detect(dem_normalized, None)

# Draw keypoints on the DEM image
dem_with_keypoints = cv2.drawKeypoints(dem_normalized, keypoints_dem, None, color=(255, 0, 0))
plt.imshow(dem_with_keypoints, cmap="gray")
plt.title("DEM Keypoints")
plt.show()

# Convert DEM keypoints to a dataframe and save as CSV
keypoints_dem_df = pd.DataFrame([{
    "x": kp.pt[0],
    "y": kp.pt[1],
    "size": kp.size,
    "angle": kp.angle,
    "response": kp.response,
    "octave": kp.octave,
    "class_id": kp.class_id
} for kp in keypoints_dem])
keypoints_dem_df.to_csv(output_keypoints_dem, index=False)

# Perform keypoint matching using BFMatcher
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
# Since FAST does not provide descriptors, we must use another detector (e.g., ORB) for matching
orb = cv2.ORB_create()
_, des_img = orb.compute(image, keypoints_img)
_, des_dem = orb.compute(dem_normalized, keypoints_dem)

matches = bf.match(des_img, des_dem)
matches = sorted(matches, key=lambda x: x.distance)

# Draw matches
matched_image = cv2.drawMatches(image, keypoints_img, dem_normalized, keypoints_dem, matches[:50], None, flags=cv2.DrawMatchesFlags_NOT_DRAW_SINGLE_POINTS)
plt.imshow(matched_image)
plt.title("Matched Keypoints")
plt.show()

# Convert matches to a dataframe and save as CSV
matches_df = pd.DataFrame([{
    "query_idx": match.queryIdx,
    "train_idx": match.trainIdx,
    "img_distance": match.distance
} for match in matches])
matches_df.to_csv(os.path.join(project_dir, "data", "matched_keypoints.csv"), index=False)
