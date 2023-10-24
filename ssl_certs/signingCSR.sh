export Quay_Certs=$HOME/Quay/ssl_certs

location=$(timedatectl show |grep Timezone| cut -d "/" -f 2)

COUNTRY=$(curl https://ipinfo.io/|grep country|cut -d ":" -f 2 > $Quay_Certs/country.txt;cat $Quay_Certs/country.txt |cut -d "\"" -f 2)
STATE=$(curl https://ipinfo.io/|grep region|cut -d ":" -f 2 > $Quay_Certs/region.txt;cat $Quay_Certs/region.txt |cut -d "\"" -f 2)

echo "Enter the CN for the Client cert or wildcard (e.g. *.apps.ocp4.lab.local bastion.lab.local) "
read CN_FQDN

echo "Enter the certs csr name"
read host_cert_name

echo "For how long this Client cert should be valid? (in days)"
read valid_days

export wild_card=$(echo $CN_FQDN|cut -d "." -f4-)

cat <<EOF|tee $Quay_Certs/openssl.cnf
[req]
req_extensions = v3_req
distinguished_name = req_distinguished_name
[req_distinguished_name]
[ v3_req ]
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names
[alt_names]
DNS.1 = $CN_FQDN
DNS.3 = *.$wild_card

EOF

openssl x509 -req -in $Quay_Certs/$host_cert_name.csr -CA $Quay_Certs/rootCA.cert -CAkey $Quay_Certs/rootCA.key -CAcreateserial -out $Quay_Certs/$host_cert_name.cert -days $valid_days  -extensions v3_req -extfile $Quay_Certs/openssl.cnf

rm -rfv $Quay_Certs/country.txt $Quay_Certs/openssl.cnf $Quay_Certs/region.txt

echo "##############################"
echo "# Certs Deployed Succssefuly #"
echo "##############################"
