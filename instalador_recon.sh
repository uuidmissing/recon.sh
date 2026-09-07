#!/usr/bin/env bash

############################################################################################################################
# Definição das cores ANSI
############################################################################################################################

# Variaveis de cores ANSI usadas nas mensagens do instalador.
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

# Todos os arquivos mantidos pelo projeto usam a pasta deste script como
# raiz, tornando a instalacao independente do local onde o repositorio foi
# clonado.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORDLISTS_DIR="${SCRIPT_DIR}/wordlists"
DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}"
mkdir -p "${DEFAULT_WORDLISTS_DIR}"

# Imprime uma mensagem com a cor informada e restaura a cor padrao.
color_print() {
  local color="$1"
  local message="$2"
  printf "%b%s%b\n" "$color" "$message" "$RESET"
}

color_print "$YELLOW" "[Aviso] Esse script foi feito com o propósito de ser usado no Kali Linux"
sleep 2

# O restante do instalador depende de ferramentas e pacotes do GNU/Linux.
if [ "$(uname)" != "Linux" ]; then
  color_print "$GREEN_BOLD" "Você não está usando um sistema GNU/Linux ou similar"
  exit 1
fi

# Solicita a senha do sudo uma vez e mantem a credencial validada durante
# instalacoes demoradas, renovando-a a cada 60 segundos.
color_print "$CYAN_BOLD" "Verificando permissões de sudo..."
sudo -v

(
  while true; do

    sudo -n true
    sleep 60
    kill -0 "$$" || exit
  done
) 2>/dev/null &


############################################################################################################################
# Atualiza os indices, os pacotes instalados e remove dependencias antigas.
############################################################################################################################

color_print "$CYAN_BOLD" "Vamos começar atualizando o Linux..."
sleep 3
cd "${HOME}" || { color_print "$RED_BOLD" "Falha ao entrar no diretório HOME"; exit 1; }
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
# Instala os pacotes necessarios que ainda nao estiverem disponiveis.
color_print "$CYAN" "Instalando linguagens de programação e pacotes necessários..."
sleep 1

# Alterar aqui para adicionar ou remover pacotes da lista
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
  cool-retro-term
  hydra
  burpsuite
)

# Registra os erros do apt em um arquivo ao lado do script, sem misturar
# esses logs com os resultados da recon.
DEFAULT_LOG_DIR="${SCRIPT_DIR}/.logs"
mkdir -p "${DEFAULT_LOG_DIR}"
data=$(date +%Y-%m-%d_%H:%M)



printf "%b[*] Instalando pacotes...%b\n" "$CYAN_BOLD" "$RESET"

# Loop para instalar pacotes. "p" se refere a cada pacote individual separado por linha pelo [@]
for p in "${pkg[@]}"; do
  if command -v "${p}" &>/dev/null; then
    printf "%b[✔] %s já instalado.%b\n" "$GREEN_BOLD" "$p" "$RESET"
  else
    # Apenas os erros do apt vao para o log; a mensagem resumida continua
    # sendo exibida no terminal quando a instalacao falha.
    printf "%b[ * ] Instalando %s...%b\n" "$YELLOW" "$p" "$RESET"
    sudo apt install -y "${p}" 2>> "${DEFAULT_LOG_DIR}/pkginstall_logerror_${data}.txt" || printf "%b[✘] Erro ao instalar %s...%b\n" "$RED_BOLD" "$p" "$RESET"
  fi
done

###########################################################################################################################
# Instalação do VSCODE
###########################################################################################################################

color_print "$CYAN_BOLD" "Instalando VS Code via .deb na pasta Downloads..."
sleep 1
if command -v code >/dev/null 2>&1; then # Evita baixar e instalar o VS Code novamente.
  printf "%b[✔] VS Code já instalado.%b\n" "$GREEN_BOLD" "$RESET"
else
  download_dir="${HOME}/Downloads"
  deb_file="${download_dir}/code_latest_amd64.deb"
  mkdir -p "${download_dir}"
  printf "%b[ * ] Baixando VS Code para %s...%b\n"  "$GREEN_LIGHT" "$download_dir" "$RESET"
  # Baixa o pacote para Downloads antes de instala-lo com o apt.
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
############################################################################################################################
# Instalando ferramentas Go
############################################################################################################################

