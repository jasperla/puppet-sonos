# simple smoke test for sonos_speaker
sonos_speaker { 'Office':
  ensure => present,
  volume => 20,
  bass   => 10
}
