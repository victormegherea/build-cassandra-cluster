#!/bin/bash

# Copyright 2017 Cloudbase Solutions Srl
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.

# small script that installs Cassandra and starts it
# Example usage: <script name> <url to Cassandra binary>
# i chose binray installation over package one, because
# it's more self contained, logs and conf in a single place

exec_with_retry2 () {
    MAX_RETRIES=$1
    INTERVAL=$2

    COUNTER=0
    while [ $COUNTER -lt $MAX_RETRIES ]; do
        EXIT=0
        eval '${@:3}' || EXIT=$?
        if [ $EXIT -eq 0 ]; then
            return 0
        fi
        let COUNTER=COUNTER+1

        if [ -n "$INTERVAL" ]; then
            sleep $INTERVAL
        fi
    done
    return $EXIT
}

exec_with_retry () {
    CMD=$1
    MAX_RETRIES=${2-10}
    INTERVAL=${3-0}

    exec_with_retry2 $MAX_RETRIES $INTERVAL $CMD
}

install_deps() {
    export DEBIAN_FRONTEND=noninteractive
    exec_with_retry 'apt-get update -y' 3
    exec_with_retry 'apt-get upgrade -y' 3
    exec_with_retry 'apt-get install python openjdk-8-jdk openjdk-8-jre wget -y' 3
}

retrieve_cassandra() {
    local URL; local BASEFILE; local INSTALL_FOLDER; local TAR_FOLDER;
    URL=$1
    BASEFILE=$(basename $URL)
    INSTALL_FOLDER=$2
    pushd $INSTALL_FOLDER

    exec_with_retry "wget $URL" 3
    TAR_FOLDER=$(sudo tar tzf $BASEFILE | head -1 | cut -f1 -d"/")
    tar -xzf $BASEFILE
    mv $TAR_FOLDER /opt/cassandra
    rm -rf $BASEFILE $TAR_FOLDER
    popd
}

main() {
    local URL; local INSTALL_FOLDER
    URL="http://mirror.evowise.com/apache/cassandra/3.11.0/apache-cassandra-3.11.0-bin.tar.gz"
    INSTALL_FOLDER="/opt"

    #TODO(papagalu): get username/password from conf file
    echo 'root:Passw0rd' | chpasswd
    echo "127.0.0.1 $(hostname)" >> /etc/hosts

    install_deps
    retrieve_cassandra $URL $INSTALL_FOLDER
}

main

exit 0

