require 'sonos'

Puppet::Type.type(:sonos).provide(:sonos) do
  desc 'Manage a Sonos system.'

  # There's no real way of telling if speakers are in a party right now, so
  # the heuristic used here is if there are more than 1 speakers, but not > 1
  # group, then it's a party!
  # XXX: This is totally untested due to lack of multiple speakers.
  def party
    party?
  end

  # Enter party mode; only makes sense for multiple speakers.
  def party=(value)
    system = Sonos::System.new
    return false if not party?

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

    system.groups.size == '1' ? 'true' : 'false'
  end

  def playing?
    system = Sonos::System.new
    speakers = system.speakers
    if speakers.size < 1
      fail("No speakers associated to Sonos system.")
    else
      is_playing = false
      # There is no clear way to check which state a speaker is in (playing or
      # not playing). It depends on the audio source (streaming radio or
      # playing from the queue) how we can check the state.
      speakers.each do |speaker|
        return false if speaker.now_playing.nil?

        # When playing radio the artist and album are left empty, which is a simple
        # enough heuristic to rely on here.
        playing = speaker.now_playing

        if playing.fetch(:album) == '' and playing.fetch(:artist) == ''
          source = :radio
        else
          source = :queue
        end

        # When streaming radio is the source, the :current_position is set to 0:00:00
        # when paused/stopped.
        # In case of :queue there is no way to figure out if it's playing aside from
        # getting the current position and checking again 1 second later to see if the
        # clock has ticked.
        case source
          when :radio
            playing[:current_position].gsub(/:/, '').to_i > 0 ? is_playing = true : is_playing = false
          when :queue
            old = playing[:current_position].gsub(/:/, '').to_i
            sleep 1
            now = speaker.now_playing[:current_position].gsub(/:/, '').to_i

            old != now ? is_playing = true : is_playing = false
        end

        # Take a shortcut out if the latest speaker isn't playing
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
