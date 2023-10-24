location=$(timedatectl show |grep Timezone| cut -d "/" -f 2)

COUNTRY=$(curl https://ipinfo.io/|grep country|cut -d ":" -f 2 > $Quay_Certs/country.txt;cat $Quay_Certs/country.txt |cut -d "\"" -f 2)
STATE=$(curl https://ipinfo.io/|grep region|cut -d ":" -f 2 > $Quay_Certs/region.txt;cat $Quay_Certs/region.txt |cut -d "\"" -f 2)

#rm -rfv ca.* server.* client.*
#rm -rfv *.{crt,csr,key}

echo "Checking FQDN in Root CA $FQDN"
echo "Checking wild_card in Root CA $wild_card"


echo "For how long this rootCA should be valid? (in days)"
read valid_days

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
DNS.1 = *$wild_card
DNS.2 = *.apps.ocp4.$wild_card

EOF
####################################
## Step 1 - Certificate Authority ##
####################################
# Step 1.1 - Generate the Certificate Authority (CA) Private Key
openssl genrsa -out $Quay_Certs/rootCA.key 2048
#echo "Creating CA Certificate"
# Step 1.2 - Generate the Certificate Authority Certificate
openssl req -x509 -new -nodes -key $Quay_Certs/rootCA.key -subj "/C=$COUNTRY/ST=$STATE/L=$location/O=Quay/OU=Docs/CN=Nuc Lab Root CA"  -sha256 -days $valid_days -out $Quay_Certs/rootCA.cert

sudo cat $Quay_Certs/rootCA.cert >> $Quay_Certs/rootCA.pem
sudo cat $Quay_Certs/rootCA.key >> $Quay_Certs/rootCA.pem

#sudo cp -v $Quay_Certs/rootCA.cert /etc/pki/ca-trust/source/anchors/$wild_card.cert
sudo cp -v $Quay_Certs/rootCA.cert /etc/pki/ca-trust/source/anchors/rootCA.cert
sudo update-ca-trust
