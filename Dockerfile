# 1. 베이스 이미지 설정
FROM docker.io/rockylinux/rockylinux:9

ARG USERNAME=developer
ARG USER_UID=1000
ARG USER_GID=1000

ARG CMAKE_VERSION="4.2.3"
ARG AUTOCONF_VERSION="2.72"

# 기본 쉘을 bash로 설정 (source 명령어 사용 위함)
SHELL ["/bin/bash", "-c"]

# 3. 필수 시스템 패키지 및 GCC Toolset 설치
RUN dnf update -y && \
    dnf install -y epel-release dnf-plugins-core && \
    dnf config-manager --set-enabled crb && \
    dnf groupinstall -y "Development Tools" && \
    dnf install -y sudo gcc-toolset-15 autoconf autoconf-archive automake libtool perl-core wget unzip git \
    libX11-devel libXext-devel libXcursor-devel libXi-devel libXrandr-devel libXtst-devel \
    wayland-devel wayland-protocols-devel libxkbcommon-devel \
    mesa-libGL-devel mesa-libEGL-devel vulkan-loader-devel vulkan-tools vulkan-headers mesa-vulkan-drivers mesa-dri-drivers \
    alsa-lib-devel pulseaudio-libs-devel dbus-devel lz4-devel \
    xcb-util-keysyms-devel xcb-util-devel xcb-util-wm-devel xcb-util-image-devel libXScrnSaver-devel \
    llvm-toolset clang-tools-extra && \
    dnf clean all

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
    source /opt/rh/gcc-toolset-15/enable && \
    ./configure --prefix=/usr/local && \
    make -j$(nproc) && \
    make install && \
    rm -rf /tmp/autoconf-${AUTOCONF_VERSION}*

# vcpkg 설정
ENV VCPKG_ROOT=/opt/vcpkg \
    PATH="/opt/vcpkg:$PATH"

RUN git clone https://github.com/microsoft/vcpkg.git $VCPKG_ROOT && \
    source /opt/rh/gcc-toolset-15/enable && \
    $VCPKG_ROOT/bootstrap-vcpkg.sh -disableMetrics

# 7. 사용자 생성 및 권한 부여
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && echo "$USERNAME ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/$USERNAME \
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && chown -R $USERNAME:$USERNAME $VCPKG_ROOT

USER $USERNAME
WORKDIR /home/$USERNAME/workspace

# 9. 자동 환경 변수 로드
RUN echo "source /opt/rh/gcc-toolset-15/enable" >> ~/.bashrc

CMD ["/bin/bash"]
