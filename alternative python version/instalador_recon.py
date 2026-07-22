#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import time
from pathlib import Path
from typing import List, Optional

HOME = os.path.expanduser("~")
RECON_DIR = Path(HOME) / "recon.sh"

YELLOW = "\033[1;93m"
GREEN_BOLD = "\033[1;32m"
CYAN_BOLD = "\033[1;36m"
GREEN_LIGHT = "\033[1;92m"
CYAN = "\033[1;36m"
GREEN = "\033[1;92m"
CYAN_LIGHT = "\033[96m"
RED_BOLD = "\033[1;91m"
YELLOW_BOLD = "\033[1;93m"
BLUE_LIGHT = "\033[1;94m"
PURPLE_LIGHT = "\033[1;95m"
RESET = "\033[0m"


def print_color(text: str, color: str = "") -> None:
    print(f"{color}{text}{RESET}")


def run_command(cmd: List[str], check: bool = True, capture_output: bool = False, input_text: Optional[str] = None, env: Optional[dict] = None, cwd: Optional[Path] = None) -> subprocess.CompletedProcess:
    return subprocess.run(
        cmd,
        check=check,
        capture_output=capture_output,
        input=input_text,
        text=True,
        env=env,
        cwd=str(cwd) if cwd else None,
    )


def ensure_linux() -> None:
    if os.uname().sysname != "Linux":
        print_color("Você não está usando um sistema GNU/Linux ou similar", GREEN_BOLD)
        sys.exit(1)


def ensure_sudo() -> None:
    print_color("Verificando permissões de sudo...", CYAN_BOLD)
    run_command(["sudo", "-v"], check=True)


def install_packages() -> None:
    print_color("Instalando linguagens de programação e pacotes necessários...", CYAN)
    time.sleep(1)
    packages = [
        "python3",
        "golang",
        "curl",
        "unzip",
        "wget",
        "iputils-ping",
        "openssh-client",
        "pipx",
        "zsh",
        "nmap",
        "htop",
        "gobuster",
    ]
    print_color("[*] Instalando pacotes...", CYAN_BOLD)
    for pkg in packages:
        if subprocess.run(["bash", "-lc", f"command -v {pkg} >/dev/null 2>&1"], capture_output=True).returncode == 0:
            print_color(f"[✔] {pkg} já instalado.", GREEN_BOLD)
        else:
            print_color(f"[ * ] Instalando {pkg}...", YELLOW)
            run_command(["sudo", "apt", "install", "-y", pkg], check=False)


def install_vscode() -> None:
    print_color("Instalando VS Code via .deb na pasta Downloads...", CYAN_BOLD)
    time.sleep(1)
    if subprocess.run(["bash", "-lc", "command -v code >/dev/null 2>&1"], capture_output=True).returncode == 0:
        print_color("[✔] VS Code já instalado.", GREEN_BOLD)
        return

    download_dir = Path(HOME) / "Downloads"
    deb_file = download_dir / "code_latest_amd64.deb"
    download_dir.mkdir(parents=True, exist_ok=True)
    print_color(f"[ * ] Baixando VS Code para {download_dir}...", YELLOW)
    run_command(["wget", "-qO", str(deb_file), "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"], check=False)
    if deb_file.exists():
        print_color(f"[ * ] Instalando {deb_file}...", YELLOW)
        run_command(["sudo", "apt", "install", "-y", str(deb_file)], check=False)
        if subprocess.run(["bash", "-lc", "command -v code >/dev/null 2>&1"], capture_output=True).returncode == 0:
            print_color("[✔] VS Code instalado com sucesso.", GREEN_BOLD)
        else:
            print_color("[❌] Falha ao verificar VS Code após instalação.", RED_BOLD)
    else:
        print_color(f"[❌] Falha ao baixar VS Code para {download_dir}.", RED_BOLD)


def install_go_tools() -> None:
    print_color("Instalando ferramentas em Golang...", CYAN)
    time.sleep(1)
    tools = {
        "kxss": "github.com/Emoe/kxss@latest",
        "subfinder": "github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest",
        "httpx": "github.com/projectdiscovery/httpx/cmd/httpx@latest",
        "gau": "github.com/lc/gau/v2/cmd/gau@latest",
        "anew": "github.com/tomnomnom/anew@latest",
        "ffuf": "github.com/ffuf/ffuf@latest",
        "getJS": "github.com/003random/getJS@latest",
        "nuclei": "github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest",
    }
    env = os.environ.copy()
    env["PATH"] = f"{HOME}/go/bin:{env.get('PATH','')}"
    for name, repo in tools.items():
        print_color(f"Instalando {name}...", GREEN)
        run_command(["go", "install", "-v", repo], check=False, env=env)


def create_output_dirs() -> None:
    RECON_DIR.mkdir(parents=True, exist_ok=True)
    dirs = [
        "subfinder_results",
        "gau_results",
        "nmap_results",
        "gobuster_results",
        "ffuf_results",
    ]
    print_color(f"Criando Pastas de Output em {RECON_DIR}", YELLOW_BOLD)
    for directory in dirs:
        target = RECON_DIR / directory
        if target.exists():
            print_color(f"[=] O diretório já existe: {target}", YELLOW_BOLD)
        else:
            target.mkdir(parents=True, exist_ok=True)
            print_color(f"[✔] Criado: {target}", GREEN_BOLD)


