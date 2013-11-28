# = Define: nginx::resource::upstream-member
#
#   This definition creates a new upstream server entry which is
#   collected by the nginx::resource::upstream class and added
#   to an existing upstream { } block.
#
# == Prerequisites:
#
#    ripienaar/puppet-concat. Storeconfigs on the puppetmaster
#    and PuppetDB to collect/export resources.
#
# == Sample Usage:
#
#    Exported version, declare on the server you wish to add to
#    the upstream group:
#
#     @@nginx::resource::upstream-member { 'proxypass':
#       upstream_group => 'name_of_group',
#       members => $::ipaddress,
#     }
#
#    Local/static version, declare on the load balancer itself:
#
#     nginx::resource::upstream-member {'proxypass':
#       upstream_group => 'name_of_group',
#       members => ['193.1.219.5', '193.1.219.6']
#       
#
# == Authors
#
#    Based on the puppetlabs/nginx module, modified to support
#    exported resources by rob@spoofedpacket.net - 20130801
#
define nginx::resource::upstream-member (
  $upstream_group,
  $members = $::ipaddress,
) {

  concat::fragment { "${upstream_group}_upstream_${name}":
    order    => "20-${upstream_group}-${name}",
    target   => "${nginx::params::nx_conf_dir}/conf.d/upstream.conf",
    content  => template('nginx/conf.d/upstream-member.erb'),
    notify   => Class['nginx::service'],
  }

}
