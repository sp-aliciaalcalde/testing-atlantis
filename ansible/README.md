## Ansible

### Inventory
We are using dynamic inventory to get EC2 resources to use. [Ansible Galaxy](https://galaxy.ansible.com/amazon/aws) [Documentation](https://docs.ansible.com/ansible/latest/collections/amazon/aws/aws_ec2_inventory.html)

#### Deploy
There is a bash script (`ansible.sh`) which creates a virtual environment using `pip` to install all necessary dependencies to run the ansible playbook. You just need to run this script as shown below:

> ./ansible.sh

There are different stages configured, in case you only want to deploy one of them individually. In this case it should be something like this:

> ./ansible.sh -s aws-credentials

### Stages

#### AWS Credentials
> ./ansible.sh -s aws-credentials

This stage configures AWS Credentials across all EC2 instances.

#### Datadog
> ./ansible.sh -s datadog

This stage configures Datadog agent across all EC2 instances.

We are using Datadog ansible role for agent installation and configuration on EC2 instances. [Ansible Galaxy](https://galaxy.ansible.com/DataDog/datadog) [Documentation](https://github.com/DataDog/ansible-datadog) 

##### Configuration
Datadog role configuration uses vars to configure all the parameters. In order to do it dynamic we are using a common config file for standard config (`datadog_common_config.yml`) and other for standard checks config (`datadog_common_checks.yml`).

Some instances have different ports opened because of the containers running inside, these instances will be using a different checks config file. To know which one they use, instances have a tag `Ansible` which value points to the corresponding file. 
