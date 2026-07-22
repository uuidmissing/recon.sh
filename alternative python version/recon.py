#!/usr/bin/env python3
import os
import re
import subprocess
import sys
import time
from datetime import datetime
from pathlib import Path
from typing import Optional

HOME = os.path.expanduser("~")
RECON_DIR = Path(HOME) / "recon.sh"

YELLOW = "\033[93m"
CYAN_LIGHT = "\033[96m"
GREEN = "\033[92m"
PURPLE = "\033[95m"
RED = "\033[91m"
BLUE = "\033[94m"
RESET = "\033[0m"


def print_color(text: str, color: str = "") -> None:
    print(f"{color}{text}{RESET}")


def run_command(cmd: list[str], input_text: Optional[str] = None, capture_output: bool = False) -> subprocess.CompletedProcess:
    return subprocess.run(cmd, input=input_text, text=True, capture_output=capture_output)


def normalize_url(raw_url: str) -> str:
    if not raw_url:
        raise ValueError("URL vazia")
    if not raw_url.startswith(("http://", "https://")):
        raw_url = f"https://{raw_url}"
    if not re.match(r"^https?://([A-Za-z0-9.-]+\.[A-Za-z]{2,})(/.*)?$", raw_url):
        raise ValueError(f"Dominio ou subdominio {raw_url} invalido")
    return raw_url


def menu() -> None:
    print_color("1-Recon completo (Subfinder + Httpx + Gau + Nmap)", GREEN)
    print_color("2-Usar Nuclei [ROOT NECESSÁRIO]", PURPLE)
    print_color("4-Achar informações no JavaScript", CYAN_LIGHT)
    print_color("5-procurar diretórios com Gobuster", BLUE)
    print_color("9-Mudar alvo", RED)
    print_color("00-Sair", YELLOW)


def recon_all(url: str) -> None:
    data = datetime.now().strftime("%Y-%m-%d_%H:%M")
    domain = url.split("://", 1)[1].split("/", 1)[0]
    gau_dir = RECON_DIR / "gau_results"
    subfinder_dir = RECON_DIR / "subfinder_results"
    nmap_dir = RECON_DIR / "nmap_results"
    gau_dir.mkdir(parents=True, exist_ok=True)
    subfinder_dir.mkdir(parents=True, exist_ok=True)
    nmap_dir.mkdir(parents=True, exist_ok=True)

    gau_output = gau_dir / f"{domain}._{data}txt"
    subfinder_output = subfinder_dir / f"{domain}_{data}.txt"
    nmap_output = nmap_dir / f"{domain}_{data}.txt"

    print_color("[INFO] Rodando Subfinder...", GREEN)
    subfinder_result = run_command(["subfinder", "-d", domain, "-silent"], capture_output=True)
    subfinder_result.stdout and (subfinder_output.write_text(subfinder_result.stdout, encoding="utf-8"))

    print_color("[INFO] Rodando Httpx e Gau...", GREEN)
    httpx_result = run_command(["httpx", "-silent"], input_text=subfinder_result.stdout, capture_output=True)
    gau_result = run_command(["gau"], input_text=httpx_result.stdout, capture_output=True)
    gau_output.write_text(gau_result.stdout, encoding="utf-8")

    print_color("[INFO] Rodando Nmap...", GREEN)
    nmap_cmd = ["sudo", "nmap", "-T4", "-F", "-sV", "-iL", str(subfinder_output), "-oN", str(nmap_output)]
    nmap_result = run_command(nmap_cmd)
    if nmap_result.returncode != 0:
        print_color("[WARNING] Nmap falhou, tentando modo unprivileged...", YELLOW)
        run_command(["nmap", "--unprivileged", "-T4", "-F", "-sV", "-iL", str(subfinder_output), "-oN", str(nmap_output.with_suffix(".txt"))], capture_output=True)

    print_color("[OK] Recon completo. Diretórios de saída:", GREEN)
    print_color(f"- Subfinder: {subfinder_dir}", GREEN)
    print_color(f"- Gau: {gau_dir}", GREEN)
    print_color(f"- Nmap: {nmap_dir}", GREEN)


def javascript(url: str) -> None:
    print_color("[INFO] Coletando informações no JavaScript...", GREEN)
    run_command(["getJS"], input_text=url)


