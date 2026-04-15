import cv2
import numpy as np

img = cv2.imread("DOSA2.jpeg")
h, w = img.shape[:2]

# Centers for DOSA2 based on visual inspection
centers = [
    (0.40, 0.40), # Dosa 1 (top)
    (0.40, 0.60), # Dosa 2 (middle)
    (0.40, 0.75), # Dosa 3 (bottom)
    (0.70, 0.70), # Sambar
]

masks = []
for i, (cx_frac, cy_frac) in enumerate(centers):
    cx = int(cx_frac * w)
    cy = int(cy_frac * h)
    
    # 1. Initialize mask with Probable Background
    gc_mask = np.full((h, w), cv2.GC_PR_BGD, np.uint8)
    
    # 2. Add Sure Foreground at the center
    # Sambar gets smaller seed as it is smaller
    r = int(min(w, h) * 0.05) if i == 3 else int(min(w, h) * 0.15)
    cv2.circle(gc_mask, (cx, cy), r, cv2.GC_FGD, -1)
    
    # 3. Add Probable Foreground around it (Generous area for food)
    r_pr = int(min(w, h) * 0.4)
    cv2.circle(gc_mask, (cx, cy), r_pr, cv2.GC_PR_FGD, -1)
    # Redraw Sure FGD to overlap PR FGD
    cv2.circle(gc_mask, (cx, cy), r, cv2.GC_FGD, -1)

    # 4. Add Sure Background at OTHER food centers
    for j, (ox, oy) in enumerate(centers):
        if i != j:
            cv2.circle(gc_mask, (int(ox*w), int(oy*h)), int(min(w,h)*0.05), cv2.GC_BGD, -1)
            
    # Add Sure Background at image corners (the table edges)
    cv2.rectangle(gc_mask, (0, 0), (w, int(h*0.05)), cv2.GC_BGD, -1)
    cv2.rectangle(gc_mask, (0, int(h*0.95)), (w, h), cv2.GC_BGD, -1)

    bgdModel = np.zeros((1, 65), np.float64)
    fgdModel = np.zeros((1, 65), np.float64)
    
    cv2.grabCut(img, gc_mask, None, bgdModel, fgdModel, 5, cv2.GC_INIT_WITH_MASK)
    
    final = np.where((gc_mask == 1) | (gc_mask == 3), 255, 0).astype("uint8")
    masks.append(final)

# visualization
out = img.copy()
colors = [(50, 205, 50), (100, 255, 100), (0, 150, 0), (30, 144, 255)]
for i, m in enumerate(masks):
    cnts, _ = cv2.findContours(m, cv2.RETR_EXTERNAL, cv2.CHAIN_APPROX_SIMPLE)
    if cnts:
        c = max(cnts, key=cv2.contourArea)
        ov = out.copy()
        cv2.drawContours(ov, [c], -1, colors[i], cv2.FILLED)
        cv2.addWeighted(ov, 0.5, out, 0.5, 0, out)
        cv2.drawContours(out, [c], -1, colors[i], 2)

cv2.imwrite("grabcut_test.jpg", out)
print("Done")
