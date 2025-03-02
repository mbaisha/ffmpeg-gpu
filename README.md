# 构建和使用说明：

## 构建命令：
```
docker build -t ffmpeg-gpu .
```
## 验证GPU支持：
```
docker run --gpus all --rm ffmpeg-gpu ffmpeg -hwaccels
```
## 典型转码命令示例：
```
docker run --gpus all -v $(pwd):/data ffmpeg-gpu \
-hwaccel cuda -i input.mp4 -c:v h264_nvenc -b:v 5M output.mp4
```
## 支持的硬件加速：
NVIDIA GPU编码（h264_nvenc/hevc_nvenc）
NVIDIA GPU解码（cuvid）
GPU加速滤镜（通过libnpp）
OpenCL支持
