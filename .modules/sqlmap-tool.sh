#!/usr/bin/env bash

usar_sqlmap() {
  local target=$1
  # Local de saída dos resultados do SQLMap, dentro da pasta de resultados do script.
  sqlmap_dir="${DEFAULT_OUTPUT_DIR}/sqlmap_results"
  
  if [[ ! -d "$sqlmap_dir" ]]; then
    mkdir -p "$sqlmap_dir"
  fi

  # Flag --batch evita que o SQLMap pergunte ao usuario durante a execucao.
  # Flag --random-agent faz o SQLMap usar um user-agent aleatorio a cada requisicao.
  # Flag --flush-session limpa o cache de sessões do SQLMap para evitar resultados antigos.
  # Flag --output-dir define o diretório onde os resultados serão salvos.
  # shellcheck disable=SC2154
  sqlmap -u "${target}" --batch --crawl=1 --random-agent --output-dir="${sqlmap_dir}" --flush-session

}