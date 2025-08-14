#!/bin/bash

#==============================================================================
# Script para Instalar o Oracle VM VirtualBox no Debian 12
#
# DESCRIÇÃO: Este script automatiza o processo de adição do repositório
#            oficial do VirtualBox, importação das chaves GPG, instalação
#            do VirtualBox e do Extension Pack.
#
# AUTOR:      Seu Nome
# DATA:       15 de Agosto de 2025
# VERSÃO:     1.0
#==============================================================================

# ---[ Funções de Utilidade ]---

# Função para imprimir mensagens de sucesso
print_success() {
  echo -e "\e[32m[SUCESSO]\e[0m $1"
}

# Função para imprimir mensagens de erro e sair
print_error() {
  echo -e "\e[31m[ERRO]\e[0m $1" >&2
  exit 1
}

# ---[ Verificação de Privilégios de Superusuário ]---

if [ "$(id -u)" -ne 0 ]; then
  print_error "Este script precisa ser executado com privilégios de superusuário (root). Use 'sudo'."
fi

# ---[ Instalação de Dependências ]---

echo ">>> Instalando dependências necessárias..."
apt-get update && apt-get install -y wget gpg
if [ $? -ne 0 ]; then
  print_error "Falha ao instalar as dependências."
fi
print_success "Dependências instaladas."

# ---[ Adicionando as Chaves GPG do Repositório Oracle ]---

echo ">>> Importando as chaves GPG da Oracle..."
wget -O- https://www.virtualbox.org/download/oracle_vbox_2016.asc | gpg --dearmor --yes --output /usr/share/keyrings/oracle-virtualbox-2016.gpg
if [ $? -ne 0 ]; then
  print_error "Falha ao importar as chaves GPG."
fi
print_success "Chaves GPG da Oracle importadas."

# ---[ Adicionando o Repositório do VirtualBox ]---

echo ">>> Adicionando o repositório do VirtualBox para o Debian $(lsb_release -cs)..."
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/oracle-virtualbox-2016.gpg] https://download.virtualbox.org/virtualbox/debian $(lsb_release -cs) contrib" | tee /etc/apt/sources.list.d/virtualbox.list
if [ $? -ne 0 ]; then
  print_error "Falha ao adicionar o repositório do VirtualBox."
fi
print_success "Repositório do VirtualBox adicionado."

# ---[ Atualização da Lista de Pacotes ]---

echo ">>> Atualizando a lista de pacotes..."
apt-get update
if [ $? -ne 0 ]; then
  print_error "Falha ao atualizar a lista de pacotes."
fi
print_success "Lista de pacotes atualizada."

# ---[ Instalação do VirtualBox ]---

# Obtém a versão mais recente do VirtualBox disponível no repositório
VBOX_LATEST_VERSION=$(apt-cache search virtualbox | grep -oP 'virtualbox-\d\.\d' | sort -V | tail -n 1)

if [ -z "$VBOX_LATEST_VERSION" ]; then
  print_error "Não foi possível encontrar uma versão do VirtualBox para instalar. Verifique o repositório."
fi

echo ">>> Instalando o ${VBOX_LATEST_VERSION}..."
apt-get install -y "${VBOX_LATEST_VERSION}"
if [ $? -ne 0 ]; then
  print_error "Falha ao instalar o VirtualBox."
fi
print_success "${VBOX_LATEST_VERSION} instalado com sucesso."

# ---[ Instalação do VirtualBox Extension Pack ]---

echo ">>> Baixando e instalando o VirtualBox Extension Pack..."

VBOX_VERSION=$(VBoxManage --version | rgrep -o '^[0-9]\.[0-9]\.[0-9]*')
EXT_PACK_URL="https://download.virtualbox.org/virtualbox/${VBOX_VERSION}/Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"

wget "${EXT_PACK_URL}"
if [ $? -ne 0 ]; then
  print_error "Falha ao baixar o Extension Pack. Verifique a URL ou sua conexão com a internet."
fi

echo "y" | VBoxManage extpack install --replace "Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"
if [ $? -ne 0 ]; then
  print_error "Falha ao instalar o Extension Pack."
fi

rm "Oracle_VM_VirtualBox_Extension_Pack-${VBOX_VERSION}.vbox-extpack"
print_success "VirtualBox Extension Pack instalado com sucesso."

# ---[ Adicionando o Usuário ao Grupo vboxusers ]---

CURRENT_USER=$(logname)
echo ">>> Adicionando o usuário '${CURRENT_USER}' ao grupo 'vboxusers'..."
usermod -aG vboxusers "${CURRENT_USER}"
if [ $? -ne 0 ]; then
  print_error "Falha ao adicionar o usuário ao grupo vboxusers."
fi
print_success "Usuário '${CURRENT_USER}' adicionado ao grupo 'vboxusers'."
echo ">>> É necessário reiniciar a sessão para que as alterações no grupo de usuários tenham efeito."

# ---[ Conclusão ]---

echo -e "\n\e[1;32mInstalação do VirtualBox concluída com sucesso!\e[0m"
echo "Para iniciar o VirtualBox, procure por 'VirtualBox' no seu menu de aplicativos ou execute 'virtualbox' no terminal."

exit 0
