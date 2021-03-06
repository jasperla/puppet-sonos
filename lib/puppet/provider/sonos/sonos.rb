require 'sonos'

Puppet::Type.type(:sonos).provide(:sonos) do
  desc 'Manage a Sonos system.'

  # There's no real way of telling if speakers are in a party right now, so
  # the heuristic used here is if there are more than 1 speakers, but not > 1
  # group, then it's a party!
  # XXX: This is totally untested due to lack of multiple speakers.
  def party
    party?.to_s
  end

  # Enter party mode; only makes sense for multiple speakers.
  def party=(value)
    system = Sonos::System.new
    return 'false' if not party?

    if @resource[:party_master]
      self.apply_all('party_mode', @resource[:party_master])
    else
      self.apply_all('party_mode')
    end
  end

  def pause_all
    (not self.playing?).to_s
  end

  def pause_all=(value)
    self.coerce_bool(value) ? cmd = 'pause_all' : cmd = 'play_all'
    self.apply_all(cmd)
  end

  def play_all
    # Go through all speakers and if a single one isn't playing, return false
    self.playing?.to_s
  end

  # Set all speakers to playing iff there's anything to be played.
  def play_all=(value)
    self.coerce_bool(value) ? cmd = 'play_all' : cmd = 'pause_all'
    self.apply_all(cmd)
  end

  # Local helper methods
  def apply_all(cmd, *args)
    system = Sonos::System.new
    system.send(cmd, *args)
  end

  def party?
    system = Sonos::System.new

    # Ensure some pre-conditions for a party are met.
    return false if system.speakers.size < 2 or system.groups.size < 1

    system.groups.size == '1' ? true : false
  end

  def playing?
    system = Sonos::System.new
    speakers = system.speakers
    is_playing = true

    if speakers.size < 1
      fail("No speakers associated to Sonos system.")
    else
      speakers.each do |speaker|
        if speaker.get_player_state != 'PLAYING'
          is_playing = false
        end

        # Take a shortcut out if the last speaker isn't playing.
        break if not is_playing
      end
    end

    is_playing
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
end
