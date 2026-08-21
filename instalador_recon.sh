#!/usr/bin/env bash

#-----------Definição das cores ANSI-----------
YELLOW="\u001B[1;93m"
GREEN_BOLD="\u001B[1;32m"
CYAN_BOLD="\u001B[1;36m"
GREEN_LIGHT="\u001B[1;92m"
CYAN="\u001B[1;36m"
GREEN="\u001B[1;92m"
CYAN_LIGHT="\u001B[96m"
RED_BOLD="\u001B[1;91m"
YELLOW_BOLD="\u001B[1;93m"
BLUE_LIGHT="\u001B[1;94m"
PURPLE_LIGHT="\u001B[1;95m"
RESET="\u001B[0m"

color_print() {
  local color="$1"
  local message="$2"
  printf "%b%s%b\n" "$color" "$message" "$RESET"
}

color_print "$YELLOW" "Esse script foi feito com o propósito de ser usado no Kali Linux"
sleep 2

if [ "$(uname)" != "Linux" ]; then
  color_print "$GREEN_BOLD" "Você não está usando um sistema GNU/Linux ou similar"
  exit 1
fi

# -----------Solicita senha sudo uma vez no começo----------
color_print "$CYAN_BOLD" "Verificando permissões de sudo..."
sudo -v

(
  while true; do

    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done
) 2>/dev/null &



# ---------- Atualização do sistema ----------
color_print "$CYAN_BOLD" "Vamos começar atualizando o Linux..."
sleep 3
cd "${HOME}" || { color_print "$RED_BOLD" "Falha ao entrar no diretório HOME"; exit 1; }
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
# ---------- Instalação de pacotes APT ----------
color_print "$CYAN" "Instalando linguagens de programação e pacotes necessários..."
sleep 1

pkg=(
  python3
  golang
  curl
  unzip
  wget
  iputils-ping
  openssh-client
  pipx
  zsh
  nmap
  htop
  gobuster
)

printf "%b[*] Instalando pacotes...%b\n" "$CYAN_BOLD" "$RESET"
for p in "${pkg[@]}"; do
  if command -v "${p}" &>/dev/null; then
    printf "%b[✔] %s já instalado.%b\n" "$GREEN_BOLD" "$p" "$RESET"
  else
    printf "%b[ * ] Instalando %s...%b\n" "$YELLOW" "$p" "$RESET"
    sudo apt install -y "${p}"
  fi
done

color_print "$CYAN_BOLD" "Instalando VS Code via .deb na pasta Downloads..."
sleep 1
if command -v code >/dev/null 2>&1; then
  printf "%b[✔] VS Code já instalado.%b\n" "$GREEN_BOLD" "$RESET"
else
  download_dir="${HOME}/Downloads"
  deb_file="${download_dir}/code_latest_amd64.deb"
  mkdir -p "${download_dir}"
  printf "%b[ * ] Baixando VS Code para %s...%b\n"  "$GREEN_LIGHT" "$download_dir" "$RESET"
  wget -qO "${deb_file}" "https://update.code.visualstudio.com/latest/linux-deb-x64/stable"
  if [[ -f "${deb_file}" ]]; then
    printf "%b[ * ] Instalando %s...%b\n" "$GREEN_LIGHT" "$deb_file" "$RESET"
    sudo apt install -y "${deb_file}"
    if command -v code >/dev/null 2>&1; then
      printf "%b[✔] VS Code instalado com sucesso.%b\n" "$GREEN_BOLD" "$RESET"
    else
      printf "%b[❌] Falha ao verificar VS Code após instalação.%b\n" "$RED_BOLD" "$RESET"
    fi
  else
    printf "%b[❌] Falha ao baixar VS Code para %s.%b\n" "$RED_BOLD" "$download_dir" "$RESET"
  fi
fi

# ---------- Instalando ferramentas Go ----------
declare -A ferramentas=(
  ["kxss"]="github.com/Emoe/kxss@latest"
  ["subfinder"]="github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest"
  ["httpx"]="github.com/projectdiscovery/httpx/cmd/httpx@latest"
  ["gau"]="github.com/lc/gau/v2/cmd/gau@latest"
  ["anew"]="github.com/tomnomnom/anew@latest"
  ["ffuf"]="github.com/ffuf/ffuf@latest"
  ["getJS"]="github.com/003random/getJS@latest"
  ["nuclei"]="github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest"
)

