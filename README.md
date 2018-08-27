# Avalon

Short-Term Goals (ordered by priority)
--
- [x] Allow users to join a room (no auth; just provide a username)
- [x] Allow basic chat functionality after joining a room.
- [x] Remove unused Phoenix parts, and move the Elm webapp into separate source folder.
- [ ] Implement Presense to see players currently active in a room.
- [ ] Start actually implementing game logic. Look into using fsm (finite state machine) library available in elixir.
- [ ] Allow a game to 'start'. This means that players can terminate the connection, but they will be able to join back without interruption. New players cannot join (but may be able to spectate in future).

Future Goals
---
- [ ] Dockerize for easier development/deployment
- [ ] Add a 'board' mode that will allow you to view the central Avalon game board. Imagine playing around a table with friends in real life. It'd be cool to have a tablet in the center of the table with the game board on it, right?

Far Future Goals
---
- [ ] Permform visualization on game data
- [ ] AI players by using some kind of ML on said game data
