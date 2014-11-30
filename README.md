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
* Kibana >= 3
* Java JDK
* ElasticSearch >= 1.3
* Any Webserver

Installation
------------
1. Setup elasticsearch instance
1. Start elasticsearch server
1. Setup kibana instance with your favorite webserver
1. Start webserver and check kibana via webbrowser

Usage
-----
1. Configure the kibala toolset in kibala.conf
1. Configure database password to bacula schema
   * ```
   touch ~/.my.cnf
   chmod 600 ~/.my.cnf
   cat >>~/.my.cnf <<EOF
   [client]
   password=your_pass
   EOF
   ```
1. Run the init script for ElasticSearch index:
   * kibala-init.sh
1. Run the import scripts:
   * kibala-import-bacula-client.sh
   * kibala-import-bacula-job.sh
   * kibala-import-bacula-jobhisto.sh
1. Open kibana instance
1. Import kibala dashboard file into kibana: kibala.dashboard
1. Query and filter information of your backups

TODO
----
* Import volume, pool, media information
* Check job volume size calculation based on volume status
