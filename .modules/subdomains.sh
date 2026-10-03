#!/usr/bin/env bash

recon_subdomains() {
  # Cada ferramenta possui sua propria pasta de resultados dentro da raiz
  # do script, mantendo os dados junto do clone movel do projeto.
  httpx_dir="${DEFAULT_OUTPUT_DIR}/httpx_results"
  subfinder_dir="${DEFAULT_OUTPUT_DIR}/subfinder_results"
  nmap_dir="${DEFAULT_OUTPUT_DIR}/nmap_results"
  mkdir -p "$httpx_dir" "$subfinder_dir" "$nmap_dir"

  # Remove o protocolo e qualquer caminho para obter apenas o dominio usado
  # pelo Subfinder e tambem nos nomes dos arquivos de resultado.
  # shellcheck disable=SC2154
  domain="${url#*://}"
  domain="${domain%%/*}"

  # shellcheck disable=SC2154
  httpx_output="${httpx_dir}/${domain}._${data}txt"
  subfinder_output="${subfinder_dir}/${domain}_${data}.txt"
  nmap_output="${nmap_dir}/${domain}_${data}.txt"

  # Pipeline principal: o Subfinder descobre subdominios, o Httpx filtra os
  # que respondem e o Gau coleta URLs publicas relacionadas a esses hosts.
  # O tee exibe a saida no terminal e tambem salva uma copia em arquivo.
  color_print "$GREEN" "[INFO] Rodando Subfinder..."
  subfinder -d "$domain" -silent | tee "$subfinder_output"

  color_print "$GREEN" "[INFO] Rodando Httpx e Gau..."
  cat "$subfinder_output" | httpx -silent | tee "$httpx_output"

  # O primeiro Nmap usa sudo para permitir todos os tipos de verificacao.
  # Se nao houver permissao, repete a coleta em modo sem privilegios.
  color_print "$GREEN" "[INFO] Rodando Nmap..."
  if ! sudo nmap -T4 -F -sV -iL "$subfinder_output" -oN "$nmap_output"; then
    color_print "$YELLOW" "[WARNING] Nmap falhou, tentando modo unprivileged..."
    nmap --unprivileged -T4 -F -sV -iL "$subfinder_output" -oN "${nmap_output%.txt}_unprivileged.txt"
  fi

  color_print "$GREEN" "[OK] Recon completo. Diretórios de saída:"
  color_print "$GREEN" " - Subfinder: $subfinder_dir"
  color_print "$GREEN" " - Httpx: $httpx_dir"
  color_print "$GREEN" " - Nmap: $nmap_dir"
}


 
  