# SimpleLotto
A simple lottery addon for WoW Classic


# Commands

- /sl add {player_name} {# of tickets} # This will add a player and the number of tickets they bought. Also updates players if they already exist in the session.
- /sl remove {player_name}
- /sl status  # shows the current session's players, ticket amounts, and total pot.
- /sl close # this will close the buying of tickets and distributes the ticket numbers (in whisper) to all players. A /roll will be announced for determining winning ticket number.

- /sl reset # close the current session


# Recall

Players can whisper the lottery master 'tickets' or 'numbers' which will respond depending on the phase:

if the session is still open, the player will receive the amount of tickets they currently bought.
if the session is closed, the player will receive their ticket numbers.
