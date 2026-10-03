#!/usr/bin/env bash

resetar_url() {
  printf "%bDigite o %bDominio/Url %bque deseja analisar:%b\n" "$YELLOW" "$CYAN_LIGHT" "$YELLOW" "$RESET"
  read -r url

  if [[ -z "${url}" ]]; then
    printf "%b[ERRO]%b URL vazia.%b\n" "$RED" "$YELLOW" "$RESET"
    return 1
  fi

  # Normaliza entradas sem protocolo para que todas as funcoes recebam uma
  # URL completa.
 if [[ ! "${url}" =~ ^https?:// ]]; then
      url="https://${url}"
 fi

}