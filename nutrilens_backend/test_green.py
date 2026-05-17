import cv2
import numpy as np

img = cv2.imread("idli2.jpg")
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

lower_green = np.array([36, 15, 15])
upper_green = np.array([85, 255, 255])
green_mask = cv2.inRange(hsv, lower_green, upper_green)

res = img.copy()
res[green_mask > 0] = [0, 0, 0]

cv2.imwrite("test_green_plate_removal.jpg", res)
cv2.imwrite("test_green_mask.jpg", green_mask)
