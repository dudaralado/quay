oc create configmap custom-ca --from-file=ca-bundle.crt=/home/duda/Quay/ssl_certs/openshiftCluster.cert -n openshift-config

oc patch proxy/cluster --type=merge --patch='{"spec":{"trustedCA":{"name":"custom-ca"}}}'

oc create secret tls ingressupdate --cert=/home/duda/Quay/ssl_certs/openshiftCluster.cert --key=/home/duda/Quay/ssl_certs/openshiftCluster.key -n openshift-ingress

oc patch ingresscontroller.operator default --type=merge -p '{"spec":{"defaultCertificate": {"name": "ingressupdate"}}}' -n openshift-ingress-operator


