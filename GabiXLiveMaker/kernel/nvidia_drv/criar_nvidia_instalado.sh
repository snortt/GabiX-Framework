#!/bin/bash
#
# Ferramenta para montar tarball a partir 
# do driver proprietário da nvidia.
#
# Gabriel Marques
# gabrielm@lncc.br
#

# --------------------------------
# Cores para o shell
RESET='\033[0m'
BRANCO='\033[39;1m'
VERMELHO='\033[31;1m'
VERDE='\033[32;1m'
AMARELO='\033[33;1m'
AZUL='\033[34;1m'
MAGENTA='\033[35;1m'
CIANO='\033[36;1m'
BRANCOB='\033[37;1m'

# -------------------------------
# Tema de cores 
# Cores usadas nas mensagens de texto ao longo do boot
# Se desejar criar temas, é aqui que você deve modificar.
TEXTO="$AZUL"
FORTE="$BRANCOB"
ADERECO="$AZUL"
DEV="$MAGENTA"
MOD="$MAGENTA"
ACERTO="$VERDE"
AVISO="$AMARELO"
ERRO="$VERMELHO"
SEPARADOR="$AMARELO"
APONTADOR="$VERMELHO"
EXEC_SHELL="$VERMELHO"

# -----------------------------
# Funções auxiliares
# Funcao que imprime mensagens de sucesso
printOK() {
    echo -e "$@ ${ADERECO}[${ACERTO}OK${ADERECO}]${RESET}"
}

# Funcao que imprime mensagens de erro
printError() {
    echo -e "$@ ${ADERECO}[${ERRO}Erro${ADERECO}]${RESET}"
}

# Funcao que imprime mensagens de aviso
printWarn() {
    echo -e "$@ ${ADERECO}[${AVISO}Aviso${ADERECO}]${RESET}"
}

# Funcao que imprime mensagens
printMsg() {
    echo -e "${TEXTO}$@ ${RESET}"
}

# Vamos ajutar a ferramenta a encontrar seus recursos.
export NV_LIVE_DIR="${PWD}"

# Defina aqui o identificador de placas NVidia.
export NVID="10de:"

# Algumas definições iniciais.
# Arquivo de controle temporal. Psicodélico isso, não acha? ;-)
time_machine="time_machine"

if [ "$#" -ne "1" ]; then
	printError "Uso: ${0##*/} <driver_nvidia.run>"
	exit 201
fi

ver_tmp="$(stat -c %n $1 | cut -d "-" -f4)"
arch_drv="$(stat -c %n $1 | cut -d "-" -f3)"
ver_drv="$(echo ${ver_tmp%.*})"

case $arch_drv in
	"x86")    
		libs="/lib"
		BASE="nv_live_x86"
		LOADER_FILE="${NV_LIVE_DIR}/${BASE}/carregar_nv_drv.sh"
		DEPS="libc6-dev libc6-$(uname -m) build-essential"
		;;

	"x86_64") 
		libs="/lib /lib32 "
		BASE="nv_live_x86_64"
		LOADER_FILE="${NV_LIVE_DIR}/${BASE}/carregar_nv_drv.sh"
		DEPS="libc6-dev build-essential"
	   	;;
esac


printMsg "Instalando dependências do sistema"
apt-get --reinstall install ${DEPS} 2> /dev/null &&	printOK || printError

# Tipos de arquivos procurados para inclusão no pacote.
# Bloco, Caractere, FIFO, Comum, Link, Socket.
TIPOS="b c p f l s"

# Locais de busca
LOCAIS="/etc /bin /sbin /usr /dev /var ${libs}"

# Nome do arquivo de saída
NOME_DRV="Nvidia-${ver_drv}_${arch_drv}_$(uname -r).tar.bz2"

# Arquivo usado para construir o carregador
LOADER_FILE_TEMPLATE="${NV_LIVE_DIR}/carregar_nv_drv.sh.template"

printMsg "----------------------------------------------"
printMsg " Empacotador do driver da Nvidia para o GabiX "
printMsg "----------------------------------------------"
printMsg " "
printMsg "Arquivo de driver: ${AVISO}$(basename ${1}) ${TEXTO}"
printMsg "Versao do driver: ${ACERTO}$ver_drv${TEXTO}"
printMsg "Arquitetura do driver: ${ACERTO}$arch_drv${TEXTO}"
printMsg "Arquivo para o GabiX: ${DEV}$NOME_DRV${TEXTO}"

# Uma vez feitas as apresentações, vamos (tentar) instalar o driver fornecido.
chmod +x ${1}
rm -f ${time_machine} 2> /dev/null
printMsg "Controle cronológico para o empacotador do driver" > $time_machine
printMsg "Instalando os arquivos e compilando o driver (pode demorar alguns minutos)."
printWarn "Por favor aguarde. "
bash ${1} -sq

#
# Agora vamos procurar tudo o que mudou. 
# A partir daí, criamos o nosso próprio pacote de driver! =)
#
printMsg "Procurando arquivos do driver no sistema"
LISTA=""
for tipo in ${TIPOS}
do
	printMsg "Procurando por arquivos do tipo ${DEV}$tipo ${TEXTO}"
   	LISTA="$LISTA $(find ${LOCAIS} -type ${tipo} -newer ${time_machine} -print0 | xargs -0)"
done
export LISTA

# 
# Uma vez instalado, vamos tentar empacotar tudo novamente.
printMsg "Empacotando arquivos do driver"
tar cjf ${NV_LIVE_DIR}/${BASE}/${NOME_DRV} ${LISTA} > /dev/null 2>&1 && printOK || printError

#
# Agora vamos inserir o nome do pacote no carregador do live CD
printMsg "Inserindo arquivo de driver no carregador."
(cat ${LOADER_FILE_TEMPLATE} | sed s/"__NOME_DRIVER__/${NOME_DRV}"/g > ${LOADER_FILE}) && printOK || printError

unset LISTA

