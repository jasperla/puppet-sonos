require 'puppet/type'

Puppet::Type.newtype(:sonos_speaker) do
  @doc = <<-EOT
    Manage individual Sonos speakers.
EOT

  ensurable

  newparam(:speaker, :namevar => true) do
    desc 'Name of the speaker to manage.'
  end

  newproperty(:bass) do
    desc 'Set the bass level of the speaker to a value between -10 and 10'
    validate do |value|
      fail("Invalid bass #{value}, must be an integer between -10 and 10") unless value =~ /^[0-9]+$/
    end
  end

  newproperty(:treble) do
    desc 'Set the treble level of the speaker to a value between -10 and 10'
    validate do |value|
      fail("Invalid treble #{value}, must be an integer between -10 and 10") unless value =~ /^[0-9]+$/
    end
  end

  newproperty(:loudness) do
    desc 'Toggle the loudness of the speaker'

    defaultto :true
    newvalues(:true, :false)
  end

  newproperty(:volume) do
    desc 'Set the volume for the speaker to a value between 0 and 100'
    validate do |value|
      fail("Invalid volume #{value}, must be an integer between 0 and 100") unless value =~ /^[0-9]+$/
    end
  end

  newproperty(:crossfade) do
    desc 'Set the crossfade playmode for the speaker'

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:repeat) do
    desc 'Set the repeat playmode for the speaker'

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:shuffle) do
    desc 'Set the shuffle playmode for the speaker'

    defaultto :false
    newvalues(:true, :false)
  end

  newproperty(:mute) do
    desc 'Mute the speaker'

    defaultto :false
    newvalues(:true, :false)
  end
end
