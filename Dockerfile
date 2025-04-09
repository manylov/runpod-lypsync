# Start with NVIDIA PyTorch base image with conda
FROM continuumio/miniconda3:latest

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
    sudo \
    libgl1 \
    && rm -rf /var/lib/apt/lists/*

# Set working directory
WORKDIR /app

# Clone the LatentSync repository
RUN git clone https://github.com/bytedance/LatentSync.git .

# Create conda environment
RUN conda create -y -n latentsync python=3.10.13

# Install CUDA and PyTorch using conda
RUN conda install -y -n latentsync -c pytorch -c nvidia \
    pytorch \
    torchvision \
    pytorch-cuda=11.7 \
    cudatoolkit=11.7

# Install primary dependencies first
RUN conda run -n latentsync pip install --timeout 300 \
    diffusers==0.32.2 \
    transformers==4.48.0 \
    huggingface-hub==0.25.2 \
    decord==0.6.0 \
    accelerate==0.26.1 \
    einops==0.7.0

# Install secondary dependencies
RUN conda run -n latentsync pip install --timeout 300 \
    omegaconf==2.3.0 \
    opencv-python==4.9.0.80 \
    mediapipe==0.10.11 \
    python_speech_features==0.6 \
    librosa==0.10.1

# Install remaining dependencies
RUN conda run -n latentsync pip install --timeout 300 \
    scenedetect==0.6.1 \
    ffmpeg-python==0.2.0 \
    lpips==0.1.4 \
    face-alignment==1.4.1 \
    gradio==5.12.0 \
    numpy==1.26.4

# Install server dependencies
RUN conda run -n latentsync pip install --timeout 300 \
    fastapi \
    "uvicorn[standard]" \
    httpx \
    s3fs \
    pydantic \
    python-multipart

# Copy the server script and setup script
COPY server.py setup_env.sh /app/

# Run setup script (modified to skip conda environment creation)
RUN sed -i 's/conda create.*//g' setup_env.sh && \
    sed -i 's/conda activate.*//g' setup_env.sh && \
    sed -i 's/conda install.*//g' setup_env.sh && \
    conda run -n latentsync bash setup_env.sh

# Set environment variables
ENV PYTHONPATH=/app

# Expose the port
EXPOSE 8081

# Start the server using conda run
CMD ["conda", "run", "--no-capture-output", "-n", "latentsync", "python3", "server.py"]
