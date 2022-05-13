#!/bin/bash

banner()
{
  echo "+------------------------------------------+"
  printf "| %-40s |\n" "`date`"
  echo "|                                          |"
  printf "|`tput bold` %-40s `tput sgr0`|\n" "$@"
  echo "+------------------------------------------+"
}

function check_connectivity() {

    local test_ip
    local test_count

    test_ip="8.8.8.8"
    test_count=1

    if ping -c ${test_count} ${test_ip} > /dev/null; then
       echo "Conexão com a internet detectada!"
    else
       echo "Não há internet"
	   exit
    fi
 }

banner "Configuração Inicial do cluster LSM"

echo
echo "Verificando conexão com a internet..."
echo 

check_connectivity
sleep 5

echo
echo "Verificando as permissões necessárias..."
echo
sleep 5

if [ "$EUID" -ne 0 ]
  then echo "Por favor, execute este script como root"
  exit
  else echo "Permissões já estão concedidas em seu maior nível"
fi

echo
echo "Atualizando os repositórios do SO"
echo 
apt-get update
apt-get -y upgrade
apt-get -y dist-upgrade
sleep 3

echo 
echo "Instalando as principais bibliotecas"
sleep 5
apt-get -y install make vim gfortran cpp g++ gcc hwloc libc6 network-manager
apt-get -y install libblas3 libblas-dev liblapack3 liblapack-dev libfftw3-bin libfftw3-dev
apt-get -y install tk libglu1-mesa libtogl2 libfftw3-3 libxmu6 imagemagick openbabel libgfortran5
echo
echo

echo "Instalando os pacotes NFS e NIS cliente"
sleep 5
apt-get -y install nfs-common nis


echo
echo "Configurando acesso SSH direto do ROOT"
cp /etc/ssh/sshd_config /etc/ssh/sshd_config.backup1
echo "PermitRootLogin yes" >> /etc/ssh/sshd_config
echo
sleep 5

echo "Adicionando o IP do Server Titan"
echo "192.168.0.10   titan.lsm.cluster   titan" >> /etc/hosts
echo
sleep 5

echo "Configurando o FSTAB"
echo " "
echo "titan:/home /home nfs rw,sync 0 0" >> /etc/fstab
echo "titan:/usr/local/chem /usr/local/chem nfs defaults 0 0" >> /etc/fstab
echo "titan:/usr/local/bin /usr/local/bin nfs defaults 0 0" >> /etc/fstab
echo
sleep 5

echo "Criando pasta /usr/local/chem"
mkdir -p /usr/local/chem
echo

echo "Montando as partições do servidor na $(hostname)"
mount -a
sleep 5

echo "Configurando NIS server"
echo "ypserver titan.lsm.cluster" >> /etc/yp.conf
echo
echo "lsm.cluster" >> /etc/defaultdomain
echo
sleep 5

echo
echo "Configurando o Network Services Switch manualmente:"
echo "           *Adicionar a keyword nis no final das opções: passwd, group, shadow, hosts e netgroup*"
sleep 10
vi /etc/nsswitch.conf
echo

echo "Adicionando seção opcional no pam.d"
echo "session optional        pam_mkhomedir.so skel=/etc/skel umask=077" >> /etc/pam.d/common-session
echo

echo "Reiniciando o servidor ssh..."
/etc/init.d/ssh restart
echo
sleep 3

#vi /etc/profile

echo "Criando o diretório /work no diretório raiz..."
cd /
mkdir work
chmod 777 /work && chmod +t /work/
sleep 5

echo "Reiniciando o servidor NIS..."
systemctl restart rpcbind nscd ypbind
systemctl enable rpcbind ypbind
echo
sleep 5

echo "Montando as partições NFS do servidor..."
mount -a
echo

echo "Fazendo link entre a /usr/local/chem/ e /usr/local/cluster"
ln -s /usr/local/chem/ /usr/local/cluster
   
banner "Configuração inicial finalizada!"
