#!/bin/bash
# 명령 실패 시 즉시 종료
set -e

# 이미지 및 컨테이너 이름 설정 (create-container-image.sh에서 설정한 이미지 이름과 같아야 함)
IMAGE_NAME="cpp-template"
CONTAINER_NAME="cpp-template"

# create-container-image.sh와 동일하게 설정
USER_NAME="developer"

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 사용할 도구(Docker 또는 Podman) 자동 감지
if command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
    XHOST_TYPE="podman"
    # Podman 전용 옵션 (Rootless 권한 및 볼륨 레이블)
    EXTRA_OPTS="--userns=keep-id"
    VOL_OPTS=":Z"
elif command -v docker >/dev/null 2>&1; then
    DOCKER_CMD="docker"
    XHOST_TYPE="docker"
    EXTRA_OPTS=""
    VOL_OPTS=""
else
    echo "에러: 시스템에 docker 또는 podman이 설치되어 있지 않습니다."
    exit 1
fi

# 2. GUI 서버 접근 허용
xhost +local:$XHOST_TYPE

# 4. 기존 컨테이너 정리 (깔끔한 새 시작을 위해)
echo "--- 기존 컨테이너 '$CONTAINER_NAME' 정리 중... ---"
$DOCKER_CMD rm -f $CONTAINER_NAME 2>/dev/null || true

# =================================================================
# NVIDIA GPU를 깨우고 디바이스 노드 강제 생성
GPU_OPTS=""
if command -v nvidia-smi >/dev/null 2>&1; then
    echo "--- NVIDIA GPU 절전 모드 해제 및 장치 초기화 중... ---"
    # nvidia-smi를 실행하면 GPU가 깨어나고 디바이스 파일이 생성됨
    nvidia-smi >/dev/null 2>&1
    
    # 혹시라도 파일이 생성되지 않을 경우를 대비한 안전장치 (modprobe)
    command -v nvidia-modprobe >/dev/null 2>&1 && nvidia-modprobe -m -u 2>/dev/null || true
    
    # 장치 파일이 완전히 생성될 때까지 약간의 대기 시간 부여
    sleep 1

    GPU_OPTS="--gpus all"
fi
# =================================================================

# 5. 컨테이너 실행 (백그라운드 -d 모드)
echo "--- [$DOCKER_CMD] 컨테이너 실행 시작 ---"
$DOCKER_CMD run -dt \
    --name $CONTAINER_NAME \
    --privileged \
    --net=host \
    --shm-size=2gb \
    -e DISPLAY=$DISPLAY \
    -e XDG_RUNTIME_DIR=/tmp/runtime-root \
    -v /tmp/.X11-unix:/tmp/.X11-unix:rw \
    -v "$SCRIPT_DIR:/home/$USER_NAME/workspace$VOL_OPTS" \
    --device /dev/dri:/dev/dri \
    $GPU_OPTS \
    $EXTRA_OPTS \
    $IMAGE_NAME

# 6. 실행 확인 및 자동 접속
echo "--- 컨테이너 접속 중... ---"
if [ -f "$SCRIPT_DIR/enter-container.sh" ]; then
    exec "$SCRIPT_DIR/enter-container.sh"
else
    $DOCKER_CMD exec -it $CONTAINER_NAME /bin/bash
fi
