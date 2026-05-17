import cv2
import numpy as np

img = cv2.imread("idli2.jpg")
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)

white_mask = cv2.inRange(hsv, np.array([0, 0, 180]), np.array([179, 60, 255]))

res = img.copy()
res[white_mask == 0] = [0, 0, 0]

cv2.imwrite("test_white_filter.jpg", res)
cv2.imwrite("test_white_mask.jpg", white_mask)
