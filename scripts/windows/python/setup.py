import os
import sys
import json
import shutil
import getpass
import subprocess
from typing import List, Optional

# --- 경로 및 환경 설정 ---
CURRENT_SCRIPT_PATH = os.path.abspath(__file__)
BASE_DIR = os.path.dirname(CURRENT_SCRIPT_PATH)
REPO_ROOT_DIR = os.path.dirname(BASE_DIR)
BASH_SCRIPTS_DIR = os.path.join(REPO_ROOT_DIR, "bash")

if BASE_DIR not in sys.path:
    sys.path.insert(0, BASE_DIR)

# --- 필수 유틸리티 임포트 ---
try:
    from setup_utils import (
        is_admin,
        run_as_admin_if_needed,
        run_command_direct_output,
        set_system_environment_variable,
        add_to_system_path,
        download_msys2_installer,
        install_msys2,
        remove_msys2_installer,
        configure_powershell_profile_utf8,
        run_msys2_bash_script,
        setup_python_venv_and_packages,
        update_current_session_path_from_registry,
    )
except ImportError as e:
    print(f"오류: setup_utils.py를 찾을 수 없습니다. (경로: {BASE_DIR})")
    print(f"ImportError: {e}")
    sys.exit(1)

# --- 설정 상수 ---
MSYS2_INSTALLER_TAG = "2025-12-13"
MSYS2_ROOT_DIR = r"C:\msys64"
TEMP_DIR = os.path.join(os.getenv("TEMP", "C:\\Temp"), "dev_setup_downloads")

# Python 및 가상환경 설정
USER_NAME = getpass.getuser()
PYTHON_EXE = rf"C:\Users\{USER_NAME}\AppData\Local\Programs\Python\Python313\python.exe"
VENV_SCRIPTS_PATH = r"C:\python\msys2-venv\Scripts"
PYTHON_VENV_PACKAGES = ["mkdocs", "mkdocs-material", "mkdoxy"]

# 프로그램 및 VSCode 확장 프로그램 리스트
WINGET_PROGRAMS = {
    "PowerShell (최신)": "Microsoft.PowerShell",
    "VSCode": "Microsoft.VisualStudioCode",
    ".Net runtime 6.0": "Microsoft.DotNet.Runtime.6"
}

VSCODE_EXTENSIONS = [
    "ms-vscode.cpptools-extension-pack",
    "llvm-vs-code-extensions.vscode-clangd",
    "ms-python.python",
    "ms-python.black-formatter",
    "josetr.cmake-language-support-vscode",
]


def print_section_header(title: str):
    print(f"\n{'=' * 10} {title} {'=' * 10}")


def print_section_footer():
    print(f"{'=' * 40}\n")


