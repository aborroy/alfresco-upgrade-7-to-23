# Guide to upgrade Alfresco 7.0 to Alfresco 23.1 [![Spain](https://raw.githubusercontent.com/stevenrskelton/flag-icon/master/png/75/country-4x3/es.png "Spain")](README_es.md)

This project provides a step by step tutorial to upgrade an existing ACS 7.0 to a new ACS 23.1 deployment.

This project provides different sample projects to support this process:

* [alfresco-7.0](alfresco-7.0) folder contains Docker Compose template to deploy ACS Community 7.0
* [alfresco-23.1](alfresco-23.1) folder contains Docker Compose template to deploy ACS Community 23.1
* [tools](tools) folder contains sample content models and one Alfresco GO CLI script to populate the Repository

Running this tutorial involves following steps:

1. Prepare the original Alfresco 7.0
2. Gather addons, configuration and customizations from Alfresco 7.0
3. Prepare the final Alfresco 23.1
4. Perform backup operations in Alfresco 7.0
5. Run Alfresco 23.1 restoring the backup

```
    ┌───────────┐                           ┌───────────┐
    │           │                           │           │
    │  Addons   ├ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─ ─►│  Addons   │
    │           │                           │           │
    └─────┬─────┘                           └─────┬─────┘
          │                                       │
   ┌──────▼──────────────────────┐        ┌───────▼───────────────────┐
   │                ALFRESCO 7.0 │        │             ALFRESCO 23.1 │
   │                             │        │                           │
   │                             │        │                           │
   │   Customization             ├ ─ ─ ─ ►│     Customization         │
   │   Configuration             │        │     Configuration         │
   │                             │        │                           │
   │                             │        │                           │
   │                             │        │                           │
   └───┬────────┬────────┬───────┘        └────┬────────┬────────┬────┘
       │        │        │                     │        │        │
       │        │        │                     │        │        │
   ┌───▼──┐ ┌───▼──┐ ┌───▼──┐              ┌───▼──┐ ┌───▼──┐ ┌───▼──┐
   │      │ │      │ │      │              │      │ │      │ │      │
   │  DB  │ │  CS  │ │ SOLR ├ ─ ─ ─ ─ ─ - ►│  DB  │ │  CS  │ │ SOLR │
   │      │ │      │ │      │              │      │ │      │ │      │
   └──────┘ └──────┘ └──────┘              └──────┘ └──────┘ └──────┘

      Persistent Storage                       Persistent Storage
```


## 1. Prepare the original Alfresco 7.0

>> To simulate a populated Alfresco 7.0 deployment, the first step is to create a sample Repository with custom content models and a number of documents created in the Repository

Run [alfresco-7.0](alfresco-7.0) template

```sh
cd alfresco-7.0
docker compose up
```

**Custom content models**

Upload [tools/models/data-dictionary/custom-content-model.xml](tools/models/data-dictionary/custom-content-model.xml) to `Repository > Data Dictionary > Models` folder to deploy `cfp` content model. Be sure that `Model Active` property is enabled

Import Model [tools/models/model-manager/conference-model.zip](tools/models/model-manager/conference-model.zip) to **Model Manager** in Share web application to deploy `conference` model. Be sure that `Activate` action is enabled

Note that [acme-model](tools/models/addon/acme-model) is deployed in the Repository as an addon in [acme-model-1.0.0.jar](alfresco-7.0/alfresco/modules/jars)

**Create sample content**

Use sample Alfresco Go CLI Script provided in [alfresco-go-cli-scripts](alfresco-go-cli-scripts) to create sample content from custom content models

```sh
cd tools/alfresco-go-cli-scripts
```

Download `alfresco` Go CLI binary from https://github.com/aborroy/alfresco-go-cli/releases

Create default endpoint and credentials for Alfresco Repository

```sh
./alfresco config set -s http://localhost:8080/alfresco -u admin -p admin
```

Run the script to upload files to Alfresco Repository

