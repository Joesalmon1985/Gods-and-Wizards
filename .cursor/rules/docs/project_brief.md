# Game of the Gods / Gods and Wizards

This project is a clean Godot rebuild combining two previous prototypes.

The game has two experiences built on one shared world state.

## Strategic layer

The strategic game is a board-game simulation inspired by Catan, Pandemic, and Seven Wonders.

Players are gods guiding mortal civilisations.

Hexes produce resources.

Corner nodes hold cities, heroes, demons, and developments.

Edges connect nodes and support roads, hero movement, and demon spread.

Players build roads and cities, gather resources, develop cities with special cards, and compete for civilisation score.

At the same time, the underworld spreads across the node network. Players must contain demons or the world falls.

## Embodied wizard layer

The player may also enter the world as a wizard/hero.

This layer lets the player experience local events from inside the world:

* travelling between nodes;
* visiting cities;
* fighting demons;
* duelling rival wizards;
* resolving important board encounters;
* seeing city developments physically represented.

The embodied layer is optional. It does not own the game state.

## Source of truth

The board engine is authoritative.

The embodied layer reads from the board state and sends action requests or encounter results back to the core rules.

There must be one shared GameState, not two games loosely connected.

## Design slogan

One world state. Two ways to experience it.

The board mode controls the simulation.

The wizard mode lets the player inhabit key moments within that simulation.
