# barkvr
Social XR creation tool built on Godot 4

Though the project is not yet ready for a release of any kind,
if you would like to test it out and wonder how to launch in
desktop or XR modes, you can use the terminal and start the
app with the flag `--xr-mode` set to `default`, `on`, or `off` like
this: `./barkvr --xr-mode off` will launch without VR active

## Status

This project is currently very early in development, we are always looking for support
(especially financially [Patreon](https://www.patreon.com/pupperdev) / [Ko-Fi](https://ko-fi.com/Manage/))

If you want to see the current active work, it's in the "dev" branch. I want the main branch to eventually 
become exclusively for releases and major updates, so I've switched my current work to be on dev primarily.
A push to main will hopefully come soon when I get finished with the first primary iteration of the multiplayer.

The current work is going towards getting world saving/loading down to an easy to read plaintext file format and
getting the peer to peer networking up and going. We are using WebRTC and using Matrix as the signaling server.
The plan is to make it so that anyone with a Matrix account can just log in and immediately join other users.

## Core focus:

- Accessibility
- Decentralized design
- Let the user control their creations completely
- Open design

### For latest, look at the "dev" branch!
