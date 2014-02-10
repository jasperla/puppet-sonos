require 'sonos'

Puppet::Type.type(:sonos_speaker).provide(:sonos) do
  desc 'Manage a single Sonos speaker.'

  # List all available speakers in the current Sonos setup
  def self.instances
    speakers = []
    system = Sonos::System.new

    system.speakers.each do |speaker|
      speakers << new(:name => speaker.name)
    end

    return speakers
  end

  # Equalizer-related methods
  def bass
    self.receive_message('bass')
  end

  def bass=(value)
    self.send_message('bass=', value)
  end

  def loudness
    self.receive_message('loudness')
  end

  def loudness=(value)
    self.send_message('loudness=', self.coerce_bool(value))
  end

  def treble
    self.receive_message('treble')
  end

  def treble=
    self.send_message('treble=', value)
  end

  # Playmode-related methods
  def crossfade
    self.playmode_set?(:crossfade)
  end

  def crossfade=(value)
    self.coerce_bool(value) ? cmd = 'on' : cmd = 'off'
    self.send_message("crossfade_#{cmd}")
  end

  def shuffle
    self.playmode_set?(:shuffle)
  end

  def shuffle=(value)
    self.coerce_bool(value) ? cmd = 'on' : cmd = 'off'
    self.send_message("shuffle_#{cmd}")
  end

  def repeat
    self.playmode_set?(:repeat)
  end

  def repeat=(value)
    self.coerce_bool(value) ? cmd = 'on' : cmd = 'off'
    self.send_message("repeat_#{cmd}")
  end

  # Volume control methods
  def mute
    self.receive_message('muted?')
  end

  def mute=(value)
    self.coerce_bool(value) ? cmd = 'mute' : cmd = 'unmute'
    self.send_message(cmd)
  end

  def volume
    self.receive_message('volume')
  end

  def volume=(value)
    self.send_message('volume=', value)
  end

  # ensurable-related methods
  def create
    self.send_message('play')
  end

  def destroy
    self.send_message('stop')
  end

  # Figure out if the speaker is already playing (present) has stopped (absent).
  def exists?
    system = Sonos::System.new
    speaker = system.speakers.select { |s| s.name.downcase == @resource[:name].downcase }
    present = false
    if speaker.size < 1
      fail("Speaker #{resource[:name]} not associated to network?")
    else
      if speaker[0].get_player_state[:state] == 'PLAYING'
        present = true
      end
    end

    present
  end

  # Local helper methods
  def get_speakers(name)
    system = Sonos::System.new
    speakers = system.speakers.select { |s| s.name.downcase == @resource[:name].downcase }
    fail("Could not find speaker #{resource[:name]}") if speakers.size == 0
    speakers
  end

  # Send a specified message to the speakers.
  def send_message(msg, *args)
    speakers = get_speakers(@resource[:name])
    Puppet.debug("#{resource[:name]} => #{msg} => #{args}")
    speakers.each { |s| s.send msg, *args }
  end

  # Receive a message from the first speaker matching the name, after sending a query.
  def receive_message(msg)
    speakers = get_speakers(@resource[:name])
    answer = speakers.first.send(msg)
    Puppet.debug("#{resource[:name]} <= #{msg} <= #{answer}")
    answer.to_s
  end

  def coerce_bool(value)
    # coerce value into a real boolean
    case value
    when false, :false
      false
    when true, :true
      true
    end
  end

  def playmode_set?(mode)
    speakers = get_speakers(@resource[:name])
    res = speakers.first.get_playmode
    res[mode] == true ? set = 'true' : set = 'false'
    Puppet.debug("#{resource[:name]} playmode #{mode} is #{set}")
    set
  end
end
