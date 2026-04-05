import torch
import torch.nn as nn
from torchvision import models

class DINOv2(nn.Module):
    def __init__(self, model_name='vits'):
        super(DINOv2, self).__init__()
        # Using Torch Hub for official DINOv2 backbones
        repo = 'facebookresearch/dinov2'
        self.model = torch.hub.load(repo, f'dinov2_{model_name}14')
    
    def forward(self, x):
        features = self.model.get_intermediate_layers(x, n=4)
        return features
