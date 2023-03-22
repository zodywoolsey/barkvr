# ptb
Social XR creation tool built on Godot 4

# I am looking for funding for this project:

If you are a grant provider or an investor and are interested
in a project that's primary focus is to create an ecosystem
that allows people to experience, learn, and create XR
content and experiences with various systems; targeted 
at all age groups and team sizes, then this is for you.

The eventual goal is to produce a highly performant XR
creation toolkit with tons of built in features that will
allow people (researchers, developers, students, etc.) to 
very easily create whatever kind of XR experience they want.
Once the project is to a point where the primary features are
avaliable, the team will shift focus to helping Godot 4+ 
keep up to date with XR hardware into the future, so that
the PTB platform can offer a powerful and easy to learn
creation toolkit for the widest range of XR related hardware as
possible.

This is not a "metaverse" project. It is a social/collaborative
creation toolkit. It will allow users to create content in VR/AR
or on desktop with dedicated tooling. The idea is to create a
platform that will help push more XR creation and help the 
general public create XR content and socialize safely within
VR/AR. 

Another major planned feature, is a defined and documented format
for XR objects. We also have a small group who are working together
to define and agree upon a format that will be propogated across
the existing and future XR creation projects. This is called:
XR:OG - XR Object Group

## Status

This project is currently at the beginning of it's development.

If you want to see a deprecated version of the starting concepts of this project,
you can check out Lucid and the GB prefixed projects. 

I was initially planning on building this system for the web using A-Frame, but it
proved to not be quite up to par. There is a consideration on our part to refactor
A-Frame to use newer/faster rendering APIs.


# Current ideas list

## planned features:

- defined APIs for each feature
- shader creation
- scripting
- visual scripting (extension should also be available in Godot editor)
- open viseme detector
- terrain generation
- (maybe) plugin system to allow external systems and languages to be used for specific projects
- mesh creation
- adopt as many platforms as possible:
  - AR
    - android
    - ios
    - pico
    - meta
    - pimax
    - vive XR
    - windows
    - macos
    - linux
    - steam? (openxr)
  - VR
    - android
    - ios?
    - pico
    - meta
    - steamvr
    - windows
    - Oculus/Meta
    - Pimax
    - VivePort
    - PSVR
    - Monado
  - Web
    - ensure widspread compatibility in the hosting method
  - mobile
    - android
    - ios
  - flat view compatibility
    - playstation
    - Xbox
    - Nintendo Switch
    - Steam Deck
  - possible retro targets (might need custom render pipelines or heavy engine changes):
    - PSVita
    - PSP
    - Nintendo console prior to Switch
    - Xbox one and older
    - Playstation 4 and older
  - include a flat view while in XR
- (needs research) Adopt as many XR devices as possible
  - Face tracking
  - full body tracking
  - niche solutions should also be sought out
  - hand tracking input schemes
  - simple remote input schemes (like daydream controller)
- Heavy focus on accessibility on all platforms and in all situations (all of these should be handled by the input system so that users creating experiences don't have much friction making their content safe and accessible)
  - easy world/session/game exit functionality (panic exit)
  - safety bubble mode (panic mode)
  - ability for users to self-moderate their experience
  - one handed operation
  - support for accessibility input methods
  - voice controls
  - (needs a lot of research) EKG compatibility
    - training
      - This basically means that we should allow users who use advanced sensors as input to train the sensor data to correspond to certain input actions
    - ability to cache training data
  - Every single input option should be overrideable and compatible (in whatever way possible) with all accessibility options
  - (needs research) Modify render pipeline to allow advanced control over safety measures for those with any form of light or color sensitivity
    - includes epilepsy protections
    - includes color blindness color remapping
- Full control over all methods of input mapping (system will include initial schema for quick setup)
- (needs research) on the fly initialization and switching from flat to vr views
- Desktop interaction - needs research into high quality capture on all platforms
  - (windows) register mirror service to allow the user to interact with UAC prompts while in PTB
- Audio generation
- advanced audio analyzer
- capture and rerout audio sources
- Integrated messaging
  - offer dedicated messaging apps
    - Use e2e encryption (maybe the user is required to sync with a service on their machine to enable access for a period of time)
  - Allow in-system assets, files, images, custom emoji, etc. in the messaging system
- content repository system
  - public official content repository
  - in system official user content repository
  - allow users to self-host content repositories
  - allow experiences to have their own content repositories with custom data types
    - for example, if a user created a rhythm game, they should be able to define a custom resource that stores the audio data and the data related to the mechanics of the rhythm game
- localization
- 



### planned helpers:

- pivot caching : https://www.youtube.com/watch?v=V1nkv8g-oi0
- terrain generation
- public content repo
  - might look into contacting creators of free assets to add to the public content repo
  - pre-made effects
  - pre-created shaders
    - can be converted into editable shaders with the shader creation utility
- shader creation utility
- procedural meshes
  - a collection of meshes that are generated on the fly to allow easy procedural content creation
- various algorithms for generating advanced noise patterns
  - texture
  - get_point
- Math helpers
  - provide a wide range of math helpers ranging from simple algebraic concepts to advanced mathematics operations
    - Each math helper should have an example and detailed description of what it means/does/can be used for
