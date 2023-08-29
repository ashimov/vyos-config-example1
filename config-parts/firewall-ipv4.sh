#!/bin/vbash
# shellcheck disable=all


# Configure forward filter:
#   forward_rule <rule_number> <inbound_interface_group> <outbound_interface_group> accept
#   forward_rule <rule_number> <inbound_interface_group> <outbound_interface_group> jump
#   forward_rule <rule_number> ignored <outbound_interface_group> drop
# 
# interface_group do not have IG_ prefix - that is substituted
#
# jump target is <inbound>-<outbound> named rule
#
forward_rule_number=101
function forward_rule {
  rule=$((forward_rule_number))
  inbound=$1
  outbound=$2
  action=$3

  case $action in
    accept)
      set firewall ipv4 forward filter rule $rule action $action
      set firewall ipv4 forward filter rule $rule inbound-interface interface-group IG_$inbound
      set firewall ipv4 forward filter rule $rule outbound-interface interface-group IG_$outbound
      ;;
    drop)
      set firewall ipv4 forward filter rule $rule action $action
      set firewall ipv4 forward filter rule $rule outbound-interface interface-group IG_$outbound
      ;;
    jump)
      set firewall ipv4 forward filter rule $rule action $action
      set firewall ipv4 forward filter rule $rule inbound-interface interface-group IG_$inbound
      set firewall ipv4 forward filter rule $rule outbound-interface interface-group IG_$outbound
      set firewall ipv4 forward filter rule $rule jump-target ${inbound}-${outbound}
      ;;
  esac

  forward_rule_number=$((forward_rule_number+5))
}

# Configure input filter
#   input_rule <rule_number> <inbound_interface_group> jump
#   input_rule <rule_number> any drop
# 
# interface_group do not have IG_ prefix - that is substituted
#
# jump target is <inbound>-local named rule
#
input_rule_number=101
function input_rule {
  rule=$((input_rule_number))
  inbound=$1
  action=$2

  case $action in
    drop)
      set firewall ipv4 input filter rule $rule action $action
      ;;
    jump)
      set firewall ipv4 input filter rule $rule action $action
      set firewall ipv4 input filter rule $rule inbound-interface interface-group IG_$inbound
      set firewall ipv4 input filter rule $rule jump-target ${inbound}-local
      ;;
  esac

  input_rule_number=$((input_rule_number+5))
}

# Configure output filter
#   output_rule <rule_number> <outbound_interface_group> jump
#   output_rule <rule_number> any drop
# 
# interface_group do not have IG_ prefix - that is substituted
#
# jump target is local-<outbound> named rule
#
output_rule_number=101
function output_rule {
  rule=$((output_rule_number))
  outbound=$1
  action=$2

  case $action in
    drop)
      set firewall ipv4 output filter rule $rule action $action
      ;;
    jump)
      set firewall ipv4 output filter rule $rule action $action
      set firewall ipv4 output filter rule $rule outbound-interface interface-group IG_$outbound
      set firewall ipv4 output filter rule $rule jump-target local-$outbound
      ;;
  esac

  output_rule_number=$((output_rule_number+5))
}

function begin_traffic {
  shift # Ignore $1 which is "to"
  interface=$1

  forward_rule $interface $interface accept
}

function handle_traffic {
  shift # Ignore $1 which is to
  outbound=$1
  shift
  shift # Ignore next word which is from
  for inbound in $*; do
    forward_rule $inbound $outbound jump
  done
}

function end_traffic {
  shift # Ignore $1 which is "to"
  outbound=$1
  forward_rule any $outbound drop
}

# Default forward policy
set firewall ipv4 forward filter default-action 'accept'
set firewall ipv4 forward filter rule 1 action 'accept'
set firewall ipv4 forward filter rule 1 state established 'enable'
set firewall ipv4 forward filter rule 2 action 'drop'
set firewall ipv4 forward filter rule 2 state invalid 'enable'
set firewall ipv4 forward filter rule 3 action 'accept'
set firewall ipv4 forward filter rule 3 state related 'enable'

begin_traffic  to guest
handle_traffic to guest from homelab iot lan servers services staging trusted wan
end_traffic    to guest

#            inbound   outbound  action
forward_rule homelab   homelab   accept
forward_rule guest     homelab   jump
forward_rule iot       homelab   jump
forward_rule lan       homelab   jump
forward_rule servers   homelab   jump
forward_rule services  homelab   jump
forward_rule staging   homelab   jump
forward_rule trusted   homelab   jump
forward_rule wan       homelab   jump
forward_rule any       homelab   drop

#            inbound   outbound  action
forward_rule iot       iot       accept
forward_rule guest     iot       jump
forward_rule homelab   iot       jump
forward_rule lan       iot       jump
forward_rule servers   iot       jump
forward_rule services  iot       jump
forward_rule staging   iot       jump
forward_rule trusted   iot       jump
forward_rule wan       iot       jump
forward_rule any       iot       drop

#            inbound   outbound  action
forward_rule lan       lan       accept
forward_rule guest     lan       jump
forward_rule homelab   lan       jump
forward_rule iot       lan       jump
forward_rule servers   lan       jump
forward_rule services  lan       jump
forward_rule staging   lan       jump
forward_rule trusted   lan       jump
forward_rule wan       lan       jump
forward_rule any       lan       drop

#            inbound   outbound  action
forward_rule servers   servers   accept
forward_rule guest     servers   jump
forward_rule homelab   servers   jump
forward_rule iot       servers   jump
forward_rule lan       servers   jump
forward_rule services  servers   jump
forward_rule staging   servers   jump
forward_rule trusted   servers   jump
forward_rule wan       servers   jump
forward_rule any       servers   drop

#            inbound   outbound  action
forward_rule services  services  accept
forward_rule guest     services  jump
forward_rule homelab   services  jump
forward_rule iot       services  jump
forward_rule lan       services  jump
forward_rule servers   services  jump
forward_rule staging   services  jump
forward_rule trusted   services  jump
forward_rule wan       services  jump
forward_rule any       services  drop

#            inbound   outbound  action
forward_rule staging   staging   accept
forward_rule guest     staging   jump
forward_rule homelab   staging   jump
forward_rule iot       staging   jump
forward_rule lan       staging   jump
forward_rule servers   staging   jump
forward_rule services  staging   jump
forward_rule trusted   staging   jump
forward_rule wan       staging   jump
forward_rule any       staging   drop

#            inbound   outbound  action
forward_rule trusted   trusted   accept
forward_rule guest     trusted   jump
forward_rule homelab   trusted   jump
forward_rule iot       trusted   jump
forward_rule lan       trusted   jump
forward_rule servers   trusted   jump
forward_rule services  trusted   jump
forward_rule staging   trusted   jump
forward_rule wan       trusted   jump
forward_rule any       trusted   drop

#            inbound   outbound  action
forward_rule wan       wan       accept
forward_rule guest     wan       jump
forward_rule homelab   wan       jump
forward_rule iot       wan       jump
forward_rule lan       wan       jump
forward_rule servers   wan       jump
forward_rule services  wan       jump
forward_rule staging   wan       jump
forward_rule trusted   wan       jump
forward_rule any       wan       drop

