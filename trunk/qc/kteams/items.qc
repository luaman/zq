/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
void() W_SetCurrentAmmo;
/* ALL LIGHTS SHOULD BE 0 1 0 IN  ALL OTHER ITEMS SHOULD
BE .8 .3 .4 IN  */


void() SUB_regen =
{
	self.model = self.mdl;          // restore original model
	self.solid = 1;     // allow it to be touched again
	sound (self, 2, "items/itembk2.wav", 1, 1);    // play respawn sound
	setorigin (self, self.origin);
};



/*QUAKED noclass (0 0 0) (-8 -8 -8) (8 8 8)
prints a warning message when spawned
*/
void() noclass =
{
	dprint ("noclass spawned at");
	dprint (vtos(self.origin));
	dprint ("\n");
	remove (self);
};

void() q_touch;

void() q_touch =
{
local entity    stemp;
local float     f1;
local string 	s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	self.mdl = self.model;

	sound (other, 2, self.noise, 1, 1);
	stuffcmd (other, "bf\n");

	self.solid = 0;
	other.items = other.items | 4194304;
	self.model = string_null;
        if (deathmatch == 4)
        {
                other.armortype = 0;
                other.armorvalue = 0 * 0.01;
                other.ammo_cells = 0;
        }

// do the apropriate action
	other.super_time = 1;
	other.super_damage_finished = self.cnt;

	s=ftos(rint(other.super_damage_finished - time));

	bprint (0, other.netname);
	if (deathmatch == 4)
		bprint (0, " recovered an OctaPower with ");
	else
        	bprint (0, " recovered a Quad with ");
	bprint (0, s);
	bprint (0, " seconds remaining!\n");



	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


void(float timeleft) DropQuad =
{
	local entity    item;

	item = spawn();
	item.origin = self.origin;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = 256;
	item.solid = 1;
	item.movetype = 6;
	item.noise = "items/damage.wav";
	setmodel (item, "progs/quaddama.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');
	item.cnt = time + timeleft;
	item.touch = q_touch;
	item.nextthink = time + timeleft;    // remove it with the time left on it
	item.think = SUB_Remove;
	item.classname = "droppedquad";	//team
};


void() r_touch;

void() r_touch =
{
local entity    stemp;
local float     f1;
local string 	s;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	self.mdl = self.model;

	sound (other, 2, self.noise, 1, 1);
	stuffcmd (other, "bf\n");

	self.solid = 0;
	other.items = other.items | 524288;
	self.model = string_null;

// do the apropriate action
	other.invisible_time = 1;
	other.invisible_finished = self.cnt;
	s=ftos(rint(other.invisible_finished - time));
	bprint (0, other.netname);
	bprint (0, " recovered a Ring with ");
	bprint (0, s);
	bprint (0, " seconds remaining!\n");


	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


void(float timeleft) DropRing =
{
	local entity    item;

	item = spawn();
	item.origin = self.origin;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = 256;
	item.solid = 1;
	item.movetype = 6;
	item.noise = "items/inv1.wav";
	setmodel (item, "progs/invisibl.mdl");
	setsize (item, '-16 -16 -24', '16 16 32');
	item.cnt = time + timeleft;
	item.touch = r_touch;
	item.nextthink = time + timeleft;    // remove after 30 seconds
	item.think = SUB_Remove;
	item.classname = "droppedring";	//team
};

/*
============
PlaceItem

plants the object on the floor
============
*/
void() PlaceItem =
{
	local float     oldz;

	self.mdl = self.model;          // so it can be restored on respawn
	self.flags = 256;           // make extra wide
	self.solid = 1;
	self.movetype = 6;
	self.velocity = '0 0 0';
	self.origin_z = self.origin_z + 6;
	oldz = self.origin_z;
	if (!droptofloor())
	{
		dprint ("Bonus item fell out of level at ");
		dprint (vtos(self.origin));
		dprint ("\n");
		remove(self);
		return;
	}
};

/*
============
StartItem

Sets the clipping size and plants the object on the floor
============
*/
void() StartItem =
{
	self.nextthink = time + 0.2;    // items start after other solids
	self.think = PlaceItem;
};

/*
=========================================================================

HEALTH BOX

=========================================================================
*/
//
// T_Heal: add health to an entity, limiting health to max_health
// "ignore" will ignore max_health limit
//
float (entity e, float healamount, float ignore) T_Heal =
{
	if (e.health <= 0)
		return 0;
	if ((!ignore) && (e.health >= other.max_health))
		return 0;
	healamount = ceil(healamount);

	e.health = e.health + healamount;
	if ((!ignore) && (e.health >= other.max_health))
		e.health = other.max_health;

	if (e.health > 250)
		e.health = 250;
	return 1;
};

/*QUAKED item_health (.3 .3 1) (0 0 0) (32 32 32) rotten megahealth
Health box. Normally gives 25 points.
Rotten box heals 5-10 points,
megahealth will add 100 health, then
rot you down to your maximum health limit,
one point per second.
*/

float   H_ROTTEN = 1;
float   H_MEGA = 2;
.float  healamount, healtype;
void() health_touch;
void() item_megahealth_rot;

void() item_health =
{
	self.touch = health_touch;

	if (self.spawnflags & H_ROTTEN)
	{
		precache_model("maps/b_bh10.bsp");

		precache_sound("items/r_item1.wav");
		setmodel(self, "maps/b_bh10.bsp");
		self.noise = "items/r_item1.wav";
		self.healamount = 15;
		self.healtype = 0;
	}
	else
	if (self.spawnflags & H_MEGA)
	{
		precache_model("maps/b_bh100.bsp");
		precache_sound("items/r_item2.wav");
		setmodel(self, "maps/b_bh100.bsp");
		self.noise = "items/r_item2.wav";
		self.healamount = 100;
		self.healtype = 2;
	}
	else
	{
		precache_model("maps/b_bh25.bsp");
		precache_sound("items/health1.wav");
		setmodel(self, "maps/b_bh25.bsp");
		self.noise = "items/health1.wav";
		self.healamount = 25;
		self.healtype = 1;
	}
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


void() health_touch =
{
	local   float f1;
	local   string  s;

	if (deathmatch == 4)
		if (other.invincible_time > 0)
                        return;

	if (other.classname != "player")
		return;

	if (match_in_progress != 2) return;  // TEAM

	if (self.healtype == 2) // Megahealth?  Ignore max_health...
	{
		if (other.health >= 250)
			return;
		if (!T_Heal(other, self.healamount, 1))
			return;
	}
	else
	{
		if (!T_Heal(other, self.healamount, 0))
			return;
	}

	sprint(other, 0, "You receive ");
	s = ftos(self.healamount);
	sprint(other, 0, s);
	sprint(other, 0, " health\n");

// health touch sound
	sound(other, 3, self.noise, 1, 1);

	stuffcmd (other, "bf\n");

	self.model = string_null;
	self.solid = 0;

	// Megahealth = rot down the player's super health
	if (self.healtype == 2)
	{
		other.items = other.items | 65536;
		if (deathmatch != 4)
		{
        		self.nextthink = time + 5;
                	self.think = item_megahealth_rot;
                }
		self.owner = other;
	}
	else
	{
		if (deathmatch != 2)            // deathmatch 2 is the silly old rules
		{
			self.nextthink = time + 20;
			self.think = SUB_regen;
		}
	}

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};

void() item_megahealth_rot =
{
	other = self.owner;

	if (other.health > other.max_health)
	{
		other.health = other.health - 1;
		self.nextthink = time + 1;
		return;
	}

// it is possible for a player to die and respawn between rots, so don't
// just blindly subtract the flag off
	other.items = other.items - (other.items & 65536);

	if (deathmatch != 2)    // deathmatch 2 is silly old rules
	{
		self.nextthink = time + 20;
		self.think = SUB_regen;
	}
};

/*
===============================================================================

ARMOR

===============================================================================
*/

void() armor_touch;

void() armor_touch =
{
	local   float   type, value, bit, f1;

	if (other.health <= 0)
		return;
	if (other.classname != "player")
		return;

	if (match_in_progress != 2) return;  // TEAM

	if (deathmatch == 4)
		if (other.invincible_time > 0)
			return;

	if (self.classname == "item_armor1")
	{
		type = 0.3;
		value = 100;
		bit = 8192;
	}
	else if (self.classname == "item_armor2")
	{
		type = 0.6;
		value = 150;
		bit = 16384;
	}
	else if (self.classname == "item_armorInv")
	{
		type = 0.8;
		value = 200;
		bit = 32768;
	}
	if (other.armortype*other.armorvalue >= type*value)
		return;

	other.armortype = type;
	other.armorvalue = value;
	other.items = other.items - (other.items & (8192 | 16384 | 32768)) + bit;

	self.solid = 0;
	self.model = string_null;
	if (deathmatch != 2)
		self.nextthink = time + 20;
	self.think = SUB_regen;

	sprint(other, 0, "You got armor\n");
// armor touch sound
	sound(other, 3, "items/armor1.wav", 1, 1);
	stuffcmd (other, "bf\n");

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


/*QUAKED item_armor1 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor1 =
{
	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 0;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armor2 (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armor2 =
{
	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 1;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*QUAKED item_armorInv (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() item_armorInv =
{
	self.touch = armor_touch;
	precache_model ("progs/armor.mdl");
	setmodel (self, "progs/armor.mdl");
	self.skin = 2;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
};

/*
===============================================================================

WEAPONS

===============================================================================
*/

void() bound_other_ammo =
{
	if (other.ammo_shells > 100)
		other.ammo_shells = 100;
	if (other.ammo_nails > 200)
		other.ammo_nails = 200;
	if (other.ammo_rockets > 100)
		other.ammo_rockets = 100;
	if (other.ammo_cells > 100)
		other.ammo_cells = 100;
};


float(float w) RankForWeapon =
{
	if (w == 64)
		return 1;
	if (w == 32)
		return 2;
	if (w == 8)
		return 3;
	if (w == 16)
		return 4;
	if (w == 2)
		return 5;
	if (w == 4)
		return 6;
	return 7;
};

float (float w) WeaponCode =
{
	if (w == 2)
		return 3;
	if (w == 4)
		return 4;
	if (w == 8)
		return 5;
	if (w == 16)
		return 6;
	if (w == 32)
		return 7;
	if (w == 64)
		return 8;
	return 1;
};

/*
=============
Deathmatch_Weapon

Deathmatch weapon change rules for picking up a weapon

.float          ammo_shells, ammo_nails, ammo_rockets, ammo_cells;
=============
*/
void(float old, float new) Deathmatch_Weapon =
{
	local float or, nr;

// change self.weapon if desired
	or = RankForWeapon (self.weapon);
	nr = RankForWeapon (new);
	if ( nr < or )
		self.weapon = new;
};

/*
=============
weapon_touch
=============
*/
float() W_BestWeapon;

void() weapon_touch =
{
	local   float   hadammo, best, new, old, f1;
	local   entity  stemp;
	local   float   leave;

	// For client weapon_switch
	local   float   w_switch;

	if (!(other.flags & 8))
		return;

// TEAM -->
	if (match_in_progress != 2) return;
// <-- TEAM

	if ((stof(infokey(other,"w_switch"))) == 0)
		w_switch = 8;
	else
		w_switch = stof(infokey(other,"w_switch"));

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

	if (deathmatch == 2 || deathmatch == 3 || deathmatch == 5)
		leave = 1;
	else
		leave = 0;

	if (self.classname == "weapon_nailgun")
	{
		if (leave && (other.items & 4) )
			return;
		hadammo = other.ammo_nails;
		new = 4;
		other.ammo_nails = other.ammo_nails + 30;
	}
	else if (self.classname == "weapon_supernailgun")
	{
		if (leave && (other.items & 8) )
			return;
		hadammo = other.ammo_rockets;
		new = 8;
		other.ammo_nails = other.ammo_nails + 30;
	}
	else if (self.classname == "weapon_supershotgun")
	{
		if (leave && (other.items & 2) )
			return;
		hadammo = other.ammo_rockets;
		new = 2;
		other.ammo_shells = other.ammo_shells + 5;
	}
	else if (self.classname == "weapon_rocketlauncher")
	{
		if (leave && (other.items & 32) )
			return;
		hadammo = other.ammo_rockets;
		new = 32;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.classname == "weapon_grenadelauncher")
	{
		if (leave && (other.items & 16) )
			return;
		hadammo = other.ammo_rockets;
		new = 16;
		other.ammo_rockets = other.ammo_rockets + 5;
	}
	else if (self.classname == "weapon_lightning")
	{
		if (leave && (other.items & 64))
			return;
		hadammo = other.ammo_rockets;
		new = 64;
		other.ammo_cells = other.ammo_cells + 15;
	}
	else
		objerror ("weapon_touch: unknown classname");

	sprint (other, 0, "You got the ");
	sprint (other, 0, self.netname);
	sprint (other, 0, "\n");
// weapon touch sound
	sound (other, 3, "weapons/pkup.wav", 1, 1);
	stuffcmd (other, "bf\n");

	bound_other_ammo ();

// change to the weapon
	old = other.items;
	other.items = other.items | new;

	stemp = self;
	self = other;

	if ( WeaponCode(new) <= w_switch )
	{
		if (self.flags & 16)
		{
			if (new != 64)
			{
				Deathmatch_Weapon (old, new);
			}
		}
		else
		{
			Deathmatch_Weapon (old, new);
		}
	}

	W_SetCurrentAmmo();

	self = stemp;

	if (leave)
		return;

	if (deathmatch!=3 || deathmatch !=5)
	{
	// remove it in single player, or setup for respawning in deathmatch
		self.model = string_null;
		self.solid = 0;
		if (deathmatch != 2)
			self.nextthink = time + 30;
		self.think = SUB_regen;
	}
	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


/*QUAKED weapon_supershotgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supershotgun =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_shot.mdl");
	setmodel (self, "progs/g_shot.mdl");
	self.weapon = 2;
	self.netname = "Double-barrelled Shotgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};

/*QUAKED weapon_nailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_nailgun =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_nail.mdl");
	setmodel (self, "progs/g_nail.mdl");
	self.weapon = 4;
	self.netname = "nailgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};

/*QUAKED weapon_supernailgun (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_supernailgun =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_nail2.mdl");
	setmodel (self, "progs/g_nail2.mdl");
	self.weapon = 8;
	self.netname = "Super Nailgun";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};

/*QUAKED weapon_grenadelauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_grenadelauncher =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_rock.mdl");
	setmodel (self, "progs/g_rock.mdl");
	self.weapon = 3;
	self.netname = "Grenade Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};

/*QUAKED weapon_rocketlauncher (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_rocketlauncher =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_rock2.mdl");
	setmodel (self, "progs/g_rock2.mdl");
	self.weapon = 3;
	self.netname = "Rocket Launcher";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};


/*QUAKED weapon_lightning (0 .5 .8) (-16 -16 0) (16 16 32)
*/

void() weapon_lightning =
{
//team if (deathmatch <= 3)
//{
	precache_model ("progs/g_light.mdl");
	setmodel (self, "progs/g_light.mdl");
	self.weapon = 3;
	self.netname = "Thunderbolt";
	self.touch = weapon_touch;
	setsize (self, '-16 -16 0', '16 16 56');
	StartItem ();
//}
};


/*
===============================================================================

AMMO

===============================================================================
*/

void() ammo_touch =
{
local entity    stemp;
local float             best;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (match_in_progress != 2) return;  // TEAM

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;


// shotgun
	if (self.weapon == 1)
	{
		if (other.ammo_shells >= 100)
			return;
		other.ammo_shells = other.ammo_shells + self.aflag;
	}

// spikes
	if (self.weapon == 2)
	{
		if (other.ammo_nails >= 200)
			return;
		other.ammo_nails = other.ammo_nails + self.aflag;
	}

//      rockets
	if (self.weapon == 3)
	{
		if (other.ammo_rockets >= 100)
			return;
		other.ammo_rockets = other.ammo_rockets + self.aflag;
	}

//      cells
	if (self.weapon == 4)
	{
		if (other.ammo_cells >= 100)
			return;
		other.ammo_cells = other.ammo_cells + self.aflag;
	}

	bound_other_ammo ();

	sprint (other, 0, "You got the ");
	sprint (other, 0, self.netname);
	sprint (other, 0, "\n");
// ammo touch sound
	sound (other, 3, "weapons/lock4.wav", 1, 1);
	stuffcmd (other, "bf\n");

// change to a better weapon if appropriate

	if ( other.weapon == best )
	{
		stemp = self;
		self = other;

// fixed ammopickup-weaponchange bug
		best = stof(infokey(self, "w_switch"));
		if(!best) best = 8;
		if(WeaponCode(W_BestWeapon()) <= best) {
			self.weapon = W_BestWeapon();
			W_SetCurrentAmmo ();
		}
		self = stemp;
	}

// if changed current ammo, update it
	stemp = self;
	self = other;
	W_SetCurrentAmmo();
	self = stemp;

// remove it in single player, or setup for respawning in deathmatch
	self.model = string_null;
	self.solid = 0;
	if (deathmatch != 2)
		self.nextthink = time + 30;

// Xian -- If playing in DM 3.0 mode, halve the time ammo respawns

	if (deathmatch == 3 || deathmatch == 5)
		self.nextthink = time + 15;

	self.think = SUB_regen;

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};




float WEAPON_BIG2 = 1;

/*QUAKED item_shells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_shells =
{
/* team
	if (deathmatch == 4)
		return;
*/
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_shell1.bsp");
		setmodel (self, "maps/b_shell1.bsp");
		self.aflag = 40;
	}
	else
	{
		precache_model ("maps/b_shell0.bsp");
		setmodel (self, "maps/b_shell0.bsp");
		self.aflag = 20;
	}
	self.weapon = 1;
	self.netname = "shells";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_spikes (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_spikes =
{
/* team
	if (deathmatch == 4)
		return;
*/

	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_nail1.bsp");
		setmodel (self, "maps/b_nail1.bsp");
		self.aflag = 50;
	}
	else
	{
		precache_model ("maps/b_nail0.bsp");
		setmodel (self, "maps/b_nail0.bsp");
		self.aflag = 25;
	}
	self.weapon = 2;
	self.netname = "nails";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};

/*QUAKED item_rockets (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_rockets =
{
/* team
	if (deathmatch == 4)
		return;
*/

	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_rock1.bsp");
		setmodel (self, "maps/b_rock1.bsp");
		self.aflag = 10;
	}
	else
	{
		precache_model ("maps/b_rock0.bsp");
		setmodel (self, "maps/b_rock0.bsp");
		self.aflag = 5;
	}
	self.weapon = 3;
	self.netname = "rockets";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_cells (0 .5 .8) (0 0 0) (32 32 32) big
*/

void() item_cells =
{
/* team
	if (deathmatch == 4)
		return;
*/

	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_BIG2)
	{
		precache_model ("maps/b_batt1.bsp");
		setmodel (self, "maps/b_batt1.bsp");
		self.aflag = 12;
	}
	else
	{
		precache_model ("maps/b_batt0.bsp");
		setmodel (self, "maps/b_batt0.bsp");
		self.aflag = 6;
	}
	self.weapon = 4;
	self.netname = "cells";
	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*QUAKED item_weapon (0 .5 .8) (0 0 0) (32 32 32) shotgun rocket spikes big
DO NOT USE THIS!!!! IT WILL BE REMOVED!
*/

float WEAPON_SHOTGUN = 1;
float WEAPON_ROCKET = 2;
float WEAPON_SPIKES = 4;
float WEAPON_BIG = 8;
void() item_weapon =
{
	self.touch = ammo_touch;

	if (self.spawnflags & WEAPON_SHOTGUN)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_shell1.bsp");
			setmodel (self, "maps/b_shell1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/b_shell0.bsp");
			setmodel (self, "maps/b_shell0.bsp");
			self.aflag = 20;
		}
		self.weapon = 1;
		self.netname = "shells";
	}

	if (self.spawnflags & WEAPON_SPIKES)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_nail1.bsp");
			setmodel (self, "maps/b_nail1.bsp");
			self.aflag = 40;
		}
		else
		{
			precache_model ("maps/b_nail0.bsp");
			setmodel (self, "maps/b_nail0.bsp");
			self.aflag = 20;
		}
		self.weapon = 2;
		self.netname = "spikes";
	}

	if (self.spawnflags & WEAPON_ROCKET)
	{
		if (self.spawnflags & WEAPON_BIG)
		{
			precache_model ("maps/b_rock1.bsp");
			setmodel (self, "maps/b_rock1.bsp");
			self.aflag = 10;
		}
		else
		{
			precache_model ("maps/b_rock0.bsp");
			setmodel (self, "maps/b_rock0.bsp");
			self.aflag = 5;
		}
		self.weapon = 3;
		self.netname = "rockets";
	}

	setsize (self, '0 0 0', '32 32 56');
	StartItem ();
};


