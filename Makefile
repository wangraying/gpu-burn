ifneq ("$(wildcard /usr/bin/nvcc)", "")
CUDAPATH ?= /usr
else ifneq ("$(wildcard /usr/local/cuda/bin/nvcc)", "")
CUDAPATH ?= /usr/local/cuda
endif

IS_JETSON   ?= $(shell if grep -Fwq "Jetson" /proc/device-tree/model 2>/dev/null; then echo true; else echo false; fi)
NVCC        :=  ${CUDAPATH}/bin/nvcc
CCPATH      ?=

override CFLAGS   ?=
override CFLAGS   += -O3
override CFLAGS   += -Wno-unused-result
override CFLAGS   += -I${CUDAPATH}/include
override CFLAGS   += -std=c++11
override CFLAGS   += -DIS_JETSON=${IS_JETSON}

override LDFLAGS  ?=
override LDFLAGS  += -lcuda
override LDFLAGS  += -L${CUDAPATH}/lib64
override LDFLAGS  += -L${CUDAPATH}/lib64/stubs
override LDFLAGS  += -L${CUDAPATH}/lib
override LDFLAGS  += -L${CUDAPATH}/lib/stubs
override LDFLAGS  += -Wl,-rpath=${CUDAPATH}/lib64
override LDFLAGS  += -Wl,-rpath=${CUDAPATH}/lib
override LDFLAGS  += -lcublas
override LDFLAGS  += -lcudart

override NVCCFLAGS ?=
override NVCCFLAGS += -I${CUDAPATH}/include

SMS=$(shell nvcc --help | sed -n -e '/gpu-architecture <arch>/,/gpu-code <code>/ p' | sed -n -e '/Allowed values/,/gpu-code <code>/ p' | grep -i sm_ | grep -Eo 'sm_[0-9]+' | sed -e s/sm_//g | sort -g -u | tr '\n' ' ')
GENCODE_FLAGS := $(foreach sm, $(SMS), -gencode arch=compute_$(sm),code=sm_$(sm))

PTX_FILES := $(patsubst arch/%.cu,%.ptx,$(wildcard arch/*.cu))

.PHONY: clean

build: gpu_burn ${PTX_FILES}

gpu_burn: gpu_burn-drv.o compare.o
	g++ -o $@ $< -O3 ${LDFLAGS}

%.o: %.cpp
	g++ ${CFLAGS} -c $<

%.ptx: arch/%.cu
	PATH="${PATH}:${CCPATH}:." ${NVCC} ${NVCCFLAGS} -ptx $< -o $@

%.o: %.cu
	PATH="${PATH}:${CCPATH}:." ${NVCC} ${NVCCFLAGS} $(GENCODE_FLAGS) -o $@ -c $<

clean:
	$(RM) *.o gpu_burn
