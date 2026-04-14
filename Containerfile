# 베이스 이미지 설정
FROM docker.io/library/ubuntu:24.04

ARG USER_NAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

ARG CMAKE_VERSION="4.3.1"
ARG AUTOCONF_VERSION="2.72"
ARG GCC_VERSION="15"
ARG LLVM_VERSION="22"

# 필수 시스템 패키지 설치
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential locales sudo \
    ca-certificates lsb-release software-properties-common gnupg \
    autoconf autoconf-archive automake libtool \
    perl wget curl zip unzip tar git gdb xdg-utils

RUN locale-gen en_US.UTF-8

ENV LANG=en_US.UTF-8
ENV LC_ALL=en_US.UTF-8

# 최신 GCC 툴체인 설치를 위한 PPA 추가 및 설치
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc-$GCC_VERSION g++-$GCC_VERSION && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 100 --slave /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION

# 최신 LLVM 툴체인 설치
RUN curl -fsSLO https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh $LLVM_VERSION all && \
    rm llvm.sh

RUN apt-get update && apt-get upgrade -y

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

ENV PATH="/usr/lib/llvm-$LLVM_VERSION/bin:$PATH"

# Ninja 설치
RUN curl -fsSLO https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip && \
    unzip -o ninja-linux.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/ninja && \
    rm -f ninja-linux.zip

# CMake 설치
RUN curl -fsSLO https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --prefix=/usr/local --skip-license --exclude-subdir && \
    rm -f cmake-${CMAKE_VERSION}-linux-x86_64.sh

# Autoconf 2.72 빌드
RUN cd /tmp && \
    curl -fsSLO https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz && \
    tar -xvf autoconf-${AUTOCONF_VERSION}.tar.gz && \
    cd autoconf-${AUTOCONF_VERSION} && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/autoconf-${AUTOCONF_VERSION}*

# vcpkg 설정
ENV VCPKG_ROOT=/opt/vcpkg \
    PATH="/opt/vcpkg:$PATH"

RUN git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT && \
    $VCPKG_ROOT/bootstrap-vcpkg.sh -disableMetrics

# 기존 ubuntu 사용자 삭제 (UID/GID 1000 충돌 방지)
RUN touch /var/mail/ubuntu && chown ubuntu /var/mail/ubuntu && userdel -r ubuntu

# 사용자 생성 및 권한 부여
RUN groupadd --gid $USER_GID $USER_NAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USER_NAME \
    && echo "$USER_NAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USER_NAME \
    && chmod 0440 /etc/sudoers.d/$USER_NAME \
    && chown -R $USER_NAME:$USER_NAME $VCPKG_ROOT

# 기본 셸 지정
RUN usermod --shell /bin/bash $USER_NAME

RUN mkdir -p /run/user/1000 && chown -R $USER_NAME:$USER_NAME /run/user/1000

# 기본 사용자 지정
USER $USER_NAME

# 작업 디렉토리 설정
WORKDIR /home/$USER_NAME/workspace

CMD ["/bin/bash"]
