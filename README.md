# C++ Project Template

## 사용 방법

프로젝트를 zip 파일로 다운로드합니다.

VSCode 확장 설치:

```bash
code --install-extension ms-vscode.cpptools-extension-pack && \
code --install-extension llvm-vs-code-extensions.vscode-clangd
```

### Windows

`<프로젝트 루트>/scripts/windows/setup.bat` 실행

* 약 10분 정도 소요
* 약 6GB 저장공간 필요

---

### Linux

각 배포판에서 제공하는 `podman` 패키지 설치합니다.

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

CDI 설정 파일 생성 (`podman` 컨테이너에서 엔비디아 그래픽카드를 사용하기 위해 필요합니다.)

```bash
# CDI 설정 파일 생성 (이 명령어를 통해 호스트의 GPU가 CDI에 등록)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# 설정이 잘 생성되었는지 확인 (선택 사항)
grep "  name:" /etc/cdi/nvidia.yaml
```

---

#### 컨테이너 접속

컨테이너를 생성하기 전에 이미지 및 컨테이너 이름을 설정합니다.

`scripts/linux/config-container.sh`:

```bash
...
# 이미지 및 컨테이너 이름 설정
IMAGE_NAME="cpp-template-sdk"
IMAGE_TAG="0.1.0"
CONTAINER_NAME="cpp-template"

# 원격 설정 (Docker Hub 또는 개인 레지스트리)
IMAGE_REPO="" # docker.io/<username> 등
...
```

---

컨테이너 생성 및 실행:

```bash
./scripts/linux/create-container.sh
```

이 스크립트를 실행하면 기존 컨테이너가 삭제되고 새 컨테이너가 생성됩니다.

이미지에 대한 동작은 다음과 같습니다:

* 로컬 이미지 확인 > 원격 이미지 확인 > 직접 빌드(Containerfile)

---

생성한 컨테이너에 접속:

```bash
./scripts/linux/enter-container.sh
```

---

빌드된 컨테이너 이미지 업로드:

```bash
./scripts/linux/push-image.sh
```

* 이미지를 업로드하기 전에 터미널에서 해당 저장소로 로그인해야 합니다.

  예시 (docker.io):
  ```bash
  podman login docker.io -u <저장소 사용자 이름>
  Password: <발급받은 토큰 입력>
  ```

---

**VSCode에서 컨테이너에 접속**

* 좌측 하단 `><`(원격 창 열기) 버튼 클릭 -> `실행 중인 컨테이너에 연결...` 클릭
* 현재 실행 중인 컨테이너 클릭
  * 만약 컨테이너가 표시되지 않는다면 `enter-container.sh`로 기존 컨테이너를 실행하거나 `create-container.sh`로 새 컨테이너를 생성합니다.
* 컨테이너 접속 후 workspace 폴더 열기
* 컨테이너 내부에서 필요한 VSCode 확장 설치 (현재 프로젝트는 아래 확장이 사용됩니다.)

  ```bash
  code --install-extension ms-vscode.cpptools-extension-pack && \
  code --install-extension llvm-vs-code-extensions.vscode-clangd
  ```
