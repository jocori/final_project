import rasterio
import numpy as np
import cv2
import os
import pandas as pd
import matplotlib.pyplot as plt
from scipy.optimize import minimize

# Set up relative paths
project_dir = "/Users/joannacorimanya/Desktop/KU/Classes/machine_learning/final_project"
img_path = os.path.join(project_dir, "Monoplotting", "Bald Lake", "img", "140_2024", "take3.jpg")
dem_path = os.path.join(project_dir, "Monoplotting", "Bald Lake", "dtm", "Uintas_DEM.tif")
output_keypoints_img = os.path.join(project_dir, "data", "keypoints.csv")
output_matches = os.path.join(project_dir, "data", "matches.csv")
output_camera_params = os.path.join(project_dir, "data", "camera_params.csv")

# Ensure output directories exist
os.makedirs(os.path.join(project_dir, "data"), exist_ok=True)

# Load the image and DEM
image = cv2.imread(img_path, cv2.IMREAD_GRAYSCALE)
with rasterio.open(dem_path) as dem_file:
    dem = dem_file.read(1)
    dem_affine = dem_file.transform

# Normalize DEM for visualization
dem_normalized = np.interp(dem, (dem.min(), dem.max()), (0, 255)).astype(np.uint8)

# Keypoint detection using ORB
orb = cv2.ORB_create()
keypoints_img, descriptors_img = orb.detectAndCompute(image, None)
keypoints_dem, descriptors_dem = orb.detectAndCompute(dem_normalized, None)

# Match keypoints
bf = cv2.BFMatcher(cv2.NORM_HAMMING, crossCheck=True)
matches = bf.match(descriptors_img, descriptors_dem)
matches = sorted(matches, key=lambda x: x.distance)

# Extract matched keypoints
matched_img_points = np.array([keypoints_img[m.queryIdx].pt for m in matches])
matched_dem_points = np.array([keypoints_dem[m.trainIdx].pt for m in matches])

# Save keypoint matches to CSV
matches_df = pd.DataFrame({
    "img_x": matched_img_points[:, 0],
    "img_y": matched_img_points[:, 1],
    "dem_x": matched_dem_points[:, 0],
    "dem_y": matched_dem_points[:, 1]
})
matches_df.to_csv(output_matches, index=False)

# Camera parameter optimization
def reprojection_error(params, img_points, dem_points):
    fx, fy, cx, cy, tx, ty, tz = params
    # Add a column of ones to dem_points to handle the transformation
    dem_points_homogeneous = np.hstack((dem_points, np.ones((dem_points.shape[0], 1))))

    # Simplified projection model for error calculation
    transformation_matrix = np.array([[fx, 0, cx], [0, fy, cy], [tx, ty, tz]])
    projected_points = np.dot(dem_points_homogeneous, transformation_matrix.T)

    # Calculate Euclidean distance between projected and image points
    return np.sum(np.linalg.norm(img_points - projected_points[:, :2], axis=1))

initial_params = [1, 1, image.shape[1] / 2, image.shape[0] / 2, 0, 0, 0]
result = minimize(reprojection_error, initial_params, args=(matched_img_points, matched_dem_points))

# Save optimized camera parameters
camera_params = result.x
camera_params_df = pd.DataFrame([camera_params], columns=["fx", "fy", "cx", "cy", "tx", "ty", "tz"])
camera_params_df.to_csv(output_camera_params, index=False)

# Visualize matched keypoints
img_with_matches = cv2.drawMatches(image, keypoints_img, dem_normalized, keypoints_dem, matches, None, flags=2)
plt.imshow(img_with_matches)
plt.title("Matched Keypoints")
plt.show()
