#!/usr/bin/env bash

# Esse script contem pacotes extras que podem ser usados em conjunto com o recon.sh, mas nao sao obrigatorios.
# Esse script tem como objetivo preparar um ambiente mais completo de segurança ofensiva
# incluindo ferramentas adicionais que podem ser usadas para testes de penetração e análise de segurança.


# Estão inclusos pacotes de ferramentas como:


# linguagens de programação extra como node.js
# pacotes necessarios para configurar ambiente de CTF (Capture The Flag) como openvpn
# ferramentas que não foram colocadas no recon.sh, mas podem ser úteis para testes de penetração, como hydra, burpsuite, openssl, etc.



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

# Imprime uma mensagem com a cor informada e restaura a cor padrao.
color_print() {
  local color="$1"
  local message="$2"
  printf "%b%s%b\n" "$color" "$message" "$RESET"
}

# O restante do instalador depende de ferramentas e pacotes do GNU/Linux.
if [ "$(uname)" != "Linux" ]; then
  color_print "$GREEN_BOLD" "Você não está usando um sistema GNU/Linux ou similar. O script usa APT como instalador de pacotes. Certifique-se de estar numa distribuição baseada em Debian"
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
cd "${HOME}" || { color_print "$RED_BOLD" "Falha ao entrar na HOME do usuário"; exit 1; }
sudo apt update -y
sudo apt upgrade -y
sudo apt autoremove -y
# Instala os pacotes necessarios que ainda nao estiverem disponiveis.
color_print "$CYAN" "Instalando linguagens de programação e pacotes extras para testes de penetração..."
sleep 1

# Alterar aqui para adicionar ou remover pacotes da lista
pkg=(
  nodejs                              # Linguagem de programação para scripts e ferramentas
  npm                                 # Gerenciador de pacotes para Node.js
  git                                 # Controle de versão para clonar repositórios
  curl
  unzip                                  
  wget                              
  iputils-ping
  openssh-client                      # Cliente SSH para conexões remotas
  zsh                                 # Um bash melhorado
  htop                                # Melhor gerenciamento de processos
  cool-retro-term                     # Terminal mais elegante
  hydra                               # Quebra senhas
  burpsuite                           # Proxy web para manipulação de requisições
  openssl                             # Ferramenta de criptografia e certificados
  openvpn                             # Cliente VPN para conexões seguras e ctfs como: TryHackMe, HackTheBox, etc.
)

# Registra os erros do apt em um arquivo de log para que o usuário possa consultar posteriormente
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
    sudo apt install -y "${p}" 2>> "${DEFAULT_LOG_DIR}/pkginstall_extralogerror_${data}.txt" || printf "%b[✘] Erro ao instalar %s...%b\n" "$RED_BOLD" "$p" "$RESET"
  fi
done

###########################################################################################################################
# Instalação do VSCODE
###########################################################################################################################
printf "%bEscolha qual versão do VS Code deseja instalar:%b\n" "$CYAN_BOLD" "$RESET"
printf "%b1. VS Code Microsoft (Padrão da instalação) %b\n" "$GREEN_BOLD" "$RESET"
printf "%b2. Code-oss (Open Source) %b\n" "$GREEN_BOLD" "$RESET"
printf "%bEscolha uma opção(1 ou 2): %b\n" "$CYAN_BOLD" "$RESET"
read -r choice
case $choice in
  
  2)
    printf "%b[ * ] Instalando Code-oss (Open Source)...%b\n" "$YELLOW" "$RESET"
    color_print "$CYAN_BOLD" "Instalando Code-oss via APT..."
    sleep 1
    if command -v code-oss >/dev/null 2>&1; then # Evita baixar e instalar o Code-oss novamente se ja estiver instalado.
      printf "%b[✔] Code-oss já instalado.%b\n" "$GREEN_BOLD" "$RESET"
    else
      sudo apt install -y code-oss
      if command -v code-oss >/dev/null 2>&1; then
        printf "%b[✔] Code-oss instalado com sucesso.%b\n" "$GREEN_BOLD" "$RESET"
      else
        printf "%b[❌] Falha ao verificar Code-oss após instalação.%b\n" "$RED_BOLD" "$RESET"
      fi
    fi
    ;;
  *)
    printf "%b[ * ] Instalando VS Code (Microsoft)...%b\n" "$YELLOW" "$RESET"

    color_print "$CYAN_BOLD" "Instalando VS Code via .deb na pasta Downloads..."
    sleep 1
    if command -v code >/dev/null 2>&1; then # Evita baixar e instalar o VS Code novamente se ja estiver instalado.
      printf "%b[✔] VS Code já instalado.%b\n" "$GREEN_BOLD" "$RESET"
    else
      download_dir="${HOME}/Downloads"
      deb_file="${download_dir}/code_latest_amd64.deb"
      mkdir -p "${download_dir}"
      printf "%b[ * ] Baixando VS Code para %s...%b\n"  "$GREEN_LIGHT" "$download_dir" "$RESET"
      # Baixa o pacote do VS Code para Downloads antes de instala-lo com o apt.
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
    ;;
esac 


# O SecLists completo e opcional; as duas listas menores acima sao sempre baixadas.
if [ ! -d "SecLists" ]; then
  printf "%bDeseja instalar SecLists? (s/N)%b\n" "$CYAN_LIGHT" "$RESET"
  read -r opcao
  case "$opcao" in
  [sSyY]*) git clone https://github.com/danielmiessler/SecLists.git ;;
  *) printf "%bPulando SecLists%b\n" "$YELLOW_BOLD" "$RESET" ;;
  esac
fi

# Baixar e instalar Tool-X, uma ferramenta de instalação de outras ferramentas de segurança.
# Devido mudanças na instalação do Tool-X, o script agora baixa e executa diretamente o script de instalação oficial do Tool-X
# Instalando o Tool-X via CLI a partir do repositório oficial.
printf "%bInstalando %bTool-X%b\n" "$GREEN_BOLD" "$BLUE_BOLD" "$RESET"

if command -v tool-x >/dev/null 2>&1; then
  printf "%b[✔] Tool-X já instalado.%b\n" "$GREEN_BOLD" "$RESET"
else
  bash <(curl -s https://raw.githubusercontent.com/trmxvibs/Tool-X/main/setup.sh) || printf "%bFalha ao instalar Tool-X. Instale manualmente se necessário.%b\n" "$RED_BOLD" "$RESET"
fi

printf "%bInstalação de pacotes extras concluída.%b\n" "$GREEN_BOLD" "$RESET"