def clone_or_update_repos() -> None:
    repos = {
        "ParamSpider": "https://github.com/devanshbatham/ParamSpider",
        "https-github.com-Rajkumrdusad-Tool-X": "https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git",
        "scripts-aprendizado": "https://github.com/uuidmissing/scripts-aprendizado",
        "nuclei-templates": "https://github.com/projectdiscovery/nuclei-templates",
    }
    print_color("Baixando repositórios adicionais para adição de ferramentas...", CYAN)
    for name, url in repos.items():
        repo_path = Path(HOME) / name
        if not repo_path.exists():
            print_color(f"Clonando {name}...", CYAN_LIGHT)
            run_command(["git", "clone", url], cwd=Path(HOME), check=False)
        else:
            print_color(f"Atualizando repositório {name}...", GREEN)
            run_command(["git", "-C", str(repo_path), "reset", "--hard"], check=False)
            run_command(["git", "-C", str(repo_path), "pull"], check=False)


def download_wordlists() -> None:
    print_color("📋 Baixando common.txt (20KB) para Gobuster...", YELLOW_BOLD)
    run_command(["curl", "-s", "-o", f"{HOME}/common.txt", "https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt"], check=False)
    print_color(f"✅ common.txt instalada em {HOME}/common.txt", GREEN_BOLD)
    if Path(HOME, "common.txt").exists():
        print_color(f"✅ Verificação OK! ({sum(1 for _ in open(Path(HOME, 'common.txt'), encoding='utf-8', errors='ignore'))} linhas)", GREEN_BOLD)
    else:
        print_color("❌ FALHOU! Arquivo não encontrado", RED_BOLD)

    print_color("📋 Baixando lista XSS-Cheat-Sheet-PortSwigger.txt para ffuf...", YELLOW_BOLD)
    run_command(["curl", "-s", "-o", f"{HOME}/XSS-Cheat-Sheet-PortSwigger.txt", "https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Fuzzing/XSS/human-friendly/XSS-Cheat-Sheet-PortSwigger.txt"], check=False)
    if Path(HOME, "XSS-Cheat-Sheet-PortSwigger.txt").exists():
        print_color(f"✅ Verificação OK! ({sum(1 for _ in open(Path(HOME, 'XSS-Cheat-Sheet-PortSwigger.txt'), encoding='utf-8', errors='ignore'))} linhas)", GREEN_BOLD)
    else:
        print_color("❌ FALHOU! Arquivo não encontrado", RED_BOLD)


def install_seclists() -> None:
    if not (Path(HOME) / "SecLists").exists():
        print_color("Deseja instalar SecLists? (s/N)", CYAN_LIGHT)
        response = input().strip().lower()
        if response.startswith(("s", "y")):
            run_command(["git", "clone", "https://github.com/danielmiessler/SecLists.git"], cwd=Path(HOME), check=False)
        else:
            print_color("Pulando SecLists", YELLOW_BOLD)


def install_pipx_packages() -> None:
    repos = {
        "ParamSpider": Path(HOME) / "ParamSpider",
        "https-github.com-Rajkumrdusad-Tool-X": Path(HOME) / "https-github.com-Rajkumrdusad-Tool-X",
        "scripts-aprendizado": Path(HOME) / "scripts-aprendizado",
        "nuclei-templates": Path(HOME) / "nuclei-templates",
    }
    for name, repo_path in repos.items():
        if not repo_path.exists():
            continue
        if (repo_path / "setup.py").exists() or (repo_path / "pyproject.toml").exists():
            print_color(f"Tentando instalar {name} com Pipx", GREEN_BOLD)
            run_command(["pipx", "install", "."], cwd=repo_path, check=False)
        else:
            print_color(f"Repositório {name} não é um pacote Python instalável. Instalação manual será necessária.", YELLOW_BOLD)


def create_virtualenv() -> None:
    path4env = Path(HOME) / "scripts-aprendizado" / "python3"
    if path4env.exists():
        print_color(f"Criando ambiente virtual em {path4env}", YELLOW_BOLD)
        run_command(["python3", "-m", "venv", str(path4env / "libs")], check=False)
        activate = path4env / "libs" / "bin" / "activate"
        if activate.exists():
            env = os.environ.copy()
            env["VIRTUAL_ENV"] = str(path4env / "libs")
            env["PATH"] = f"{path4env / 'libs' / 'bin'}:{env.get('PATH','')}"
            run_command(["python", "-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel"], check=False, env=env)
            requirements = path4env / "requirements.txt"
            if requirements.exists():
                run_command(["python", "-m", "pip", "install", "-r", str(requirements)], check=False, env=env)
            else:
                print_color("requirements.txt não encontrado", YELLOW_BOLD)
        else:
            print_color("Ambiente virtual não foi criado corretamente", RED_BOLD)
    else:
        print_color(f"[AVISO] O PATH {path4env} não foi encontrado.", YELLOW_BOLD)


def link_go_tools() -> None:
    go_bin = Path(HOME) / "go" / "bin"
    if go_bin.exists():
        for tool in go_bin.iterdir():
            if tool.is_file():
                run_command(["sudo", "ln", "-sf", str(tool), f"/usr/local/bin/{tool.name}"], check=False)


def main() -> None:
    print_color("Esse script foi feito com o propósito de ser usado no Kali Linux", YELLOW)
    time.sleep(2)
    ensure_linux()
    ensure_sudo()
    run_command(["sudo", "apt", "update", "-y"], check=False)
    run_command(["sudo", "apt", "upgrade", "-y"], check=False)
    run_command(["sudo", "apt", "autoremove", "-y"], check=False)

    install_packages()
    install_vscode()
    install_go_tools()
    create_output_dirs()
    clone_or_update_repos()
    download_wordlists()
    install_seclists()
    install_pipx_packages()
    create_virtualenv()
    link_go_tools()

    print_color("Aviso: As ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas.", YELLOW)
    print_color("Instalação concluída", GREEN_BOLD)


if __name__ == "__main__":
    main()
