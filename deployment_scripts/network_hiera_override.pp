notice('MODULAR: network-node/network_hiera_override.pp')

$network_node_plugin = hiera('network-node', undef)
$hiera_dir = '/etc/hiera/override'
$plugin_name = 'network-node'
$plugin_yaml = "${plugin_name}.yaml"



if $network_node_plugin {
  $network_metadata = hiera_hash('network_metadata')
  $network_roles = ['primary-network-node', 'network-node']
  $network_nodes = get_nodes_hash_by_roles($network_metadata, $network_roles)
 
  case hiera_array('role', 'none') {
    /primary-network-node/: {  
       $corosync_roles = $network_roles
       $deploy_vrouter = false
       $haproxy_nodes = false
       $corosync_nodes = $network_nodes
    	}
	}

###################
$calculated_content = inline_template('
<% if @corosync_nodes -%>
<% require "yaml" -%>
corosync_nodes:
<%= YAML.dump(@corosync_nodes).sub(/--- *$/,"") %>
<% end -%>
<% if @corosync_roles -%>
corosync_roles:
<%
@corosync_roles.each do |crole|
%>  - <%= crole %>
<% end -%>
<% end -%>
deploy_vrouter: <%= @deploy_vrouter %>
')

###################

  file {'/etc/hiera/override':
    ensure  => directory,
  } ->
  file { '/etc/hiera/override/common.yaml':
    ensure  => file,
    content => "${calculated_content}\n",
  }
  
  package {'ruby-deep-merge':
    ensure  => 'installed',
  } 
  
  file_line {'hiera.yaml':
    path  => '/etc/hiera.yaml',
      line  => "  - override/${plugin_name}",
      after => '  - override/module/%{calling_module}',
  }

}