/*
===============================================================================

KEYS

===============================================================================
*/

void() key_touch =
{
local entity    stemp;
local float	f1;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;
	if (other.items & self.items)
		return;

	if (match_in_progress != 2) return;  // TEAM

	sprint (other, 0, "You got the ");
	sprint (other, 0, self.netname);
	sprint (other,0, "\n");

	sound (other, 3, self.noise, 1, 1);
	stuffcmd (other, "bf\n");

	other.items = other.items | self.items;

	self.solid = 0;
	self.model = string_null;

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


void() key_setsounds =
{
	if (world.worldtype == 0)
	{
		precache_sound ("misc/medkey.wav");
		self.noise = "misc/medkey.wav";
	}
	if (world.worldtype == 1)
	{
		precache_sound ("misc/runekey.wav");
		self.noise = "misc/runekey.wav";
	}
	if (world.worldtype == 2)
	{
		precache_sound2 ("misc/basekey.wav");
		self.noise = "misc/basekey.wav";
	}
};

/*QUAKED item_key1 (0 .5 .8) (-16 -16 -24) (16 16 32)
SILVER key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key1 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_s_key.mdl");
		setmodel (self, "progs/w_s_key.mdl");
		self.netname = "silver key";
	}
	else if (world.worldtype == 1)
	{
		precache_model ("progs/m_s_key.mdl");
		setmodel (self, "progs/m_s_key.mdl");
		self.netname = "silver runekey";
	}
	else if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_s_key.mdl");
		setmodel (self, "progs/b_s_key.mdl");
		self.netname = "silver keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = 131072;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_key2 (0 .5 .8) (-16 -16 -24) (16 16 32)
GOLD key
In order for keys to work
you MUST set your maps
worldtype to one of the
following:
0: medieval
1: metal
2: base
*/

void() item_key2 =
{
	if (world.worldtype == 0)
	{
		precache_model ("progs/w_g_key.mdl");
		setmodel (self, "progs/w_g_key.mdl");
		self.netname = "gold key";
	}
	if (world.worldtype == 1)
	{
		precache_model ("progs/m_g_key.mdl");
		setmodel (self, "progs/m_g_key.mdl");
		self.netname = "gold runekey";
	}
	if (world.worldtype == 2)
	{
		precache_model2 ("progs/b_g_key.mdl");
		setmodel (self, "progs/b_g_key.mdl");
		self.netname = "gold keycard";
	}
	key_setsounds();
	self.touch = key_touch;
	self.items = 262144;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

END OF LEVEL RUNES

===============================================================================
*/

void() sigil_touch =
{
local entity    stemp;
local float	f1;

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	if (match_in_progress != 2) return;  // TEAM

	centerprint (other, "You got the rune!");

	sound (other, 3, self.noise, 1, 1);
	stuffcmd (other, "bf\n");
	self.solid = 0;
	self.model = string_null;
	serverflags = serverflags | (self.spawnflags & 15);
	self.classname = "";            // so rune doors won't find it

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};


/*QUAKED item_sigil (0 .5 .8) (-16 -16 -24) (16 16 32) E1 E2 E3 E4
End of level sigil, pick up to end episode and return to jrstart.
*/

void() item_sigil =
{
	if (!self.spawnflags)
		objerror ("no spawnflags");

	precache_sound ("misc/runekey.wav");
	self.noise = "misc/runekey.wav";

	if (self.spawnflags & 1)
	{
		precache_model ("progs/end1.mdl");
		setmodel (self, "progs/end1.mdl");
	}
	if (self.spawnflags & 2)
	{
		precache_model2 ("progs/end2.mdl");
		setmodel (self, "progs/end2.mdl");
	}
	if (self.spawnflags & 4)
	{
		precache_model2 ("progs/end3.mdl");
		setmodel (self, "progs/end3.mdl");
	}
	if (self.spawnflags & 8)
	{
		precache_model2 ("progs/end4.mdl");
		setmodel (self, "progs/end4.mdl");
	}

	self.touch = sigil_touch;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*
===============================================================================

POWERUPS

===============================================================================
*/

void() powerup_touch;


void() powerup_touch =
{
local entity    stemp;
local float             best;
//team
local float f1;
//team

	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

// TEAM -->
	if (match_in_progress != 2 || !stof(infokey(world, "k_pow"))) return;
//	if (match_in_progress != 2) return;
//	if (!stof(infokey(world, "k_pow")) && self.classname != "item_artifact_envirosuit") return;
// <-- TEAM

	sprint (other, 0, "You got the ");
	sprint (other,0,  self.netname);
	sprint (other,0, "\n");

	self.mdl = self.model;

	if ((self.classname == "item_artifact_invulnerability") ||
		(self.classname == "item_artifact_invisibility"))
		self.nextthink = time + 60*5;
	else
		self.nextthink = time + 60;
//team
	f1 = rint(random() * 6);
	if(stof(infokey(world, "k_pow")) == 2) self.nextthink = self.nextthink + 3 - f1;
//team

	self.think = SUB_regen;

	sound (other, 2, self.noise, 1, 1);
	stuffcmd (other, "bf\n");

	self.solid = 0;
	other.items = other.items | self.items;
	self.model = string_null;

// do the apropriate action
	if (self.classname == "item_artifact_envirosuit")
	{
		other.rad_time = 1;
		other.radsuit_finished = time + 30;
	}

	if (self.classname == "item_artifact_invulnerability")
	{
		other.invincible_time = 1;
		other.invincible_finished = time + 30;
	}

	if (self.classname == "item_artifact_invisibility")
	{
		other.invisible_time = 1;
		other.invisible_finished = time + 30;
	}

	if (self.classname == "item_artifact_super_damage")
	{
		if (deathmatch == 4)
		{
			other.armortype = 0;
			other.armorvalue = 0 * 0.01;
			other.ammo_cells = 0;
		}
		other.super_time = 1;
		other.super_damage_finished = time + 30;
	}

	activator = other;
	SUB_UseTargets();                               // fire all targets / killtargets
};



/*QUAKED item_artifact_invulnerability (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invulnerable for 30 seconds
*/
void() item_artifact_invulnerability =
{
	self.touch = powerup_touch;

	precache_model ("progs/invulner.mdl");
	precache_sound ("items/protect.wav");
	precache_sound ("items/protect2.wav");
	precache_sound ("items/protect3.wav");
	self.noise = "items/protect.wav";
	setmodel (self, "progs/invulner.mdl");
	self.netname = "Pentagram of Protection";
	if(stof(infokey(world, "k_pow"))) self.effects = self.effects | 128;		//team
	self.items = 1048576;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};

/*QUAKED item_artifact_envirosuit (0 .5 .8) (-16 -16 -24) (16 16 32)
Player takes no damage from water or slime for 30 seconds
*/
void() item_artifact_envirosuit =
{
	self.touch = powerup_touch;

	precache_model ("progs/suit.mdl");
	precache_sound ("items/suit.wav");
	precache_sound ("items/suit2.wav");
	self.noise = "items/suit.wav";
	setmodel (self, "progs/suit.mdl");
	self.netname = "Biosuit";
	self.items = 2097152;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_invisibility (0 .5 .8) (-16 -16 -24) (16 16 32)
Player is invisible for 30 seconds
*/
void() item_artifact_invisibility =
{
	self.touch = powerup_touch;

	precache_model ("progs/invisibl.mdl");
	precache_sound ("items/inv1.wav");
	precache_sound ("items/inv2.wav");
	precache_sound ("items/inv3.wav");
	self.noise = "items/inv1.wav";
	setmodel (self, "progs/invisibl.mdl");
	self.netname = "Ring of Shadows";
	self.items = 524288;
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};


/*QUAKED item_artifact_super_damage (0 .5 .8) (-16 -16 -24) (16 16 32)
The next attack from the player will do 4x damage
*/
void() item_artifact_super_damage =
{
	self.touch = powerup_touch;

	precache_model ("progs/quaddama.mdl");
	precache_sound ("items/damage.wav");
	precache_sound ("items/damage2.wav");
	precache_sound ("items/damage3.wav");
	self.noise = "items/damage.wav";
	setmodel (self, "progs/quaddama.mdl");
	if (deathmatch == 4)
		self.netname = "OctaPower";
	else
        	self.netname = "Quad Damage";
	self.items = 4194304;
	if(stof(infokey(world, "k_pow"))) self.effects = self.effects | 64;		//team
	setsize (self, '-16 -16 -24', '16 16 32');
	StartItem ();
};



/*
===============================================================================

PLAYER BACKPACKS

===============================================================================
*/

void() BackpackTouch =
{
	local string    s;
	local   float   best, old, new, f1;
	local           entity  stemp;
	local   float   acount;
	local   float   b_switch;

	if (match_in_progress != 2) return;  // TEAM
	if (deathmatch == 4)
		if (other.invincible_time > 0)
			return;

	if ((stof(infokey(other,"b_switch"))) == 0)
		b_switch = 8;
	else
		b_switch = stof(infokey(other,"b_switch"));


	if (other.classname != "player")
		return;
	if (other.health <= 0)
		return;

	acount = 0;
	sprint (other, 0, "You get ");

	if (deathmatch == 4)
	{
		other.health = other.health + 10;
		sprint (other, 0, "10 additional health\n");
		if ((other.health > 250) && (other.health < 300))
			sound (other, 3, "items/protect3.wav", 1, 1);
		else
			sound (other, 3, "weapons/lock4.wav", 1, 1);
		stuffcmd (other, "bf\n");
		remove(self);

		if (other.health >299)
		{
			if (other.invincible_time != 1)
			{
				other.invincible_time = 1;
				other.invincible_finished = time + 30;
				other.items = other.items | 1048576;

				other.super_time = 1;
				other.super_damage_finished = time + 30;
				other.items = other.items | 4194304;

				other.ammo_cells = 0;


				sound (other, 2, "boss1/sight1.wav", 1, 1);
				stuffcmd (other, "bf\n");
				bprint (2, other.netname);
				bprint (2, " attains bonus powers!!!\n");
			}
		}
		self = other;
		return;
	}

	if (self.items)
		if ((other.items & self.items) == 0)
		{
			acount = 1;
			sprint (other, 0, "the ");
			sprint (other, 0, self.netname);
		}

// if the player was using his best weapon, change up to the new one if better
	stemp = self;
	self = other;
	best = W_BestWeapon();
	self = stemp;

// change weapons
	other.ammo_shells = other.ammo_shells + self.ammo_shells;
	other.ammo_nails = other.ammo_nails + self.ammo_nails;
	other.ammo_rockets = other.ammo_rockets + self.ammo_rockets;
	other.ammo_cells = other.ammo_cells + self.ammo_cells;

	new = self.items;
	if (!new)
		new = other.weapon;
	old = other.items;
	other.items = other.items | self.items;

	bound_other_ammo ();

	if (self.ammo_shells)
	{
		if (acount)
			sprint(other, 0, ", ");
		acount = 1;
		s = ftos(self.ammo_shells);
		sprint (other, 0, s);
		sprint (other, 0, " shells");
	}
	if (self.ammo_nails)
	{
		if (acount)
			sprint(other, 0, ", ");
		acount = 1;
		s = ftos(self.ammo_nails);
		sprint (other, 0, s);
		sprint (other, 0, " nails");
	}
	if (self.ammo_rockets)
	{
		if (acount)
			sprint(other, 0, ", ");
		acount = 1;
		s = ftos(self.ammo_rockets);
		sprint (other, 0, s);
		sprint (other, 0, " rockets");
	}
	if (self.ammo_cells)
	{
		if (acount)
			sprint(other, 0, ", ");
		acount = 1;
		s = ftos(self.ammo_cells);
		sprint (other, 0, s);
		sprint (other,0, " cells");
	}

	if ( (deathmatch==3 || deathmatch == 5) & ( (WeaponCode(new)==6) || (WeaponCode(new)==7) ) & (other.ammo_rockets < 5) )
		other.ammo_rockets = 5;

	sprint (other, 0, "\n");
// backpack touch sound
	sound (other, 3, "weapons/lock4.wav", 1, 1);
	stuffcmd (other, "bf\n");

	remove(self);
	self = other;

// change to the weapon


	if ( WeaponCode(new) <= b_switch )
	{
		if (self.flags & 16)
		{
			if (new != 64)
			{
				Deathmatch_Weapon (old, new);
			}
		}
		else
		{
			Deathmatch_Weapon (old, new);
		}
	}



	W_SetCurrentAmmo ();
};

/*
===============
DropBackpack
===============
*/
void() DropBackpack =
{
	local entity    item;
	local string s1;
	local float f1;

	if (match_in_progress != 2 || !stof(infokey(world, "dp"))) return;	//team

	f1 = stof(infokey(world, "k_frp"));

// no ammo droppack bug fix; drop if contains weapon even if empty
	if (!(self.ammo_shells + self.ammo_nails + self.ammo_rockets +
		self.ammo_cells) && !(self.weapon & 126) &&
		!(f1 == 2 && (self.lastwepfired & 126)))
			return;	// nothing in it

	item = spawn();
	item.origin = self.origin - '0 0 24';

	item.items = self.weapon;

// added to drop lastfired even if no ammo in case of fairpacks 2
	if(f1 == 2)
		if(self.lastwepfired & 126)
			item.items = self.lastwepfired;

//team

	// Drop best weapon
	if(f1==1)
        {
		if((self.items & 4) && (self.ammo_nails > 0)) item.items = 4;
		if((self.items & 2) && (self.ammo_shells > 0)) item.items = 2;
		if((self.items & 8) && (self.ammo_nails > 0)) item.items = 8;
		if((self.items & 16) && (self.ammo_rockets > 0)) item.items = 16;
		if((self.items & 64) && (self.ammo_cells > 0)) item.items = 64;
		if((self.items & 32) && (self.ammo_rockets > 0)) item.items = 32;
	}

//team

	if (item.items == 4096)
		item.netname = "Axe";
	else if (item.items == 1)
		item.netname = "Shotgun";
	else if (item.items == 2)
		item.netname = "Double-barrelled Shotgun";
	else if (item.items == 4)
		item.netname = "Nailgun";
	else if (item.items == 8)
		item.netname = "Super Nailgun";
	else if (item.items == 16)
		item.netname = "Grenade Launcher";
	else if (item.items == 32)
		item.netname = "Rocket Launcher";
	else if (item.items == 64)
		item.netname = "Thunderbolt";
	else
		item.netname = "";

	item.ammo_shells = self.ammo_shells;
	item.ammo_nails = self.ammo_nails;
	item.ammo_rockets = self.ammo_rockets;
	item.ammo_cells = self.ammo_cells;

	item.velocity_z = 300;
	item.velocity_x = -100 + (random() * 200);
	item.velocity_y = -100 + (random() * 200);

	item.flags = 256;
	item.solid = 1;
	item.movetype = 6;
	setmodel (item, "progs/backpack.mdl");
	setsize (item, '-16 -16 0', '16 16 56');
	item.touch = BackpackTouch;

	item.nextthink = time + 120;    // remove after 2 minutes
	item.think = SUB_Remove;
};
