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

# Install CUDA and PyTorch dependencies
RUN conda install -y pytorch torchvision pytorch-cuda=11.7 -c pytorch -c nvidia

# Set working directory
WORKDIR /app

# Clone the LatentSync repository
RUN git clone https://github.com/bytedance/LatentSync.git .

# Create and activate conda environment
RUN conda create -y -n latentsync python=3.10.13 && \
    echo "conda activate latentsync" >> ~/.bashrc

SHELL ["/bin/bash", "--login", "-c"]

# Install Python dependencies
RUN conda activate latentsync && \
    pip install -r requirements.txt && \
    pip install fastapi uvicorn httpx s3fs pydantic python-multipart

# Copy the server script and setup script
COPY server.py setup_env.sh /app/

# Run setup script (modified to skip conda environment creation)
RUN sed -i 's/conda create.*//g' setup_env.sh && \
    sed -i 's/conda activate.*//g' setup_env.sh && \
    sed -i 's/conda install.*//g' setup_env.sh && \
    conda activate latentsync && \
    bash setup_env.sh

# Set environment variables
ENV PYTHONPATH=/app

# Expose the port
EXPOSE 8081

# Start the server
CMD ["conda", "run", "-n", "latentsync", "python3", "server.py"]