def nuclei(url: str) -> None:
    print_color("Quais templates quer usar?", YELLOW)
    print_color("1-todos", GREEN)
    print("2-exposures")
    print("3-cves")
    print("4-exposed panels")
    print("5-fuzzing")
    print_color("6-vulnerabilities", RESET)
    template = input().strip()

    nuclei_bin = Path(HOME) / "go" / "bin" / "nuclei"
    templates_dir = Path(HOME) / "nuclei-templates"
    mapping = {
        "1": [str(nuclei_bin), "-u", url, "-t", str(templates_dir)],
        "2": [str(nuclei_bin), "-u", url, "-t", str(templates_dir / "exposures")],
        "3": [str(nuclei_bin), "-u", url, "-t", str(templates_dir / "cves")],
        "4": [str(nuclei_bin), "-u", url, "-t", str(templates_dir / "exposed-panels")],
        "5": [str(nuclei_bin), "-u", url, "-t", str(templates_dir / "fuzzing")],
        "6": [str(nuclei_bin), "-u", url, "-t", str(templates_dir / "vulnerabilities")],
    }
    if template in mapping:
        run_command(mapping[template])
    else:
        print_color("Opção inválida (╯°□°）╯︵┻━┻", YELLOW)


def usar_gobuster(url: str) -> None:
    gobuster_url = url.split("://", 1)[1].split("/", 1)[0]
    gobuster_dir = RECON_DIR / "gobuster_results"
    gobuster_dir.mkdir(parents=True, exist_ok=True)
    gobuster_out = gobuster_dir / f"{gobuster_url}_{datetime.now().strftime('%Y-%m-%d_%H:%M')}.txt"
    wordlist = Path(HOME) / "common.txt"

    print_color(f"Preparando Gobuster em https://{gobuster_url}", YELLOW)
    print_color("[1] common.txt --- Lista Padrão", GREEN)
    print_color(f"[2] lista personalizada --- Informe o PATH. EX: {wordlist}", GREEN)
    opcao = input().strip()

    if opcao == "1":
        run_command(["gobuster", "dir", "-u", f"https://{gobuster_url}", "-w", str(wordlist), "-r", "-t", "5", "--delay", "500ms", "-b", "403,404,406,429", "-o", str(gobuster_out)])
    elif opcao == "2":
        user_wordlist = input("Informe a lista que quer usar: ").strip()
        run_command(["gobuster", "dir", "-u", f"https://{gobuster_url}", "-w", user_wordlist, "-r", "-t", "5", "--delay", "500ms", "-b", "403,404,406,429", "-o", str(gobuster_out)])
    else:
        print_color("Opção inválida (╯°□°）╯︵┻━┻", YELLOW)


def resetar_url() -> str:
    print_color("Digite o Dominio/Url que deseja analisar:", YELLOW)
    raw_url = input().strip()
    if not raw_url:
        print_color("[ERRO] URL vazia.", RED)
        raise ValueError("URL vazia")
    return normalize_url(raw_url)


def main() -> None:
    url = ""
    for i in range(len(sys.argv)):
        if sys.argv[i] == "-u" and i + 1 < len(sys.argv):
            url = sys.argv[i + 1]
            break
    if not url:
        print_color("A flag -u não pode ser vazia", YELLOW)
        print_color("Use python3 recon.py -u <url ou dominio>", GREEN)
        sys.exit(1)

    try:
        url = normalize_url(url)
    except ValueError as exc:
        print_color(f"[ERRO] {exc}", RED)
        sys.exit(2)

    while True:
        menu()
        print_color("Digite o numero da opção que você quer", GREEN,)
        opcao = input().strip()
        if opcao == "1":
            recon_all(url)
        elif opcao == "2":
            nuclei(url)
        elif opcao == "4":
            javascript(url)
        elif opcao == "5":
            usar_gobuster(url)
        elif opcao == "9":
            try:
                url = resetar_url()
            except ValueError:
                continue
        elif opcao == "00":
            print_color("Saindo...", YELLOW)
            break
        else:
            print_color("Opção inválida (╯°□°）╯︵┻━┻", YELLOW)


if __name__ == "__main__":
    main()
