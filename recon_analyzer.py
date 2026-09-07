#!/usr/bin/env python3
"""Organiza resultados coletados pelo recon.sh.

Essa ferramenta analisa os resultados das ferramentas de reconhecimento e gera um relatório consolidado em formato JSON e Markdown. 
O relatório inclui informações sobre subdomínios, URLs, hosts encontrados, portas abertas, caminhos encontrados e arquivos analisados.
"""

from __future__ import annotations

import argparse
import json
import re
from collections import Counter
from dataclasses import asdict, dataclass, field
from datetime import datetime, timezone
from pathlib import Path
from typing import Iterable
from urllib.parse import urlparse


RESULT_DIRECTORIES = (
    "subfinder_results",
    "gau_results",
    "nmap_results",
    "gobuster_results",
    "ffuf_results",
)
TEXT_SUFFIXES = {".txt", ".log", ".out"}
URL_PATTERN = re.compile(r"https?://[^\s\"'<>]+", re.IGNORECASE)
NMAP_HOST_PATTERN = re.compile(
    r"Nmap scan report for (.+?)(?: \(([^)]+)\))?$", re.IGNORECASE
)
NMAP_PORT_PATTERN = re.compile(
    r"^(\d+)/(tcp|udp)\s+(\S+)\s+(\S+)(?:\s+(.*))?$", re.IGNORECASE
)
GOBUSTER_STATUS_PATTERN = re.compile(r"\[Status:\s*(\d{3})\]", re.IGNORECASE)
GOBUSTER_PATH_PATTERN = re.compile(r"^(/\S+)")


@dataclass
class SourceFile:
    tool: str
    path: str
    lines: int


@dataclass
class Report:
    generated_at: str
    root: str
    source_files: list[SourceFile] = field(default_factory=list)
    subdomains: list[str] = field(default_factory=list)
    urls: list[str] = field(default_factory=list)
    url_hosts: list[str] = field(default_factory=list)
    nmap_hosts: list[str] = field(default_factory=list)
    nmap_ports: list[dict[str, str]] = field(default_factory=list)
    gobuster_paths: list[dict[str, str]] = field(default_factory=list)
    status_codes: dict[str, int] = field(default_factory=dict)
    file_errors: list[str] = field(default_factory=list)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="Analisa e organiza resultados gerados pelo recon.sh."
    )
    parser.add_argument(
        "--root",
        type=Path,
        default=Path(__file__).resolve().parent,
        help="Diretorio que contem as pastas *_results (padrao: local do script).",
    )
    parser.add_argument(
        "--output-dir",
        type=Path,
        help="Pasta dos relatorios (padrao: <root>/analysis_results).",
    )
    return parser.parse_args()


def read_lines(path: Path) -> list[str]:
    return path.read_text(encoding="utf-8", errors="replace").splitlines()


def result_files(root: Path) -> Iterable[tuple[str, Path]]:
    for tool in RESULT_DIRECTORIES:
        directory = root / tool
        if not directory.is_dir():
            continue
        for path in sorted(directory.rglob("*")):
            if path.is_file() and (path.suffix.lower() in TEXT_SUFFIXES or path.suffix == ".json"):
                yield tool.removesuffix("_results"), path


def unique_sorted(values: Iterable[str]) -> list[str]:
    return sorted({value for value in values if value})


def normalize_host(value: str) -> str:
    candidate = value.strip().rstrip(".,]")
    if "://" in candidate:
        candidate = urlparse(candidate).hostname or candidate
    return candidate.lower().rstrip(".")


def extract_urls(lines: Iterable[str]) -> list[str]:
    urls = []
    for line in lines:
        for match in URL_PATTERN.findall(line):
            urls.append(match.rstrip(".,;)]\"'"))
    return urls


def parse_nmap(lines: Iterable[str], report: Report) -> None:
    current_host = ""
    for line in lines:
        host_match = NMAP_HOST_PATTERN.search(line)
        if host_match:
            current_host = normalize_host(host_match.group(1))
            report.nmap_hosts.append(current_host)
            continue

        port_match = NMAP_PORT_PATTERN.match(line.strip())
        if port_match:
            port, protocol, state, service, version = port_match.groups()
            report.nmap_ports.append(
                {
                    "host": current_host,
                    "port": port,
                    "protocol": protocol.lower(),
                    "state": state.lower(),
                    "service": service,
                    "version": (version or "").strip(),
                }
            )


def parse_gobuster(lines: Iterable[str], report: Report) -> None:
    for line in lines:
        status_match = GOBUSTER_STATUS_PATTERN.search(line)
        path_match = GOBUSTER_PATH_PATTERN.match(line.strip())
        if not status_match or not path_match:
            continue
        status = status_match.group(1)
        report.gobuster_paths.append({"path": path_match.group(1), "status": status})
        report.status_codes[status] = report.status_codes.get(status, 0) + 1


def parse_ffuf(path: Path, report: Report) -> None:
    try:
        payload = json.loads(path.read_text(encoding="utf-8", errors="replace"))
    except (OSError, json.JSONDecodeError) as error:
        report.file_errors.append(f"{path}: {error}")
        return

    for result in payload.get("results", []):
        status = str(result.get("status", ""))
        url = str(result.get("url", ""))
        if url:
            report.gobuster_paths.append({"path": url, "status": status})
        if status:
            report.status_codes[status] = report.status_codes.get(status, 0) + 1


