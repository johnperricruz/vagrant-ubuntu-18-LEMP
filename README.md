## Requirement

* [VirtualBox](https://www.virtualbox.org/)
* [Vagrant](https://www.vagrantup.com/)
* [Vagrant::Hostsupdater](https://github.com/cogitatio/vagrant-hostsupdater)

_Note: Vagrant::Hostsupdater is optional to automatically add the entry to the hosts file. If you skip that, you will need to manually edit the hosts file and add the related entry yourself._

```
$ vagrant plugin install vagrant-hostsupdater

```

## Usage

```
$ mkdir <project-name>
$ cd <project-name>
$ git clone https://github.com/johnperricruz/vagrant-ubuntu-18-LEMP.git
$ cd vagrant
$ vagrant up
$ vagrant ssh
```

All Vagrant commands like `vagrant halt`, `vagrant destroy` and `vagrant suspend` are applicable.

## Credentials

MySQL root:

**User**: `root`
**Password**: `password`

Additional MySQL access:

**User**: `vagrant`
**Password**: `password`
**Database**: `vagrant`

## What's Included?

* [Ubuntu 18.04](http://www.ubuntu.com/)
* [nginx (mainline)](http://nginx.org/)
* [MySQL (stable)](http://mysql.com/)
* [php-fpm 8.1.x](http://php-fpm.org/)
* [Git](https://git-scm.com/)
* [Composer](https://getcomposer.org/)
* [Elastic Search](https://www.elastic.co/)
* [MailHog](https://github.com/mailhog/MailHog)

## Directory Structure

* `config` - Contains all services related configuration, please modify it accordingly to your usage.
* `logs` - Contains all the logs generated from nginx as well as PHP errors.
* `www` - The web root of your web application.

www.johnperricruz.com
