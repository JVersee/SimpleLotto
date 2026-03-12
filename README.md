# SimpleLotto
A simple lottery addon for WoW TBC Anniversary


# Commands

- /sl add {player_name} {# of tickets} # This will add a player and the number of tickets they bought. Also updates players if they already exist in the session.
- /sl remove {player_name}
- /sl status  # shows the current session's players, ticket amounts, and total pot.
- /sl close # this will close the buying of tickets and distributes the ticket numbers (in whisper) to all players. A /roll will be announced for determining winning ticket number.

- /sl reset # close the current session

- /sl  # this will open the UI window to manage the lottery

# Recall

Players can whisper the lottery master 'tickets' or 'numbers' which will respond depending on the phase:

if the session is still open, the player will receive the amount of tickets they currently bought.
if the session is closed, the player will receive their ticket numbers.


# Usage

1. Open the main window with /sl 
2. Use the 'settings' option to set the amount of tickets, price per ticket, guild bank/winner cut off, and which channels to post announcements
3. Save your settings
4. Use the 'Announce Start' button in the top of the main window, to announce lottery start in the configured channels
5. Add players by targetting them and using the 'Add Target' to add number of tickets for targetted player (click multiple times for each ticket)
6. Once all players have been added, use the 'Close & Assign' to assign numbers to tickets which will be shown in the main screen
7. Perform the announced /roll amount to determine a winner
