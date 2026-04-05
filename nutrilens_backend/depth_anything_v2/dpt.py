import torch
import torch.nn as nn
import torch.nn.functional as F
from .dinov2 import DINOv2

class DPTHead(nn.Module):
    def __init__(self, in_channels, features=256, use_clstoken=False):
        super(DPTHead, self).__init__()
        self.use_clstoken = use_clstoken
        
        self.project = nn.Conv2d(in_channels, features, kernel_size=1)
        self.output_conv = nn.Sequential(
            nn.Conv2d(features, features // 2, kernel_size=3, padding=1),
            nn.Upsample(scale_factor=2, mode='bilinear', align_corners=True),
            nn.Conv2d(features // 2, 32, kernel_size=3, padding=1),
            nn.ReLU(True),
            nn.Conv2d(32, 1, kernel_size=1),
            nn.ReLU(True)
        )

    def forward(self, x):
        x = self.project(x)
        return self.output_conv(x)

class DepthAnythingV2(nn.Module):
    def __init__(self, encoder='vits', features=64, out_channels=[48, 96, 192, 384], use_clstoken=False):
        super(DepthAnythingV2, self).__init__()
        
        self.encoder = encoder
        self.pretrained = DINOv2(model_name=encoder)
        
        self.depth_head = DPTHead(out_channels[-1], features, use_clstoken)

    def forward(self, x):
        h, w = x.shape[-2:]
        features = self.pretrained(x)
        depth = self.depth_head(features[-1])
        depth = F.interpolate(depth, size=(h, w), mode='bilinear', align_corners=True)
        return depth.squeeze(1)
