import cv2
from ultralytics import YOLO

model = YOLO("yolov8n-seg.pt")
results = model("idli2.jpg", verbose=False)[0]

boxes = results.boxes.xyxy.cpu().numpy().astype(int)
clss = results.boxes.cls.cpu().numpy().astype(int)
confs = results.boxes.conf.cpu().numpy()

for i in range(len(clss)):
    print(f"Detected class {clss[i]}: {model.names[clss[i]]} with conf {confs[i]:.2f}")
