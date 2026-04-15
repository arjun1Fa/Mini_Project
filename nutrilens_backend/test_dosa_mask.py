import cv2
import numpy as np

img = cv2.imread("DOSA2.jpeg")
h, w = img.shape[:2]

# 1. GrabCut with big box
bx, by, bw, bh = int(w*0.02), int(h*0.02), int(w*0.96), int(h*0.96)
gc_mask = np.zeros((h, w), np.uint8)
cv2.grabCut(img, gc_mask, (bx, by, bw, bh), np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64), 4, cv2.GC_INIT_WITH_RECT)
fg_mask = np.where((gc_mask==1)|(gc_mask==3), 255, 0).astype('uint8')
cv2.imwrite("stage1_grabcut.jpg", fg_mask)

# 2. Green filter
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
green_mask_30 = cv2.inRange(hsv, np.array([30, 40, 40]), np.array([85, 255, 255]))
cv2.imwrite("stage2_green_30.jpg", green_mask_30)

green_mask_38 = cv2.inRange(hsv, np.array([36, 40, 40]), np.array([85, 255, 255]))
cv2.imwrite("stage2_green_38.jpg", green_mask_38)

fg_mask_30 = fg_mask.copy()
fg_mask_30[green_mask_30 > 0] = 0
cv2.imwrite("stage3_fg_minus_green30.jpg", fg_mask_30)

fg_mask_38 = fg_mask.copy()
fg_mask_38[green_mask_38 > 0] = 0
cv2.imwrite("stage3_fg_minus_green38.jpg", fg_mask_38)
