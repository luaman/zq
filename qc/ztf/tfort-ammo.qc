/*
	tfort-ammo.qc

    qwtf ammo related functions/definitions

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

void TeamFortress_AmmoboxThink () {
    //self.pteam.num_ammoboxes = self.pteam.num_ammoboxes - 1;
    store_obs.num_ammoboxes = store_obs.num_ammoboxes - 1;
    dremove(self);
}

void RemoveboldAmmobox () {
    entity box, bold;
    float rt;
    rt = time + 999;
    box = find (world, classname, "ammobox");
    while (box != world) {
        if ((box.nextthink < rt)) {
            bold = box;
            rt = box.nextthink;
        }
        box = find (box, classname, "ammobox");
    }
    if (bold == world) // impossible?
        return ;
    store_obs.num_ammoboxes = store_obs.num_ammoboxes - 1;
    //bold.pteam.num_ammoboxes = bold.pteam.num_ammoboxes - 1;
    dremove(bold);
}

void TeamFortress_AmmoboxTouch () {
    float took;
    string quantity;
    took = 1;
    if ((other == self.enemy) && (time < (self.health + 2)))
        return ;
    if ((other.tfstate & 65536) || (other.tfstate & 2048))
        return ;
    if (other.classname != "player")
        return ;
    if (other.health <= 0)
        return ;
    if ( (self.weapon == 0) ) {
        sprint (other, PRINT_HIGH,"You got ");
        if ( (self.ammo_shells > 0) ) {
            other.ammo_shells = (other.ammo_shells + self.ammo_shells);
            quantity = ftos (self.ammo_shells);
            sprint (other, PRINT_HIGH,quantity," shells  ");
        }
        if ( (self.ammo_nails > 0) ) {
            other.ammo_nails = (other.ammo_nails + self.ammo_nails);
            quantity = ftos (self.ammo_nails);
            sprint (other, PRINT_HIGH,quantity," nails  ");
        }
        if ( (self.ammo_rockets > 0) ) {
            other.ammo_rockets = (other.ammo_rockets + self.ammo_rockets);
            quantity = ftos (self.ammo_rockets);
            sprint (other, PRINT_HIGH,quantity," rockets  ");
        }
        if ( (self.ammo_cells > 0) ) {
            other.ammo_cells = (other.ammo_cells + self.ammo_cells);
            quantity = ftos (self.ammo_cells);
            sprint (other, PRINT_HIGH,quantity," cells  ");
        }
        sprint (other, PRINT_HIGH," from ",self.enemy.netname,"'s discarded pack.\n");
    } else if ( (self.weapon == 1) ) {
        if (other.ammo_shells >= other.maxammo_shells)
            return ;
        other.ammo_shells = (other.ammo_shells + self.ammo_shells);
        if (other.ammo_shells > other.maxammo_shells) {
            self.ammo_shells = other.ammo_shells - other.maxammo_shells;
            took = 0;
        }
        self.netname = "shell";
    } else if ( (self.weapon == 2) ) {
        if (other.ammo_nails >= other.maxammo_nails)
            return ;
        other.ammo_nails = (other.ammo_nails + self.aflag);
        if (other.ammo_nails > other.maxammo_nails) {
            self.ammo_nails = other.ammo_nails - other.maxammo_nails;
            took = 0;
        }
        self.netname = "nail";
    } else if ( (self.weapon == 3) ) {
        if (other.ammo_rockets >= other.maxammo_rockets)
            return ;
        other.ammo_rockets = (other.ammo_rockets + self.aflag);
        if (other.ammo_rockets > other.maxammo_rockets) {
            self.ammo_rockets = other.ammo_rockets - other.maxammo_rockets;
            took = 0;
        }
        self.netname = "rocket";
    } else if ( (self.weapon == 4) ) {
        if (other.ammo_cells >= other.maxammo_cells)
            return ;
        other.ammo_cells = (other.ammo_cells + self.ammo_cells);
        if (other.ammo_cells > other.maxammo_cells) {
            self.ammo_cells = other.ammo_cells - other.maxammo_cells;
            took = 0;
        }
        self.netname = "cell";
    } else if (self.weapon == 5) {
        if ((other.no_grenades_1 >= 4) || (other.tp_grenades_1 != self.tp_grenades_1))
            return;
        other.no_grenades_1 = other.no_grenades_1 + self.no_grenades_1;
        self.netname = Status_GrenTypeToString(self.tp_grenades_1);
    } else if (self.weapon == 6) {
        if ( ( (other.no_grenades_2 >= 4)
                || ((other.no_grenades_2 >= 2) && (other.tp_grenades_2 == 3)) )
                || (other.tp_grenades_2 != self.tp_grenades_2) )
            return;
        other.no_grenades_2 = other.no_grenades_2 + self.no_grenades_2;
        self.netname = Status_GrenTypeToString(self.tp_grenades_2);
    } else if ( (self.weapon == 10) ) {
        if (other.ammo_detpack >= other.maxammo_detpack)
            return ;
        other.ammo_detpack = (other.ammo_detpack + self.ammo_detpack);
        if (other.ammo_detpack > other.maxammo_detpack) {
            self.ammo_detpack = other.ammo_detpack - other.maxammo_detpack;
            took = 0;
        }
        if (modetype & 4) {
            self.netname = "Bomb";
            bprint(PRINT_HIGH, other.netname, " picked up the bomb.\n");
            stuffcmd (other,"topcolor 0\n");
            if (other.playerclass == 8) {
                other.is_unabletospy = 1;
            }
        } else {
            self.netname = "detpack";
        }
    }
    bound_other_ammo (other);
    if (self.weapon > 0) {
        quantity = ftos (self.aflag);
        sprint (other,PRINT_LOW,"You picked up ",quantity," ",self.netname);
        if (self.aflag != 1)
            sprint (other,PRINT_LOW,"s");
        sprint (other,PRINT_LOW,"\n");
    }
    sound (other,CHAN_ITEM,"weapons/lock4.wav",1,1);
    stuffcmd (other,"bf\n");
    if (took) {
        TeamFortress_AmmoboxThink();
    }
    self = other;
    W_SetCurrentAmmo ();
}

void TeamFortress_DropAmmo (float type, float ammo) {
	self.impulse = 0;
	if (type == AMMO_CELLS) {
		if ( (self.ammo_shells < ammo) ) {
			if ( (self.playerclass == CLASS_ENGINEER) ) {
				if ( ((self.ammo_cells / 3) > (ammo - self.ammo_shells)) ) {
					sprint (self,PRINT_HIGH,"you make some shells.\n");
					self.ammo_cells = (self.ammo_cells - ((ammo - self.ammo_shells) * 3));
					self.ammo_shells = ammo;
				}
			}
			if ( (self.ammo_shells < ammo) ) {
				return ;
			}
		}
		self.ammo_shells = (self.ammo_shells - ammo);
	} else if ( (type == AMMO_NAILS) ) {
		if ( (self.ammo_nails < ammo) ) {
			if ( (self.playerclass == CLASS_ENGINEER) ) {
				if ( ((self.ammo_cells / 2) > (ammo - self.ammo_nails)) ) {
					sprint (self,PRINT_HIGH,"you make some nails.\n");
					self.ammo_cells = (self.ammo_cells - ((ammo - self.ammo_nails) * 2));
					self.ammo_nails = ammo;
				}
			}
			if ( (self.ammo_nails < ammo) ) {
				return ;
			}
		}
		self.ammo_nails = (self.ammo_nails - ammo);
	} else if ( (type == AMMO_ROCKETS) ) {
		if ( (self.ammo_rockets < ammo) ) {
			if ( (self.playerclass == CLASS_ENGINEER) ) {
				if ( ((self.ammo_cells / 5) > (ammo - self.ammo_rockets)) ) {
					sprint (self,PRINT_HIGH,"you make some rockets.\n");
					self.ammo_cells = (self.ammo_cells - ((ammo - self.ammo_rockets) * 5));
					self.ammo_rockets = ammo;
				}
			}
			if ( (self.ammo_rockets < ammo) ) {
				return ;
			}
		}
		self.ammo_rockets = (self.ammo_rockets - ammo);
	} else if ( (type == AMMO_CELLS) ) {
		if (self.ammo_cells < ammo)
			return ;
		self.ammo_cells = (self.ammo_cells - ammo);
	} else if (type == AMMO_GREN1)  {
		ammo = 1;
		if (self.no_grenades_1 < 1)
			return;
		self.no_grenades_1 = self.no_grenades_1 - 1;
	} else if (type == AMMO_GREN2) {
		ammo = 1;
		if (self.no_grenades_2 < 1)
			return;
		self.no_grenades_2 = self.no_grenades_2 - 1;
	}

    W_SetCurrentAmmo ();
    store_obs.num_ammoboxes = store_obs.num_ammoboxes + 1;
    if (store_obs.num_ammoboxes > store_obs.max_ammoboxes )
        RemoveboldAmmobox ();
    newmis = spawn ();
    newmis.aflag = ammo;
    newmis.weapon = type;
	if ( (newmis.weapon == AMMO_SHELLS) ) {
		newmis.ammo_shells = ammo;
	} else if ( (newmis.weapon == AMMO_NAILS) ) {
		newmis.ammo_nails = ammo;
	} else if ( (newmis.weapon == AMMO_ROCKETS) ) {
		newmis.ammo_rockets = ammo;
	} else if ( (newmis.weapon == AMMO_CELLS) ) {
		newmis.ammo_cells = ammo;
	} else if (newmis.weapon == AMMO_GREN1) {
		newmis.no_grenades_1 = ammo;
		newmis.tp_grenades_1 = self.tp_grenades_1;
	} else if (newmis.weapon == AMMO_GREN2) {
		newmis.no_grenades_2 = ammo;
		newmis.tp_grenades_2 = self.tp_grenades_2;
	}

    newmis.enemy = self;
    newmis.health = time;
    newmis.movetype = 6;
    newmis.solid = 1;
    newmis.classname = "ammobox";
    newmis.pteam = self.pteam;
    makevectors (self.v_angle);
    if ( self.v_angle_x ) {
        newmis.velocity = ((v_forward * 400) + (v_up * 200));
    } else {
        newmis.velocity = aim (self,10000);
        newmis.velocity = (newmis.velocity * 400);
        newmis.velocity_z = 200;
    }
    newmis.avelocity = '0 300 0';
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,self.origin);
    newmis.nextthink = (time + 20);
    newmis.think = TeamFortress_AmmoboxThink;
    newmis.touch = TeamFortress_AmmoboxTouch;
    newmis.skin = (type - 1);
    if (newmis.skin > 5)
        newmis.skin = 2;
    setmodel (newmis,"progs/ammobox.mdl");
}

void Drop_detpack () {
    if (!self.ammo_detpack) return;
    if (!self.playerclass) return;
    self.ammo_detpack = self.ammo_detpack - 1;
    if (modetype & 4) {
        if (self.pteam == pteam2) {
            stuffcmd (self,"topcolor ");
            stuffcmd (self,ftos(self.pteam.colormap));
            stuffcmd (self,"\n");
        }
        self.is_unabletospy = 0;
    }
    newmis = spawn ();
    newmis.health = time;
    newmis.ammo_detpack = 1;
    newmis.weapon = 10;
    newmis.pteam = self.pteam;
    newmis.angles = '90 0 0';
    newmis.solid = 1;
    newmis.movetype = 6;
    newmis.enemy = self;
    newmis.classname = "ammobox";
    makevectors (self.v_angle);
    if ( self.v_angle_x ) {
        newmis.velocity = ((v_forward * 400) + (v_up * 200));
    } else {
        newmis.velocity = aim (self,10000);
        newmis.velocity = (newmis.velocity * 400);
        newmis.velocity_z = 200;
    }
    newmis.avelocity = '0 300 0';
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,self.origin);
    if (!modetype & 4) {
        newmis.think = TeamFortress_AmmoboxThink;
        newmis.nextthink = (time + 30);
    } else {
        if (round_active) {
            bprint (PRINT_HIGH, self.netname, " dropped the bomb!\n");
        }
    }
    newmis.touch = TeamFortress_AmmoboxTouch;
    setmodel (newmis,"progs/detpack.mdl");
    setsize (newmis,'-16 -16 0','16 16 8');
}

void TeamFortress_Discard () {
    newmis = spawn ();
    if (self.playerclass == CLASS_SCOUT) {
        newmis.ammo_rockets = self.ammo_rockets;
    } else if (self.playerclass == CLASS_SNIPER) {
        newmis.ammo_rockets = self.ammo_rockets;
        if (classtype & 1) {
            newmis.ammo_nails = self.ammo_nails;
        } else {
            newmis.ammo_cells = self.ammo_cells;
        }
    } else if (self.playerclass == CLASS_SOLDIER) {
        newmis.ammo_cells = self.ammo_cells;
        newmis.ammo_nails = self.ammo_nails;
    } else if (self.playerclass == CLASS_DEMOMAN) {
        newmis.ammo_cells = self.ammo_cells;
        newmis.ammo_nails = self.ammo_nails;
    } else if (self.playerclass == CLASS_MEDIC) {
        newmis.ammo_rockets = self.ammo_rockets;
        newmis.ammo_cells = self.ammo_cells;
    } else if (self.playerclass == CLASS_HWGUY) {
        newmis.ammo_rockets = self.ammo_rockets;
        newmis.ammo_nails = self.ammo_nails;
    } else if (self.playerclass == CLASS_PYRO) {
        newmis.ammo_nails = self.ammo_nails;
    } else if (self.playerclass == CLASS_SPY) {
        newmis.ammo_rockets = self.ammo_rockets;
        newmis.ammo_cells = self.ammo_cells;
    } else if (self.playerclass == CLASS_ENGINEER) {
        newmis.ammo_rockets = self.ammo_rockets;
    }
    if ( !(((newmis.ammo_shells + newmis.ammo_nails) + newmis.ammo_rockets * 2) + newmis.ammo_cells * 2) ) {
        dremove (newmis);
        return ;
    }
    self.ammo_shells = self.ammo_shells - newmis.ammo_shells;
    self.ammo_nails = self.ammo_nails - newmis.ammo_nails;
    self.ammo_rockets = self.ammo_rockets - newmis.ammo_rockets;
    self.ammo_cells = self.ammo_cells - newmis.ammo_cells;
    W_SetCurrentAmmo ();
    sound (self,CHAN_ITEM,"weapons/lock4.wav",1,1);
    store_obs.num_ammoboxes = store_obs.num_ammoboxes + 1;
    if (store_obs.num_ammoboxes > store_obs.max_ammoboxes)
        RemoveboldAmmobox ();
    newmis.enemy = self;
    newmis.health = time;
    newmis.weapon = 0;
    newmis.movetype = 6;
    newmis.solid = 1;
    newmis.classname = "ammobox";
    newmis.pteam = self.pteam;
    makevectors (self.v_angle);
    if ( self.v_angle_x ) {
        newmis.velocity = ((v_forward * 400) + (v_up * 200));
    } else {
        newmis.velocity = aim (self,10000);
        newmis.velocity = (newmis.velocity * 400);
        newmis.velocity_z = 200;
    }
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,self.origin);
    newmis.nextthink = (time + 30);
    newmis.think = TeamFortress_AmmoboxThink;
    newmis.touch = TeamFortress_AmmoboxTouch;
    setmodel (newmis,"progs/backpack.mdl");
}

void Ammobox_Explode () {
    float expsize;
    expsize = self.ammo_shells * 0.75 + self.ammo_rockets * 1.5 + self.ammo_cells * 1.5;
    if (expsize > 0) {
        self.solid = 0;
        deathmsg = 30;
        T_RadiusDamage (self.enemy,self.enemy.owner,expsize,self);
        WriteByte (4,23);
        WriteByte (4,3);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
    }
    TeamFortress_AmmoboxThink();
}
