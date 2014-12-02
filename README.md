kibala - kibana bacula backup information visualization
=======================================================

Author: Armin Pech <github (at) arminpech (dot) de>

Introduction
------------
This projects supplies a tool set to visualize information of bacula backups
using the tool kibana.
Information of the bacula database are imported into an elasticsearch
cluster/instance and returned by kibana to the client.

Examples
--------
See screenshots of
* [Filtering](/doc/screenshots/kibala1.png)
* [Information](/doc/screenshots/kibala2.png)

Requirements
------------
* Bacula >= 5.2
* Access to MySQL database of bacula
* MySQL client (for shell)
* Java JDK
* ElasticSearch >= 1.3 && < 1.4
* Kibana >= 3

Installation
------------
1. Create an installation path

    ```
    mkdir /opt/kibala-suite
    cd /opt/kibala-suite
    ```

1. Setup elasticsearch instance

    ```
    wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.6.tar.gz
    tar -xzf elasticsearch-1.3.6.tar.gz
    ln -s elasticsearch-1.3.6 elasticsearch
    ```

1. Start elasticsearch server

    ```
    nohup ./elasticsearch/bin/elasticsearch &
    ```

1. Install kibana instance

    ```
    wget https://download.elasticsearch.org/kibana/kibana/kibana-3.1.2.tar.gz
    tar -xzf kibana-3.1.2.tar.gz
    ln -s kibana-3.1.2 kibana
    ```

1. Configure your favorite webserver to deliver kibana directory

   * Apache2 Webserver:

    ```
    <VirtualHost *:80>
        ServerName kibala.local
        
        DocumentRoot /opt/kibala-suite/kibana/
        <Directory /opt/kibala-suite/kibana/>
                Order allow,deny
                allow from all
        </Directory>
    </VirtualHost>
    ```

1. Start webserver and check kibana via webbrowser
1. Get kibala
    ```
    git clone git@github.com:pecharmin/kibala.git
    cd kibala
    git checkout <version>
    ```

Usage
-----
1. Configure the kibala toolset in kibala.conf
1. Configure database password to bacula schema
```touch ~/.my.cnf
chmod 600 ~/.my.cnf
cat >>~/.my.cnf <<EOF
[client]
password=your_pass
EOF```
1. Run the init and import script for ElasticSearch index (includes substeps below):
   * ./kibala-delete-index.sh # Delete complete index if already existing
   * ./kibala-create-index.sh # Create elasticsearch index with defined mappings
   * ./kibala-indexer.sh # Import all relevant information for bacula DB tables to ES types
1. Open kibana instance
1. Import kibala dashboard file into kibana: kibala.dashboard
1. Filter information of your backups

TODO
----
* Import volume, pool, media information
* Check job volume size calculation based on volume status
* Integration into bacula to update elasticsearch index after backups
