# Internal: Prepare your system for MySQL.
#
# Examples
#
#   include mysql::config

class mysql::config(
  $ensure,

  $configdir,
  $globalconfigprefix,
  $datadir,
  $executable,
  $realmysqldir,

  $logdir,

  $host,
  $port,
  $socket,
  $user,
) {

  File {
    ensure => $ensure,
    owner  => $user,
  }

  file {
    [
      $configdir,
      $datadir,
      $logdir,
    ]:
      ensure => directory ;

    "${configdir}/my.cnf":
      content => template('mysql/my.cnf.erb'),
      notify  => Service['mysql'] ;
  }

  ->
  exec { 'init-mysql-db':
    command  => "mysql_install_db \
      --verbose \
      --basedir=${realmysqldir} \
      --datadir=${datadir} \
      --tmpdir=/tmp",
    creates  => "${datadir}/mysql",
    provider => shell,
    user     => $user,
  }

  ->
  boxen::env_script { 'mysql':
    ensure   => $ensure,
    content  => template('mysql/env.sh.erb'),
    priority => 'higher',
  }

  if $::osfamily == 'Darwin' {
    file {
    "${boxen::config::envdir}/mysql.sh":
      ensure => absent ;

    '/Library/LaunchDaemons/dev.mysql.plist':
      content => template('mysql/dev.mysql.plist.erb'),
      group   => 'wheel',
      owner   => 'root' ;

    "${globalconfigprefix}/var/mysql":
      ensure  => absent,
      force   => true,
      recurse => true ;

    "${globalconfigprefix}/etc/my.cnf":
      ensure  => link,
      target  => "${configdir}/my.cnf" ;
    }
  }
}
