# Pastec reverse image search with performance improvements

FROM ubuntu:22.04

# Avoid interactive prompts during package installation
ENV DEBIAN_FRONTEND=noninteractive

# Install build dependencies
RUN apt-get update && apt-get install -y --no-install-recommends \
    build-essential \
    cmake \
    ca-certificates \
    curl \
    libcurl4-openssl-dev \
    libjsoncpp-dev \
    libmicrohttpd-dev \
    libopencv-dev \
    pkg-config \
    && rm -rf /var/lib/apt/lists/*

# Copy project source (includes improvements: distance 80, rerank 30, no-copy index)
WORKDIR /usr/src/pastec
COPY . .

# Setup runtime: copy visual words to /pastec (or download if not bundled)
RUN mkdir -p /pastec \
    && if [ -f data/visualWordsORB.dat ]; then \
        cp data/visualWordsORB.dat /pastec/; \
    else \
        curl -fsSL -o /pastec/visualWordsORB.tar.gz https://pastec.io/files/visualWordsORB.tar.gz \
        && tar xzf /pastec/visualWordsORB.tar.gz -C /pastec \
        && rm /pastec/visualWordsORB.tar.gz; \
    fi

# Build with Release and our optimized settings
# PASTEC_RERANK_POOL=30, PASTEC_NO_COPY_INDEX=1 are defaults in CMakeLists
RUN mkdir build && cd build \
    && cmake .. -DCMAKE_BUILD_TYPE=Release \
    && make -j$(nproc) \
    && mv pastec /usr/local/bin/ \
    && cd .. && rm -rf build

# Runtime: index and visual words live in /pastec (mount volume for persistence)
VOLUME ["/pastec"]

EXPOSE 4212

# Usage: pastec [-p port] [-i indexPath] visualWordsPath
# Index is created at /pastec/backwardIndex.dat if it doesn't exist
ENTRYPOINT ["pastec"]
CMD ["-p", "4212", "-i", "/pastec/backwardIndex.dat", "/pastec/visualWordsORB.dat"]
