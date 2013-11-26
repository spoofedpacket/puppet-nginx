# = Define: nginx::resource::upstream
#
#   This definition creates a new upstream proxy entry for NGINX
#   Upstream proxy entries are then collected via exported resources
#   declared on the upstream web servers themselves. See 
#   nginx::resource::upstream-member.
#
# == Prerequisites:
#
#    ripienaar/puppet-concat. Storeconfigs on the puppetmaster
#    and PuppetDB to collect/export resources.
#
# == Parameters:
#    [*members*]              - Array of member URIs for NGINX to connect to. Must follow valid NGINX syntax.
#    [*ensure*]               - Enables or disables the specified location (present|absent)
#    [*upstream_cfg_prepend*] - It expects a hash with custom directives to put before anything else inside upstream
#
#    [*upstream_sticky*]      - Whether to use sticky sessions for the upstream servers. 
#                               Requires nginx to be compiled with the nginx-sticky-module: 
#                               https://code.google.com/p/nginx-sticky-module
#    [*upstream_check*]       - Perform health checks on the upstream servers. Requires nginx
#                               to be compiled with the upstream_check module:
#                               https://github.com/yaoweibin/nginx_upstream_check_module
#    [*upstream_check_url*]   - If upstream_check is enabled, check this URL.
#    [*upstream_check_host*]  - If upstream_check is enabled, check this host.
#
# == Actions:
#
# == Requires:
#
# == Sample Usage:
#  nginx::resource::upstream { 'proxypass':
#    ensure  => present,
#    members => [
#      'localhost:3000',
#      'localhost:3001',
#      'localhost:3002',
#    ],
#  }
#
#  Custom config example to use ip_hash, and 20 keepalive connections
#  create a hash with any extra custom config you want.
#  $my_config = {
#    'ip_hash'   => '',
#    'keepalive' => '20',
#  }
#  nginx::resource::upstream { 'proxypass':
#    ensure              => present,
#    members => [
#      'localhost:3000',
#      'localhost:3001',
#      'localhost:3002',
#    ],
#    upstream_cfg_prepend => $my_config,
#  }
#
#    nginx::resource::upstream { 'proxypass': 
#     upstream_sticky     => true,
#     upstream_check      => true,
#     upstream_check_url  => '/foo/index.php',
#     upstream_check_host => 'www.example.com',
#    }
define nginx::resource::upstream (
  $members,
  $ensure = 'present',
  $upstream_cfg_prepend = undef,
  $upstream_sticky = false,
  $upstream_check  = false,
  $upstream_check_url = undef,
  $upstream_check_host = undef
) {
  File {
    owner => 'root',
    group => 'root',
    mode  => '0644',
  }

  concat::fragment { "${name}_upstream_block":
    order    => "20-${name}-00",
    target   => "${nginx::params::nx_conf_dir}/conf.d/upstream.conf", 
    content  => template('nginx/conf.d/upstream.erb'),
    notify   => Class['nginx::service'],
  }

  # Populate upstream block with exported members.
  Nginx::Resource::Upstream-Member <<| upstream_group == $name |>>

  # Close off upstream block.
  concat::fragment { "end_block":
    order    => "25",
    target   => "${nginx::params::nx_conf_dir}/conf.d/upstream.conf", 
    content  => "\n}\n",
  }


  file { "/etc/nginx/conf.d/${name}-upstream.conf":
    ensure  => $ensure ? {
      'absent' => absent,
      default  => 'file',
    },
    content => template('nginx/conf.d/upstream.erb'),
    notify  => Class['nginx::service'],
  }
}
