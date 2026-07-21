# recon.sh

Scripts para configurar um ambiente de *recon* (ferramentas Go, VScode, e repositórios de estudo em PT-BR) pensado para uso em Kali Linux (ex.: VirtualBox).
script com automação basica de algumas ferramentas incluso(subfinder, httpx, gau, nuclei)

> Observação: o script pede `sudo` durante a execução (ele não precisa ser executado usando o usuario root — ele usa o proprio usuario root mesmo que você execute por um usuario padrão. apenas garanta que tenha uma usuario Root)

> ## O scripts ja vem com chmod 700, mas se não funcionar:

```bash
git clone https://github.com/uuidmissing/recon.sh
cd recon.sh
chmod +x instalador_recon.sh
./instalador_recon.sh