# Mapeia o nome exibido de cada ferramenta para o modulo Go instalado.
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
# O PATH temporario permite que o Go encontre o binario instalado em HOME/go/bin.
for f in "${!ferramentas[@]}"; do
  printf "%bInstalando %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${f}" "$GREEN" "$RESET"
  sleep 1
  env PATH="${HOME}/go/bin:${PATH}" go install -v "${ferramentas[${f}]}" || printf "%bFalha ao instalar %s%b\n" "$YELLOW" "${f}" "$RESET"
done
############################################################################################################################
# Criando Pastas de Output
############################################################################################################################

# Faz pipelines retornarem erro quando qualquer comando interno falhar.
set -o pipefail
recon_outdirs=(
  subfinder_results
  gau_results
  nmap_results
  gobuster_results
  ffuf_results
  gobuster_results
)

mkdir -p "${DEFAULT_OUTPUT_DIR}"
printf "%bCriando Pastas de Output em %b%s%b\n" "$YELLOW_BOLD" "$GREEN_BOLD" "${DEFAULT_OUTPUT_DIR}" "$RESET"
for dir in "${recon_outdirs[@]}"; do
  outputdir="${DEFAULT_OUTPUT_DIR}/${dir}"
  if [[ ! -d "${outputdir}" ]]; then
    mkdir -p "${outputdir}"
    printf "%b[✔]%b Criado: %s\n" "$GREEN_BOLD" "$RESET" "${outputdir}"
  else
    printf "%b[=]%b O diretório já existe: %s\n" "$YELLOW_BOLD" "$RESET" "${outputdir}"
  fi
done
set +o pipefail # Desativa pipefail apos criar as pastas.

############################################################################################################################
# Clonando repositorios
############################################################################################################################

# Repositorios que serao clonados ou atualizados dentro de HOME.
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
    # Descarta alterações locais e baixa a versao mais recente do repositorio.
    printf "%bAtualizando repositório %b%s%b...%b\n" "$GREEN" "$CYAN_LIGHT" "${repo}" "$GREEN" "$RESET"
    git -C "${repo}" reset --hard
    git -C "${repo}" pull
  fi
done

# Wordlists sao armazenadas na pasta do projeto e reutilizadas pelas ferramentas.
COMMON_WORDLIST="${DEFAULT_WORDLISTS_DIR}/common.txt"
XSS_WORDLIST="${DEFAULT_WORDLISTS_DIR}/XSS-Cheat-Sheet-PortSwigger.txt"

printf "%b📋 Baixando common.txt (20KB) para Gobuster...%b\n" "$YELLOW_BOLD" "$RESET"
curl -fsSL -o "$COMMON_WORDLIST" https://raw.githubusercontent.com/danielmiessler/SecLists/master/Discovery/Web-Content/common.txt
printf "%b✅ %bcommon.txt instalada em %b%s%b\n" "$GREEN_BOLD" "$YELLOW_BOLD" "$GREEN_BOLD" "$COMMON_WORDLIST" "$RESET"
[[ -f "$COMMON_WORDLIST" ]] && printf "%b✅ Verificação OK! (%s linhas)%b\n" "$GREEN_BOLD" "$(wc -l <"$COMMON_WORDLIST")" "$RESET" || printf "%b❌ %bFALHOU! Arquivo não encontrado%b\n" "$RED_BOLD" "$YELLOW_BOLD" "$RESET"

printf "%b📋 Baixando lista XSS-Cheat-Sheet-PortSwigger.txt para ffuf...%b\n" "$YELLOW_BOLD" "$RESET"
curl -fsSL -o "$XSS_WORDLIST" https://raw.githubusercontent.com/danielmiessler/SecLists/refs/heads/master/Fuzzing/XSS/human-friendly/XSS-Cheat-Sheet-PortSwigger.txt
[[ -f "$XSS_WORDLIST" ]] && printf "%b✅ Verificação OK! (%s linhas)%b\n" "$GREEN_BOLD" "$(wc -l <"$XSS_WORDLIST")" "$RESET" || printf "%b❌ %bFALHOU! Arquivo não encontrado%b\n" "$RED_BOLD" "$YELLOW_BOLD" "$RESET"

