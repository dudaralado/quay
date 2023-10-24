##Disabling SELinux
sudo setenforce 0
sudo sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config

##Intall needed packages
sudo yum install -y podman openssl tree wget skopeo vim bash-completion git
sudo yum module install -y container-tools

sudo firewall-cmd --permanent --add-port=80/tcp
sudo firewall-cmd --permanent --add-port=443/tcp

sudo firewall-cmd --permanent --add-port=8080/tcp
sudo firewall-cmd --permanent --add-port=8090/tcp
sudo firewall-cmd --permanent --add-port=8081/tcp
sudo firewall-cmd --permanent --add-port=8082/tcp
sudo firewall-cmd --permanent --add-port=8089/tcp
sudo firewall-cmd --permanent --add-port=8444/tcp
sudo firewall-cmd --permanent --add-port=8445/tcp
sudo firewall-cmd --permanent --add-port=8446/tcp
sudo firewall-cmd --permanent --add-port=8988/tcp

sudo firewall-cmd --permanent --add-port=5432/tcp
sudo firewall-cmd --permanent --add-port=5433/tcp
sudo firewall-cmd --permanent --add-port=5434/tcp

sudo firewall-cmd --permanent --add-port=6379/tcp
sudo firewall-cmd --permanent --add-port=6380/tcp
sudo firewall-cmd --permanent --add-port=9000/tcp
sudo firewall-cmd --permanent --add-port=9001/tcp


sudo firewall-cmd --reload

sudo firewall-cmd --list-all
#sleep 10
