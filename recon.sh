#!/usr/bin/env bash

############################################################################################################################
# Configuracao de caminhos
############################################################################################################################
# Usa o diretorio deste arquivo como raiz para que o script possa ser
# executado de qualquer local e continue encontrando seus arquivos.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORDLISTS_DIR="${SCRIPT_DIR}/wordlists"
# shellcheck disable=SC2034
DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}"
# shellcheck disable=SC2034
DEFAULT_COMMON_WORDLIST="${DEFAULT_WORDLISTS_DIR}/common.txt"

# função basica de print colorido, para evitar repetição de código.
color_print() {
  local color="$1"
  local message="$2"
  printf "%b%s%b\n" "$color" "$message" "$RESET"
}

# O timestamp evita sobrescrever resultados de execucoes anteriores.
# shellcheck disable=SC2034
data=$(date +%Y-%m-%d_%H:%M)


# Carregando modulos do script

for module in "${SCRIPT_DIR}"/.modules/*.sh; do
    # shellcheck disable=SC1090
    source "$module"
done

menu() {
  color_print "$GREEN" "1-Recon completo (Subfinder + Httpx + Nmap)"
  color_print "$PURPLE" "2-Usar Nuclei [ROOT NECESSÁRIO]"
  color_print "$YELLOW" "3-Usar SQLMap"
  color_print "$CYAN_LIGHT" "4-Achar informações no JavaScript"
  color_print "$BLUE" "5-procurar diretórios com Gobuster"
  color_print "$RED" "9-Mudar alvo"
  color_print "$YELLOW" "00-Sair"
  
}

javascript() {
  local target=$1
  # O getJS recebe a URL pela entrada padrao e lista recursos JavaScript
  # encontrados no alvo. Esta opcao nao cria arquivo de resultado.
  color_print "$GREEN" "[INFO] Coletando informações no JavaScript..."
  printf "%s" "${target}" | getJS
}


# Processa as opcoes de linha de comando -u e -h antes de abrir o menu.
url=""

while getopts "u:h" flag; do
  case "$flag" in
  h)
    printf "%bForma de uso: $0 -u %b<url>%b\n" "${GREEN_LIGHT}" "${CYAN_LIGHT}" "${RESET}"
    printf "-u      %bdefine a url inicial %b(ex: -u exemplo.com ou -u %bhttps://exemplo.com)%b\n" "${YELLOW_LIGHT}" "${BLUE_LIGHT}" "${BG_GREEN}" "${RESET}"
    printf "-h        %bmostra esse texto%b\n" "${PURPLE_LIGHT}" "${RESET}"
    exit 0
    ;;
  u)
    url=$OPTARG
    # Mantem a mesma normalizacao e validacao usada por resetar_url.
    if [[ ! "${url}" =~ ^https?:// ]]; then
      url="https://${url}"
    fi
     
    ;;
  ?)
    echo "Opção inválida. Use $0 -h para ajuda."
    exit 1
    ;;
  esac
done

# Sem um alvo inicial, nao ha operacao que possa ser executada.
if [[ -z "${url}" ]]; then
  color_print "$YELLOW" "A flag -u não pode ser vazia"
  color_print "$GREEN" "Use $0 -u <url ou dominio>"
  exit 1
fi

###########################################################################################################################
# Loop principal: mostra o menu e encaminha cada opcao para sua funcao.
###########################################################################################################################

while true; do
  menu
  color_print "$GREEN" "Digite o numero da opção que você quer:"
  read -r opcao
  case "$opcao" in
  1) recon_subdomains "${url}" ;;
  2) usar_nuclei "${url}" ;;
  3) usar_sqlmap "${url}" ;;
  4) javascript "${url}" ;;
  5) usar_gobuster "${url}" ;;
  9) resetar_url ;;
  00)
    color_print "$YELLOW" "Saindo do script. Até mais!"
    exit 0
    ;;
  *)
    printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
    ;;
  esac
done