# O SecLists completo e opcional; as duas listas menores acima sao sempre baixadas.
if [ ! -d "SecLists" ]; then
  printf "%bDeseja instalar SecLists? (s/N)%b\n" "$CYAN_LIGHT" "$RESET"
  read -r opcao
  case "$opcao" in
  [sSyY]*) git clone https://github.com/danielmiessler/SecLists.git ;;
  *) printf "%bPulando SecLists%b\n" "$YELLOW_BOLD" "$RESET" ;;
  esac
fi

# Esta etapa e opcional porque cada repositorio pode exigir um metodo proprio
# de instalacao. O pipx so sera usado quando o usuario autorizar e o projeto
# possuir setup.py ou pyproject.toml.

PIPX_INSTALL=false
printf "%bDeseja instalar os repositórios Python com Pipx? (s/N)%b\n" "$CYAN_LIGHT" "$RESET"
read -r pipx_opcao
case "$pipx_opcao" in
  [sSyY]*) PIPX_INSTALL=true ;;
  *) printf "%bPulando instalação com Pipx%b\n" "$YELLOW_BOLD" "$RESET" ;;
esac

if [[ "$PIPX_INSTALL" == true ]]; then
  if ! command -v pipx >/dev/null 2>&1; then
    printf "%bPipx não está disponível. Instalação manual será necessária.%b\n" "$YELLOW_BOLD" "$RESET"
  else
    for repo in "${!links[@]}"; do
      REPO_PATH="${HOME}/${repo}"
      if [[ ! -d "$REPO_PATH" ]]; then
        printf "%b❌ Repositório não encontrado: %s%b\n" "$RED_BOLD" "$REPO_PATH" "$RESET"
        continue
      fi

      if [[ -f "${REPO_PATH}/setup.py" || -f "${REPO_PATH}/pyproject.toml" ]]; then
        printf "%bTentando instalar %s com Pipx%b\n" "$GREEN_BOLD" "$repo" "$RESET"
        pipx install "$REPO_PATH" || printf "%bFalha ao instalar %s via Pipx. Consulte as instruções do repositório.%b\n" "$RED_BOLD" "$repo" "$RESET"
      else
        printf "%bRepositório %s não é um pacote Python instalável. Consulte as instruções do repositório.%b\n" "$YELLOW_BOLD" "$repo" "$RESET"
      fi
    done
  fi
fi


# Executa o instalador externo do Tool-X somente quando ele ainda nao existe.
printf "%bInstalando %bTool-X%b\n" "$GREEN_BOLD" "$BLUE_BOLD" "$RESET"

if command -v tool-x >/dev/null 2>&1; then
  printf "%b[✔] Tool-X já instalado.%b\n" "$GREEN_BOLD" "$RESET"
else
  bash <(curl -s https://raw.githubusercontent.com/trmxvibs/Tool-X/main/setup.sh) || printf "%bFalha ao instalar Tool-X. Instale manualmente se necessário.%b\n" "$RED_BOLD" "$RESET"
fi

# Cria links em /usr/local/bin para que os binarios Go sejam encontrados sem
# precisar informar HOME/go/bin no PATH de cada terminal.
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

# Exemplos resumidos para lembrar como iniciar as principais ferramentas.
printf "%bExemplos de uso das ferramentas instaladas:%b\n" "$CYAN_BOLD" "$RESET"
printf "1. subfinder: %bsubfinder -d alvo%b\n" "$CYAN_LIGHT" "$RESET"
printf "2. ffuf: %bffuf -u alvo/FUZZ -w caminho/da/wordlist%b\n" "$BLUE_LIGHT" "$RESET"
printf "3. nuclei: %bnuclei -u alvo -t nuclei-templates/cves%b\n" "$PURPLE_LIGHT" "$RESET"
printf "4. script de recon: %b./recon.sh -u alvo%b\n" "$GREEN_BOLD" "$RESET"
printf "5. kxss: %bkxss -d alvo.com -o output.txt%b\n" "$CYAN_LIGHT" "$RESET"
