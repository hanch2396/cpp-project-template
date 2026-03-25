#!/bin/bash
set -e

# 이미지 이름 설정
IMAGE_NAME="cpp-template"
CONTAINER_NAME="cpp-template"

# 컨테이너 사용자 설정
USER_NAME="developer"
USER_UID=1000
USER_GID=1000

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# 1. 사용할 도구(Docker 또는 Podman) 감지
if command -v docker >/dev/null 2>&1; then
    DOCKER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
else
    echo "에러: 시스템에 docker 또는 podman이 설치되어 있지 않습니다."
    exit 1
fi

echo "--- [$DOCKER_CMD]를 사용하여 이미지를 빌드합니다: $IMAGE_NAME ---"

$DOCKER_CMD rm -f $CONTAINER_NAME 2>/dev/null || true
$DOCKER_CMD rmi -f $IMAGE_NAME || true

# 3. 빌드 수행
# --no-cache 옵션은 필요할 때만 추가하세요.
$DOCKER_CMD build \
    --build-arg USERNAME=$USER_NAME \
    --build-arg USER_UID=$USER_UID \
    --build-arg USER_GID=$USER_GID \
    --format docker \
    -t "$IMAGE_NAME" $SCRIPT_DIR

# 4. 결과 확인
if [ $? -eq 0 ]; then
    echo "--- 빌드 성공! ---"
    $DOCKER_CMD images | grep "$IMAGE_NAME"
else
    echo "--- 빌드 실패 ---"
    exit 1
fi

