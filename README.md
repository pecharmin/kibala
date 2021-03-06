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
See screenshots of bacula backup information:
* [Configuration](/doc/screenshots/kibala-configuration.png)
* [Status](/doc/screenshots/kibala-status.png)
* [History](/doc/screenshots/kibala-history.png)
* [Job details with logs](/doc/screenshots/kibala-job-details.png)

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

1. Change kibana configuration kibana/config.js

   * Using another elasticsearch instance:
   
   ```
   elasticsearch: "http://elastic.host:9200",
   ```

   * Use local elasticsearch instance via HTTPS behind Apache webserver with webserver's HTTP basic authentication (see apache configuration below):

   ```
   elasticsearch: { server: "https://kibala.local/es", withCredentials: true },
   ```

1. Configure your favorite webserver to deliver kibana directory

   * For Apache2 webserver see [doc/configs/apache2-vhost.txt](/doc/configs/apache2-vhost.txt)

1. Start webserver and check kibana via webbrowser
1. Get kibala and checkout stable version for Kibana 3

    ```
    git clone git@github.com:pecharmin/kibala.git
    cd kibala
    git checkout kibana3
    ```

Usage
-----
1. Configure the kibala toolset in kibala.conf
1. Configure database password to bacula schema

    ```
    touch ~/.my.cnf
    chmod 600 ~/.my.cnf
    cat >>~/.my.cnf <<EOF
    [client]
    password=your_pass
    EOF
    ```

1. Run the init and import script for ElasticSearch index (includes substeps below):
   * ```./kibala-delete-index.sh # Delete complete index if already existing```
   * ```./kibala-create-index.sh # Create elasticsearch index with defined mappings```
   * ```./kibala-indexer.sh # Import all relevant information from bacula DB tables to ES types```
1. Open kibana instance
1. Import kibala dashboard file into kibana: kibala.dashboard
1. Filter information of your backups

TODO
----
* Fix "Total Media Blocks" in dashboard
* Make LogText searchable
* Import pools and medias
* Integration into bacula to update elasticsearch index after backups