def main():
    # 0. 관리자 권한 확인
    run_as_admin_if_needed()

    print("=" * 50)
    print("개발 환경 설정 스크립트 (Python 통합 버전)")
    print("=" * 50)

    # 1. winget 기본 프로그램 설치
    print_section_header("1. 기본 프로그램 설치 (winget)")
    winget_args = ["--accept-package-agreements", "--accept-source-agreements", "-e"]

    for name, prog_id in WINGET_PROGRAMS.items():
        print(f"--- {name} 설치 시도 ---")
        run_command_direct_output(
            ["winget", "install"] + winget_args + ["--id", prog_id],
            success_message=f"{name}: 설치 성공 또는 이미 최신 상태입니다.",
            error_message=f"{name}: 설치 중 오류가 발생했습니다."
        )
    
    update_current_session_path_from_registry()
    print_section_footer()

    # 2. PowerShell UTF-8 설정
    print_section_header("2. PowerShell 프로필 UTF-8 설정")
    configure_powershell_profile_utf8()
    print_section_footer()

    # 3. MSYS2 설치
    print_section_header("3. MSYS2 설치")
    msys2_installer_exe = None
    should_install = not os.path.isdir(MSYS2_ROOT_DIR)
    
    if not should_install:
        choice = input(f"'{MSYS2_ROOT_DIR}'가 이미 존재합니다. 다시 설치하시겠습니까? (y/n): ").lower()
        should_install = (choice == 'y')

    if should_install:
        tag_clean = MSYS2_INSTALLER_TAG.replace("-", "")
        msys2_url = f"https://github.com/msys2/msys2-installer/releases/download/{MSYS2_INSTALLER_TAG}/msys2-x86_64-{tag_clean}.exe"
        
        msys2_installer_exe = download_msys2_installer(msys2_url, TEMP_DIR)
        if msys2_installer_exe:
            if install_msys2(msys2_installer_exe, MSYS2_ROOT_DIR):
                print("MSYS2 설치가 완료되었습니다.")
            else:
                print("MSYS2 설치 실패. 다음 단계에서 문제가 발생할 수 있습니다.")
            remove_msys2_installer(msys2_installer_exe)
    else:
        print("MSYS2 설치 단계를 건너뜁니다.")
    print_section_footer()

    # 4. MSYS2 환경 변수 설정
    print_section_header("4. MSYS2 환경 변수 설정")
    set_system_environment_variable("MSYS2_ROOT", MSYS2_ROOT_DIR, "REG_SZ")

    # MSYS2_PATH 구성 (가상환경 + UCRT64 + USR)
    msys2_path_val = f"{VENV_SCRIPTS_PATH};{os.path.join(MSYS2_ROOT_DIR, 'ucrt64', 'bin')};{os.path.join(MSYS2_ROOT_DIR, 'usr', 'bin')}"
    set_system_environment_variable("MSYS2_PATH", msys2_path_val, "REG_SZ")
    
    update_current_session_path_from_registry()
    print_section_footer()

    # 5. MSYS2 초기 설정 (Bash 스크립트)
    print_section_header("5. MSYS2 패키지 업데이트 및 의존성 설치")
    if os.path.isdir(MSYS2_ROOT_DIR):
        bash_scripts = ["setup-pacman.sh", "update-packages.sh", "update-packages.sh", "install-deps.sh"]
        
        for script in bash_scripts:
            full_path = os.path.join(BASH_SCRIPTS_DIR, script)
            if os.path.exists(full_path):
                print(f"--- MSYS2: {script} 실행 ---")
                run_msys2_bash_script(MSYS2_ROOT_DIR, f"bash/{script}", REPO_ROOT_DIR)
            else:
                print(f"경고: {full_path} 파일을 찾을 수 없습니다.")
    else:
        print("MSYS2가 설치되지 않아 Bash 스크립트 실행을 건너뜁니다.")
    print_section_footer()

    # 6. Python 가상 환경 패키지 업데이트
    print_section_header("6. Python 패키지 설치")
    if os.path.isdir(VENV_SCRIPTS_PATH):
        pip_exe = os.path.join(VENV_SCRIPTS_PATH, "pip.exe")
        run_command_direct_output(
            [pip_exe, "install", "--upgrade"] + PYTHON_VENV_PACKAGES,
            success_message="Python 패키지 업데이트 성공.",
            error_message="Python 패키지 설치 중 오류 발생."
        )
    else:
        print(f"가상환경 경로({VENV_SCRIPTS_PATH})를 찾을 수 없습니다.")
    print_section_footer()

    # 7. VSCode 확장 설치
    print_section_header("7. VSCode 확장 프로그램 설치")
    code_bin = shutil.which("code")
    if code_bin:
        for ext_id in VSCODE_EXTENSIONS:
            print(f"--- 확장 설치: {ext_id} ---")
            run_command_direct_output(
                [code_bin, "--install-extension", ext_id, "--force"],
                success_message=f"'{ext_id}' 설치 완료.",
                error_message=f"'{ext_id}' 설치 실패."
            )
    else:
        print("VSCode('code') 명령어를 PATH에서 찾을 수 없습니다.")
    print_section_footer()

    # 8. VSCode settings.json 업데이트
    print_section_header("8. VSCode 전역 설정 업데이트")
    appdata = os.environ.get('APPDATA')
    if appdata:
        vscode_settings_path = os.path.join(appdata, 'Code', 'User', 'settings.json')
        
        # 적용할 설정 값들
        updates = {
            "cmake.cmakePath": "${env:MSYS2_ROOT}/ucrt64/bin/cmake",
            "clangd.path": "${env:MSYS2_ROOT}/ucrt64/bin/clangd.exe",
            "cmake.debugConfig": {"miDebuggerPath": "C:/msys64/ucrt64/bin/gdb.exe"}
        }

        try:
            settings_dict = {}
            if os.path.exists(vscode_settings_path):
                with open(vscode_settings_path, 'r', encoding='utf-8') as f:
                    lines = [l for l in f.read().splitlines() if not l.strip().startswith('//')]
                    try:
                        settings_dict = json.loads('\n'.join(lines))
                    except json.JSONDecodeError:
                        print("기존 settings.json 형식이 올바르지 않아 초기화합니다.")

            modified = False
            # 설정 반영 (중첩 구조인 cmake.debugConfig 별도 처리)
            for key, val in updates.items():
                if key == "cmake.debugConfig":
                    if settings_dict.get(key, {}).get("miDebuggerPath") != val["miDebuggerPath"]:
                        settings_dict.setdefault(key, {})["miDebuggerPath"] = val["miDebuggerPath"]
                        modified = True
                        print(f"'{key}.miDebuggerPath' 업데이트 완료.")
                else:
                    if settings_dict.get(key) != val:
                        settings_dict[key] = val
                        modified = True
                        print(f"'{key}' 업데이트 완료.")

            if modified:
                os.makedirs(os.path.dirname(vscode_settings_path), exist_ok=True)
                with open(vscode_settings_path, 'w', encoding='utf-8') as f:
                    json.dump(settings_dict, f, indent=4, ensure_ascii=False)
                print("VSCode 설정 파일이 저장되었습니다.")
            else:
                print("이미 모든 설정이 최신입니다.")

        except Exception as e:
            print(f"VSCode 설정 중 오류 발생: {e}")
    else:
        print("APPDATA 환경 변수를 찾을 수 없습니다.")
    print_section_footer()

    print("=" * 50)
    print("모든 설정이 완료되었습니다. 변경 사항 적용을 위해 재부팅을 권장합니다.")
    print("=" * 50)


if __name__ == "__main__":
    main()