printf "%bInstalando ferramentas em Golang...%b" "$CYAN" "$RESET"
sleep 1
for f in "${!ferramentas[@]}"; do
  printf "%bInstalando %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${f}" "$GREEN" "$RESET"
  sleep 1
  env PATH="${HOME}/go/bin:${PATH}" go install -v "${ferramentas[${f}]}" || printf "%bFalha ao instalar %s%b\n" "$YELLOW" "${f}" "$RESET"
done

# ---------- Criando Pastas de Output -----------

# ativar pipefail
set -o pipefail
recon_outdirs=(
  subfinder_results
  gau_results
  nmap_results
  gobuster_results
  ffuf_results
  gobuster_results
)

mkdir -p "${HOME}/recon.sh"
printf "%bCriando Pastas de Output em %b%s%b\n" "$YELLOW_BOLD" "$GREEN_BOLD" "${HOME}/recon.sh" "$RESET"
for dir in "${recon_outdirs[@]}"; do
  outputdir="${HOME}/recon.sh/${dir}"
  if [[ ! -d "${outputdir}" ]]; then
    mkdir -p "${outputdir}"
    printf "%b[✔]%b Criado: %s\n" "$GREEN_BOLD" "$RESET" "${outputdir}"
  else
    printf "%b[=]%b O diretório já existe: %s\n" "$YELLOW_BOLD" "$RESET" "${outputdir}"
  fi
done
set +o pipefail
# ---------- Clonando repositórios --------------
declare -A links=(
  ["ParamSpider"]="https://github.com/devanshbatham/ParamSpider"
  ["https-github.com-Rajkumrdusad-Tool-X"]="https://github.com/vaibhavguru/https-github.com-Rajkumrdusad-Tool-X.git"
  ["scripts-aprendizado"]="https://github.com/uuidmissing/scripts-aprendizado"
  ["nuclei-templates"]="https://github.com/projectdiscovery/nuclei-templates"
)

printf "%bBaixando repositórios adicionais para adição de ferramentas...%b\n" "$CYAN" "$RESET"
for repo in "${!links[@]}"; do
  if [ ! -d "${repo}" ]; then
    printf "%bClonando %s...%b\n" "$CYAN_LIGHT" "${repo}" "$RESET"
    git clone "${links[${repo}]}"
  else
    printf "%bAtualizando repositório %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${repo}" "$GREEN" "$RESET"
    git -C "${repo}" reset --hard
    git -C "${repo}" pull
  fi
done

#------------- Listas para fuzzing --------------
printf "%b📋 Baixando common.txt (20KB) para Gobuster...%b\n" "$YELLOW_BOLD" "$RESET"
curl -s -o ~/common.txt https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt
printf "%b✅ %bcommon.txt instalada em %b~/common.txt%b\n" "$GREEN_BOLD" "$YELLOW_BOLD" "$GREEN_BOLD" "$RESET"
[[ -f ~/common.txt ]] && printf "%b✅ Verificação OK! (%s linhas)%b\n" "$GREEN_BOLD" "$(wc -l <"${HOME}/common.txt")" "$RESET" || printf "%b❌ %bFALHOU! Arquivo não encontrado%b\n" "$RED_BOLD" "$YELLOW_BOLD" "$RESET"

printf "%b📋 Baixando lista XSS-Cheat-Sheet-PortSwigger.txt para  ffuf...%b\n" "$YELLOW_BOLD" "$RESET"
curl -s -o ~/XSS-Cheat-Sheet-PortSwigger.txt https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Fuzzing/XSS/human-friendly/XSS-Cheat-Sheet-PortSwigger.txt
[[ -f ~/XSS-Cheat-Sheet-PortSwigger.txt ]] && printf "%b✅ Verificação OK! (%s linhas)%b\n" "$GREEN_BOLD" "$(wc -l <"${HOME}/XSS-Cheat-Sheet-PortSwigger.txt")" "$RESET" || printf "%b❌ %bFALHOU! Arquivo não encontrado%b\n" "$RED_BOLD" "$YELLOW_BOLD" "$RESET"

