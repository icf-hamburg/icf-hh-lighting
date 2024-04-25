# Lighting

This repository tracks any scripts / utilities in use for the lighting operator at ICF Hamburg.

Most prominently, this started with a system that allows to connect any MIDI controller to a Windows Host and use this to control about anything using Companion + AutoHotKey. But it also allows to use the same MIDI device in multiple active programs in Windows, which is not possible by default.

# Dependencies

- AutoHotkey (AHK) >=2.0.10: https://www.autohotkey.com/

- Companion: https://bitfocus.io/companion

- MIDI Relay >=3.3.0: https://github.com/josephdadams/midi-relay/releases
	Send REST calls to Companion
	
- MIDI-OX >=7.0.2: http://midiox.com/
	Route the MIDI Signal. Great (while antiquated) utility to work with MIDI

- LoopMIDI >=1.0.16: https://www.tobias-erichsen.de/software/loopmidi.html
	Create multiple virtual MIDI ports
