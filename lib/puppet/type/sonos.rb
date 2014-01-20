require 'puppet/type'

Puppet::Type.newtype(:sonos) do
  @doc = <<-EOT
    Manage a full Sonos system.

    This type is not ensurable as the system is either setup or not, and within
    the system there is no notion of it's name.

    Main purpose is in conjunction with Schedule in order to ensure all speakers
    paused or playing between certain hours of the day.
EOT

  newparam(:system, :namevar => true) do
    desc 'Name of the Sonos system.'
  end

  newproperty(:play_all) do
    desc 'Set all speakers to playing.'

    defaultto :true
    newvalues(:true, :false)
  end

  newproperty(:pause_all) do
    desc 'Pause all the speakers.'

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:party) do
    desc 'Party mode!'

    defaultto :false
    newvalues(:true, :false)
  end

  newparam(:party_master) do
    desc 'Name of the party master speaker.'
  end
end
