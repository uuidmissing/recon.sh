#!/usr/bin/env bash

# Cores ANSI usadas nas mensagens do menu e da execucao.
YELLOW="\u001B[93m"
CYAN_LIGHT="\u001B[96m"
GREEN="\u001B[92m"
PURPLE="\u001B[95m"
RED="\u001B[91m"
BLUE="\u001B[94m"
RESET="\u001B[0m"

############################################################################################################################
# Configuracao de caminhos
############################################################################################################################
# Usa o diretorio deste arquivo como raiz para que o script possa ser
# executado de qualquer local e continue encontrando seus arquivos.
SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
DEFAULT_WORDLISTS_DIR="${SCRIPT_DIR}/wordlists"
DEFAULT_OUTPUT_DIR="${SCRIPT_DIR}"
DEFAULT_COMMON_WORDLIST="${DEFAULT_WORDLISTS_DIR}/common.txt"
DEFAULT_XSS_WORDLIST="${DEFAULT_WORDLISTS_DIR}/XSS-Cheat-Sheet-PortSwigger.txt"

color_print() {
  local color="$1"
  local message="$2"
  printf "%b%s%b\n" "$color" "$message" "$RESET"
}

# O timestamp evita sobrescrever resultados de execucoes anteriores.
data=$(date +%Y-%m-%d_%H:%M)



menu() {
  color_print "$GREEN" "1-Recon completo (Subfinder + Httpx + Gau + Nmap)"
  color_print "$PURPLE" "2-Usar Nuclei [ROOT NECESSÁRIO]"
  color_print "$YELLOW" "3-Usar SQLMap"
  color_print "$CYAN_LIGHT" "4-Achar informações no JavaScript"
  color_print "$BLUE" "5-procurar diretórios com Gobuster"
  color_print "$RED" "9-Mudar alvo"
  color_print "$YELLOW" "00-Sair"
  
}

recon_all() {
  # Cada ferramenta possui sua propria pasta de resultados dentro da raiz
  # do script, mantendo os dados junto do clone movel do projeto.
  gau_dir="${DEFAULT_OUTPUT_DIR}/gau_results"
  subfinder_dir="${DEFAULT_OUTPUT_DIR}/subfinder_results"
  nmap_dir="${DEFAULT_OUTPUT_DIR}/nmap_results"
  mkdir -p "$gau_dir" "$subfinder_dir" "$nmap_dir"

  # Remove o protocolo e qualquer caminho para obter apenas o dominio usado
  # pelo Subfinder e tambem nos nomes dos arquivos de resultado.
  domain="${url#*://}"
  domain="${domain%%/*}"

  gau_output="${gau_dir}/${domain}._${data}txt"
  subfinder_output="${subfinder_dir}/${domain}_${data}.txt"
  nmap_output="${nmap_dir}/${domain}_${data}.txt"

  # Pipeline principal: o Subfinder descobre subdominios, o Httpx filtra os
  # que respondem e o Gau coleta URLs publicas relacionadas a esses hosts.
  # O tee exibe a saida no terminal e tambem salva uma copia em arquivo.
  color_print "$GREEN" "[INFO] Rodando Subfinder..."
  subfinder -d "$domain" -silent | tee "$subfinder_output"

  color_print "$GREEN" "[INFO] Rodando Httpx e Gau..."
  cat "$subfinder_output" | httpx -silent | gau | tee "$gau_output"

  # O primeiro Nmap usa sudo para permitir todos os tipos de verificacao.
  # Se nao houver permissao, repete a coleta em modo sem privilegios.
  color_print "$GREEN" "[INFO] Rodando Nmap..."
  if ! sudo nmap -T4 -F -sV -iL "$subfinder_output" -oN "$nmap_output"; then
    color_print "$YELLOW" "[WARNING] Nmap falhou, tentando modo unprivileged..."
    nmap --unprivileged -T4 -F -sV -iL "$subfinder_output" -oN "${nmap_output%.txt}_unprivileged.txt"
  fi

  color_print "$GREEN" "[OK] Recon completo. Diretórios de saída:"
  color_print "$GREEN" " - Subfinder: $subfinder_dir"
  color_print "$GREEN" " - Gau: $gau_dir"
  color_print "$GREEN" " - Nmap: $nmap_dir"
}

javascript() {
  # O getJS recebe a URL pela entrada padrao e lista recursos JavaScript
  # encontrados no alvo. Esta opcao nao cria arquivo de resultado.
  color_print "$GREEN" "[INFO] Coletando informações no JavaScript..."
  printf "%s" "${url}" | getJS
}

nuclei() {
  printf "%bQuais templates quer usar?%b\n" "$YELLOW" "$RESET"
  printf "%b1-todos\n" "$GREEN"
  printf "2-exposures\n"
  printf "3-cves\n"
  printf "4-exposed panels\n"
  printf "5-fuzzing\n"
  printf "6-vulnerabilities%b\n" "$RESET"

  read -r template
  # Os templates sao instalados separadamente pelo instalador em HOME.
  # A opcao escolhida define qual subdiretorio de templates sera usado.
  case "$template" in
  1) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates" ;;
  2) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposures" ;;
  3) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/cves" ;;
  4) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/exposed-panels" ;;
  5) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/fuzzing" ;;
  6) "$HOME/go/bin/nuclei" -u "${url}" -t "${HOME}/nuclei-templates/vulnerabilities" ;;
  *)
    printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
    return
    ;;
  esac
}

