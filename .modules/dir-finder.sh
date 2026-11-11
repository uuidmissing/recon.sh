#!/usr/bin/env bash

usar_gobuster() {

  local target=$1
  local target_url="${target}"
  local target_label=""
  # O resultado fica junto do script; a wordlist, por padrao, vem da pasta
  # local de wordlists, mas o usuario pode informar outro caminho.
  if [[ ! "${target_url}" =~ ^https?:// ]]; then
    target_url="https://${target_url}"
  fi

  # O nome do arquivo usa a URL completa, mas troca caracteres que nao podem
  # fazer parte de um nome de arquivo por underscores.
  target_label="${target_url//[^a-zA-Z0-9._-]/_}"
  # shellcheck disable=SC2154
  local gobuster_dir="${DEFAULT_OUTPUT_DIR}/gobuster_results"
  # shellcheck disable=SC2154
  local gobuster_out="${gobuster_dir}/${target_label}_${data}.txt"
  local wordlist="${DEFAULT_COMMON_WORDLIST}"
  local user_wordlist=""
  local opcao=""

  if [[ ! -d "${gobuster_dir}" ]]; then
    mkdir -p "${gobuster_dir}"
  else
    printf "%b[=] Diretório %s já existe e está pronto para uso%b\n" "$YELLOW" "${gobuster_dir}" "$RESET"
  fi

  if [[ ! -f "${wordlist}" ]]; then
    printf "%b[AVISO]%b A lista padrão não foi encontrada em %s. Rode o instalador novamente ou coloque uma wordlist manualmente.%b\n" "$YELLOW" "$RESET" "$wordlist" "$RESET"
  fi

  printf "%bPreparando Gobuster em  %b%s%b\n" "$YELLOW" "$GREEN" "${target_url}" "$RESET"
  printf "%b[1] %bcommon.txt%b --- Lista Padrão\n" "$GREEN" "$YELLOW" "$RESET"
  printf "%b[2] %blista personalizada --- Informe o PATH. EX: %b%s%b\n" "$GREEN" "$YELLOW" "$GREEN" "${wordlist}" "$RESET"

  read -r opcao

  case "$opcao" in
  1) gobuster dir -u "${target_url}" -w "${wordlist}" -r -t 5 --delay 500ms -b "403,404,406,429" -o "${gobuster_out}" ;;
  2)
    printf "%bInforme a lista que quer usar%b:\n" "$YELLOW" "$RESET"
    read -r user_wordlist
    gobuster dir -u "${target_url}" -w "${user_wordlist}" -r -t 5 --delay 500ms -b "403,404,406,429" -o "${gobuster_out}"
    ;;
  *)
    printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
    return
    ;;
  esac
}
