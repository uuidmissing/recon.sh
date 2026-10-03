#!/usr/bin/env bash

nuclei() {
  # shellcheck disable=SC2154
  local target_url="${url}"
  local nuclei_bin="${HOME}/go/bin/nuclei"
  if [[ ! -x "${nuclei_bin}" ]]; then
    nuclei_bin="$(type -P nuclei 2>/dev/null || true)"
  fi
  if [[ -z "${nuclei_bin}" ]]; then
    printf "%b[ERRO] Nuclei não está instalado. Execute ./instalador_recon.sh e verifique as mensagens da instalação Go.%b\n" "$RED" "$RESET" >&2
    return 127
  fi

  local templates_root="${HOME}/nuclei-templates"
  local templates_dir=""

  printf "%bQuais templates quer usar?%b\n" "$YELLOW" "$RESET"
  printf "%b1-todos\n" "$GREEN"
  printf "2-exposures\n"
  printf "3-cves\n"
  printf "4-exposed panels\n"
  printf "5-fuzzing\n"
  printf "6-vulnerabilities%b\n" "$RESET"

  read -r template
  case "$template" in
  1) templates_dir="${templates_root}" ;;
  2) templates_dir="${templates_root}/http/exposures" ;;
  3) templates_dir="${templates_root}/http/cves" ;;
  4) templates_dir="${templates_root}/http/exposed-panels" ;;
  5) templates_dir="${templates_root}/http/fuzzing" ;;
  6) templates_dir="${templates_root}/http/vulnerabilities" ;;
  *)
    printf "%bOpção inválida %b%s%b\n" "$YELLOW" "$CYAN_LIGHT" "(╯°□°）╯︵┻━┻" "$RESET"
    return
    ;;
  esac

  if [[ ! -d "${templates_dir}" ]]; then
    printf "%b[ERRO] Diretório de templates não encontrado: %s%b\n" "$RED" "${templates_dir}" "$RESET" >&2
    printf "%bClone/atualize projectdiscovery/nuclei-templates em %s.%b\n" "$YELLOW" "${templates_root}" "$RESET" >&2
    return 1
  fi

  "${nuclei_bin}" -u "${target_url}" -t "${templates_dir}"
}
