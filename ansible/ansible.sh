#!/bin/bash

function usage(){
    echo "$(basename $0) usage:"
    echo "  -s stage (optional)"
    exit 1
}

while [[ $# -gt 1 ]]
do
    case $1 in
        -s)
        STAGE="${2}"
        shift
        ;;
        *)
        usage
        shift
        ;;
    esac
    shift
done

export ANSIBLE_INVENTORY="./inventory"
export ANSIBLE_INVENTORY_ENABLED="aws_ec2"
export ANSIBLE_HOST_KEY_CHECKING="False"

pipenv install --skip-lock
pipenv run ansible-galaxy collection install amazon.aws && ansible-galaxy install datadog.datadog
pipenv run ansible-playbook playbook.yml -e "stage=${STAGE}" -v
