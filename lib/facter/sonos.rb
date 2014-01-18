# Both facts are in the same file to prevent duplicating the costly process of
# setting up the connection and discovering all the devices multiple times.

begin
  require 'sonos'
  system = Sonos::System.new
rescue Exception
  Facter.debug('ruby-sonos not available')
end

Facter.add('sonos_speakers') do
  s = []
  system.speakers.each { |speaker| s << speaker.name }

  setcode do
    s.join(',')
  end
end

system.speakers.each do |speaker|
  Facter.add("sonos_#{speaker.name}_model") do
    setcode do
      speaker.model
    end
  end
end
