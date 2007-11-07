/*
    soldier.qc

    class functions/definitions

    Copyright (C) 1996-1997  Id Software, Inc.

    This program is free software; you can redistribute it and/or
    modify it under the terms of the GNU General Public License
    as published by the Free Software Foundation; either version 2
    of the License, or (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.

    See the GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to:

        Free Software Foundation, Inc.
        59 Temple Place - Suite 330
        Boston, MA  02111-1307, USA

*/

void NailGrenadeExplode ();

void NailGrenadeNailEm ();

void NailGrenadeLaunchNail ();

void NailGrenadeTouch () {
    if ( (other == self.owner) ) {
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void NailGrenadeExplode () {
    entity te;
    float pos;
    if (anti_spam) {
        te = findradius (self.origin, anti_spam);
        while ( te ) {
            te.chain2 = te.chain;
            if ( (te.classname == "info_player_teamspawn") ) {
                spawn_tfog(self.origin);
                dremove (self);
                return;
            }
            te = te.chain2;
        }
    }
    self.owner.no_active_nail_grens = (self.owner.no_active_nail_grens + 1);
    if ( (self.owner.no_active_nail_grens > 0) ) {
        te = find (world,classname,"grenade");
        while ( te ) {
            if ( ((te.owner == self.owner) && (te.no_active_nail_grens == 1)) ) {
                te.weapon = 9;
                te.think = GrenadeExplode;
                te.nextthink = (time + 0.100);
            }
            te = find (te,classname,"grenade");
        }
    }
    self.no_active_nail_grens = self.owner.no_active_nail_grens;
    self.velocity = '0 0 0';
    self.movetype = MOVETYPE_FLY;
    pos = pointcontents (self.origin + '0 0 32');
    if ( ((pos == -2) || (pos == -6)) ) {
        pos = pointcontents (self.origin - '0 0 32');
        if ( ((pos == -2) || (pos == -6)) ) {
            setorigin (self,(self.origin));
        } else {
            setorigin (self,(self.origin - '0 0 32'));
        }
    } else {
        setorigin (self,(self.origin + '0 0 32'));
    }
    self.avelocity = '0 500 0';
    self.nextthink = (time + 0.700);
    self.think = NailGrenadeNailEm;
}

void NailGrenadeNailEm () {
    self.velocity = '0 0 0';
    self.nextthink = (time + 0.100);
    self.think = NailGrenadeLaunchNail;
    self.playerclass = 0;
}

void NailGrenadeLaunchNail () {
    float i;
    float j;
    float cur_yaw;
    i = 0;
    while ( (i < 3) ) {
        j = ((random () + 2) * 5);
        cur_yaw = anglemod ((self.angles_y + j));
        self.angles_y = cur_yaw;
        self.angles_x = 0;
        self.angles_z = 0;
        makevectors (self.angles);
        deathmsg = 9;
		// XXX: identical branches?
        if (modetype & 256) {
            launch_spike (self.origin,v_forward);
            newmis.touch = superspike_touch;
        } else {
            launch_spike (self.origin,v_forward);
            newmis.touch = superspike_touch;
        }
        //newmis.owner = self;
        newmis.weapon = 9;
        i = (i + 1);
    }
    self.playerclass = (self.playerclass + 1);
    self.nextthink = (time + 0.100);
    if ( (self.playerclass > 50) ) {
        self.weapon = 9;
        self.think = GrenadeExplode;
    }
}
