# Use NVIDIA PyTorch base image with platform specification
FROM --platform=linux/arm64 pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime

# Install system dependencies
RUN apt-get update && apt-get install -y \
    git \
    wget \
    ffmpeg \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the LatentSync repository
RUN git clone https://github.com/bytedance/LatentSync.git .

# Install Python dependencies
RUN pip install -r requirements.txt

# Download required checkpoints
# Note: You'll need to modify setup_env.sh to download directly without user interaction
COPY setup_env.sh /app/
RUN bash setup_env.sh

# Create the handler for RunPod
COPY handler.py /app/

# Set environment variables
ENV PYTHONPATH=/app

# Add RunPod serverless handler
RUN pip install runpod

# Set the entry point
CMD [ "python", "-u", "handler.py" ]
