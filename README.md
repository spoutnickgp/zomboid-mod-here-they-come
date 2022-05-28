Here They Come (beta): An immersive horde event experience!

What does it do?
This mod introduces horde events to Zomboid! These events are meant to remain immersive, and highly configurable.
Configuration range from their spread, size, variation, and trigger time frame.

Over time, zombies get restless and excited by your scent. After a certain threshold is reached, a horde of zombies will come hunting you down.
The event will also trigger an invisible sound pulse that will draw both existing and horde zombies towards the player (this behavior can be adjusted and turned off).

How do I customize my experience?
There are many sandbox variables that can help you tailor the experience to your liking:
	
    - Cooldown: Cooldown between two hordes in game minutes
	- Min Starting Hour: Min hour of day at which the Horde may happen
    - Max Starting Hour: Max hour of day at which the Horde may happend
    - Minimum hourly progress: Minimum amount of agitation per hour
    - Maximum hourly progress: Maximum amount of agitation per hour
    - Trigger threshold: Horde agitation trigger threshold
    - First day: First day at which a horde may appear
    - Number of waves: Number of zombie waves per horde
    - Minimum zombies: Minimum amount of zombies per wave
    - Maximum zombies: Maximum amount of zombies per wave
    - Additional Zombies per horde: Additional number of maximum zombies for each horde
    - Time between waves: Number of minutes between waves
    - Minimum spawn distance: Minimum wave spawn distance
    - Maximum horde spawn distance: Maximum wave spawn distance
    - Horde Angle Spread: Max angle at which the wave origin may be focused
    - Zombies per spawn batch: Number of zombies per spawn batch
    - Spawn Rate: Delay in ticks between spawn batches
    - Horde progress indicator: Whether to display the horde agitation icon or not
    - Heads-up text: Displays a warning text when horde starts/progresses
    - Heads-up time: Number of minutes after the event before the first wave starts
    - Noise pulse on player: Silently pulse and draw zombies to player during Horde
    - Pulse Range: Range of the pulse pulling zombies to players
    - Noise Pulse Frequency: How many minutes between noise pulses

Will it work on multiplayer?
This mod was designed with MP in mind, so: YES!

Where and how will the zombies spawn?
They currently spawn outside only, in adjustable batches, and in several waves. Each player in an area will increase the amount of spawned zombies. Their direction is random, but will be consistent across players. The spread can be adjusted so they may also come from every direction.

What kind of zombies will spawn?
Zombies will have their outfits adequately adjusted according to their spawn biome.

Is it safe to add to an existing save?
Yes.

Mod by SpoutNick, code available on github: https://github.com/spoutnickgp/zomboid-mod-here-they-come

CHANGELOG:

222-05-28 - v0.3.1
- Tweaked zombie diversity to reduce army presence in some vegetation biomes
- Switch to new logo by M1NH4U
- Add documentation by M1NH4U

2022-04-01 - v0.3.0
- Fix wave spacing not waiting for wave to finish spawning
- Fix north/south inversion
- Reduce defaults spawn range

2022-03-28 - v0.2.1
- Wake sleeping players on horde start
- Improve sound effects on wave start
- Fix ambient sounds not triggering properly
- Fix errors on UI image sequence missload

2022-03-27 - v0.2.0
- New display icon for horde status
- Fix horde size increment calculation
- Adjust default time frame
- Increase nav biome zombies diversity

2022-03-26 - v0.1.0
- Initial beta release