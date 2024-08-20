ARG CUDA_VERSION=12.2.2
ARG OS_VERSION=20.04

FROM nvidia/cuda:${CUDA_VERSION}-devel-ubuntu${OS_VERSION} AS builder

WORKDIR /build

COPY . /build/

RUN ./preprocess.sh && \
    make clean && make

FROM nvidia/cuda:${CUDA_VERSION}-runtime-ubuntu${OS_VERSION}

COPY --from=builder /build/gpu_burn /app/
COPY --from=builder /build/compare*.ptx /app/compare_kernels/

WORKDIR /app