def analyze(root: Path) -> Report:
    report = Report(
        generated_at=datetime.now(timezone.utc).isoformat(),
        root=str(root.resolve()),
    )
    all_subdomains: list[str] = []
    all_urls: list[str] = []
    all_url_hosts: list[str] = []

    for tool, path in result_files(root):
        try:
            lines = read_lines(path)
        except OSError as error:
            report.file_errors.append(f"{path}: {error}")
            continue

        report.source_files.append(SourceFile(tool=tool, path=str(path), lines=len(lines)))
        if tool == "subfinder":
            all_subdomains.extend(normalize_host(line) for line in lines if line.strip())
        elif tool == "gau":
            urls = extract_urls(lines)
            all_urls.extend(urls)
            all_url_hosts.extend(normalize_host(url) for url in urls)
        elif tool == "nmap":
            parse_nmap(lines, report)
        elif tool == "gobuster":
            parse_gobuster(lines, report)
        elif tool == "ffuf" and path.suffix.lower() == ".json":
            parse_ffuf(path, report)

    report.subdomains = unique_sorted(all_subdomains)
    report.urls = unique_sorted(all_urls)
    report.url_hosts = unique_sorted(all_url_hosts)
    report.nmap_hosts = unique_sorted(report.nmap_hosts)
    report.nmap_ports.sort(key=lambda item: (item["host"], int(item["port"]), item["protocol"]))
    report.gobuster_paths.sort(key=lambda item: (item["status"], item["path"]))
    report.status_codes = dict(sorted(report.status_codes.items()))
    return report


def markdown_report(report: Report) -> str:
    open_ports = [port for port in report.nmap_ports if port["state"] == "open"]
    lines = [
        "# Recon Analysis",
        "",
        f"- Gerado em: `{report.generated_at}`",
        f"- Raiz dos resultados: `{report.root}`",
        "",
        "## Resumo",
        "",
        f"- Arquivos lidos: **{len(report.source_files)}**",
        f"- Subdominios unicos: **{len(report.subdomains)}**",
        f"- URLs unicas: **{len(report.urls)}**",
        f"- Hosts encontrados nas URLs: **{len(report.url_hosts)}**",
        f"- Hosts vistos no Nmap: **{len(report.nmap_hosts)}**",
        f"- Portas abertas: **{len(open_ports)}**",
        f"- Caminhos encontrados: **{len(report.gobuster_paths)}**",
        "",
        "## Subdominios",
        "",
    ]
    lines.extend(f"- `{item}`" for item in report.subdomains or ["Nenhum resultado."])
    lines.extend(["", "## Hosts das URLs", ""])
    lines.extend(f"- `{item}`" for item in report.url_hosts or ["Nenhum resultado."])
    lines.extend(["", "## Portas abertas", "", "| Host | Porta | Servico | Versao |", "| --- | ---: | --- | --- |"])
    lines.extend(
        f"| `{item['host']}` | {item['port']}/{item['protocol']} | {item['service']} | {item['version'] or '-'} |"
        for item in open_ports
    )
    if not open_ports:
        lines.append("| - | - | Nenhum resultado | - |")
    lines.extend(["", "## Caminhos encontrados", "", "| Status | Caminho |", "| ---: | --- |"])
    lines.extend(f"| {item['status']} | `{item['path']}` |" for item in report.gobuster_paths)
    if not report.gobuster_paths:
        lines.append("| - | Nenhum resultado |")
    lines.extend(["", "## Arquivos analisados", "", "| Ferramenta | Arquivo | Linhas |", "| --- | --- | ---: |"])
    lines.extend(f"| {item.tool} | `{item.path}` | {item.lines} |" for item in report.source_files)
    if report.file_errors:
        lines.extend(["", "## Erros de leitura", ""])
        lines.extend(f"- `{error}`" for error in report.file_errors)
    return "\n".join(lines) + "\n"


def write_reports(report: Report, output_dir: Path) -> tuple[Path, Path]:
    output_dir.mkdir(parents=True, exist_ok=True)
    json_path = output_dir / "recon_report.json"
    markdown_path = output_dir / "recon_report.md"
    payload = asdict(report)
    payload["source_files"] = [asdict(item) for item in report.source_files]
    json_path.write_text(json.dumps(payload, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    markdown_path.write_text(markdown_report(report), encoding="utf-8")
    return markdown_path, json_path


def main() -> int:
    args = parse_args()
    root = args.root.expanduser().resolve()
    output_dir = (args.output_dir or root / "analysis_results").expanduser().resolve()
    report = analyze(root)
    markdown_path, json_path = write_reports(report, output_dir)

    print(f"Arquivos analisados: {len(report.source_files)}")
    print(f"Subdominios: {len(report.subdomains)} | URLs: {len(report.urls)}")
    print(f"Relatorio Markdown: {markdown_path}")
    print(f"Relatorio JSON: {json_path}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())