# Start with NVIDIA PyTorch base image
FROM pytorch/pytorch:2.0.1-cuda11.7-cudnn8-runtime

# Set environment variables globally to prevent interactive prompts
ENV DEBIAN_FRONTEND=noninteractive
ENV TZ=Etc/UTC

# Pre-configure tzdata explicitly
RUN ln -snf /usr/share/zoneinfo/$TZ /etc/localtime && echo $TZ > /etc/timezone

# Install system dependencies with additional flags to prevent prompts
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
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