# ------------ SecLists Opcional -------------
if [ ! -d "SecLists" ]; then
  printf "%bDeseja instalar SecLists? (s/N)%b\n" "$CYAN_LIGHT" "$RESET"
  read -r opcao
  case "$opcao" in
  [sSyY]*) git clone https://github.com/danielmiessler/SecLists.git ;;
  *) printf "%bPulando SecLists%b\n" "$YELLOW_BOLD" "$RESET" ;;
  esac
fi

# ---------- Tentando instalar repositorios com Pipx ----------
for repo in "${!links[@]}"; do
  REPO_PATH="${HOME}/${repo}"
cd "${REPO_PATH}" || { printf "%b❌ Falha ao entrar em %s%b\n" "$RED_BOLD" "${REPO_PATH}" "$RESET"; continue; }
  if [ -f "${REPO_PATH}/setup.py" ] || [ -f "${REPO_PATH}/pyproject.toml" ]; then
    printf "%bTentando instalar %s com Pipx%b\n" "$GREEN_BOLD" "${repo}" "$RESET"
    pipx install . || printf "%bFalha ao instalar %s com Pipx. Instale manualmente se necessário.%b\n" "$RED_BOLD" "${repo}" "$RESET"
  else
    printf "%bRepositório %s não é um pacote Python instalável. Instalação manual será necessária.%b\n" "$YELLOW_BOLD" "${repo}" "$RESET"
  fi
done

printf "%bInstalando %bTool-X%b\n" "$GREEN_BOLD" "$BLUE_BOLD" "$RESET"

if command -v tool-x >/dev/null 2>&1; then
  printf "%b[✔] Tool-X já instalado.%b\n" "$GREEN_BOLD" "$RESET"
else
  bash <(curl -s https://raw.githubusercontent.com/trmxvibs/Tool-X/main/setup.sh)|| printf "%bFalha ao instalar Tool-X. Instale manualmente se necessário.%b\n" "$RED_BOLD" "$RESET"
fi

# ---------- Links simbólicos para Go ----------
if compgen -G "${HOME}/go/bin/*" >/dev/null; then
  if (
    cd /usr/local/bin || { printf "%b❌ Falha ao entrar em /usr/local/bin%b\n" "$RED_BOLD" "$RESET"; exit 1; }
    for go_tool in "${HOME}/go/bin/"*; do
      tool_name=$(basename "${go_tool}")
      sudo ln -sf "${go_tool}" "${tool_name}"
    done
  ); then
    color_print "$YELLOW" "Aviso:"
    color_print "$GREEN" "As ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas."
  else
    color_print "$RED_BOLD" "Falha ao criar links simbólicos para as ferramentas Go."
  fi
fi
printf "%bAviso: %bAs ferramentas em Golang foram linkadas para /usr/local/bin para facilitar o uso das mesmas.%b\n" "$YELLOW" "$GREEN" "$RESET"
printf "%bInstalação concluída%b\n" "$GREEN_BOLD" "$RESET"
sleep 1

# ---------- Exemplos de uso ----------
printf "%bExemplos de uso das ferramentas instaladas:%b\n" "$CYAN_BOLD" "$RESET"
printf "1. subfinder: %bsubfinder -d alvo%b\n" "$CYAN_LIGHT" "$RESET"
printf "2. ffuf: %bffuf -u alvo/FUZZ -w caminho/da/wordlist%b\n" "$BLUE_LIGHT" "$RESET"
printf "3. nuclei: %bnuclei -u alvo -t nuclei-templates/cves%b\n" "$PURPLE_LIGHT" "$RESET"
printf "4. script de recon: %b./recon.sh -u alvo%b\n" "$GREEN_BOLD" "$RESET"
printf "5. kxss: %bkxss -d alvo.com -o output.txt%b\n" "$CYAN_LIGHT" "$RESET"
