#  PairsWellWithCheese

PairsWellWithCheese lets users select a trigger that will cause an effect.

Think "if I mount my sorrel horse, my piebald cat appears!"

Currently supported triggers:
- Currently slotted skills
- Collectibles (note not all collectible types are supported!)
- Mounts
- Swimming
- Entering a PVP Zone
- Accepting a duel invitation

Currently supported effects:
- Collectibles (ditto above!)

Deliberately unsupported triggers:
- Fast travel - does not work with mementos (Finnvir's trinket being the one exception), and no other effect would really make sense
- Fishing - the ESO Game API does not really support this
- Combat - I tried but it is just too unreliable.  When you enter combat, collectibles are paused temporarily and everything gets confused.  For the same reason, using skills that pre-buff over a long period of time is better for triggering collectibles than ones that fire quickly and do not buff

Deliberately unsupported effects:
- Companion collectibles - these cannot be equipped outside the companion menu
