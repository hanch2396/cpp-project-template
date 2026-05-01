# 베이스 이미지 설정
FROM docker.io/library/ubuntu:26.04

ARG CMAKE_VERSION="4.3.2"
ARG AUTOCONF_VERSION="2.72"
ARG AUTOCONF_ARCHIVE_VERSION="2024.10.16"
# ARG GCC_VERSION="15"
ARG BINUTILS_VERSION="2.46.0"
ARG GDB_VERSION="17.1"
ARG LLVM_VERSION="22.1.4"

# 필수 시스템 패키지 설치
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    \
    # 패키지 목록
    automake \
    build-essential \
    ca-certificates \
    curl \
    g++ \
    gcc \
    gettext \
    git \
    gnupg \
    libtool \
    locales \
    lsb-release \
    pkg-config \
    perl \
    software-properties-common \
    sudo \
    tar \
    unzip \
    wget \
    xdg-utils \
    zip \
    && \
    # 캐시 정리
    apt-get clean && rm -rf /var/lib/apt/lists/*

RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# GCC 툴체인 설치를 위한 PPA 추가 및 설치
# RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends gcc-$GCC_VERSION g++-$GCC_VERSION && \
#     apt-get clean && rm -rf /var/lib/apt/lists/* && \
#     update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 100 --slave /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION

# Binutils, GDB 빌드에 필요한 패키지 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    bison \
    flex \
    texinfo \
    zlib1g-dev \
    libzstd-dev \
    libncurses-dev \
    libexpat1-dev \
    libgmp-dev \
    libsource-highlight-dev \
    python3-dev \
    libmpfr-dev \
    liblzma-dev \
    && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# Binutils 빌드 및 설치
RUN cd /tmp && \
    curl -fsSLO https://sourceware.org/pub/binutils/releases/binutils-${BINUTILS_VERSION}.tar.xz && \
    tar -xf binutils-${BINUTILS_VERSION}.tar.xz && \
    mkdir -p binutils-build && \
    cd binutils-build && \
    ../binutils-${BINUTILS_VERSION}/configure --prefix=/usr/local --disable-multilib --disable-werror && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/binutils*

# GDB 빌드 및 설치
RUN cd /tmp && \
    curl -fsSLO https://ftp.gnu.org/gnu/gdb/gdb-${GDB_VERSION}.tar.xz && \
    tar -xf gdb-${GDB_VERSION}.tar.xz && \
    mkdir -p gdb-build && \
    cd gdb-build && \
    ../gdb-${GDB_VERSION}/configure --prefix=/usr/local --with-python && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/gdb*

# LLVM 툴체인 설치 (현재 우분투 26.04 저장소를 제공하지 않아서 직접 다운로드하여 설치)
# RUN curl -fsSLO https://apt.llvm.org/llvm.sh && \
#     chmod +x llvm.sh && \
#     ./llvm.sh $LLVM_VERSION all && \
#     rm llvm.sh

RUN cd /opt && \
    curl -fsSLO https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
    tar -xf LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
    mv LLVM-${LLVM_VERSION}-Linux-X64 llvm && \
    rm LLVM-${LLVM_VERSION}-Linux-X64.tar.xz

ENV PATH="/opt/llvm/bin:$PATH"

# RUN apt-get update && \
#     apt-get upgrade -y && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

# Ninja 설치
RUN curl -fsSLO https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip && \
    unzip -o ninja-linux.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/ninja && \
    rm -f ninja-linux.zip

# CMake 설치
RUN curl -fsSLO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --prefix=/usr/local --skip-license --exclude-subdir && \
    rm -f cmake-${CMAKE_VERSION}-linux-x86_64.sh

# Autoconf 빌드
RUN cd /tmp && \
    curl -fsSLO https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz && \
    tar -xvf autoconf-${AUTOCONF_VERSION}.tar.gz && \
    cd autoconf-${AUTOCONF_VERSION} && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/autoconf-${AUTOCONF_VERSION}*

# Autoconf Archive 빌드
RUN cd /tmp && \
    curl -fsSLO https://ftp.gnu.org/gnu/autoconf-archive/autoconf-archive-${AUTOCONF_ARCHIVE_VERSION}.tar.xz && \
    tar -xvf autoconf-archive-${AUTOCONF_ARCHIVE_VERSION}.tar.xz && \
    cd autoconf-archive-${AUTOCONF_ARCHIVE_VERSION} && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/autoconf-archive*

# vcpkg 설정
ENV VCPKG_ROOT=/opt/vcpkg \
    PATH="/opt/vcpkg:$PATH"

RUN git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT && \
    $VCPKG_ROOT/bootstrap-vcpkg.sh -disableMetrics

# 기존 ubuntu 사용자 삭제 (UID/GID 1000 충돌 방지)
# RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

CMD ["/bin/bash"]
