# 베이스 이미지 설정
FROM docker.io/library/ubuntu:22.04

ARG USER_NAME="developer"

# ARG CMAKE_VERSION="4.3.2"
ARG AUTOCONF_VERSION="2.73"
ARG AUTOCONF_ARCHIVE_VERSION="2024.10.16"
# ARG GCC_VERSION="15"
ARG BINUTILS_VERSION="2.47"
ARG GDB_VERSION="17.2"
ARG LLVM_VERSION="22"
# ARG LLVM_VERSION="22.1.4"

ENV DEBIAN_FRONTEND=noninteractive

# 필수 시스템 패키지 설치
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
    \
    # 패키지 목록
    automake \
    build-essential \
    ca-certificates \
    curl \
    gettext \
    git \
    gnupg \
    libtool \
    locales \
    lsb-release \
    nano \
    patchelf \
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

RUN \
    # 기존 ubuntu 사용자 삭제 (UID/GID 1000 충돌 방지)
    # touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu && \
    # 사용자 생성 및 권한 부여
    useradd -m -s /bin/bash -G sudo $USER_NAME && \
    echo "$USER_NAME ALL=(ALL) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME && \
    chmod 0440 /etc/sudoers.d/$USER_NAME && \
    # 기본 셸 지정
    usermod --shell /bin/bash $USER_NAME && \
    # GUI 앱 및 D-Bus 통신을 위한 사용자 전용 런타임 디렉토리 생성 및 권한 설정
    mkdir -p /run/user/1000 && chown -R $USER_NAME:$USER_NAME /run/user/1000 && \
    # sudo 관련 메시지 제거
    touch /home/$USER_NAME/.sudo_as_admin_successful && \
    chown $USER_NAME:$USER_NAME /home/$USER_NAME/.sudo_as_admin_successful

# 최신 GCC 툴체인 설치를 위한 PPA 추가 및 설치
# RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
#     apt-get update && \
#     apt-get install -y --no-install-recommends gcc-$GCC_VERSION g++-$GCC_VERSION && \
#     update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 100 --slave /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION && \
#     apt-get update && \
#     apt-get upgrade -y && \
#     apt-get clean && rm -rf /var/lib/apt/lists/*

COPY toolchain/linux/gcc-16.1.0-ubuntu22.04.tar.xz /tmp/
RUN tar -xf /tmp/gcc-16.1.0-ubuntu22.04.tar.xz -C /opt/ && \
    rm -f /tmp/gcc-16.1.0-ubuntu22.04.tar.xz && \
    echo "/opt/gcc-16/lib64" > /etc/ld.so.conf.d/gcc-16.conf && \
    ldconfig

ENV PATH="/opt/gcc-16/bin:$PATH"

# 최신 Binutils, GDB 빌드에 필요한 패키지 설치
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

# 최신 Binutils 빌드 및 설치
RUN cd /tmp && \
    curl -fsSLO https://ftp.kaist.ac.kr/gnu/binutils/binutils-${BINUTILS_VERSION}.tar.xz && \
    tar -xf binutils-${BINUTILS_VERSION}.tar.xz && \
    mkdir -p binutils-build && \
    cd binutils-build && \
    ../binutils-${BINUTILS_VERSION}/configure --prefix=/usr/local --disable-multilib --disable-werror && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/binutils*

# 최신 GDB 빌드 및 설치
RUN cd /tmp && \
    curl -fsSLO https://ftp.kaist.ac.kr/gnu/gdb/gdb-${GDB_VERSION}.tar.xz && \
    tar -xf gdb-${GDB_VERSION}.tar.xz && \
    mkdir -p gdb-build && \
    cd gdb-build && \
    ../gdb-${GDB_VERSION}/configure --prefix=/usr/local --with-python && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/gdb*

# 최신 LLVM 툴체인 설치
RUN curl -fsSLO https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh $LLVM_VERSION && \
    rm llvm.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/lib/llvm-${LLVM_VERSION}/bin:$PATH"

RUN echo "--gcc-install-dir=/opt/gcc-16/lib/gcc/x86_64-pc-linux-gnu/16.1.0" \
      | tee /usr/lib/llvm-${LLVM_VERSION}/bin/clang.cfg \
            /usr/lib/llvm-${LLVM_VERSION}/bin/clang++.cfg

# RUN cd /opt && \
#     curl -fsSLO https://github.com/llvm/llvm-project/releases/download/llvmorg-${LLVM_VERSION}/LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
#     tar -xf LLVM-${LLVM_VERSION}-Linux-X64.tar.xz && \
#     mv LLVM-${LLVM_VERSION}-Linux-X64 llvm && \
#     rm LLVM-${LLVM_VERSION}-Linux-X64.tar.xz

# ENV PATH="/opt/llvm/bin:$PATH"

# Ninja 설치
RUN curl -fsSLO https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip && \
    unzip -o ninja-linux.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/ninja && \
    rm -f ninja-linux.zip

# CMake 설치
RUN cd /tmp && \
    curl -fsSLO https://apt.kitware.com/kitware-archive.sh && \
    chmod +x kitware-archive.sh && \
    ./kitware-archive.sh && \
    apt-get update && \
    apt-get install -y --no-install-recommends cmake && \
    rm -f kitware-archive.sh && \
    apt-get clean && rm -rf /var/lib/apt/lists/*

# RUN curl -fsSLO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
#     sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --prefix=/usr/local --skip-license --exclude-subdir && \
#     rm -f cmake-${CMAKE_VERSION}-linux-x86_64.sh

# Autoconf 빌드
RUN cd /tmp && \
    curl -fsSLO https://ftp.kaist.ac.kr/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz && \
    tar -xvf autoconf-${AUTOCONF_VERSION}.tar.gz && \
    cd autoconf-${AUTOCONF_VERSION} && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/autoconf-${AUTOCONF_VERSION}*

# Autoconf Archive 빌드
RUN cd /tmp && \
    curl -fsSLO https://ftp.kaist.ac.kr/gnu/autoconf-archive/autoconf-archive-${AUTOCONF_ARCHIVE_VERSION}.tar.xz && \
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
    $VCPKG_ROOT/bootstrap-vcpkg.sh -disableMetrics && \
    chown -R $USER_NAME:$USER_NAME $VCPKG_ROOT

# 기본 사용자 지정
# USER $USER_NAME

# 작업 디렉토리 설정
# WORKDIR /home/$USER_NAME

CMD ["/bin/bash"]
