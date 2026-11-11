#!/usr/bin/env bash

resetar_url() {
  printf "%bDigite o %bDominio/Url %bque deseja analisar:%b\n" "$YELLOW" "$CYAN_LIGHT" "$YELLOW" "$RESET"
  local nova_url
  read -r nova_url

  if [[ "${nova_url}" != http://* && "${nova_url}" != https://* ]]; then
    printf "%b[ERRO]%b Informe uma URL iniciada por http:// ou https://.%b\n" "$RED" "$YELLOW" "$RESET"
    return 1
  fi

  # shellcheck disable=SC2034
  url="${nova_url}"
}
