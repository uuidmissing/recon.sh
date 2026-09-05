# recon.sh

Scripts para configurar um ambiente de *recon* (ferramentas Go, VScode, e repositórios de estudo em PT-BR) pensado para uso em Kali Linux (ex.: VirtualBox).
script com automação basica de algumas ferramentas incluso(subfinder, httpx, gau, nuclei)

## Analise dos resultados

O script Bash continua responsavel por executar as ferramentas. Para organizar
os resultados coletados sem executar uma nova varredura, use o analisador
Python:

```bash
python3 recon_analyzer.py
```

Ele procura as pastas `*_results` ao lado do proprio arquivo e cria:

- `analysis_results/recon_report.md`, para leitura humana;
- `analysis_results/recon_report.json`, para processamento posterior.

Tambem e possivel analisar uma copia dos resultados em outro local:

```bash
python3 recon_analyzer.py --root /caminho/dos/resultados --output-dir /caminho/do/relatorio
```

O analisador consolida subdominios, URLs, hosts, portas abertas do Nmap e
caminhos encontrados pelo Gobuster ou FFUF. Ele nao executa ferramentas de
reconhecimento nem substitui as instrucoes especificas de instalacao delas.

> Observação: o script pede `sudo` durante a execução (ele não precisa ser executado usando o usuario root — ele usa o proprio usuario root mesmo que você execute por um usuario padrão. apenas garanta que tenha uma usuario Root)

> ## O scripts ja vem com chmod 700, mas se não funcionar:

```bash
git clone https://github.com/uuidmissing/recon.sh
cd recon.sh
chmod +x instalador_recon.sh
./instalador_recon.sh


