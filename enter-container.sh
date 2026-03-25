#!/bin/bash

# 접속할 컨테이너 이름 설정 (run 스크립트에서 설정한 이름과 일치해야 함)
CONTAINER_NAME="cpp-template"

# 1. 사용할 도구(Docker 또는 Podman) 감지
if command -v docker >/dev/null 2>&1; then
    DOCKER_CMD="docker"
elif command -v podman >/dev/null 2>&1; then
    DOCKER_CMD="podman"
else
    echo "에러: 시스템에 docker 또는 podman이 설치되어 있지 않습니다."
    exit 1
fi

# 2. 컨테이너가 존재하는지 확인 (실행 중이 아니어도 생성되어 있는지 확인)
# -a: 모든 컨테이너, -q: ID만, -f: 필터링 (이름이 정확히 일치하도록 ^/이름$ 사용)
CONTAINER_EXISTS=$($DOCKER_CMD ps -a -q -f name="^/${CONTAINER_NAME}$")

if [ -z "$CONTAINER_EXISTS" ]; then
    echo "에러: '$CONTAINER_NAME' 컨테이너가 존재하지 않습니다."
    echo "먼저 './run-container.sh'를 실행하여 컨테이너를 생성하세요."
    exit 1
fi

# 3. 컨테이너가 실행 중인지 확인
IS_RUNNING=$($DOCKER_CMD ps -q -f name="^/${CONTAINER_NAME}$")

if [ -z "$IS_RUNNING" ]; then
    echo "--- '$CONTAINER_NAME' 컨테이너가 중지되어 있습니다. 시작하는 중... ---"
    $DOCKER_CMD start "$CONTAINER_NAME"
    
    # 시작 실패 시 에러 처리
    if [ $? -ne 0 ]; then
        echo "에러: 컨테이너를 시작하지 못했습니다."
        exit 1
    fi
fi

echo "--- [$DOCKER_CMD] '$CONTAINER_NAME' 컨테이너에 접속합니다... ---"

# GUI 설정을 위한 xhost 권한 부여 (필요한 경우)
if command -v xhost >/dev/null 2>&1; then
    xhost +local:$DOCKER_CMD >/dev/null 2>&1
fi

# 4. 컨테이너 내부로 진입
$DOCKER_CMD exec -it "$CONTAINER_NAME" /bin/bash