```sh
./create-custom-content.sh
```

This will create the following content in `Shared` folder: 

* Folder `acme` containing 20 documents named `file_acme_[1..20].txt` from ACME Model
* Folder `cfp` containing 20 documents named `file_cfp_[1..20].txt` from CFP Model
* Folder `conf` containing 20 documents named `file_conf_[1..20].txt` from Conferences Model

>> From this point source ACS Repository contains document from custom content models


## 2. Gather addons, configuration and customizations from Alfresco 7.0

Existing customizations in Alfresco 7.0 need to be identified to be applied to the new 23.1 deployment

**Addons**

* Repository
  * [alfresco-7.0/alfresco/modules/amps/share-site-creators-repo-0.0.8-SNAPSHOT.amp](alfresco-7.0/alfresco/modules/amps)
  * [alfresco-7.0/alfresco/modules/amps/support-tools-repo-1.2.1.0-amp.amp](alfresco-7.0/alfresco/modules/amps)
  * [alfresco-7.0/alfresco/modules/jars/acme-model-1.0.0.jar](alfresco-7.0/alfresco/modules/jars)
  * [alfresco-7.0/alfresco/modules/jars/activemq-broker-5.17.2.jar](alfresco-7.0/alfresco/modules/jars)

* Share
  * [alfresco-7.0/share/modules/amps/share-site-creators-share-0.0.8-SNAPSHOT.amp](alfresco-7.0/share/modules/amps)
  * [alfresco-7.0/share/modules/amps/support-tools-share-1.2.1.0-amp.amp](alfresco-7.0/share/modules/amps)

**Configuration**

Mainly available in [alfresco-7.0/docker-compose.yml](alfresco-7.0/docker-compose.yml).

* Repository
  * `solr.secureComms=none` 
  * `-Dmessaging.broker.url="failover:(nio://activemq:61616)?timeout=3000&jms.useCompression=true"`

* SOLR
  * `ALFRESCO_COMMS: none`

**Customization**

* Share
  * [alfresco-7.0/share/web-extension/share-config-custom-dev.xml](alfresco-7.0/share/web-extension/)


## 3. Prepare the final Alfresco 23.1

Apply customizations from Alfresco 7.0 to 23.1 deployment

**Addons**

* Repository
  * [alfresco-23.1/alfresco/modules/amps/share-site-creators-repo-0.0.8-SNAPSHOT.amp](alfresco-23.1/alfresco/modules/amps)
  * `[X]` *support-tools-repo-1.2.1.0-amp.amp* is not supported in Alfresco 23.1 (due to the upgrade to Jakarta EE 10)
  * [alfresco-23.1/alfresco/modules/jars/acme-model-1.0.0.jar](alfresco-23.1/alfresco/modules/jars)
  * `[X]` *activemq-broker-5.17.2.jar* is not required in Alfresco 23.1 to disable Messaging, applying following configuration to `alfresco` service is enough:
```
-Dmessaging.subsystem.autoStart=false
-Drepo.event2.enabled=false
```

* Share
  * [alfresco-23.1/share/modules/amps/share-site-creators-share-0.0.8-SNAPSHOT.amp](alfresco-23.1/share/modules/amps)
  * `[X]` *support-tools-share-1.2.1.0-amp.amp* is not supported in Alfresco 23.1 (due to the upgrade to Jakarta EE 10)

**Configuration**

Mainly to be applied in [alfresco-23.1/compose.yaml](alfresco-23.1/compose.yaml).

* Repository
  * `solr.secureComms=none` is not supported in Alfresco 23.1, it's required to switch to `solr.secureComms=secret` plus `solr.sharedSecret=w3n8o6vjh1e `
  * `-Dmessaging.broker.url="failover:(nio://activemq:61616)?timeout=3000&jms.useCompression=true"` can be removed, as Messaging has been disabled by using the properties described above

