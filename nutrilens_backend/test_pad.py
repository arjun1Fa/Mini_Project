import cv2
import numpy as np

img = cv2.imread("DOSA2.jpeg")
h, w = img.shape[:2]

# YOLO's actual plate_box for DOSA2.jpeg from our earlier run:
plate_box = [156, 38, 1459, 1018] # I looked at the image. The plate is essentially this

# Let's pad it by 5%
padx = int((plate_box[2]-plate_box[0])*0.05)
pady = int((plate_box[3]-plate_box[1])*0.05)

bx = max(0, plate_box[0] - padx)
by = max(0, plate_box[1] - pady)
bw = min(w, plate_box[2] + padx) - bx
bh = min(h, plate_box[3] + pady) - by

gc_mask = np.zeros((h, w), np.uint8)
cv2.grabCut(img, gc_mask, (bx, by, bw, bh), np.zeros((1, 65), np.float64), np.zeros((1, 65), np.float64), 4, cv2.GC_INIT_WITH_RECT)
fg_mask = np.where((gc_mask==1)|(gc_mask==3), 255, 0).astype('uint8')

# Green filter (using 36 instead of 30 to prevent cutting off dosashadows)
hsv = cv2.cvtColor(img, cv2.COLOR_BGR2HSV)
green_mask = cv2.inRange(hsv, np.array([36, 40, 40]), np.array([85, 255, 255]))
fg_mask[green_mask > 0] = 0

cv2.imwrite("test_padded_grabcut.jpg", fg_mask)
