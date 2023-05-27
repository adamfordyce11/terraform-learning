# Terraform Learning

## Terraform Objectives

- Create an AWS Landing Zone
- Use Account Vending
- Deploy a service within an account

## Constraints

- Each account will have its own VPC

## Environment

The repository has a .devcontainer directory that sets up an environment with the latest AWS CLI and the latest terraform version installed.

The Dev Container has been configured to mount the SSH AUTH Socket, this means that when their is a local ssh agent running, when the container starts up, any keys that were added to the host machine will be available when using SSH within the Dev Container.

### Usage

```bash
eval "$(ssh-agent -s)"
ssh-add /path/to/GitHub/ssh.pem
code /path/to/this/repo
```