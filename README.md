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

CDI 설정 파일 생성

```bash
# CDI 설정 파일 생성 (이 명령어를 통해 호스트의 GPU가 CDI에 등록)
sudo nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml

# 설정이 잘 생성되었는지 확인 (선택 사항)
grep "  name:" /etc/cdi/nvidia.yaml
```

#### 컨테이너 접속

좌측 하단 `><`(원격 창 열기) 버튼 클릭 -> `컨테이너에서 다시 열기` 클릭

이후 자동으로 도커 이미지를 빌드하고 컨테이너 환경으로 접속
