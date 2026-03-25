# C++ Project Template

## 사용 방법

프로젝트를 zip 파일로 다운로드

VSCode 확장 설치:

```bash
code --install-extension ms-vscode.cpptools-extension-pack && \
code --install-extension llvm-vs-code-extensions.vscode-clangd && \
code --install-extension ms-python.python && \
code --install-extension ms-vscode-remote.remote-containers
```

### Windows

`<프로젝트 루트>/scripts/windows/setup.bat` 실행

* 약 10분 정도 소요
* 약 6GB 저장공간 필요

### Linux

각 배포판에서 제공하는 `podman` 패키지 설치

#### Nvidia 그래픽카드 사용 시

Ubuntu 기반:

```bash
# 저장소 설정
curl -fsSL https://nvidia.github.io/libnvidia-container/gpgkey | sudo gpg --dearmor -o /usr/share/keyrings/nvidia-container-toolkit-keyring.gpg
curl -s -L https://nvidia.github.io/libnvidia-container/stable/deb/nvidia-container-toolkit.list | \
  sed 's#deb https://#deb [signed-by=/usr/share/keyrings/nvidia-container-toolkit-keyring.gpg] https://#g' | \
  sudo tee /etc/apt/sources.list.d/nvidia-container-toolkit.list

# 설치
sudo apt-get update
sudo apt-get install -y nvidia-container-toolkit
```

RHEL 기반:

```bash
# 저장소 설정
curl -s -L https://nvidia.github.io/libnvidia-container/stable/rpm/nvidia-container-toolkit.repo | sudo tee /etc/yum.repos.d/nvidia-container-toolkit.repo

# 설치
sudo dnf install -y nvidia-container-toolkit
```

Archlinux 기반:

```bash
sudo pacman -S nvidia-container-toolkit
```

---

CDI 설정 파일 생성

```bash
# CDI 설정 파일 생성 (이 명령어를 통해 호스트의 GPU가 CDI에 등록)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# 설정이 잘 생성되었는지 확인 (선택 사항)
grep "  name:" /etc/cdi/nvidia.yaml
```

---

#### 컨테이너 접속

컨테이너 관련 스크립트를 실행하기 전에 이미지 및 컨테이너 이름 설정

`create-container-image.sh`:

```bash
...
# 이미지 이름 설정
IMAGE_NAME="my-img"
CONTAINER_NAME="my-container"
...
```

`run-container.sh`:

```bash
...
# 이미지 및 컨테이너 이름 설정 (create-container-image.sh에서 설정한 이미지 이름과 같아야 함)
IMAGE_NAME="my-img"
CONTAINER_NAME="my-container"
...
```

`enter-container.sh`:

```bash
# 접속할 컨테이너 이름 설정 (run 스크립트에서 설정한 이름과 일치해야 함)
CONTAINER_NAME="my-container"
```

---

컨테이너 이미지 생성:

```bash
./create-container-image.sh
```

컨테이너 생성 및 실행:

```bash
./run-container.sh
```

이 스크립트를 실행하면 기존 컨테이너가 삭제되고 새 컨테이너 생성

생성한 컨테이너에 접속:

```bash
./enter-container.sh
```

---

**VSCode에서 컨테이너에 접속**

* 좌측 하단 `><`(원격 창 열기) 버튼 클릭 -> `실행 중인 컨테이너에 연결...` 클릭
* 현재 실행 중인 컨테이너 클릭
  * 만약 컨테이너가 표시되지 않는다면 `enter-container.sh`로 기존 컨테이너를 실행하거나 `run-container.sh`로 새 컨테이너 생성
* 컨테이너 접속 후 workspace 폴더 열기
* 컨테이너 내부에서 필요한 VSCode 확장 설치 (현재 프로젝트는 아래 확장이 사용됨)

  ```bash
  code --install-extension ms-vscode.cpptools-extension-pack && \
  code --install-extension llvm-vs-code-extensions.vscode-clangd && \
  code --install-extension ms-python.python && \
  code --install-extension ms-vscode-remote.remote-containers
  ```