# Default input policy
set firewall ipv4 input filter default-action 'accept'
set firewall ipv4 input filter rule 1 action 'accept'
set firewall ipv4 input filter rule 1 state established 'enable'
set firewall ipv4 input filter rule 2 action 'drop'
set firewall ipv4 input filter rule 2 state invalid 'enable'
set firewall ipv4 input filter rule 3 action 'accept'
set firewall ipv4 input filter rule 3 state related 'enable'

# Handle traffic from an interface group to local
#          from      action
input_rule guest     jump
input_rule homelab   jump
input_rule iot       jump
input_rule lan       jump
input_rule servers   jump
input_rule services  jump
input_rule staging   jump
input_rule trusted   jump
input_rule wan       jump
input_rule any       drop

# Default output policy
set firewall ipv4 output filter default-action 'accept'
set firewall ipv4 output filter rule 1 action 'accept'
set firewall ipv4 output filter rule 1 state established 'enable'
set firewall ipv4 output filter rule 2 action 'drop'
set firewall ipv4 output filter rule 2 state invalid 'enable'
set firewall ipv4 output filter rule 3 action 'accept'
set firewall ipv4 output filter rule 3 state related 'enable'

# Handle traffic from local to an interface group
#           from      action
output_rule guest     jump
output_rule homelab   jump
output_rule iot       jump
output_rule lan       jump
output_rule servers   jump
output_rule services  jump
output_rule staging   jump
output_rule trusted   jump
output_rule wan       jump
output_rule any       drop


