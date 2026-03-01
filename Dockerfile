# 1. 베이스 이미지 설정 (VFX 표준 glibc 2.28 기반)
FROM docker.io/rockylinux/rockylinux:8

ARG USERNAME
ARG USER_UID
ARG USER_GID

# 2. 환경 변수 사전 설정
ENV CMAKE_VERSION="4.2.3" \
    AUTOCONF_VERSION="2.72" \
    PATH="/opt/cmake/bin:/opt/rh/gcc-toolset-15/root/usr/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/rh/gcc-toolset-15/root/usr/lib64:/opt/rh/gcc-toolset-15/root/usr/lib:$LD_LIBRARY_PATH"

# 3. 필수 시스템 패키지 및 GCC Toolset 설치
RUN dnf update -y && \
    dnf install -y epel-release && \
    dnf groupinstall -y "Development Tools" && \
    # PowerTools 활성화 (일부 개발 라이브러리용)
    dnf config-manager --set-enabled powertools && \
    dnf install -y sudo gcc-toolset-15 autoconf autoconf-archive automake libtool perl-core wget unzip git \
    libX11-devel libXext-devel libXcursor-devel libXi-devel libXrandr-devel libXtst-devel \
    wayland-devel wayland-protocols-devel libxkbcommon-devel \
    mesa-libGL-devel mesa-libEGL-devel vulkan-loader-devel vulkan-tools vulkan-headers mesa-vulkan-drivers mesa-dri-drivers \
    alsa-lib-devel pulseaudio-libs-devel dbus-devel lz4-devel \
    xcb-util-keysyms-devel xcb-util-devel xcb-util-wm-devel xcb-util-image-devel \
    llvm-toolset clang-tools-extra && \
    dnf clean all

# 4. Ninja 빌드 도구 설치
RUN wget https://github.com/ninja-build/ninja/releases/latest/download/ninja-linux.zip && \
    unzip -o ninja-linux.zip -d /usr/local/bin/ && \
    chmod +x /usr/local/bin/ninja && \
    rm -rf ninja-linux.zip

# 5. CMake 최신 버전 설치
RUN wget https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}-linux-x86_64.sh && \
    mkdir -p /opt/cmake && \
    sh cmake-${CMAKE_VERSION}-linux-x86_64.sh --prefix=/opt/cmake --skip-license --exclude-subdir && \
    rm -rf cmake-${CMAKE_VERSION}-linux-x86_64.sh

# 6. Autoconf 2.72 소스 빌드 및 설치
# 시스템 기본 버전보다 높은 버전을 사용하기 위해 직접 컴파일합니다.
RUN cd /tmp && \
    wget https://ftp.gnu.org/gnu/autoconf/autoconf-${AUTOCONF_VERSION}.tar.gz && \
    tar -xvf autoconf-${AUTOCONF_VERSION}.tar.gz && \
    cd autoconf-${AUTOCONF_VERSION} && \
    # GCC 15 환경 활성화 후 빌드
    source /opt/rh/gcc-toolset-15/enable && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    cd / && rm -rf /tmp/autoconf-${AUTOCONF_VERSION}*

ENV VCPKG_ROOT=/opt/vcpkg \
    PATH="/opt/vcpkg:$PATH"

RUN git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT && \
    source /opt/rh/gcc-toolset-15/enable && \
    $VCPKG_ROOT/bootstrap-vcpkg.sh -disableMetrics && \
    # 모든 사용자가 실행 및 쓰기(라이브러리 설치 시 필요) 가능하도록 권한 설정
    chmod -R 777 $VCPKG_ROOT

# 7. 사용자 생성 및 Sudo 권한 부여
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir -p /etc/sudoers.d \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME

USER $USERNAME
WORKDIR /home/$USERNAME/workspace

# 9. 자동 환경 변수 로드 설정
RUN echo "source /opt/rh/gcc-toolset-15/enable" >> ~/.bashrc

CMD ["/bin/bash"]
