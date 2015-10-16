notice('MODULAR: network-node/network_hiera_override.pp')

$network_node_plugin = hiera('network=node', undef)
$hiera_dir = '/etc/hiera/override'
$plugin_name = 'network-node'
$plugin_yaml = "${plugin_name}.yaml"


if $network_node_plugin {
  
  $corosync_roles = ['primary-network-node', 'network-node']
  $haproxy_nodes = false
  $quantum_settings['neutron_agents'] = ['l3', 'metadata', 'dhcp']
  $quantum_settings["neutron_server_enable"] = false
  $quantum_settings["conf_nova"] = false

 ###################
  file {'/etc/hiera/override':
    ensure  => directory,
  } ->
  file { "${hiera_dir}/${plugin_yaml}":
    ensure  => file,
    content => "${network_node_plugin['yaml_additional_config']}\n${calculated_content}\n",
  }

  package {'ruby-deep-merge':
    ensure  => 'installed',
  }

  file_line {"${plugin_name}_hiera_override":
    path  => '/etc/hiera.yaml',
    line  => "  - override/${plugin_name}",
    after => '  - override/module/%{calling_module}',
  }

}