set firewall ipv4 name guest-homelab default-action 'drop'
set firewall ipv4 name guest-homelab description 'From GUEST to HOMELAB'
set firewall ipv4 name guest-homelab enable-default-log
set firewall ipv4 name guest-homelab rule 370 action 'accept'
set firewall ipv4 name guest-homelab rule 370 description 'Rule: accept plex users'
set firewall ipv4 name guest-homelab rule 370 destination group address-group 'plex-server'
set firewall ipv4 name guest-homelab rule 370 destination port '32400'
set firewall ipv4 name guest-homelab rule 370 protocol 'tcp'
set firewall ipv4 name guest-homelab rule 370 source group address-group 'plex-users'
set firewall ipv4 name guest-iot default-action 'drop'
set firewall ipv4 name guest-iot description 'From GUEST to IOT'
set firewall ipv4 name guest-iot enable-default-log
set firewall ipv4 name guest-iot rule 380 action 'accept'
set firewall ipv4 name guest-iot rule 380 description 'Rule: accept_tcp_printer_from_allowed_devices'
set firewall ipv4 name guest-iot rule 380 destination group address-group 'printers'
set firewall ipv4 name guest-iot rule 380 destination port 'http,https,9100'
set firewall ipv4 name guest-iot rule 380 protocol 'tcp'
set firewall ipv4 name guest-iot rule 430 action 'accept'
set firewall ipv4 name guest-iot rule 430 description 'Rule: accept_tcp_from_sonos_controllers_to_sonos_players'
set firewall ipv4 name guest-iot rule 430 destination group address-group 'sonos-players'
set firewall ipv4 name guest-iot rule 430 destination port '1400,1443,4444,7000,30000-65535'
set firewall ipv4 name guest-iot rule 430 protocol 'tcp'
set firewall ipv4 name guest-iot rule 430 source group address-group 'sonos-controllers'
set firewall ipv4 name guest-iot rule 431 action 'accept'
set firewall ipv4 name guest-iot rule 431 description 'Rule: accept_udp_from_sonos_controllers_to_sonos_players'
set firewall ipv4 name guest-iot rule 431 destination group address-group 'sonos-players'
set firewall ipv4 name guest-iot rule 431 destination port '319,320,30000-65535'
set firewall ipv4 name guest-iot rule 431 protocol 'udp'
set firewall ipv4 name guest-iot rule 431 source group address-group 'sonos-controllers'
set firewall ipv4 name guest-lan default-action 'drop'
set firewall ipv4 name guest-lan description 'From GUEST to LAN'
set firewall ipv4 name guest-lan enable-default-log
set firewall ipv4 name guest-local default-action 'drop'
set firewall ipv4 name guest-local description 'From GUEST to LOCAL'
set firewall ipv4 name guest-local enable-default-log
set firewall ipv4 name guest-local rule 100 action 'accept'
set firewall ipv4 name guest-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name guest-local rule 100 destination port 'ntp'
set firewall ipv4 name guest-local rule 100 protocol 'udp'
set firewall ipv4 name guest-local rule 110 action 'accept'
set firewall ipv4 name guest-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name guest-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name guest-local rule 110 protocol 'udp'
set firewall ipv4 name guest-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name guest-local rule 120 action 'accept'
set firewall ipv4 name guest-local rule 120 description 'Rule: accept igmp'
set firewall ipv4 name guest-local rule 120 protocol '2'
set firewall ipv4 name guest-local rule 130 action 'accept'
set firewall ipv4 name guest-local rule 130 description 'Rule: accept mdns'
set firewall ipv4 name guest-local rule 130 destination port 'mdns'
set firewall ipv4 name guest-local rule 130 protocol 'udp'
set firewall ipv4 name guest-local rule 130 source port 'mdns'
set firewall ipv4 name guest-local rule 450 action 'accept'
set firewall ipv4 name guest-local rule 450 description 'Rule: accept_discovery_from_sonos_controllers'
set firewall ipv4 name guest-local rule 450 destination port '1900,1901,1902,57621'
set firewall ipv4 name guest-local rule 450 protocol 'udp'
set firewall ipv4 name guest-local rule 450 source group address-group 'sonos-controllers'
set firewall ipv4 name guest-servers default-action 'drop'
set firewall ipv4 name guest-servers description 'From GUEST to SERVERS'
set firewall ipv4 name guest-servers enable-default-log
set firewall ipv4 name guest-services default-action 'drop'
set firewall ipv4 name guest-services description 'From GUEST to SERVICES'
set firewall ipv4 name guest-services enable-default-log
set firewall ipv4 name guest-services rule 170 action 'accept'
set firewall ipv4 name guest-services rule 170 description 'Rule: accept dns'
set firewall ipv4 name guest-services rule 170 destination port 'domain,domain-s'
set firewall ipv4 name guest-services rule 170 protocol 'tcp_udp'
set firewall ipv4 name guest-staging default-action 'drop'
set firewall ipv4 name guest-staging description 'From GUEST to STAGING'
set firewall ipv4 name guest-staging enable-default-log
set firewall ipv4 name guest-trusted default-action 'drop'
set firewall ipv4 name guest-trusted description 'From GUEST to TRUSTED'
set firewall ipv4 name guest-trusted enable-default-log
set firewall ipv4 name guest-wan default-action 'accept'
set firewall ipv4 name guest-wan description 'From IOT to WAN'
set firewall ipv4 name homelab-guest default-action 'drop'
set firewall ipv4 name homelab-guest description 'From HOMELAB to GUEST'
set firewall ipv4 name homelab-guest enable-default-log
set firewall ipv4 name homelab-homelab default-action 'accept'
set firewall ipv4 name homelab-homelab description 'From HOMELAB to HOMELAB'
set firewall ipv4 name homelab-iot default-action 'accept'
set firewall ipv4 name homelab-iot description 'From HOMELAB to IOT'
set firewall ipv4 name homelab-lan default-action 'drop'
set firewall ipv4 name homelab-lan description 'From HOMELAB to LAN'
set firewall ipv4 name homelab-lan enable-default-log
set firewall ipv4 name homelab-lan rule 140 action 'accept'
set firewall ipv4 name homelab-lan rule 140 description 'Rule: accept icmp'
set firewall ipv4 name homelab-lan rule 140 protocol 'icmp'
set firewall ipv4 name homelab-lan rule 500 action 'accept'
set firewall ipv4 name homelab-lan rule 500 description 'Rule: accept rtsp'
set firewall ipv4 name homelab-lan rule 500 destination group address-group 'unifi-unvr'
set firewall ipv4 name homelab-local default-action 'drop'
set firewall ipv4 name homelab-local description 'From HOMELAB to LOCAL'
set firewall ipv4 name homelab-local enable-default-log
set firewall ipv4 name homelab-local rule 100 action 'accept'
set firewall ipv4 name homelab-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name homelab-local rule 100 destination port 'ntp'
set firewall ipv4 name homelab-local rule 100 protocol 'udp'
set firewall ipv4 name homelab-local rule 110 action 'accept'
set firewall ipv4 name homelab-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name homelab-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name homelab-local rule 110 protocol 'udp'
set firewall ipv4 name homelab-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name homelab-local rule 140 action 'accept'
set firewall ipv4 name homelab-local rule 140 description 'Rule: accept icmp'
set firewall ipv4 name homelab-local rule 140 protocol 'icmp'
set firewall ipv4 name homelab-local rule 150 action 'accept'
set firewall ipv4 name homelab-local rule 150 description 'Rule: accept bgp'
set firewall ipv4 name homelab-local rule 150 destination port 'bgp'
set firewall ipv4 name homelab-local rule 150 protocol 'tcp'
set firewall ipv4 name homelab-local rule 330 action 'accept'
set firewall ipv4 name homelab-local rule 330 description 'Rule: accept iperf'
set firewall ipv4 name homelab-local rule 330 destination port '5001'
set firewall ipv4 name homelab-local rule 330 protocol 'tcp'
set firewall ipv4 name homelab-local rule 350 action 'accept'
set firewall ipv4 name homelab-local rule 350 description 'Rule: accept prometheus metrics scrape'
set firewall ipv4 name homelab-local rule 350 destination group port-group 'prometheus-metrics'
set firewall ipv4 name homelab-local rule 350 protocol 'tcp'
set firewall ipv4 name homelab-local rule 450 action 'accept'
set firewall ipv4 name homelab-local rule 450 description 'Rule: accept_discovery_from_sonos_controllers'
set firewall ipv4 name homelab-local rule 450 destination port '1900,1901,1902,57621'
set firewall ipv4 name homelab-local rule 450 protocol 'udp'
set firewall ipv4 name homelab-local rule 450 source group address-group 'sonos-controllers'
set firewall ipv4 name homelab-local rule 910 action 'drop'
set firewall ipv4 name homelab-local rule 910 description 'Rule: drop multicast to 224.0.0.1 (no log)'
set firewall ipv4 name homelab-local rule 910 destination address '224.0.0.1'
set firewall ipv4 name homelab-local rule 910 protocol '2'
set firewall ipv4 name homelab-servers default-action 'accept'
set firewall ipv4 name homelab-servers description 'From HOMELAB to SERVERS'
set firewall ipv4 name homelab-services default-action 'accept'
set firewall ipv4 name homelab-services description 'From HOMELAB to SERVICES'
set firewall ipv4 name homelab-staging default-action 'accept'
set firewall ipv4 name homelab-staging description 'From HOMELAB to STAGING'
set firewall ipv4 name homelab-trusted default-action 'drop'
set firewall ipv4 name homelab-trusted description 'From HOMELAB to TRUSTED'
set firewall ipv4 name homelab-trusted rule 140 action 'accept'
set firewall ipv4 name homelab-trusted rule 140 description 'Rule: accept icmp'
set firewall ipv4 name homelab-trusted rule 140 protocol 'icmp'
set firewall ipv4 name homelab-wan default-action 'accept'
set firewall ipv4 name homelab-wan description 'From HOMELAB to WAN'
set firewall ipv4 name iot-guest default-action 'drop'
set firewall ipv4 name iot-guest description 'From IOT to GUEST'
set firewall ipv4 name iot-guest enable-default-log
set firewall ipv4 name iot-guest rule 420 action 'accept'
set firewall ipv4 name iot-guest rule 420 description 'Rule: accept_udp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-guest rule 420 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-guest rule 420 destination port '319,320,30000-65535'
set firewall ipv4 name iot-guest rule 420 protocol 'udp'
set firewall ipv4 name iot-guest rule 420 source group address-group 'sonos-players'
set firewall ipv4 name iot-guest rule 421 action 'accept'
set firewall ipv4 name iot-guest rule 421 description 'Rule: accept_tcp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-guest rule 421 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-guest rule 421 destination port '1400,3400,3401,3500,30000-65535'
set firewall ipv4 name iot-guest rule 421 protocol 'tcp'
set firewall ipv4 name iot-guest rule 421 source group address-group 'sonos-players'
set firewall ipv4 name iot-homelab default-action 'drop'
set firewall ipv4 name iot-homelab description 'From IOT to HOMELAB'
set firewall ipv4 name iot-homelab enable-default-log
set firewall ipv4 name iot-homelab rule 370 action 'accept'
set firewall ipv4 name iot-homelab rule 370 description 'Rule: accept plex users'
set firewall ipv4 name iot-homelab rule 370 destination group address-group 'plex-server'
set firewall ipv4 name iot-homelab rule 370 destination port '32400'
set firewall ipv4 name iot-homelab rule 370 protocol 'tcp'
set firewall ipv4 name iot-homelab rule 370 source group address-group 'plex-users'
set firewall ipv4 name iot-homelab rule 420 action 'accept'
set firewall ipv4 name iot-homelab rule 420 description 'Rule: accept_udp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-homelab rule 420 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-homelab rule 420 destination port '319,320,30000-65535'
set firewall ipv4 name iot-homelab rule 420 protocol 'udp'
set firewall ipv4 name iot-homelab rule 420 source group address-group 'sonos-players'
set firewall ipv4 name iot-homelab rule 421 action 'accept'
set firewall ipv4 name iot-homelab rule 421 description 'Rule: accept_tcp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-homelab rule 421 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-homelab rule 421 destination port '1400,3400,3401,3500,30000-65535'
set firewall ipv4 name iot-homelab rule 421 protocol 'tcp'
set firewall ipv4 name iot-homelab rule 421 source group address-group 'sonos-players'
set firewall ipv4 name iot-homelab rule 460 action 'accept'
set firewall ipv4 name iot-homelab rule 460 description 'Rule: accept_music_library_sonos_players'
set firewall ipv4 name iot-homelab rule 460 destination group address-group 'sonos-library'
set firewall ipv4 name iot-homelab rule 460 destination port '4534,http,https'
set firewall ipv4 name iot-homelab rule 460 protocol 'tcp'
set firewall ipv4 name iot-homelab rule 460 source group address-group 'sonos-players'
set firewall ipv4 name iot-lan default-action 'drop'
set firewall ipv4 name iot-lan description 'From IOT to LAN'
set firewall ipv4 name iot-lan enable-default-log
set firewall ipv4 name iot-local default-action 'drop'
set firewall ipv4 name iot-local description 'From IOT to LOCAL'
set firewall ipv4 name iot-local enable-default-log
set firewall ipv4 name iot-local rule 100 action 'accept'
set firewall ipv4 name iot-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name iot-local rule 100 destination port 'ntp'
set firewall ipv4 name iot-local rule 100 protocol 'udp'
set firewall ipv4 name iot-local rule 110 action 'accept'
set firewall ipv4 name iot-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name iot-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name iot-local rule 110 protocol 'udp'
set firewall ipv4 name iot-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name iot-local rule 120 action 'accept'
set firewall ipv4 name iot-local rule 120 description 'Rule: accept igmp'
set firewall ipv4 name iot-local rule 120 protocol '2'
set firewall ipv4 name iot-local rule 130 action 'accept'
set firewall ipv4 name iot-local rule 130 description 'Rule: accept mdns'
set firewall ipv4 name iot-local rule 130 destination port 'mdns'
set firewall ipv4 name iot-local rule 130 protocol 'udp'
set firewall ipv4 name iot-local rule 130 source port 'mdns'
set firewall ipv4 name iot-local rule 440 action 'accept'
set firewall ipv4 name iot-local rule 440 description 'Rule: accept_discovery_from_sonos_players'
set firewall ipv4 name iot-local rule 440 destination port '1900,1901,1902'
set firewall ipv4 name iot-local rule 440 protocol 'udp'
set firewall ipv4 name iot-local rule 440 source group address-group 'sonos-players'
set firewall ipv4 name iot-servers default-action 'drop'
set firewall ipv4 name iot-servers description 'From IOT to SERVERS'
set firewall ipv4 name iot-servers enable-default-log
set firewall ipv4 name iot-services default-action 'drop'
set firewall ipv4 name iot-services description 'From IOT to SERVICES'
set firewall ipv4 name iot-services enable-default-log
set firewall ipv4 name iot-staging default-action 'drop'
set firewall ipv4 name iot-staging description 'From IOT to STAGING'
set firewall ipv4 name iot-staging enable-default-log
set firewall ipv4 name iot-trusted default-action 'drop'
set firewall ipv4 name iot-trusted description 'From IOT to TRUSTED'
set firewall ipv4 name iot-trusted enable-default-log
set firewall ipv4 name iot-trusted rule 360 action 'accept'
set firewall ipv4 name iot-trusted rule 360 description 'Rule: accept scanner traffic'
set firewall ipv4 name iot-trusted rule 360 destination group address-group 'scanner-clients'
set firewall ipv4 name iot-trusted rule 360 destination group port-group 'scanner-outbound-ports'
set firewall ipv4 name iot-trusted rule 360 protocol 'udp'
set firewall ipv4 name iot-trusted rule 420 action 'accept'
set firewall ipv4 name iot-trusted rule 420 description 'Rule: accept_udp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-trusted rule 420 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-trusted rule 420 destination port '319,320,30000-65535'
set firewall ipv4 name iot-trusted rule 420 protocol 'udp'
set firewall ipv4 name iot-trusted rule 420 source group address-group 'sonos-players'
set firewall ipv4 name iot-trusted rule 421 action 'accept'
set firewall ipv4 name iot-trusted rule 421 description 'Rule: accept_tcp_from_sonos_players_to_sonos_controllers'
set firewall ipv4 name iot-trusted rule 421 destination group address-group 'sonos-controllers'
set firewall ipv4 name iot-trusted rule 421 destination port '1400,3400,3401,3500,30000-65535'
set firewall ipv4 name iot-trusted rule 421 protocol 'tcp'
set firewall ipv4 name iot-trusted rule 421 source group address-group 'sonos-players'
set firewall ipv4 name iot-wan default-action 'accept'
set firewall ipv4 name iot-wan description 'From IOT to WAN'
set firewall ipv4 name lan-guest default-action 'drop'
set firewall ipv4 name lan-guest description 'From LAN to GUEST'
set firewall ipv4 name lan-guest enable-default-log
set firewall ipv4 name lan-homelab default-action 'drop'
set firewall ipv4 name lan-homelab description 'From LAN to HOMELAB'
set firewall ipv4 name lan-homelab enable-default-log
set firewall ipv4 name lan-iot default-action 'drop'
set firewall ipv4 name lan-iot description 'From LAN to IOT'
set firewall ipv4 name lan-iot enable-default-log
set firewall ipv4 name lan-local default-action 'drop'
set firewall ipv4 name lan-local description 'From LAN to LOCAL'
set firewall ipv4 name lan-local enable-default-log
set firewall ipv4 name lan-local rule 100 action 'accept'
set firewall ipv4 name lan-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name lan-local rule 100 destination port 'ntp'
set firewall ipv4 name lan-local rule 100 protocol 'udp'
set firewall ipv4 name lan-local rule 110 action 'accept'
set firewall ipv4 name lan-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name lan-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name lan-local rule 110 protocol 'udp'
set firewall ipv4 name lan-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name lan-local rule 160 action 'accept'
set firewall ipv4 name lan-local rule 160 description 'Rule: accept ssh'
set firewall ipv4 name lan-local rule 160 destination port 'ssh'
set firewall ipv4 name lan-local rule 160 protocol 'tcp'
set firewall ipv4 name lan-local rule 900 action 'drop'
set firewall ipv4 name lan-local rule 900 description 'Rule: drop 10001 (no log)'
set firewall ipv4 name lan-local rule 900 destination port '10001'
set firewall ipv4 name lan-local rule 900 protocol 'udp'
set firewall ipv4 name lan-local rule 910 action 'drop'
set firewall ipv4 name lan-local rule 910 description 'Rule: drop multicast to 224.0.0.1 (no log)'
set firewall ipv4 name lan-local rule 910 destination address '224.0.0.1'
set firewall ipv4 name lan-local rule 910 protocol '2'
set firewall ipv4 name lan-servers default-action 'drop'
set firewall ipv4 name lan-servers description 'From LAN to SERVERS'
set firewall ipv4 name lan-servers enable-default-log
set firewall ipv4 name lan-services default-action 'accept'
set firewall ipv4 name lan-services description 'From LAN to SERVICES'
set firewall ipv4 name lan-services enable-default-log
set firewall ipv4 name lan-services rule 170 action 'accept'
set firewall ipv4 name lan-services rule 170 description 'Rule: accept dns'
set firewall ipv4 name lan-services rule 170 destination port 'domain,domain-s'
set firewall ipv4 name lan-services rule 170 protocol 'tcp_udp'
set firewall ipv4 name lan-services rule 300 action 'accept'
set firewall ipv4 name lan-services rule 300 description 'Rule: accept unifi'
set firewall ipv4 name lan-services rule 300 destination group address-group 'unifi-controller'
set firewall ipv4 name lan-staging default-action 'drop'
set firewall ipv4 name lan-staging description 'From LAN to STAGING'
set firewall ipv4 name lan-staging enable-default-log
set firewall ipv4 name lan-trusted default-action 'drop'
set firewall ipv4 name lan-trusted description 'From LAN to TRUSTED'
set firewall ipv4 name lan-trusted enable-default-log
set firewall ipv4 name lan-trusted rule 900 action 'drop'
set firewall ipv4 name lan-trusted rule 900 description 'Rule: drop 10001 (no log)'
set firewall ipv4 name lan-trusted rule 900 destination port '10001'
set firewall ipv4 name lan-trusted rule 900 protocol 'udp'
set firewall ipv4 name lan-wan default-action 'accept'
set firewall ipv4 name lan-wan description 'From LAN to WAN'
set firewall ipv4 name local-guest default-action 'drop'
set firewall ipv4 name local-guest description 'From LOCAL to GUEST'
set firewall ipv4 name local-guest enable-default-log
set firewall ipv4 name local-guest rule 120 action 'accept'
set firewall ipv4 name local-guest rule 120 description 'Rule: accept igmp'
set firewall ipv4 name local-guest rule 120 protocol '2'
set firewall ipv4 name local-guest rule 130 action 'accept'
set firewall ipv4 name local-guest rule 130 description 'Rule: accept mdns'
set firewall ipv4 name local-guest rule 130 destination port 'mdns'
set firewall ipv4 name local-guest rule 130 protocol 'udp'
set firewall ipv4 name local-guest rule 130 source port 'mdns'
set firewall ipv4 name local-guest rule 410 action 'accept'
set firewall ipv4 name local-guest rule 410 description 'Rule: accept_discovery_from_sonos_players'
set firewall ipv4 name local-guest rule 410 destination port '1900,1901,1902'
set firewall ipv4 name local-guest rule 410 protocol 'udp'
set firewall ipv4 name local-guest rule 410 source group address-group 'sonos-players'
set firewall ipv4 name local-homelab default-action 'drop'
set firewall ipv4 name local-homelab description 'From LOCAL to HOMELAB'
set firewall ipv4 name local-homelab enable-default-log
set firewall ipv4 name local-homelab rule 140 action 'accept'
set firewall ipv4 name local-homelab rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-homelab rule 140 protocol 'icmp'
set firewall ipv4 name local-homelab rule 150 action 'accept'
set firewall ipv4 name local-homelab rule 150 description 'Rule: accept bgp'
set firewall ipv4 name local-homelab rule 150 destination port 'bgp'
set firewall ipv4 name local-homelab rule 150 protocol 'tcp'
set firewall ipv4 name local-homelab rule 310 action 'accept'
set firewall ipv4 name local-homelab rule 310 description 'Rule: accept vector syslog'
set firewall ipv4 name local-homelab rule 310 destination port '6003'
set firewall ipv4 name local-homelab rule 310 protocol 'tcp'
set firewall ipv4 name local-homelab rule 410 action 'accept'
set firewall ipv4 name local-homelab rule 410 description 'Rule: accept_discovery_from_sonos_players'
set firewall ipv4 name local-homelab rule 410 destination port '1900,1901,1902'
set firewall ipv4 name local-homelab rule 410 protocol 'udp'
set firewall ipv4 name local-homelab rule 410 source group address-group 'sonos-players'
set firewall ipv4 name local-iot default-action 'drop'
set firewall ipv4 name local-iot description 'From LOCAL to IOT'
set firewall ipv4 name local-iot enable-default-log
set firewall ipv4 name local-iot rule 120 action 'accept'
set firewall ipv4 name local-iot rule 120 description 'Rule: accept igmp'
set firewall ipv4 name local-iot rule 120 protocol '2'
set firewall ipv4 name local-iot rule 130 action 'accept'
set firewall ipv4 name local-iot rule 130 description 'Rule: accept mdns'
set firewall ipv4 name local-iot rule 130 destination port 'mdns'
set firewall ipv4 name local-iot rule 130 protocol 'udp'
set firewall ipv4 name local-iot rule 130 source port 'mdns'
set firewall ipv4 name local-iot rule 140 action 'accept'
set firewall ipv4 name local-iot rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-iot rule 140 protocol 'icmp'
set firewall ipv4 name local-iot rule 400 action 'accept'
set firewall ipv4 name local-iot rule 400 description 'Rule: accept_discovery_from_sonos_controllers'
set firewall ipv4 name local-iot rule 400 destination port '1900,1901,1902,57621'
set firewall ipv4 name local-iot rule 400 protocol 'udp'
set firewall ipv4 name local-iot rule 400 source group address-group 'sonos-controllers'
set firewall ipv4 name local-lan default-action 'drop'
set firewall ipv4 name local-lan description 'From LOCAL to LAN'
set firewall ipv4 name local-lan enable-default-log
set firewall ipv4 name local-lan rule 140 action 'accept'
set firewall ipv4 name local-lan rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-lan rule 140 protocol 'icmp'
set firewall ipv4 name local-lan rule 160 action 'accept'
set firewall ipv4 name local-lan rule 160 description 'Rule: accept ssh'
set firewall ipv4 name local-lan rule 160 destination port 'ssh'
set firewall ipv4 name local-lan rule 160 protocol 'tcp'
set firewall ipv4 name local-servers default-action 'drop'
set firewall ipv4 name local-servers description 'From LOCAL to SERVERS'
set firewall ipv4 name local-servers enable-default-log
set firewall ipv4 name local-servers rule 140 action 'accept'
set firewall ipv4 name local-servers rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-servers rule 140 protocol 'icmp'
set firewall ipv4 name local-servers rule 150 action 'accept'
set firewall ipv4 name local-servers rule 150 description 'Rule: accept bgp'
set firewall ipv4 name local-servers rule 150 destination port 'bgp'
set firewall ipv4 name local-servers rule 150 protocol 'tcp'
set firewall ipv4 name local-services default-action 'accept'
set firewall ipv4 name local-services description 'From LOCAL to SERVICES'
set firewall ipv4 name local-staging default-action 'drop'
set firewall ipv4 name local-staging description 'From LOCAL to STAGING'
set firewall ipv4 name local-staging enable-default-log
set firewall ipv4 name local-staging rule 140 action 'accept'
set firewall ipv4 name local-staging rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-staging rule 140 protocol 'icmp'
set firewall ipv4 name local-staging rule 150 action 'accept'
set firewall ipv4 name local-staging rule 150 description 'Rule: accept bgp'
set firewall ipv4 name local-staging rule 150 destination port 'bgp'
set firewall ipv4 name local-staging rule 150 protocol 'tcp'
set firewall ipv4 name local-trusted default-action 'drop'
set firewall ipv4 name local-trusted description 'From LOCAL to TRUSTED'
set firewall ipv4 name local-trusted enable-default-log
set firewall ipv4 name local-trusted rule 120 action 'accept'
set firewall ipv4 name local-trusted rule 120 description 'Rule: accept igmp'
set firewall ipv4 name local-trusted rule 120 protocol '2'
set firewall ipv4 name local-trusted rule 130 action 'accept'
set firewall ipv4 name local-trusted rule 130 description 'Rule: accept mdns'
set firewall ipv4 name local-trusted rule 130 destination port 'mdns'
set firewall ipv4 name local-trusted rule 130 protocol 'udp'
set firewall ipv4 name local-trusted rule 130 source port 'mdns'
set firewall ipv4 name local-trusted rule 140 action 'accept'
set firewall ipv4 name local-trusted rule 140 description 'Rule: accept icmp'
set firewall ipv4 name local-trusted rule 140 protocol 'icmp'
set firewall ipv4 name local-trusted rule 180 action 'accept'
set firewall ipv4 name local-trusted rule 180 description 'Rule: accept wireguard'
set firewall ipv4 name local-trusted rule 180 destination port '51820'
set firewall ipv4 name local-trusted rule 180 protocol 'udp'
set firewall ipv4 name local-trusted rule 410 action 'accept'
set firewall ipv4 name local-trusted rule 410 description 'Rule: accept_discovery_from_sonos_players'
set firewall ipv4 name local-trusted rule 410 destination port '1900,1901,1902'
set firewall ipv4 name local-trusted rule 410 protocol 'udp'
set firewall ipv4 name local-trusted rule 410 source group address-group 'sonos-players'
set firewall ipv4 name local-wan default-action 'accept'
set firewall ipv4 name local-wan description 'From LOCAL to WAN'
set firewall ipv4 name servers-guest default-action 'drop'
set firewall ipv4 name servers-guest description 'From SERVERS to GUEST'
set firewall ipv4 name servers-guest enable-default-log
set firewall ipv4 name servers-homelab default-action 'accept'
set firewall ipv4 name servers-homelab description 'From SERVERS to HOMELAB'
set firewall ipv4 name servers-iot default-action 'accept'
set firewall ipv4 name servers-iot description 'From SERVERS to IOT'
set firewall ipv4 name servers-lan default-action 'drop'
set firewall ipv4 name servers-lan description 'From SERVERS to LAN'
set firewall ipv4 name servers-lan enable-default-log
set firewall ipv4 name servers-lan rule 140 action 'accept'
set firewall ipv4 name servers-lan rule 140 description 'Rule: accept icmp'
set firewall ipv4 name servers-lan rule 140 protocol 'icmp'
set firewall ipv4 name servers-lan rule 500 action 'accept'
set firewall ipv4 name servers-lan rule 500 description 'Rule: accept rtsp'
set firewall ipv4 name servers-lan rule 500 destination group address-group 'unifi-unvr'
set firewall ipv4 name servers-local default-action 'drop'
set firewall ipv4 name servers-local description 'From SERVERS to LOCAL'
set firewall ipv4 name servers-local enable-default-log
set firewall ipv4 name servers-local rule 100 action 'accept'
set firewall ipv4 name servers-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name servers-local rule 100 destination port 'ntp'
set firewall ipv4 name servers-local rule 100 protocol 'udp'
set firewall ipv4 name servers-local rule 110 action 'accept'
set firewall ipv4 name servers-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name servers-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name servers-local rule 110 protocol 'udp'
set firewall ipv4 name servers-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name servers-local rule 140 action 'accept'
set firewall ipv4 name servers-local rule 140 description 'Rule: accept icmp'
set firewall ipv4 name servers-local rule 140 protocol 'icmp'
set firewall ipv4 name servers-local rule 150 action 'accept'
set firewall ipv4 name servers-local rule 150 description 'Rule: accept bgp'
set firewall ipv4 name servers-local rule 150 destination port 'bgp'
set firewall ipv4 name servers-local rule 150 protocol 'tcp'
set firewall ipv4 name servers-local rule 160 action 'accept'
set firewall ipv4 name servers-local rule 160 description 'Rule: accept ssh'
set firewall ipv4 name servers-local rule 160 destination port 'ssh'
set firewall ipv4 name servers-local rule 160 protocol 'tcp'
set firewall ipv4 name servers-local rule 330 action 'accept'
set firewall ipv4 name servers-local rule 330 description 'Rule: accept iperf'
set firewall ipv4 name servers-local rule 330 destination port '5001'
set firewall ipv4 name servers-local rule 330 protocol 'tcp'
set firewall ipv4 name servers-local rule 910 action 'drop'
set firewall ipv4 name servers-local rule 910 description 'Rule: drop multicast to 224.0.0.1 (no log)'
set firewall ipv4 name servers-local rule 910 destination address '224.0.0.1'
set firewall ipv4 name servers-local rule 910 protocol '2'
set firewall ipv4 name servers-services default-action 'accept'
set firewall ipv4 name servers-services description 'From SERVERS to SERVICES'
set firewall ipv4 name servers-staging default-action 'accept'
set firewall ipv4 name servers-staging description 'From SERVERS to STAGING'
set firewall ipv4 name servers-trusted default-action 'drop'
set firewall ipv4 name servers-trusted description 'From SERVERS to TRUSTED'
set firewall ipv4 name servers-trusted rule 140 action 'accept'
set firewall ipv4 name servers-trusted rule 140 description 'Rule: accept icmp'
set firewall ipv4 name servers-trusted rule 140 protocol 'icmp'
set firewall ipv4 name servers-trusted rule 160 action 'accept'
set firewall ipv4 name servers-trusted rule 160 description 'Rule: accept ssh'
set firewall ipv4 name servers-trusted rule 160 destination port 'ssh'
set firewall ipv4 name servers-trusted rule 160 protocol 'tcp'
set firewall ipv4 name servers-wan default-action 'accept'
set firewall ipv4 name servers-wan description 'From SERVERS to WAN'
set firewall ipv4 name services-guest default-action 'drop'
set firewall ipv4 name services-guest description 'From SERVICES to GUEST'
set firewall ipv4 name services-guest enable-default-log
set firewall ipv4 name services-homelab default-action 'accept'
set firewall ipv4 name services-homelab description 'From SERVICES to HOMELAB'
set firewall ipv4 name services-iot default-action 'drop'
set firewall ipv4 name services-iot description 'From SERVICES to IOT'
set firewall ipv4 name services-iot enable-default-log
set firewall ipv4 name services-iot rule 140 action 'accept'
set firewall ipv4 name services-iot rule 140 description 'Rule: accept icmp'
set firewall ipv4 name services-iot rule 140 protocol 'icmp'
set firewall ipv4 name services-lan default-action 'accept'
set firewall ipv4 name services-lan description 'From SERVICES to LAN'
set firewall ipv4 name services-lan enable-default-log
set firewall ipv4 name services-lan rule 140 action 'accept'
set firewall ipv4 name services-lan rule 140 description 'Rule: accept icmp'
set firewall ipv4 name services-lan rule 140 protocol 'icmp'
set firewall ipv4 name services-local default-action 'drop'
set firewall ipv4 name services-local description 'From SERVICES to LOCAL'
set firewall ipv4 name services-local enable-default-log
set firewall ipv4 name services-local rule 100 action 'accept'
set firewall ipv4 name services-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name services-local rule 100 destination port 'ntp'
set firewall ipv4 name services-local rule 100 protocol 'udp'
set firewall ipv4 name services-local rule 110 action 'accept'
set firewall ipv4 name services-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name services-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name services-local rule 110 protocol 'udp'
set firewall ipv4 name services-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name services-servers default-action 'accept'
set firewall ipv4 name services-servers description 'From SERVICES to SERVERS'
set firewall ipv4 name services-staging default-action 'accept'
set firewall ipv4 name services-staging description 'From SERVICES to STAGING'
set firewall ipv4 name services-trusted default-action 'drop'
set firewall ipv4 name services-trusted description 'From SERVICES to TRUSTED'
set firewall ipv4 name services-trusted enable-default-log
set firewall ipv4 name services-wan default-action 'accept'
set firewall ipv4 name services-wan description 'From SERVICES to WAN'
set firewall ipv4 name staging-guest default-action 'drop'
set firewall ipv4 name staging-guest description 'From STAGING to GUEST'
set firewall ipv4 name staging-guest enable-default-log
set firewall ipv4 name staging-homelab default-action 'accept'
set firewall ipv4 name staging-homelab description 'From STAGING to HOMELAB'
set firewall ipv4 name staging-iot default-action 'accept'
set firewall ipv4 name staging-iot description 'From STAGING to IOT'
set firewall ipv4 name staging-lan default-action 'drop'
set firewall ipv4 name staging-lan description 'From STAGING to LAN'
set firewall ipv4 name staging-lan enable-default-log
set firewall ipv4 name staging-lan rule 140 action 'accept'
set firewall ipv4 name staging-lan rule 140 description 'Rule: accept icmp'
set firewall ipv4 name staging-lan rule 140 protocol 'icmp'
set firewall ipv4 name staging-local default-action 'drop'
set firewall ipv4 name staging-local description 'From STAGING to LOCAL'
set firewall ipv4 name staging-local enable-default-log
set firewall ipv4 name staging-local rule 100 action 'accept'
set firewall ipv4 name staging-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name staging-local rule 100 destination port 'ntp'
set firewall ipv4 name staging-local rule 100 protocol 'udp'
set firewall ipv4 name staging-local rule 110 action 'accept'
set firewall ipv4 name staging-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name staging-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name staging-local rule 110 protocol 'udp'
set firewall ipv4 name staging-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name staging-local rule 140 action 'accept'
set firewall ipv4 name staging-local rule 140 description 'Rule: accept icmp'
set firewall ipv4 name staging-local rule 140 protocol 'icmp'
set firewall ipv4 name staging-local rule 150 action 'accept'
set firewall ipv4 name staging-local rule 150 description 'Rule: accept bgp'
set firewall ipv4 name staging-local rule 150 destination port 'bgp'
set firewall ipv4 name staging-local rule 150 protocol 'tcp'
set firewall ipv4 name staging-local rule 350 action 'accept'
set firewall ipv4 name staging-local rule 350 description 'Rule: accept prometheus metrics scrape'
set firewall ipv4 name staging-local rule 350 destination group port-group 'prometheus-metrics'
set firewall ipv4 name staging-local rule 350 protocol 'tcp'
set firewall ipv4 name staging-local rule 910 action 'drop'
set firewall ipv4 name staging-local rule 910 description 'Rule: drop multicast to 224.0.0.1 (no log)'
set firewall ipv4 name staging-local rule 910 destination address '224.0.0.1'
set firewall ipv4 name staging-local rule 910 protocol '2'
set firewall ipv4 name staging-servers default-action 'accept'
set firewall ipv4 name staging-servers description 'From STAGING to SERVERS'
set firewall ipv4 name staging-services default-action 'accept'
set firewall ipv4 name staging-services description 'From STAGING to SERVICES'
set firewall ipv4 name staging-trusted default-action 'drop'
set firewall ipv4 name staging-trusted description 'From STAGING to TRUSTED'
set firewall ipv4 name staging-trusted rule 140 action 'accept'
set firewall ipv4 name staging-trusted rule 140 description 'Rule: accept icmp'
set firewall ipv4 name staging-trusted rule 140 protocol 'icmp'
set firewall ipv4 name staging-wan default-action 'accept'
set firewall ipv4 name staging-wan description 'From STAGING to WAN'
set firewall ipv4 name trusted-guest default-action 'drop'
set firewall ipv4 name trusted-guest description 'From TRUSTED to GUEST'
set firewall ipv4 name trusted-guest enable-default-log
set firewall ipv4 name trusted-homelab default-action 'drop'
set firewall ipv4 name trusted-homelab description 'From TRUSTED to HOMELAB'
set firewall ipv4 name trusted-homelab enable-default-log
set firewall ipv4 name trusted-homelab rule 520 action 'accept'
set firewall ipv4 name trusted-homelab rule 520 description 'Rule: accept scotte'
set firewall ipv4 name trusted-homelab rule 520 source group address-group 'scotte-devices'
set firewall ipv4 name trusted-homelab rule 530 action 'accept'
set firewall ipv4 name trusted-homelab rule 530 description 'Rule: accept sophie'
set firewall ipv4 name trusted-homelab rule 530 source group address-group 'sophie-devices'
set firewall ipv4 name trusted-iot default-action 'accept'
set firewall ipv4 name trusted-iot description 'From TRUSTED to IOT'
set firewall ipv4 name trusted-iot rule 430 action 'accept'
set firewall ipv4 name trusted-iot rule 430 description 'Rule: accept_tcp_from_sonos_controllers_to_sonos_players'
set firewall ipv4 name trusted-iot rule 430 destination group address-group 'sonos-players'
set firewall ipv4 name trusted-iot rule 430 destination port '1400,1443,4444,7000,30000-65535'
set firewall ipv4 name trusted-iot rule 430 protocol 'tcp'
set firewall ipv4 name trusted-iot rule 430 source group address-group 'sonos-controllers'
set firewall ipv4 name trusted-iot rule 431 action 'accept'
set firewall ipv4 name trusted-iot rule 431 description 'Rule: accept_udp_from_sonos_controllers_to_sonos_players'
set firewall ipv4 name trusted-iot rule 431 destination group address-group 'sonos-players'
set firewall ipv4 name trusted-iot rule 431 destination port '319,320,30000-65535'
set firewall ipv4 name trusted-iot rule 431 protocol 'udp'
set firewall ipv4 name trusted-iot rule 431 source group address-group 'sonos-controllers'
set firewall ipv4 name trusted-lan default-action 'drop'
set firewall ipv4 name trusted-lan description 'From TRUSTED to LAN'
set firewall ipv4 name trusted-lan enable-default-log
set firewall ipv4 name trusted-lan rule 520 action 'accept'
set firewall ipv4 name trusted-lan rule 520 description 'Rule: accept scotte'
set firewall ipv4 name trusted-lan rule 520 source group address-group 'scotte-devices'
set firewall ipv4 name trusted-lan rule 540 action 'accept'
set firewall ipv4 name trusted-lan rule 540 description 'Rule: accept cameras'
set firewall ipv4 name trusted-lan rule 540 source group address-group 'unifi-cameras'
set firewall ipv4 name trusted-local default-action 'drop'
set firewall ipv4 name trusted-local description 'From TRUSTED to LOCAL'
set firewall ipv4 name trusted-local enable-default-log
set firewall ipv4 name trusted-local rule 100 action 'accept'
set firewall ipv4 name trusted-local rule 100 description 'Rule: accept ntp'
set firewall ipv4 name trusted-local rule 100 destination port 'ntp'
set firewall ipv4 name trusted-local rule 100 protocol 'udp'
set firewall ipv4 name trusted-local rule 110 action 'accept'
set firewall ipv4 name trusted-local rule 110 description 'Rule: accept dhcp'
set firewall ipv4 name trusted-local rule 110 destination port 'bootps,bootpc'
set firewall ipv4 name trusted-local rule 110 protocol 'udp'
set firewall ipv4 name trusted-local rule 110 source port 'bootps,bootpc'
set firewall ipv4 name trusted-local rule 120 action 'accept'
set firewall ipv4 name trusted-local rule 120 description 'Rule: accept igmp'
set firewall ipv4 name trusted-local rule 120 protocol '2'
set firewall ipv4 name trusted-local rule 130 action 'accept'
set firewall ipv4 name trusted-local rule 130 description 'Rule: accept mdns'
set firewall ipv4 name trusted-local rule 130 destination port 'mdns'
set firewall ipv4 name trusted-local rule 130 protocol 'udp'
set firewall ipv4 name trusted-local rule 130 source port 'mdns'
set firewall ipv4 name trusted-local rule 140 action 'accept'
set firewall ipv4 name trusted-local rule 140 description 'Rule: accept icmp'
set firewall ipv4 name trusted-local rule 140 protocol 'icmp'
set firewall ipv4 name trusted-local rule 160 action 'accept'
set firewall ipv4 name trusted-local rule 160 description 'Rule: accept ssh'
set firewall ipv4 name trusted-local rule 160 destination port 'ssh'
set firewall ipv4 name trusted-local rule 160 protocol 'tcp'
set firewall ipv4 name trusted-local rule 320 action 'accept'
set firewall ipv4 name trusted-local rule 320 description 'Rule: accept vnstat'
set firewall ipv4 name trusted-local rule 320 destination port '8685'
set firewall ipv4 name trusted-local rule 320 protocol 'tcp'
set firewall ipv4 name trusted-local rule 330 action 'accept'
set firewall ipv4 name trusted-local rule 330 description 'Rule: accept iperf'
set firewall ipv4 name trusted-local rule 330 destination port '5001'
set firewall ipv4 name trusted-local rule 330 protocol 'tcp'
set firewall ipv4 name trusted-local rule 340 action 'drop'
set firewall ipv4 name trusted-local rule 340 description 'Rule: ignore scansnap probe'
set firewall ipv4 name trusted-local rule 340 destination address '255.255.255.255'
set firewall ipv4 name trusted-local rule 340 destination port '52217'
set firewall ipv4 name trusted-local rule 340 protocol 'udp'
set firewall ipv4 name trusted-local rule 340 source group address-group 'scanner-clients'
set firewall ipv4 name trusted-local rule 450 action 'accept'
set firewall ipv4 name trusted-local rule 450 description 'Rule: accept_discovery_from_sonos_controllers'
set firewall ipv4 name trusted-local rule 450 destination port '1900,1901,1902,57621'
set firewall ipv4 name trusted-local rule 450 protocol 'udp'
set firewall ipv4 name trusted-local rule 450 source group address-group 'sonos-controllers'
set firewall ipv4 name trusted-servers default-action 'drop'
set firewall ipv4 name trusted-servers description 'From TRUSTED to SERVERS'
set firewall ipv4 name trusted-servers enable-default-log
set firewall ipv4 name trusted-servers rule 520 action 'accept'
set firewall ipv4 name trusted-servers rule 520 description 'Rule: accept scotte'
set firewall ipv4 name trusted-servers rule 520 source group address-group 'scotte-devices'
set firewall ipv4 name trusted-servers rule 530 action 'accept'
set firewall ipv4 name trusted-servers rule 530 description 'Rule: accept sophie'
set firewall ipv4 name trusted-servers rule 530 source group address-group 'sophie-devices'
set firewall ipv4 name trusted-services default-action 'accept'
set firewall ipv4 name trusted-services description 'From TRUSTED to SERVICES'
set firewall ipv4 name trusted-staging default-action 'drop'
set firewall ipv4 name trusted-staging description 'From TRUSTED to STAGING'
set firewall ipv4 name trusted-staging enable-default-log
set firewall ipv4 name trusted-staging rule 520 action 'accept'
set firewall ipv4 name trusted-staging rule 520 description 'Rule: accept scotte'
set firewall ipv4 name trusted-staging rule 520 source group address-group 'scotte-devices'
set firewall ipv4 name trusted-wan default-action 'accept'
set firewall ipv4 name trusted-wan description 'From TRUSTED to WAN'
set firewall ipv4 name wan-guest default-action 'drop'
set firewall ipv4 name wan-guest description 'From WAN to GUEST'
set firewall ipv4 name wan-guest enable-default-log
set firewall ipv4 name wan-homelab default-action 'drop'
set firewall ipv4 name wan-homelab description 'From WAN to HOMELAB'
set firewall ipv4 name wan-homelab enable-default-log
set firewall ipv4 name wan-iot default-action 'drop'
set firewall ipv4 name wan-iot description 'From WAN to IOT'
set firewall ipv4 name wan-iot enable-default-log
set firewall ipv4 name wan-lan default-action 'drop'
set firewall ipv4 name wan-lan description 'From WAN to LAN'
set firewall ipv4 name wan-lan enable-default-log
set firewall ipv4 name wan-local default-action 'drop'
set firewall ipv4 name wan-local description 'From WAN to LOCAL'
set firewall ipv4 name wan-local enable-default-log
set firewall ipv4 name wan-local rule 180 action 'accept'
set firewall ipv4 name wan-local rule 180 description 'Rule: accept wireguard'
set firewall ipv4 name wan-local rule 180 destination port '51820'
set firewall ipv4 name wan-local rule 180 protocol 'udp'
set firewall ipv4 name wan-servers default-action 'drop'
set firewall ipv4 name wan-servers description 'From WAN to SERVERS'
set firewall ipv4 name wan-servers enable-default-log
set firewall ipv4 name wan-services default-action 'drop'
set firewall ipv4 name wan-services description 'From WAN to SERVICES'
set firewall ipv4 name wan-services enable-default-log
set firewall ipv4 name wan-staging default-action 'drop'
set firewall ipv4 name wan-staging description 'From WAN to STAGING'
set firewall ipv4 name wan-staging enable-default-log
set firewall ipv4 name wan-trusted default-action 'drop'
set firewall ipv4 name wan-trusted description 'From WAN to TRUSTED'
set firewall ipv4 name wan-trusted enable-default-log
