# 第一阶段：构建环境
FROM nvidia/cuda:12.2.2-devel-ubuntu22.04 as builder

# 安装构建依赖
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    git \
    nasm \
    pkg-config \
    autoconf \
    automake \
    libtool \
    make \
    g++ \
    libx264-dev \
    libx265-dev \
    libvpx-dev \
    libfdk-aac-dev \
    libmp3lame-dev \
    libopus-dev \
    libass-dev \
    libssl-dev \
    zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

# 安装NVIDIA编解码头文件
RUN git clone https://github.com/FFmpeg/nv-codec-headers.git && \
    cd nv-codec-headers && \
    make install && \
    cd .. && \
    rm -rf nv-codec-headers

# 编译安装libwebp
RUN git clone https://github.com/webmproject/libwebp.git && \
    cd libwebp && \
    ./autogen.sh && \
    ./configure --prefix=/usr/local --enable-shared && \
    make -j$(nproc) && \
    make install && \
    cd .. && \
    rm -rf libwebp

# 克隆FFmpeg源码
RUN git clone https://github.com/FFmpeg/FFmpeg.git /app/ffmpeg

# 编译安装FFmpeg
WORKDIR /app/ffmpeg
RUN ./configure \
    --prefix=/usr/local \
    --enable-gpl \
    --enable-nonfree \
    --enable-cuda-nvcc \
    --enable-cuvid \
    --enable-nvenc \
    --enable-libnpp \
    --enable-ffnvcodec \
    --extra-cflags="-I/usr/local/cuda/include -I/usr/local/include" \
    --extra-ldflags="-L/usr/local/cuda/lib64 -L/usr/local/lib" \
    --enable-shared \
    --enable-libx264 \
    --enable-libx265 \
    --enable-libvpx \
    --enable-libfdk-aac \
    --enable-libmp3lame \
    --enable-libopus \
    --enable-libass \
    --enable-libwebp \
    --enable-openssl \
    --disable-doc \
    && make -j$(nproc) \
    && make install

# 第二阶段：运行环境
FROM nvidia/cuda:12.2.2-runtime-ubuntu22.04

# 安装运行时依赖
RUN apt-get update && \
    DEBIAN_FRONTEND=noninteractive apt-get install -y \
    libx264-163 \
    libx265-199 \
    libvpx7 \
    libfdk-aac2 \
    libmp3lame0 \
    libopus0 \
    libass9 \
    libssl3 \
    zlib1g \
    ocl-icd-libopencl1 \
    && rm -rf /var/lib/apt/lists/*

# 从builder阶段复制必要文件
COPY --from=builder /usr/local /usr/local
COPY --from=builder /usr/local/cuda/lib64/libcudart.so.12 /usr/lib/
COPY --from=builder /usr/local/cuda/lib64/libnpp*.so.12 /usr/lib/
COPY --from=builder /usr/local/lib/libwebp*.so* /usr/lib/

# 配置动态链接库
RUN ldconfig && \
    # 清理开发文件
    rm -rf /usr/local/include /usr/local/lib/pkgconfig

# 验证安装
RUN ffmpeg -buildconf | grep -i webp

CMD ["ffmpeg", "-version", "-hide_banner"]
