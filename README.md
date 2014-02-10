sonos
=====

This is the sonos module currently providing a single type to manage
your Sonos system. Currently only a single speaker can be managed.

Types
-----

- `sonos_speaker`
- `sonos`

Facts
-----

- `sonos_speakers` -- list of all Sonos speakers, by name
- `sonos_$speaker_model` -- model of the given Sonos speaker

ToDo
----

- Add additional types such as:
  - `sonos_queue` to manage the queue for a given speaker
- Implement some notion of groups and/or zones.
- ensure => playing/stopped/paused

Dependencies
------------

- The types and facts require that the 'sonos' gem (> 0.3.5) is installed.
- A Sonos system :-) This module was tested with Play:1 and Playbar.

License
-------
ISC
