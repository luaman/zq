/*  Copyright (C) 2004  Matthew T. Atkinson

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

/* $AGRIP-START */
/* AGRIP Sound Entities */


// NOTES
// 
// All functions here, unless specifed by ``_public'' at the end of their names,
// are intended to work with the soundtoclient() builtin and provide private
// sound messaging to their owner in-game.


// PROTOTYPES

void()  snap_se_singlesound;
void()  snap_se_stickysound;
void()  snap_se_cornersound;
void()  snap_se_loopedsound;
void()  snap_se_loopedsound_public;


// IMPLEMENTATIONS

void() snap_se_singlesound =
/*
    Purpose:
        Facilitates us making delayed sounds.
    Takes:
        void
    Returns:
        void
    Notes:
        Is spawned at the right position and given the apprpriate
        nextthink time.
        Removes itself when done.
*/
{
    soundtoclient(self.owner, self, CHAN_AUTO, self.message, self.frags, ATTN_NORM);
    remove(self);
};

void() snap_se_stickysound =
/*
    Purpose:
        Facilitates us making delayed sounds.
        But doesn't kill itself.
    Takes:
        void
    Returns:
        void
    Notes:
        + An entity should be spawned at the right position and given the
          apprpriate nextthink time.
        + This is the object's .think function.
        + To avoid eating bandwidth, you should not call this more than twice
          per second.
*/
{
    soundtoclient(self.owner, self, CHAN_AUTO, self.message, self.frags, ATTN_NORM);
};


void() snap_se_cornersound =
/*
    Purpose:
        Facilitates us making delayed corner sounds.
    Takes:
        void
    Returns:
        void
    Notes:
        * The following properties are used:
            + self.dest1    - vector to far mid point.
            + self.dest2    - vector to corner point.
            + self.frags    - volume of far mid point's sound.
            + self.health   - volume of corner point's sound.
        * This entity removes itself when completed.
*/
{
    // Check if we've made the first sound yet or not...
    if( ! self.items )
    {
        // No, we haven't...
        setorigin(self, self.dest1);
        soundtoclient(self.owner, self, CHAN_AUTO, self.message, self.frags, ATTN_NORM);
        self.nextthink = time + 0.2;
        self.items = true;
    }
    else
    {
        // Yes, we have; do the corner sound now...
        setorigin(self, self.dest2);
        soundtoclient(self.owner, self, CHAN_AUTO, self.message, self.health, ATTN_NORM);
        remove(self);
    }
};

void() snap_se_loopedsound =
/*
    Purpose:
        Make a looped sound (not ambient, as we might want to delete it
        at some point later on).
    Takes:
        void
    Returns:
        void
*/
{
    soundtoclient(self.owner, self, CHAN_AUTO, self.message, self.frags, ATTN_NORM);
    self.nextthink = time + self.health;
};

void() snap_se_loopedsound_public =
/*
    Purpose:
        Make a looped sound (not ambient, as we might want to delete it
        at some point later on).
    Takes:
        void
    Returns:
        void
*/
{
    sound(self, CHAN_AUTO, self.message, self.frags, ATTN_NORM);
    self.nextthink = time + self.health;
};

/* $AGRIP-END */
