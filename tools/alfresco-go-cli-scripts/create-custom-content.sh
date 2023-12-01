#!/bin/bash

set -o errexit
set -o pipefail

# Create local files
rm -rf files && mkdir -p files
echo "Call for Papers management" > "files/file_cfp.txt"
echo "ACME Document" > "files/file_acme.txt"
echo "Presentation management" > "files/file_conf.txt"

# Upload local files to Repository
CFP_FOLDER_ID=$(./alfresco node create -n cfp -i -shared- -t cm:folder -o id)
for i in {1..20}
do
./alfresco node create -n file_cfp_$i.txt -i $CFP_FOLDER_ID -t cfp:proposal -f $PWD/files/file_cfp.txt -o id >> /dev/null
done

ACME_FOLDER_ID=$(./alfresco node create -n acme -i -shared- -t cm:folder -o id)
for i in {1..20}
do
./alfresco node create -n file_acme_$i.txt -i $ACME_FOLDER_ID -t acme:document -f $PWD/files/file_acme.txt -o id >> /dev/null
done

CONF_FOLDER_ID=$(./alfresco node create -n conf -i -shared- -t cm:folder -o id)
for i in {1..20}
do
./alfresco node create -n file_conf_$i.txt -i $CONF_FOLDER_ID -t conf:Presentation -f $PWD/files/file_conf.txt -o id >> /dev/null
done