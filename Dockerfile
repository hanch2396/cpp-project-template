# 1. 베이스 이미지 설정
FROM docker.io/library/ubuntu:24.04

ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

ARG CMAKE_VERSION="4.2.3"
ARG AUTOCONF_VERSION="2.72"
ARG GCC_VERSION="15"
ARG LLVM_VERSION="21"

# 기본 쉘을 bash로 설정 (source 명령어 사용 위함)
SHELL ["/bin/bash", "-c"]

# 3. 필수 시스템 패키지 설치
RUN apt-get update && apt-get upgrade -y && \
    apt-get install -y --no-install-recommends \
    build-essential \
    sudo \
    ca-certificates lsb-release software-properties-common gnupg \
    gcc g++ cmake ninja-build \
    autoconf autoconf-archive automake libtool \
    perl wget curl zip unzip tar git \
    llvm clang clang-tools

# 최신 GCC 툴체인 설치를 위한 PPA 추가 및 설치
RUN add-apt-repository ppa:ubuntu-toolchain-r/test -y && \
    apt-get update && \
    apt-get install -y --no-install-recommends gcc-$GCC_VERSION g++-$GCC_VERSION && \
    update-alternatives --install /usr/bin/gcc gcc /usr/bin/gcc-$GCC_VERSION 100 --slave /usr/bin/g++ g++ /usr/bin/g++-$GCC_VERSION

RUN wget https://apt.llvm.org/llvm.sh && \
    chmod +x llvm.sh && \
    ./llvm.sh $LLVM_VERSION all && \
    rm llvm.sh

RUN apt-get clean && rm -rf /var/lib/apt/lists/*

ENV VCPKG_ROOT=/opt/vcpkg \
    PATH="/usr/lib/llvm-21/bin:$PATH"

# 4. Ninja 설치
RUN wget https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip && \
    unzip -o ninja-linux.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/ninja && \
    rm -f ninja-linux.zip

# 5. CMake 설치 (버전 변수 확인 필요: 현재 4.x는 출시 전이거나 미리보기일 수 있음. 보통 3.x대 사용)
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --prefix=/usr/local --skip-license --exclude-subdir && \
    rm -f cmake-${CMAKE_VERSION}-linux-x86_64.sh

# 6. Autoconf 2.72 빌드
RUN cd /tmp && \
    wget https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz && \
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

# 7. 사용자 생성 및 권한 부여
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chown -R $USERNAME:$USERNAME $VCPKG_ROOT

RUN usermod --shell /bin/bash $USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME/workspace

CMD ["/bin/bash"]
