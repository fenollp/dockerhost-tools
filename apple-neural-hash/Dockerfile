# syntax=docker/dockerfile:1.2@sha256:e2a8561e419ab1ba6b2fe6cbdf49fd92b95912df1cf7d313c3e2230a333fdbcc

# https://github.com/AsuharietYgvar/AppleNeuralHash2ONNX/issues/2#issuecomment-901246239

FROM --platform=$BUILDPLATFORM python:3-slim@sha256:8402d0ea6e4eaeba7b390dfe522496e365334daaeb05361b24636f2407e10aae AS tool
ADD https://github.com/AsuharietYgvar/AppleNeuralHash2ONNX/files/7008624/apple-neural-hash.zip /
# ADD https://github.com/AsuharietYgvar/AppleNeuralHash2ONNX/raw/master/nnhash.py nnhash.py
ADD https://github.com/AsuharietYgvar/AppleNeuralHash2ONNX/raw/8c12f06ae6b9f788fef25a361f7609b8fb6f7c73/nnhash.py nnhash.py
RUN \
    set -ux \
 && pip install --no-cache-dir onnxruntime pillow \
 && apt-get update \
 && apt-get install -y unzip \
 && unzip apple-neural-hash.zip

FROM tool AS product
ARG IMAGE_URL
ADD "$IMAGE_URL" /img
RUN \
    set -ux \
 && /usr/local/bin/python3 nnhash.py model.onnx neuralhash_128x96_seed1.dat /img >/out

FROM scratch
COPY --from=product /out /

# DOCKER_BUILDKIT=1 docker build -o=. --build-arg IMAGE_URL='https://placekitten.com/200/140' - <Dockerfile && cat out
#  ...
# 7d03c745ed592088533d8f78

# Pre-image example
# https://github.com/AsuharietYgvar/AppleNeuralHash2ONNX/issues/1#issue-973388387
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg IMAGE_URL=https://user-images.githubusercontent.com/1328/129860794-e7eb0132-d929-4c9d-b92e-4e4faba9e849.png - <Dockerfile && cat out
#  ...
# 59a34eabe31910abfb06f308
# DOCKER_BUILDKIT=1 docker build -o=. --build-arg IMAGE_URL=https://user-images.githubusercontent.com/1328/129860810-f414259a-3253-43e3-9e8e-a0ef78372233.png - <Dockerfile && cat out
# 59a34eabe31910abfb06f308
