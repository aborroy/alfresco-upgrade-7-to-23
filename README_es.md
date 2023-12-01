# Guía para actualizar Alfresco 7.0 a Alfresco 23.1

Este proyecto incluye un tutorial paso a paso para actualizar un Alfresco 7.0 en uso a la nueva versión 23.1.

Se incluyen varias carpetas con los recursos necesarios para ejecutar el proceso de actualización:

* La carpeta [alfresco-7.0](alfresco-7.0) incluye una plantilla de Docker Compose para ejecutar Alfresco Community 7.0
* La carpeta [alfresco-23.1](alfresco-23.1) incluye una plantilla de Docker Compose para ejecutar Alfresco Community 23.1
* La carpeta [tools](tools) incluye modelos de contenido de ejemplo y un *script* para [Alfresco GO CLI](https://github.com/aborroy/alfresco-go-cli) que permite crear documentos en el repositorio

Este tutorial consta de los siguientes pasos:

1. Preparar la instalación original de Alfresco 7.0
2. Recolectar *addons*, configuraciones y personalizaciones de Alfresco 7.0
3. Preparar la instalación final de Alfresco 23.1
4. Realizar las operaciones de *backup* en Alfresco 7.0
5. Ejecutar Alfresco 23.1 con la restauración del *backup* de Alfresco 7.0

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
   │   Personalizaciones         ├ ─ ─ ─ ►│     Personalizaciones     │
   │   Configuración             │        │     Configuración         │
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

   Almacenamiento Persistente              Almacenamiento Persistente
```


## 1. Preparar la instalación original de Alfresco 7.0

>> Para simular un repositorio de Alfresco 7.0 existente, el primer paso es crear un Repositorio de ejemplo con modelos de contenido personalizados y documentos asociados a esos modelos

Ejecutar [alfresco-7.0](alfresco-7.0)

```sh
cd alfresco-7.0
docker compose up
```

**Modelos de Contenido Personalizados**

Sube el archivo [tools/models/data-dictionary/custom-content-model.xml](tools/models/data-dictionary/custom-content-model.xml) a la carpeta `Repository > Data Dictionary > Models` para desplegar el modelo `cfp`. Asegúrate de que la propiedad `Model Active` está activada

Importa el modelo [tools/models/model-manager/conference-model.zip](tools/models/model-manager/conference-model.zip) en la opción **Model Manager** de la aplicación Share para desplegar el modelo `conference`. Asegúrate de que la acción `Activate` está activada

Adicionalmente, el modelo [acme-model](tools/models/addon/acme-model) está desplegado en el Repositorio como un *addon* mediante el fichero [acme-model-1.0.0.jar](alfresco-7.0/alfresco/modules/jars)

**Creación de contenido de ejemplo**

Usa el *script* de ejemplo para [Alfresco GO CLI](https://github.com/aborroy/alfresco-go-cli) disponible en la carpeta [alfresco-go-cli-scripts](alfresco-go-cli-scripts) para crear contenido de ejemplo asociado a los modelos de contenido personalizados

```sh
cd tools/alfresco-go-cli-scripts
```

Descarga el binario de [Alfresco GO CLI](https://github.com/aborroy/alfresco-go-cli) que corresponda a tu sistema operativo y arquitectura en https://github.com/aborroy/alfresco-go-cli/releases

Establece la dirección y las credenciales del Repositorio de Alfresco

```sh
./alfresco config set -s http://localhost:8080/alfresco -u admin -p admin
```

Ejecuta el *script* para crear los documentos en el repositorio

```sh
./create-custom-content.sh
```

El siguiente contenido será creado en la carpeta `Shared` del Repositorio:

* Una carpeta `acme` que contiene 20 documents llamados `file_acme_[1..20].txt` pertenecientes al modelo ACME
* Una carpeta `cfp` que contiene 20 documents llamados `file_cfp_[1..20].txt` pertenecientes al modelo CFP
* Una carpeta `conf` que contiene 20 documents llamados `file_conf_[1..20].txt` pertenecientes al modelo Conferences

>> A partir de este punto, el Repositorio de Alfresco 7.0.0 contiene documentos de modelos de contenido personalizados


## 2. Recolectar addons, configuraciones y personalizaciones de Alfresco 7.0

Identifica las personalizaciones en Alfresco 7.0 para aplicarlas al nuevo despliegue de la 23.1

**Addons**

* Repositorio
  * [alfresco-7.0/alfresco/modules/amps/share-site-creators-repo-0.0.8-SNAPSHOT.amp](alfresco-7.0/alfresco/modules/amps)
  * [alfresco-7.0/alfresco/modules/amps/support-tools-repo-1.2.1.0-amp.amp](alfresco-7.0/alfresco/modules/amps)
  * [alfresco-7.0/alfresco/modules/jars/acme-model-1.0.0.jar](alfresco-7.0/alfresco/modules/jars)
  * [alfresco-7.0/alfresco/modules/jars/activemq-broker-5.17.2.jar](alfresco-7.0/alfresco/modules/jars)

* Share
  * [alfresco-7.0/share/modules/amps/share-site-creators-share-0.0.8-SNAPSHOT.amp](alfresco-7.0/share/modules/amps)
  * [alfresco-7.0/share/modules/amps/support-tools-share-1.2.1.0-amp.amp](alfresco-7.0/share/modules/amps)

**Configuración**

Mayormente especificada en [alfresco-7.0/docker-compose.yml](alfresco-7.0/docker-compose.yml)

* Repositorio
  * `solr.secureComms=none` 
  * `-Dmessaging.broker.url="failover:(nio://activemq:61616)?timeout=3000&jms.useCompression=true"`

* SOLR
  * `ALFRESCO_COMMS: none`

**Personalización**

* Share
  * [alfresco-7.0/share/web-extension/share-config-custom-dev.xml](alfresco-7.0/share/web-extension/)


## 3. Preparar la instalación final de Alfresco 23.1

Aplica las personalizaciones de Alfresco 7.0 al despliegue de 23.1

**Addons**

* Repository
  * [alfresco-23.1/alfresco/modules/amps/share-site-creators-repo-0.0.8-SNAPSHOT.amp](alfresco-23.1/alfresco/modules/amps)
  * `[X]` *support-tools-repo-1.2.1.0-amp.amp* no está soportado para Alfresco 23.1, debido a la actualización a Jakarta EE 10 del repositorio
  * [alfresco-23.1/alfresco/modules/jars/acme-model-1.0.0.jar](alfresco-23.1/alfresco/modules/jars)
  * `[X]` *activemq-broker-5.17.2.jar* no es requerido en Alfresco 23.1 para deshabilitar ActiveMQ, es suficiente con aplicar la siguiente configuración al servicio `alfresco`:
```
-Dmessaging.subsystem.autoStart=false
-Drepo.event2.enabled=false
```

* Share
  * [alfresco-23.1/share/modules/amps/share-site-creators-share-0.0.8-SNAPSHOT.amp](alfresco-23.1/share/modules/amps)
  * `[X]` *support-tools-share-1.2.1.0-amp.amp* no está soportado para Alfresco 23.1, debido a la actualización a Jakarta EE 10 del repositorio

**Configuración**

Mayormente especificada en [alfresco-23.1/compose.yaml](alfresco-23.1/compose.yaml).

* Repositorio
  * `solr.secureComms=none` no está soportado en Alfresco 23.1, se require cambiar a `solr.secureComms=secret` junto con `solr.sharedSecret=w3n8o6vjh1e `
  * `-Dmessaging.broker.url="failover:(nio://activemq:61616)?timeout=3000&jms.useCompression=true"` puede ser eliminado, se deshabilita ActiveMQ con las dos propiedades descritas arriba

* SOLR
  * `ALFRESCO_COMMS: none` no está soportado en Alfresco 23.1, se requiere cambiar a `ALFRESCO_COMMS: secret` junto con `-Dalfresco.secureComms.secret=w3n8o6vjh1e`

**Personalización**

* Share
  * [alfresco-23.1/share/web-extension/share-config-custom-dev.xml](alfresco-23.1/share/web-extension/)


Una vez que todas las personalizaciones se han aplicado, inicia Alfresco 23.1 para verificar que todo funciona correctamente

```sh
cd alfresco-23.1
docker compose up
```

Para Alfresco 23.1 una vez que hayas terminado esta verificación


```sh
docker compose stop
docker compose down
```

Elimina también los datos que se han creado durante la verificación

```sh
rm -rf data
```


## 4. Realizar las operaciones de backup en Alfresco 7.0

Las copias de seguridad de Alfresco se realizan en el siguiente orden:

* *Cores* de SOLR (alfresco, archive)
* Base de Datos
* Sistema de ficheros

Ejecuta [alfresco-7.0](alfresco-7.0)

```sh
cd alfresco-7.0
docker compose up
```

**Copia de seguridad de los cores de SOLR**

Usa la herramienta *backup* de SOLR para almacenar una *snapshot* de cada *core* (alfresco, archive)

```sh
curl -u admin:admin "http://localhost:8080/solr/alfresco/replication?command=backup&numberToKeep=1&wt=xml"
curl -u admin:admin "http://localhost:8080/solr/archive/replication?command=backup&numberToKeep=1&wt=xml"
```

Si la ejecución ha sido existosa, los *snapshots* se almacenarán en la carpeta `backup` de `alfresco-7.0`

```sh
backup
└── solr
    ├── alfresco
    │   └── snapshot.20231201131552743
    └── archive
        └── snapshot.20231201131607263
```

**Copia de Seguridad de la Base de Datos**

Usa la herramienta *dump* de la base de datos para crear la copia de seguridad

```sh
cd backup
docker-compose exec postgres pg_dump --username alfresco alfresco > pg-dump.sql
```

Si la ejecución ha sido existosa, el *dump* de base de datos quedará almacenado al lado de las *snapshots* de SOLR

```sh
backup
├── pg-dump.sql
└── solr
    ├── alfresco
    └── archive
```

**Copia de Seguridad del Sistema de Ficheros**

Usa el comando `rsync` o alguna equivalente para crear una copia del *Content Store*

```sh
rsync -r data/alf-repo-data backup
```

Este comando completa la copia de seguridad del Alfresco 7.0.0 original

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


## 5. Ejecutar Alfresco 23.1 con la restauración del backup de Alfresco 7.0

Para restaurar la copia de seguridad de Postgres de Alfresco 7.0 en Alfresco 23.1, lanzamos únicamente el servicio `postgres`

```sh
cd alfresco-23.1
docker-compose up postgres
```

Una vez que la base de datos está activa, restaura la copia de seguridad obtenida en el paso anterior

```sh
cat ../alfresco-1/backup/pg-dump.sql | docker-compose exec -T \
postgres psql --username alfresco --password alfresco 
```

Puedes usar otro formato para crear y restaurar la copia de seguridad de Postgres, ya que este método usa un fichero de texto (lo que puede no estar recomendado para grandes volúmenes de información)

Para el servicio de `postgres` cuando la restauración se haya realizado

```sh
docker-compose stop postgres
```

Restaura el sistema de ficheros (el *Content Store*) copiando la carpeta original de Alfresco 7.0.0 a `alf-repo-data`

```sh
cp -r ../alfresco-7.0/backup/alf-repo-data data/
```

Para finalizar, restaura la copia de seguridad de los *cores* de SOLR usando los nombres esperados: `alfresco` y `archive`

```
mkdir -p data/solr-data/alfresco
cp -r ../alfresco-7.0/backup/solr/alfresco data/solr-data
mv data/solr-data/alfresco/snapshot.20231201131552743 data/solr-data/alfresco/index

mkdir -p data/solr-data/archive
cp -r ../alfresco-7.0/backup/solr/archive data/solr-data/
mv data/solr-data/archive/snapshot.20231201131552743 data/solr-data/archive/index
```

La carpeta `data` de `alfresco-23.1` debería contener la siguiente estructura tras la ejecución de estos pasos

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

En este momento, toda la información necesaria ha sido migrada y puede lanzarse Alfresco 23.1 para verificar que todo funciona según lo esperado

```sh
docker-compose up --build --force-recreate
```