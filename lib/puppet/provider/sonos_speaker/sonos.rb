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

  def create
    self.send_message('play')
  end

  def destroy
    self.send_message('stop')
  end

  def bass
    self.receive_message('bass')
  end

  def bass=(value)
    self.send_message('bass=', value)
  end

  def treble
    self.receive_message('treble')
  end

  def treble=
    self.send_message('treble=', value)
  end

  def loudness
    self.receive_message('loudness')
  end

  def loudness=(value)
    self.send_message('loudness=', self.coerce_bool(value))
  end

  def volume
    self.receive_message('volume')
  end

  def volume=(value)
    self.send_message('volume=', value)
  end

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

  # Figure out if the speaker is already playing (present) has stopped (absent).
  def exists?
    system = Sonos::System.new
    speakers = system.speakers.select { |s| s.name.downcase == @resource[:name].downcase }
    if speakers.size < 1
      fail("Speaker #{resource[:name]} not associated to network?")
    else
      # There is no clear way to check which state a speaker is in (playing or
      # not playing). It depends on the audio source (streaming radio or
      # playing from the queue) how we can check the state.

      # In order to figure out what the device is actually playing right now,
      # we need to retrieve the item from the queue with the position that the
      # currently playing track has.
      speaker = speakers.first
      queue_head = speaker.queue[:items][speaker.now_playing[:queue_position].to_i - 1]
      playing = speaker.now_playing

      # Items on the queue have an :id which becomes their :uri when they are
      # actually the currently playing track. If the :id is the :uri, then we are
      # thus playing from the queue. Otherwise we're streaming radio as radio stations
      # are not put onto the queue.
      begin
        queue_head[:id] != playing[:uri] and source = :radio or source = :queue
      rescue
        # Certain radio stations report an out of bounds :queue_position
        source = :radio
      end

      # When streaming radio is the source, the :current_position is set to 0:00:00
      # when paused/stopped.
      # In case of :queue there is no way to figure out if it's playing aside from
      # getting the current position and checking again 1 second later to see if the
      # clock has ticked.
      case source
        when :radio
          playing[:current_position].gsub(/:/, '').to_i > 0 ? present = true : present = false
        when :queue
          old = playing[:current_position].gsub(/:/, '').to_i
          sleep 1
          now = speaker.now_playing[:current_position].gsub(/:/, '').to_i

          old != now ? present = true : present = false
      end
    end

    present
  end

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