usar_sqlmap() {
  # Local de saída dos resultados do SQLMap, dentro da pasta de resultados do script.
  sqlmap_dir="${DEFAULT_OUTPUT_DIR}/sqlmap_results"
  
  if [[ ! -d "$sqlmap_dir" ]]; then
    mkdir -p "$sqlmap_dir"
  fi

  # Flag --batch evita que o SQLMap pergunte ao usuario durante a execucao.
  # Flag --random-agent faz o SQLMap usar um user-agent aleatorio a cada requisicao.
  # Flag --flush-session limpa o cache de sessões do SQLMap para evitar resultados antigos.
  # Flag --output-dir define o diretório onde os resultados serão salvos.
  sqlmap -u "${url}" --batch --crawl=1 --random-agent --output-dir="${sqlmap_dir}" --flush-session 

}

usar_gobuster() {

  # O resultado fica junto do script; a wordlist, por padrao, vem da pasta
  # local de wordlists, mas o usuario pode informar outro caminho.
  gobuster_url="${url#*://}"
  gobuster_dir="${DEFAULT_OUTPUT_DIR}/gobuster_results"
  gobuster_out="${gobuster_dir}/${gobuster_url}_${data}.txt"
  local wordlist="${DEFAULT_COMMON_WORDLIST}"
  local user_wordlist=""
  local opcao=""

  if [[ ! -d "$gobuster_dir" ]]; then
    mkdir -p "$gobuster_dir"
  else
    printf "%b[=] Diretório %s já existe e está pronto para uso%b\n" "$YELLOW" "$gobuster_dir" "$RESET"
  fi

  if [[ ! -f "$wordlist" ]]; then
    printf "%b[AVISO]%b A lista padrão não foi encontrada em %s. Rode o instalador novamente ou coloque uma wordlist manualmente.%b\n" "$YELLOW" "$RESET" "$wordlist" "$RESET"
  fi

  printf "%bPreparando Gobuster em  %bhttps://%s%b\n" "$YELLOW" "$GREEN" "$gobuster_url" "$RESET"
  printf "%b[1] %bcommon.txt%b --- Lista Padrão\n" "$GREEN" "$YELLOW" "$RESET"
  printf "%b[2] %blista personalizada --- Informe o PATH. EX: %b%s%b\n" "$GREEN" "$YELLOW" "$GREEN" "$wordlist" "$RESET"

  read -r opcao

  case "$opcao" in
  1) gobuster dir -u "https://${gobuster_url}" -w "$wordlist" -r -t 5 --delay 500ms -b "403,404,406,429" -o "$gobuster_out" ;;
  2)
    printf "%bInforme a lista que quer usar%b:\n" "$YELLOW" "$RESET"
    read -r user_wordlist
    gobuster dir -u "https://${gobuster_url}" -w "$user_wordlist" -r -t 5 --delay 500ms -b "403,404,406,429" -o "$gobuster_out"
    ;;
  *)
    printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
    return
    ;;
  esac
}

resetar_url() {
  printf "%bDigite o %bDominio/Url %bque deseja analisar:%b\n" "$YELLOW" "$CYAN_LIGHT" "$YELLOW" "$RESET"
  read -r url

  if [[ -z "${url}" ]]; then
    printf "%b[ERRO]%b URL vazia.%b\n" "$RED" "$YELLOW" "$RESET"
    return 1
  fi

  # Normaliza entradas sem protocolo para que todas as funcoes recebam uma
  # URL completa.
  if [[ "${url}" != https://* && "${url}" != http://* ]]; then
    url="https://${url}"
  fi

  # Valida o protocolo, o nome do dominio e um sufixo de dominio com pelo
  # menos duas letras.
  if [[ "${url}" =~ ^https?://([A-Za-z0-9.-]+.[A-Za-z]{2,})(/.*)?$ ]]; then
    printf "%bAtualmente analisando o link: %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "${url}" "$RESET"
    return 0
  else
    printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
    return 2
  fi
}

# Processa as opcoes de linha de comando -u e -h antes de abrir o menu.
url=""

while getopts "u:h" flag; do
  case "$flag" in
  h)
    echo "Forma de uso: $0 -u <url>"
    echo "-u      define a url inicial (ex: -u exemplo.com ou -u https://exemplo.com)"
    echo "-h      mostra esse texto"
    exit 0
    ;;
  u)
    url=$OPTARG
    # Mantem a mesma normalizacao e validacao usada por resetar_url.
    if [[ "${url}" != https://* && "${url}" != http://* ]]; then
      url="https://${url}"
    fi
    if [[ ! "${url}" =~ ^https?://([A-Za-z0-9.-]+.[A-Za-z]{2,})(/.*)?$ ]]; then
      printf "%b[ERRO]%b Dominio ou subdominio %s invalido.%b\n" "$RED" "$YELLOW" "${url}" "$RESET"
      exit 2
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
  1) recon_all ;;
  2) nuclei ;;
  3) usar_sqlmap ;;
  4) javascript ;;
  5) usar_gobuster ;;
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