* SOLR
  * `ALFRESCO_COMMS: none` is not supported in Alfresco 23.1, it's required to switch to `ALFRESCO_COMMS: secret` plus `-Dalfresco.secureComms.secret=w3n8o6vjh1e`

**Customization**

* Share
  * [alfresco-23.1/share/web-extension/share-config-custom-dev.xml](alfresco-23.1/share/web-extension/)


Once the customizations has been applied, start Alfresco 23.1 to verify everything is working as expected.

```sh
cd alfresco-23.1
docker compose up
```

Alfresco 23.1 can be stopped after this verification.


```sh
docker compose stop
docker compose down
```

Remove also data persisted for this verification

```sh
rm -rf data
```


## 4. Perform backup operations in Alfresco 7.0

Alfresco Backups must be performed following the next order:

* SOLR Cores (alfresco, archive)
* Database
* Filesystem

Run [alfresco-7.0](alfresco-7.0) template

```sh
cd alfresco-7.0
docker compose up
```

**Backup of SOLR Cores**

Use the SOLR *backup* tool to store a snapshot of every core.

```sh
curl -u admin:admin "http://localhost:8080/solr/alfresco/replication?command=backup&numberToKeep=1&wt=xml"
curl -u admin:admin "http://localhost:8080/solr/archive/replication?command=backup&numberToKeep=1&wt=xml"
```

This action will create the snapshots in `backup` folder.

```sh
backup
└── solr
    ├── alfresco
    │   └── snapshot.20231201131552743
    └── archive
        └── snapshot.20231201131607263
```

**Backup of Database**

Use the Database *dump* tool to store a backup of the database.

```sh
cd backup
docker-compose exec postgres pg_dump --username alfresco alfresco > pg-dump.sql
```

This will add the dump to the backup folder.

```sh
backup
├── pg-dump.sql
└── solr
    ├── alfresco
    └── archive
```

**Backup of Filesystem**

Use `rsync` or equivalent to create a copy of the Content Store

```sh
rsync -r data/alf-repo-data backup
```

This will complete the backup from the original Alfresco 7.0.0

```sh
backup
├── alf-repo-data
│   ├── contentstore
│   └── contentstore.deleted
├── pg-dump.sql
└── solr
    ├── alfresco
    │   └── snapshot.20231201131552743
    └── archive
        └── snapshot.20231201131607263
```


## 5. Run Alfresco 23.1 restoring the backup

In order to restore Postgres dump from Alfresco 7.0 in Alfresco 23.1, we need to start only postgres service.

```sh
cd alfresco-23.1
docker-compose up postgres
```

Once the new database is ready, restore the backup we dumped in the previous section

```sh
cat ../alfresco-1/backup/pg-dump.sql | docker-compose exec -T \
postgres psql --username alfresco --password alfresco 
```

Remember that you can use some other approach in order to restore the Postgres backup. This one is using a plain text file.

Stop again postgres service when the restore is done.

```sh
docker-compose stop postgres
```

In order to restore the filesystem, just copy the saved folder to `alf-repo-data`.

```sh
cp -r ../alfresco-7.0/backup/alf-repo-data data/
```

Finally, SOLR cores backup need to be restored using the expected names (alfresco and archive).

```
mkdir -p data/solr-data/alfresco
cp -r ../alfresco-7.0/backup/solr/alfresco data/solr-data
mv data/solr-data/alfresco/snapshot.20231201131552743 data/solr-data/alfresco/index

mkdir -p data/solr-data/archive
cp -r ../alfresco-7.0/backup/solr/archive data/solr-data/
mv data/solr-data/archive/snapshot.20231201131552743 data/solr-data/archive/index
```

Folder `data` should contain following structure after performing these steps.

```sh
data
├── alf-repo-data
│   ├── contentstore
│   └── contentstore.deleted
├── postgres-data
└── solr-data
    ├── alfresco
    └── archive
```

From this point, every persisted information is available in the right place, so you can start your ACS in order to check that everything has been restored.

```sh
docker-compose up --build --force-recreate
```