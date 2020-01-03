HOW-TO guide for "Collecting containers' runtime metrics for historical trends reports." using docker environment.
#Róbert Zsótér


You can use -after some technical modifications- within your other local docker daemon environment!
- of course, you can use it -regarding AWX infrastructure- if you want also.


Some thoughts about the environment, main components:
We will deploy:
- 3 containers, within docker environment:
 - cadvisor: this will collect the necessary information (for example: memory usage of containers, host) from docker daemon,directly
 - influxdb: the data will be stored in database (sq3lite)
 - grafana: graphical interface for metrics,historical data
- 2 networks:
 - backend: network link between containers (similar to internal network,without exposing ports to external network)
 - frontend: link between cadvisor+grafana and external network (using bridge driver)


I. PRE-requierements:
- ensure if everything goes well within your environment. For example: you have enough free space, docker daemon runs and works well, etc.
- create the necessary directory structure. We will store the data of containers here.
For example:
/srv/metrics-data/monitoring/influxdb
/srv/metrics-data/monitoring/grafana/data
/srv/metrics-data/monitoring/grafana/dashboards
/srv/metrics-data/monitoring/cadvisor //-->it is not needed in this version/deployment but later we would like to use this
You will get a similar result:
/srv/metrics-data/monitoring/
├── cadvisor
├── grafana
│   ├── dashboards
│   └── data
└── influxdb

- put the configuration files to destination path:
for example:
copy (recursively) everything, from  downloaded repository (for example: from /root/git/docker-resource-usage/ to destination path: /srv/metrics-env/monitoring/
You will get similar to this:
../monitoring/
├── docker-compose.yml //this file will create the environment and set up that. : influxdb,cadvisor,grafana containers will be started.
├── docker-compose.yml.with.limits  //same file, with additional parts: the containers' limit has been set. Don't use this - without validation - The limits are depends on your environment,usage's method,etc.
├── .env //--> this file will store the passwords, you have to edit before the deployment (and delete the passwords after that)
├── provisioning
│   ├── cadvisor
│   ├── grafana
│   │   ├── dashboards
│   │   │   └── add-dashb.yml //-->you can use similar configuration file to insert dashboard(s)
│   │   ├── datasources
│   │   │   └── add-connector-2-db.yml //--> the database connector will be created - meanwhile deployment - automatically
│   │   └── grafana.ini //if you want, you can edit based on your expectations, for example: database (default:sqlite3), admin user name and password, certificate, etc
│   └── influxdb
│       └── influxdb-createdb.sh //-->if you have to create the database manually (after the influxdb container has been started)
└── README.txt

and
- edit the necessary files, and focus on edit the "original" passwords using your "right" passwords
important files:
.env:
 //please take your attention to put these passwords without space character!
 for example:
#db admin user
 INFLUXDB_ADMIN_USER=noSpaceHere
#db admin user password
 INFLUXDB_ADMIN_PASSWORD=noSpaceHere
#grafana admin user password
 GF_SECURITY_ADMIN_PASSWORD=noSpaceHere
grafana.ini:
 //please take your attention, put these passwords with space character!
 You can edit based on your expectations, for example: sqlite3 admin user name and password, certificate, etc
 for example:
 ;secret_key = ThereIsASpaceBeforeThePassword
 [database]
 ...
# PassDbUserNameHere
 ;user = ThereIsASpaceBeforeTheUserName
#PassDbUserPassHere
 ;password = ThereIsASpaceBeforeThePassword

docker-compose.yml:
 edit:
 - the path(s) of volume(s), - if needed (current path: under the /srv/.... )
 - cadvisor's port: keep it in your mind if the webui-port will be also published meanwhile the deployment.
   That means, the portal will be available for anybody -without authentication! If you don't want to public this port, please edit the right part in compose file before the deployment!


II. Deployment:
Pre-check:
- "common" function test - as usually -: check if whether the host (where the containers are running) has enough resource (disk,cpu,memory,etc) and the load is normal.
  If you want you can change the paths (see above): in this case you have to edit the configuration files, -  before the deployment.-
Deployment:
- run the docker-compose command, for example:
  cd /srv/metrics-env/monitoring/
  docker-compose --compatibility up -d
- check the webportal, - using the ip address of the host (where the grafana container is running)- and login to webpage, using admin user account (or other "right" user which have been set in the configuration file -before deployment):
  for example, visit the webpage to check:
  - the historical data, via grafana -with authentication: via http://xxx.xxx.xxx.xxx:3000
  - the actual information about host and container via cadvisor -without authentication:  http://xxx.xxx.xxx.xxx:8080


III. Additional steps:
After you logged in the portal:
- you can check the data source is available,
- you can create a dashboard -as you would like- based on your requirements
- you can find a few examples: within "examples" directory
select statements (examples):
cpu usage-cadvisor-1week:
SELECT derivative("value", 1s)/1000000000 FROM "cpu_usage_total" WHERE ("container_name" = 'cadvisor') AND time >= now() - 1w
ok-docker-monitoring-0.9-METRICS.json:
SELECT mean("value") FROM "cpu_usage_system" WHERE  ("container_name" = 'cadvisor') AND $timeFilter GROUP BY time($interval), "container_name" fill(null)
SELECT mean("value") FROM "memory_usage" WHERE ("container_name" = 'cadvisor') AND $timeFilter GROUP BY time($interval), "container_name"  fill(null)
SELECT mean("value") FROM "rx_bytes" WHERE $timeFilter GROUP BY time($__interval) fill(null)


IV: POST task(s):
- please ensure if your passwords (which have been set up - before the deployment- ) will be destroyed/deleted at the end this process, in configuration files! Don't store those your on local - not encrypted - filesystem!
