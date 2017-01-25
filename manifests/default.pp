define append_if_no_such_line($file, $line, $refreshonly = 'false') {
   exec { "/bin/echo '$line' >> '$file'":
      unless      => "/bin/grep -Fxqe '$line' '$file'",
      path        => "/bin",
      refreshonly => $refreshonly,
   }
}
$atlassian_home="/opt/atlassian"
class common_dependencies {
  include apt
  apt::ppa { "ppa:webupd8team/java": }
 
 
  file { 'atlassianhome':
    ensure => 'directory',
    path => "${atlassian_home}",
    owner  => 'erp',
    group  => 'erp',
    mode   => '0755',
  }
 
 
  exec { 'apt-get update':
    command => '/usr/bin/apt-get update',
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  exec { 'apt-get update 2':
    command => '/usr/bin/apt-get update',
    require => [ Apt::Ppa["ppa:webupd8team/java"], Package["git-core"] ],
  }

  package { ["vim",
             "curl",
             "git-core",
             "bash"]:
    ensure => present,
    require => Exec["apt-get update"],
    before => Apt::Ppa["ppa:webupd8team/java"],
  }

  package { ["oracle-java8-installer"]:
    ensure => present,
    require => Exec["apt-get update 2"],
  }

  exec {
    "accept_license":
    command => "echo debconf shared/accepted-oracle-license-v1-1 select true | sudo debconf-set-selections && echo debconf shared/accepted-oracle-license-v1-1 seen true | sudo debconf-set-selections",
    cwd => "${atlassian_home}",
    user => "root",
    path    => "/usr/bin/:/bin/",
    require => [ Package["curl"], File["atlassianhome"] ],
    before => Package["oracle-java8-installer"],
    logoutput => true,
  }

}

class bamboo {
  include common_dependencies

  $bamboo_home = "/vagrant/bamboo-home"
  $bamboo_version = "4.4.5"

  exec {
    "download_bamboo":
    command => "curl -L http://www.atlassian.com/software/bamboo/downloads/binary/atlassian-bamboo-${bamboo_version}.tar.gz | tar zx",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "/vagrant/atlassian-bamboo-${bamboo_version}",
  }

  exec {
    "create_bamboo_home":
    command => "mkdir -p ${bamboo_home}",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_bamboo"],
    logoutput => true,
    creates => "${bamboo_home}",
  }

  exec {
    "start_bamboo_in_background":
    environment => "BAMBOO_HOME=${bamboo_home}",
    command => "/vagrant/atlassian-bamboo-${bamboo_version}/bamboo.sh start &",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java8-installer"],
                 Exec["accept_license"],
                 Exec["download_bamboo"],
                 Exec["create_bamboo_home"] ],
    logoutput => true,
  }
}

class confluence {
  include common_dependencies

  $confluence_home = "/vagrant/confluence-home"
  $confluence_version = "5.1"

  exec {
    "download_confluence":
    command => "curl -L http://www.atlassian.com/software/confluence/downloads/binary/atlassian-confluence-${confluence_version}.tar.gz | tar zx",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "/vagrant/atlassian-confluence-${confluence_version}",
  }

  exec {
    "create_confluence_home":
    command => "mkdir -p ${confluence_home}",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_confluence"],
    logoutput => true,
    creates => "${confluence_home}",
  }

  exec {
    "start_confluence_in_background":
    environment => "CONFLUENCE_HOME=${confluence_home}",
    command => "/vagrant/atlassian-confluence-${confluence_version}/bin/start-confluence.sh &",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java8-installer"],
                 Exec["accept_license"],
                 Exec["download_confluence"],
                 Exec["create_confluence_home"] ],
    logoutput => true,
  }
}

class jira {
  include common_dependencies
  
  $jira_version = "7.3.0"
  $webappjira = "${atlassian_home}/atlassian-jira-software-${jira_version}-standalone"
  $jira_home="${atlassian_home}/jira"
  

  exec {
    "download_jira":
    command => "curl -L https://www.atlassian.com/software/jira/downloads/binary/atlassian-jira-software-${jira_version}.tar.gz | tar zx",
    cwd => "${atlassian_home}",
    user => "erp",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "${webappjira}",
  }

   exec {
    "create_jira_home":
    command => "mkdir -p ${jira_home}",
    cwd => "$atlassian_home",
    user => "erp",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_jira"],
    logoutput => true,
    creates => "${jira_home}",
  }
  

  exec {
    "start_jira_in_background":
    environment => "JIRA_HOME=${jira_home}",
    command => "$webappjira/bin/start-jira.sh &",
    cwd => "$atlassian_home",
    user => "erp",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java8-installer"],
                 Exec["accept_license"],
                 Exec["download_jira"],
                 Exec["create_jira_home"] ],
    logoutput => true,
  }
}

class stash {
  include common_dependencies

  $stash_version = "2.3.1"
  $stash_home = "/vagrant/stash-home"

  exec {
    "download_stash":
    command => "curl -L http://www.atlassian.com/software/stash/downloads/binary/atlassian-stash-${stash_version}.tar.gz | tar zx",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["accept_license"],
    logoutput => true,
    creates => "/vagrant/atlassian-stash-${stash_version}",
  }

  exec {
    "create_stash_home":
    command => "mkdir -p ${stash_home}",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => Exec["download_stash"],
    logoutput => true,
    creates => "${stash_home}",
  }

  exec {
    "start_stash_in_background":
    environment => "STASH_HOME=${stash_home}",
    command => "/vagrant/atlassian-stash-${stash_version}/bin/start-stash.sh &",
    cwd => "/vagrant",
    user => "vagrant",
    path    => "/usr/bin/:/bin/",
    require => [ Package["oracle-java8-installer"],
                 Exec["accept_license"],
                 Exec["download_stash"],
                 Exec["create_stash_home"] ],
    logoutput => true,
  }
}

#include bamboo
#include confluence
include jira
#include stash
