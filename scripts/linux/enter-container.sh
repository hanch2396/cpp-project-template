#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$SCRIPT_DIR/config-container.sh"

# 컨테이너가 존재하는지 확인 (실행 중이 아니어도 생성되어 있는지 확인)
# -a: 모든 컨테이너, -q: ID만, -f: 필터링 (이름이 정확히 일치하도록 ^/이름$ 사용)
CONTAINER_EXISTS=$($DOCKER_CMD ps -a -q -f name="^/${CONTAINER_NAME}$")

if [ -z "$CONTAINER_EXISTS" ]; then
    echo "에러: '$CONTAINER_NAME' 컨테이너가 존재하지 않습니다."
    echo "먼저 './create-container.sh'를 실행하여 컨테이너를 생성하세요."
    exit 1
fi

# 컴퓨터 재시작 후 GPU 디바이스 노드가 없을 경우를 대비해 초기화
if command -v nvidia-smi >/dev/null 2>&1; then
    nvidia-smi >/dev/null 2>&1
    command -v nvidia-modprobe >/dev/null 2>&1 && nvidia-modprobe -m -u 2>/dev/null || true
    sleep 1
fi

echo "--- '$CONTAINER_NAME' 컨테이너에 접속합니다..."
distrobox enter "$CONTAINER_NAME" -- bash -lc "cd $PROJECT_DIR && exec bash"
