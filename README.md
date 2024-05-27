
### Running:
- install [Love2d](https://love2d.org/) 11.5 (latest atm)
- `love .` runs the client
- `love . --server` runs the server  

saves and config are within the love2d save folder, [check here](https://love2d.org/wiki/love.filesystem)

### Todo:
- dont send all player data every update (stuff like skin only need to be sent once on join)
- add a modular command system to the console, so scenes can load their own custom commands
- move character rendering data to json

### Todo (Bugs):
- setting config arg copies last config into new one because loadconfig is on require
- players can get tiny speedboost from running along + into walls
- fix lang color support, all text that has color must begin with a color code, or it wont be rendered
- disabling fullscreen in menu unfocuses game, meaning youll have to click twice to activate a button again
- server will override clients config if closed first

### Todo (Long term):
- separate server from love2d (i didnt before because it relies on enet which is packed with love)
- add singleplayer option (self hosting)
