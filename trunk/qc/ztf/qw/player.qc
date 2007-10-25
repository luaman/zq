/*
	player.qc

	player functions/definitions

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

void bubble_bob ();

void Throw_Grapple ();

/*
==============================================================================

PLAYER

==============================================================================
*/

$cd /raid/quake/id1/models/player_4
$origin 0 -6 24
$base base
$skin skin

//
// running
//
$frame axrun1 axrun2 axrun3 axrun4 axrun5 axrun6

$frame rockrun1 rockrun2 rockrun3 rockrun4 rockrun5 rockrun6

//
// standing
//
$frame stand1 stand2 stand3 stand4 stand5

$frame axstnd1 axstnd2 axstnd3 axstnd4 axstnd5 axstnd6
$frame axstnd7 axstnd8 axstnd9 axstnd10 axstnd11 axstnd12


//
// pain
//
$frame axpain1 axpain2 axpain3 axpain4 axpain5 axpain6

$frame pain1 pain2 pain3 pain4 pain5 pain6


//
// death
//

$frame axdeth1 axdeth2 axdeth3 axdeth4 axdeth5 axdeth6
$frame axdeth7 axdeth8 axdeth9

$frame deatha1 deatha2 deatha3 deatha4 deatha5 deatha6 deatha7 deatha8
$frame deatha9 deatha10 deatha11

$frame deathb1 deathb2 deathb3 deathb4 deathb5 deathb6 deathb7 deathb8
$frame deathb9

$frame deathc1 deathc2 deathc3 deathc4 deathc5 deathc6 deathc7 deathc8
$frame deathc9 deathc10 deathc11 deathc12 deathc13 deathc14 deathc15

$frame deathd1 deathd2 deathd3 deathd4 deathd5 deathd6 deathd7
$frame deathd8 deathd9

$frame deathe1 deathe2 deathe3 deathe4 deathe5 deathe6 deathe7
$frame deathe8 deathe9

//
// attacks
//
$frame nailatt1 nailatt2

$frame light1 light2

$frame rockatt1 rockatt2 rockatt3 rockatt4 rockatt5 rockatt6

$frame shotatt1 shotatt2 shotatt3 shotatt4 shotatt5 shotatt6

$frame axatt1 axatt2 axatt3 axatt4 axatt5 axatt6

$frame axattb1 axattb2 axattb3 axattb4 axattb5 axattb6

$frame axattc1 axattc2 axattc3 axattc4 axattc5 axattc6

$frame axattd1 axattd2 axattd3 axattd4 axattd5 axattd6


/*
==============================================================================
PLAYER
==============================================================================
*/

void player_run ();

void()  player_stand1 =[        $axstnd1,       player_stand1   ]
{
	self.weaponframe=0;
	if (self.velocity_x || self.velocity_y)
	{
		self.walkframe=0;
		player_run();
		return;
	}
	if (self.weapon <= WEAP_AXE)
	{
		if (self.walkframe >= 12)
			self.walkframe = 0;
		self.frame = $axstnd1 + self.walkframe;
	}
	else
	{
		if (self.walkframe >= 5)
			self.walkframe = 0;
		self.frame = $stand1 + self.walkframe;
	}
	self.walkframe = self.walkframe + 1;
}

void()  player_run =[   $rockrun1,      player_run      ]
{
	self.weaponframe=0;
	if (!self.velocity_x && !self.velocity_y)
	{
		self.walkframe=0;
		player_stand1();
		return;
	}

	if (self.weapon <= WEAP_AXE)
	{
		if (self.walkframe >= 6)
			self.walkframe = 0;
		self.frame = $axrun1 + self.walkframe;
	}
	else
	{
		if (self.walkframe >= 6)
			self.walkframe = 0;
		self.frame = self.frame + self.walkframe;
	}
	self.walkframe = self.walkframe + 1;

#ifdef AGRIP
	agh_player_footsteps();
#endif
}

void muzzleflash ()
{
	WriteByte (MSG_MULTICAST, SVC_MUZZLEFLASH);
	WriteEntity (MSG_MULTICAST, self);
	multicast (self.origin, MULTICAST_PVS);
}


void()  player_shot1 =  [$shotatt1, player_shot2        ] {self.weaponframe=1;muzzleflash();}
void()  player_shot2 =  [$shotatt2, player_shot3        ] {self.weaponframe=2;}
void()  player_shot3 =  [$shotatt3, player_shot4        ] {self.weaponframe=3;}
void()  player_shot4 =  [$shotatt4, player_shot5        ] {self.weaponframe=4;}
void()  player_shot5 =  [$shotatt5, player_shot6        ] {self.weaponframe=5;}
void()  player_shot6 =  [$shotatt6, player_run  ] {self.weaponframe=6;}

void() player_autorifle1 = [ 113, player_autorifle2 ] {self.weaponframe=1;muzzleflash();}
void() player_autorifle2 = [ 114, player_autorifle3 ] {self.weaponframe=2;}
void() player_autorifle3 = [ 118, player_run ] {self.weaponframe = 6;}

void()  player_axe1 =   [$axatt1, player_axe2   ] {self.weaponframe=1;}
void()  player_axe2 =   [$axatt2, player_axe3   ] {self.weaponframe=2;}
void()  player_axe3 =   [$axatt3, player_axe4   ] {self.weaponframe=3;
    if ( (self.weapon == WEAP_AXE) ) {
        W_FireAxe();
    } else {
        W_FireSpanner();
    }
}

void()  player_axe4 =   [$axatt4, player_run    ] {self.weaponframe=4;}

void()  player_axeb1 =  [$axattb1, player_axeb2 ] {self.weaponframe=5;}
void()  player_axeb2 =  [$axattb2, player_axeb3 ] {self.weaponframe=6;}
void()  player_axeb3 =  [$axattb3, player_axeb4 ] {self.weaponframe=7;
    if ( (self.weapon == WEAP_AXE) ) {
        W_FireAxe();
    } else {
        W_FireSpanner();
    }
}
void()  player_axeb4 =  [$axattb4, player_run   ] {self.weaponframe=8;}

void()  player_axec1 =  [$axattc1, player_axec2 ] {self.weaponframe=1;}
void()  player_axec2 =  [$axattc2, player_axec3 ] {self.weaponframe=2;}
void()  player_axec3 =  [$axattc3, player_axec4 ] {self.weaponframe=3;
    if ( (self.weapon == WEAP_AXE) ) {
        W_FireAxe();
    } else {
        W_FireSpanner();
    }
}
void()  player_axec4 =  [$axattc4, player_run   ] {self.weaponframe=4;}

void()  player_axed1 =  [$axattd1, player_axed2 ] {self.weaponframe=5;}
void()  player_axed2 =  [$axattd2, player_axed3 ] {self.weaponframe=6;}
void()  player_axed3 =  [$axattd3, player_axed4 ] {self.weaponframe=7;
    if ( (self.weapon == WEAP_AXE) ) {
        W_FireAxe();
    } else {
        W_FireSpanner();
    }
}
void()  player_axed4 =  [$axattd4, player_run   ] {self.weaponframe=8;}

void() player_chain1 = [ 137, player_chain1a ] {self.weaponframe=1;Throw_Grapple();}
void() player_chain1a = [ 137, player_chain2 ] {self.weaponframe=2;} 
void() player_chain2 = [ 138, player_chain2a ] {self.weaponframe=3;}
void() player_chain2a = [ 138, player_chain3 ] {self.weaponframe=4;}
void() player_chain3 = [ 139, player_chain3 ] {self.weaponframe=6;
    if ( !self.hook_out ) {
        player_chain5 ();
        return;
    }
    if ( self.speed >= 750)  {
        player_chain4 ();
        return;
    }
}
void() player_chain4 = [ 73, player_chain4 ] { self.weaponframe=6;
    if ( !self.hook_out ) {
        player_chain5 ();
        return;
    }
    if ( self.speed < 750)  {
        player_chain3 ();
        return;
    }
}
void() player_chain5 = [ 140, player_run ] { self.weaponframe=0;}

void() player_medikit1 = [ 119, player_medikit2 ] {self.weaponframe=1;}
void() player_medikit2 = [ 120, player_medikit3 ] {self.weaponframe=2;}
void() player_medikit3 = [ 121, player_medikit4 ] {self.weaponframe=3;W_FireMedikit();}
void() player_medikit4 = [ 122, player_run ] {self.weaponframe=4;}

void() player_medikitb1 = [ 125, player_medikitb2 ] {self.weaponframe=5;}
void() player_medikitb2 = [ 126, player_medikitb3 ] {self.weaponframe=6;}
void() player_medikitb3 = [ 127, player_medikitb4 ] {self.weaponframe=7;W_FireMedikit();}
void() player_medikitb4 = [ 128, player_run ] {self.weaponframe=8;}

void() player_medikitc1 = [ 131, player_medikitc2 ] {self.weaponframe=1;}
void() player_medikitc2 = [ 132, player_medikitc3 ] {self.weaponframe=2;}
void() player_medikitc3 = [ 133, player_medikitc4 ] {self.weaponframe=3;W_FireMedikit();}
void() player_medikitc4 = [ 134, player_run ] {self.weaponframe=4;}

void() player_medikitd1 = [ 137, player_medikitd2 ] {self.weaponframe=5;}
void() player_medikitd2 = [ 138, player_medikitd3 ] {self.weaponframe=6;}
void() player_medikitd3 = [ 139, player_medikitd4 ] {self.weaponframe=7;W_FireMedikit();}
void() player_medikitd4 = [ 140, player_run ] {self.weaponframe=8;}

//============================================================================

void() player_nail1   =[$nailatt1, player_nail2  ]
{
	muzzleflash();

	if (!self.button0 || intermission_running || self.impulse)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 9)
		self.weaponframe = 1;
	SuperDamageSound();
	W_FireSpikes (4);
	self.attack_finished = time + 0.2;
}
void() player_nail2   =[$nailatt2, player_nail1  ]
{
	muzzleflash();

	if (!self.button0 || intermission_running || self.impulse)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 9)
		self.weaponframe = 1;
	SuperDamageSound();
	// alternate nail firing
    if (self.nailpos == 0) {
        W_FireSpikes (4);
        self.nailpos = 1;
    } else {
        W_FireSpikes (-4);
        self.nailpos = 0;
    }
	self.attack_finished = time + 0.2;
}

//============================================================================

void() player_assaultcannonup1 = [ 103, player_assaultcannonup2 ] {
    if ( ((!self.button0 || (self.ammo_shells < 1)) || intermission_running)) {
        //self.tfstate = (self.tfstate - (self.tfstate & 2048));
        if (classtype & 2)
            self.tfstate = self.tfstate - (self.tfstate & 65536);

        TeamFortress_SetSpeed (self);
        self.count = 1;
        self.heat = 0;
        player_assaultcannondown1 ();
        return;
    }
    self.fire_held_down = 1;
    if ( (self.heat == 1) ) {
        sound (self,CHAN_WEAPON,"weapons/asscan1.wav",1,1);
    }
    SuperDamageSound ();
    Attack_Finished (0.100);
    if ( ((self.heat != 2) && (self.heat != 4)) ) {
        if ( (self.weaponframe >= 3) ) {
            self.weaponframe = 0;
        } else {
            self.weaponframe = (self.weaponframe + 1);
        }
    }
    self.heat = (self.heat + 1);
    if ( (self.heat >= 7) ) {
        self.heat = 0;
        player_assaultcannon1 ();
    }
}

void() player_assaultcannonup2 = [ 103, player_assaultcannonup1 ] {
    if ( ((!self.button0 || (self.ammo_shells < 1)) || intermission_running) || (!(self.flags & 512))  ) {
        self.tfstate = (self.tfstate - (self.tfstate & 2048));
        if (classtype & 2) {
            self.tfstate = self.tfstate - (self.tfstate & 65536);
        }
        TeamFortress_SetSpeed (self);
        self.count = 1;
        self.heat = 0;
        player_assaultcannondown1 ();
        return;
    }
    SuperDamageSound ();
    Attack_Finished (0.100);
    if ( (((self.heat != 2) && (self.heat != 4)) && (self.heat != 7)) ) {
        if ( ((self.weaponframe == 2) && (self.heat >= 9)) ) {
            self.weaponframe = 0;
        } else {
            if ( (self.weaponframe >= 3) ) {
                self.weaponframe = 0;
            } else {
                self.weaponframe = (self.weaponframe + 1);
            }
        }
    }
    self.heat = (self.heat + 1);
    if ( (self.heat >= 13) ) {
        self.heat = 0;
        player_assaultcannon1 ();
    }
}

void() player_assaultcannon1 = [ 103, player_assaultcannon2 ] {
    string st;
    if ( (!(classtype & 2) && (self.speed < 150)) || ((classtype & 2) && (self.speed < 50))  ) {
        muzzleflash ();
        sound (self,CHAN_WEAPON,"weapons/asscan2.wav",1,1);
        if ( (self.weaponframe == 2) ) {
            self.weaponframe = 4;
        } else {
            self.weaponframe = 2;
        }
        SuperDamageSound ();
        W_FireAssaultCannon();
        if (classtype & 2) {
            stuffcmd (self, "v_idlescale ");
            if (self.heat < 5) {
                st = ftos (self.heat * 4);
            } else {
                st = "20";
            }
            stuffcmd (self, st);
            stuffcmd (self, "\n");
        }
    } else {
        sound (self,CHAN_WEAPON,"weapons/asscan4.wav",1,1);
        if ( (self.weaponframe == 2) ) {
            self.weaponframe = 0;
        } else {
            self.weaponframe = 2;
        }
        if (classtype & 2)
            stuffcmd (self, "v_idlescale 5\n");
    }
    if ( ((!self.button0 || (self.ammo_shells < 1)) || intermission_running) ) {
        self.tfstate = (self.tfstate - (self.tfstate & 2048));
        if (classtype & 2) {
            self.tfstate = self.tfstate - (self.tfstate & 65536);
            stuffcmd (self, "v_idlescale 0\n");
        }
        TeamFortress_SetSpeed (self);
        self.weaponframe = 0;
        self.count = 1;
        player_assaultcannondown1 ();
        return;
    }
    Attack_Finished (0.100);
}

void() player_assaultcannon2 = [ 104, player_assaultcannon1 ] {
    if (classtype & 2)
        stuffcmd (self, "v_idlescale 0\n");
    if ( (!(classtype & 2) && (self.speed < 135)) || ((classtype & 2) && (self.speed < 20))  ) {
        if ( (self.weaponframe == 2) ) {
            self.weaponframe = 4;
        } else {
            self.weaponframe = 2;
        }
        SuperDamageSound ();
        W_FireAssaultCannon();
        self.heat = (self.heat + 0.100);
        stuffcmd (self,"bf\n");
    } else {
        if ( (self.weaponframe == 2) ) {
            self.weaponframe = 0;
        } else {
            self.weaponframe = 2;
        }
    }
    if ( ((!self.button0 || (self.ammo_shells < 1)) || intermission_running) ) {
        self.tfstate = (self.tfstate - (self.tfstate & 2048));
        if (classtype & 2) {
            self.tfstate = self.tfstate - (self.tfstate & 65536);
            stuffcmd (self, "v_idlescale 0\n");
        }
        TeamFortress_SetSpeed (self);
        self.weaponframe = 0;
        self.count = 1;
        player_assaultcannondown1 ();
        return;
    }
    Attack_Finished (0.100);
}

void() player_assaultcannondown1 = [ 103, player_assaultcannondown1 ] {
    //entity tcool;
    if (self.flags & 512) {
        if ( (self.count == 1) ) {

            sound (self,CHAN_WEAPON,"weapons/asscan3.wav",1,1);
        }

        if ( (self.count >= 15) ) {
            self.heat = 0;
            self.fire_held_down = 0;
            if (classtype & 2)
                self.tfstate = self.tfstate - (self.tfstate & 65536);
            self.tfstate = (self.tfstate - (self.tfstate & 2048));
            TeamFortress_SetSpeed (self);
            if ( ((self.ammo_shells < 1) || (self.ammo_cells < 7)) ) {
                self.last = self.weapon;
                self.weapon = W_BestWeapon ();
                W_SetCurrentAmmo ();
                W_PrintWeaponMessage ();
                return;
            }
            player_run ();
            return;
        }
        if ( ((((self.count != 8) && (self.count != 10)) && (self.count != 12)) && (self.count != 14)) ) {
            if ( (self.weaponframe == 3) ) {
                self.weaponframe = 0;
            } else {
                self.weaponframe = (self.weaponframe + 1);
            }
        }
        self.count = (self.count + 1);
        Attack_Finished (0.100);
    } else {
        if ( (self.count == 1) ) {

            sound (self,CHAN_WEAPON,"weapons/asscan3.wav",1,1);
        }
        self.heat = 0;
        self.fire_held_down = 0;
        if (classtype & 2)
            self.tfstate = self.tfstate - (self.tfstate & 65536);
        self.tfstate = (self.tfstate - (self.tfstate & 2048));
        TeamFortress_SetSpeed (self);
        if ( ((self.ammo_shells < 1) || (self.ammo_cells < 7)) ) {
            self.last = self.weapon;
            self.weapon = W_BestWeapon ();
            W_SetCurrentAmmo ();
            W_PrintWeaponMessage ();
            return;
        }
        player_run ();
        return;
    }
}

//============================================================================

void() player_light1   =[$light1, player_light2  ]
{
	muzzleflash();

	if (!self.button0 || intermission_running)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 5)
		self.weaponframe = 1;
	SuperDamageSound();
	W_FireLightning();
	self.attack_finished = time + 0.2;
}
void() player_light2   =[$light2, player_light1  ]
{
	muzzleflash();

	if (!self.button0 || intermission_running)
		{player_run ();return;}
	self.weaponframe = self.weaponframe + 1;
	if (self.weaponframe == 5)
		self.weaponframe = 1;
	SuperDamageSound();
	W_FireLightning();
	self.attack_finished = time + 0.2;
}

//============================================================================


void() player_rocket1   =[$rockatt1, player_rocket2  ] {self.weaponframe=1;muzzleflash();}
void() player_rocket2   =[$rockatt2, player_rocket3  ] {self.weaponframe=2;}
void() player_rocket3   =[$rockatt3, player_rocket4  ] {self.weaponframe=3;}
void() player_rocket4   =[$rockatt4, player_rocket5  ] {self.weaponframe=4;}
void() player_rocket5   =[$rockatt5, player_rocket6  ] {self.weaponframe=5;}
void() player_rocket6   =[$rockatt6, player_run  ] {self.weaponframe=6;}
void DeathBubbles (float num_bubbles);

void PainSound ()
{
	float	rs;

	if (self.health < 0)
		return;

	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
		return;
	}

// water pain sounds
	if (self.watertype == CONTENT_WATER && self.waterlevel == 3)
	{
		DeathBubbles(1);
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/drown1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/drown2.wav", 1, ATTN_NORM);
		return;
	}

// slime pain sounds
	if (self.watertype == CONTENT_SLIME)
	{
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.watertype == CONTENT_LAVA)
	{
		if (random() > 0.5)
			sound (self, CHAN_VOICE, "player/lburn1.wav", 1, ATTN_NORM);
		else
			sound (self, CHAN_VOICE, "player/lburn2.wav", 1, ATTN_NORM);
		return;
	}

	if (self.pain_finished > time)
	{
		self.axhitme = 0;
		return;
	}
	self.pain_finished = time + 0.5;

// don't make multiple pain sounds right after each other

// ax pain sound
	if (self.axhitme == 1)
	{
		self.axhitme = 0;
		sound (self, CHAN_VOICE, "player/axhit1.wav", 1, ATTN_NORM);
		return;
	}


	rs = rint((random() * 5) + 1);

	self.noise = "";
	if (rs == 1)
		self.noise = "player/pain1.wav";
	else if (rs == 2)
		self.noise = "player/pain2.wav";
	else if (rs == 3)
		self.noise = "player/pain3.wav";
	else if (rs == 4)
		self.noise = "player/pain4.wav";
	else if (rs == 5)
		self.noise = "player/pain5.wav";
	else
		self.noise = "player/pain6.wav";

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NORM);
	return;
}

void()  player_pain1 =  [       $pain1, player_pain2    ] {PainSound();self.weaponframe=0;}
void()  player_pain2 =  [       $pain2, player_pain3    ] {}
void()  player_pain3 =  [       $pain3, player_pain4    ] {}
void()  player_pain4 =  [       $pain4, player_pain5    ] {}
void()  player_pain5 =  [       $pain5, player_pain6    ] {}
void()  player_pain6 =  [       $pain6, player_run      ] {}

void()  player_axpain1 =        [       $axpain1,       player_axpain2  ] {PainSound();self.weaponframe=0;}
void()  player_axpain2 =        [       $axpain2,       player_axpain3  ] {}
void()  player_axpain3 =        [       $axpain3,       player_axpain4  ] {}
void()  player_axpain4 =        [       $axpain4,       player_axpain5  ] {}
void()  player_axpain5 =        [       $axpain5,       player_axpain6  ] {}
void()  player_axpain6 =        [       $axpain6,       player_run      ] {}

void player_pain ()
{
    if ( self.weaponframe ) {
        if ( (deathmsg == 37) ) {
            PainSound ();
        }
        return;
    }
	if (self.invisible_finished > time)
		return;         // eyes don't have pain frames
    if ( self.is_feigning ) {
        PainSound ();
        return;
    }
    if ( (self.button0 && (self.weapon == WEAP_ASSAULT_CANNON)) ) {
        return;
    }
	if (self.weapon <= WEAP_AXE)
		player_axpain1 ();
	else
		player_pain1 ();
}

void player_diea1 ();
void player_dieb1 ();
void player_diec1 ();
void player_died1 ();
void player_diee1 ();
void player_die_ax1 ();

void DeathBubblesSpawn ()
{
	entity	bubble;
	if ((self.owner.waterlevel != 3) && (self.owner.health > 0))
        {
                remove(self);       // remove bubble spawner
                return;
        }
	bubble = spawn();
	setmodel (bubble, "progs/s_bubble.spr");
	setorigin (bubble, self.owner.origin + '0 0 24');
	bubble.movetype = MOVETYPE_NOCLIP;
	bubble.solid = SOLID_NOT;
	bubble.velocity = '0 0 15';
	bubble.nextthink = time + 0.5;
	bubble.think = bubble_bob;
	bubble.classname = "bubble";
	bubble.frame = 0;
	bubble.cnt = 0;
	setsize (bubble, '-8 -8 -8', '8 8 8');
	self.nextthink = time + 0.1;
	self.think = DeathBubblesSpawn;
	self.air_finished = self.air_finished + 1;
	if (self.air_finished >= self.bubble_count)
		remove(self);
}

void DeathBubbles (float num_bubbles)
{
	entity	bubble_spawner;

	bubble_spawner = spawn();
	setorigin (bubble_spawner, self.origin);
	bubble_spawner.movetype = MOVETYPE_NONE;
	bubble_spawner.solid = SOLID_NOT;
	bubble_spawner.nextthink = time + 0.1;
	bubble_spawner.think = DeathBubblesSpawn;
	bubble_spawner.air_finished = 0;
	bubble_spawner.owner = self;
	bubble_spawner.bubble_count = num_bubbles;
}


void DeathSound ()
{
	float	rs;

	// water death sounds
	if (self.waterlevel == 3)
	{
        if (self.is_feigning) {
            DeathBubbles(2);
        } else {
            DeathBubbles(10); // FIXME: upped to 10 on purpose?
        }
		sound (self, CHAN_VOICE, "player/h2odeath.wav", 1, ATTN_NONE);
		return;
	}

	rs = rint ((random() * 4) + 1);
	if (rs == 1)
		self.noise = "player/death1.wav";
	if (rs == 2)
		self.noise = "player/death2.wav";
	if (rs == 3)
		self.noise = "player/death3.wav";
	if (rs == 4)
		self.noise = "player/death4.wav";
	if (rs == 5)
		self.noise = "player/death5.wav";

	sound (self, CHAN_VOICE, self.noise, 1, ATTN_NONE);
	return;
}


void PlayerDead ()
{
	self.nextthink = -1;
// allow respawn after a certain time
	self.deadflag = DEAD_DEAD;
}

vector VelocityForDamage (float dm)
{
	vector	v;

	if (vlen(damage_inflictor.velocity)>0)
	{
		v = 0.5 * damage_inflictor.velocity;
		v = v + (25 * normalize(self.origin-damage_inflictor.origin));
		v_z = 100 + 240 * random();
		v_x = v_x + (200 * crandom());
		v_y = v_y + (200 * crandom());
		//dprint ("Velocity gib\n");
	}
	else
	{
		v_x = 100 * crandom();
		v_y = 100 * crandom();
		v_z = 200 + 100 * random();
	}

	//v_x = 100 * crandom();
	//v_y = 100 * crandom();
	//v_z = 200 + 100 * random();

	if (dm > -50)
	{
	//      dprint ("level 1\n");
		v = v * 0.7;
	}
	else if (dm > -200)
	{
	//      dprint ("level 3\n");
		v = v * 2;
	}
	else
		v = v * 10;

	return v;
}

void ThrowGib (string gibname, float dm)
{
	entity	new;

	new = spawn();
	new.origin = self.origin;
	setmodel (new, gibname);
	setsize (new, VEC_ORIGIN, VEC_ORIGIN);	// link into world
	new.velocity = VelocityForDamage (dm);
	new.movetype = MOVETYPE_BOUNCE;
	new.solid = SOLID_NOT;
	new.avelocity_x = random()*600;
	new.avelocity_y = random()*600;
	new.avelocity_z = random()*600;
	new.think = SUB_Remove;
	new.ltime = time;
	new.nextthink = time + 10 + random()*10;
	new.frame = 0;
	new.flags = 0;
}

void ThrowHead (string gibname, float dm)
{
	setmodel (self, gibname);
	self.frame = 0;
	self.nextthink = -1;
	self.movetype = MOVETYPE_BOUNCE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.view_ofs = '0 0 8';
	setsize (self, '-16 -16 0', '16 16 56');
	self.velocity = VelocityForDamage (dm);
	self.origin_z = self.origin_z - 24;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.avelocity = crandom() * '0 600 0';
}

void HeadShotThrowHead (string gibname) {
	setmodel (self, gibname);
	self.frame = 0;
	self.nextthink = -1;
	self.movetype = MOVETYPE_BOUNCE;
	self.takedamage = DAMAGE_NO;
	self.solid = SOLID_NOT;
	self.view_ofs = '0 0 8';
	setsize (self, '-16 -16 0', '16 16 56');
    self.velocity = (normalize (self.head_shot_vector) * 600);
	self.origin_z = self.origin_z + 24;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
    self.avelocity = '0 0 0';
}

void KillPlayer ()
{
    self.owner.deadflag = 2;
    dremove (self);
}

#ifdef CSQC
float WriteGibs (entity ent) {
    WriteByte(MSG_ENTITY, CLASS_GIB);
    WriteByte(MSG_ENTITY, self.cnt);
    WriteByte(MSG_ENTITY, -self.health);
    WriteCoord(MSG_ENTITY, self.origin_x);
    WriteCoord(MSG_ENTITY, self.origin_y);
    WriteCoord(MSG_ENTITY, self.origin_z);
    return 1;
}

void ThrowCSQCGibs (float type) {
    self.cnt = type;
    self.Version = self.Version+1;
    self.SendEntity = WriteGibs;
    if (type != GIB_PLAYER) {	//schedule removal after a second.
        self.think = SUB_Remove;
        self.nextthink = time+1;
    }
}
#endif

void GibPlayer ()
{
#ifdef VWEP_TEST
	self.vw_index = 0;
#endif
    if (deathmsg == 29)
        HeadShotThrowHead("progs/h_player.mdl");
    else
        ThrowHead ("progs/h_player.mdl",self.health);
	ThrowGib ("progs/gib1.mdl", self.health);
	ThrowGib ("progs/gib2.mdl", self.health);
	ThrowGib ("progs/gib3.mdl", self.health);
#ifdef CSQC
    ThrowCSQCGibs(0);
#endif
    if ( (deathmsg == 36) ) {
        newmis = spawn ();
        newmis.owner = self;
        newmis.think = KillPlayer;
        newmis.nextthink = (time + 1);
    } else {
		self.deadflag = DEAD_DEAD;
    }
    TeamFortress_SetupRespawn ();
	if (damage_attacker.classname == "teledeath")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
        self.respawn_time = ((time + 2) + (random () * 2)); // FIXME: random respawn delay?
		return;
	}
	if (damage_attacker.classname == "teledeath2")
	{
		sound (self, CHAN_VOICE, "player/teledth1.wav", 1, ATTN_NONE);
        self.respawn_time = ((time + 2) + (random () * 2)); // FIXME: random respawn delay?
		return;
	}

	if (random() < 0.5)
		sound (self, CHAN_VOICE, "player/gib.wav", 1, ATTN_NONE);
	else
		sound (self, CHAN_VOICE, "player/udeath.wav", 1, ATTN_NONE);
}

#ifdef Q3_ENTS
void DecrementQue ();
#endif

void PlayerDie ()
{
    entity te;
	float	i;

    if ( self.hook_out ) {
        Reset_Grapple (self.hook);
        Attack_Finished (0.750);
        self.hook_out = 1;
    }
    if ( (self.heat && (self.weapon == WEAP_ASSAULT_CANNON)) ) {
        self.count = 0;
        sound (self,CHAN_WEAPON,"weapons/asscan3.wav",1,1);
    }
	self.items = self.items - (self.items & IT_INVISIBILITY);
	self.invisible_finished = 0;    // don't die as eyes
	self.invincible_finished = 0;
	self.super_damage_finished = 0;
	self.radsuit_finished = 0;
	self.modelindex = modelindex_player;    // don't use eyes
    if ( ((self.tfstate & 16) && (self == self.enemy)) ) {
        te = find (world,classname,"timer");
        while ( te ) {
            if ( ((te.owner == self) && (te.think == BioInfection_Decay)) ) {
                logfrag (te.enemy,self);
                TF_AddFrags (te.enemy,1, 1);
            }
            te = find (te,classname,"timer");
        }
    }
    TeamFortress_RemoveTimers ();
    if ( (deathmatch || coop) ) {
		DropBackpack();
        if (modetype & 4) {
            if (self.is_detpacking) {
                self.ammo_detpack = 1;
            }
            Drop_detpack();
        }
    }
	self.weaponmodel="";
#ifdef VWEP_TEST
	if (vw_available != 0)
		self.vw_index = 9;
#endif
	self.view_ofs = '0 0 -8';
	self.deadflag = DEAD_DYING;
	self.solid = SOLID_NOT;
	self.flags = self.flags - (self.flags & FL_ONGROUND);
	self.movetype = MOVETYPE_TOSS;
	if (self.velocity_z < 10)
		self.velocity_z = self.velocity_z + random()*300;

    if (rounds) {
        self.respawn_time = time + 2.500;
        if (modetype & 32) {
#ifdef NEW_ENTS
            DecrementQue();
#endif
            self.a_n = TeamFortress_GetNoPlayers();
        }

    } else {
        if (self.respawn_time < time) {
            self.respawn_time = time + respawn_delay_time;
        }
    }
    if (( !intermission_running )  && ( !cb_prematch )) {
        self.deaths = self.deaths + 1;
    }
    if ( (self.velocity_z < 10) ) {
        self.velocity_z = (self.velocity_z + (random () * 300));
    }
    if (self.health < -40 || self.deathtype == "squish")
	{
        if (infokey (world,"gibs") != "off" ) {
			GibPlayer ();
			return;
        }
    }
    DeathSound();
    self.angles_x = 0;
    self.angles_z = 0;
    if ( (self.weapon <= WEAP_AXE) ) {
		player_die_ax1 ();
        TeamFortress_SetupRespawn ();
        return;
    }

	// XXX: this generates random values in 1..6 range, so player_diee1 is
	// executed twice as often as other death sequences. Dunno if this should be
	// fixed -- Tonik
	i = 1 + floor(random()*6);

	if (i == 1)
		player_diea1();
	else if (i == 2)
		player_dieb1();
	else if (i == 3)
		player_diec1();
	else if (i == 4)
		player_died1();
	else
		player_diee1();

    TeamFortress_SetupRespawn ();
}

void set_suicide_frame ()
{       // used by kill command and diconnect command
	if (self.model != "progs/player.mdl")
		return; // already gibbed

    setmodel (self,string_null);
    setsize (self,'-16 -16 -24','16 16 32');
}

void()  player_diea1    =       [       $deatha1,       player_diea2    ] {}
void()  player_diea2    =       [       $deatha2,       player_diea3    ] {}
void()  player_diea3    =       [       $deatha3,       player_diea4    ] {}
void()  player_diea4    =       [       $deatha4,       player_diea5    ] {}
void()  player_diea5    =       [       $deatha5,       player_diea6    ] {}
void()  player_diea6    =       [       $deatha6,       player_diea7    ] {}
void()  player_diea7    =       [       $deatha7,       player_diea8    ] {}
void()  player_diea8    =       [       $deatha8,       player_diea9    ] {}
void()  player_diea9    =       [       $deatha9,       player_diea10   ] {}
void()  player_diea10   =       [       $deatha10,      player_diea11   ] {}
void()  player_diea11   =       [       $deatha11,      player_diea11 ] {PlayerDead();}

void()  player_dieb1    =       [       $deathb1,       player_dieb2    ] {}
void()  player_dieb2    =       [       $deathb2,       player_dieb3    ] {}
void()  player_dieb3    =       [       $deathb3,       player_dieb4    ] {}
void()  player_dieb4    =       [       $deathb4,       player_dieb5    ] {}
void()  player_dieb5    =       [       $deathb5,       player_dieb6    ] {}
void()  player_dieb6    =       [       $deathb6,       player_dieb7    ] {}
void()  player_dieb7    =       [       $deathb7,       player_dieb8    ] {}
void()  player_dieb8    =       [       $deathb8,       player_dieb9    ] {}
void()  player_dieb9    =       [       $deathb9,       player_dieb9    ] {PlayerDead();}

void()  player_diec1    =       [       $deathc1,       player_diec2    ] {}
void()  player_diec2    =       [       $deathc2,       player_diec3    ] {}
void()  player_diec3    =       [       $deathc3,       player_diec4    ] {}
void()  player_diec4    =       [       $deathc4,       player_diec5    ] {}
void()  player_diec5    =       [       $deathc5,       player_diec6    ] {}
void()  player_diec6    =       [       $deathc6,       player_diec7    ] {}
void()  player_diec7    =       [       $deathc7,       player_diec8    ] {}
void()  player_diec8    =       [       $deathc8,       player_diec9    ] {}
void()  player_diec9    =       [       $deathc9,       player_diec10   ] {}
void()  player_diec10   =       [       $deathc10,      player_diec11   ] {}
void()  player_diec11   =       [       $deathc11,      player_diec12   ] {}
void()  player_diec12   =       [       $deathc12,      player_diec13   ] {}
void()  player_diec13   =       [       $deathc13,      player_diec14   ] {}
void()  player_diec14   =       [       $deathc14,      player_diec15   ] {}
void()  player_diec15   =       [       $deathc15,      player_diec15 ] {PlayerDead();}

void()  player_died1    =       [       $deathd1,       player_died2    ] {}
void()  player_died2    =       [       $deathd2,       player_died3    ] {}
void()  player_died3    =       [       $deathd3,       player_died4    ] {}
void()  player_died4    =       [       $deathd4,       player_died5    ] {}
void()  player_died5    =       [       $deathd5,       player_died6    ] {}
void()  player_died6    =       [       $deathd6,       player_died7    ] {}
void()  player_died7    =       [       $deathd7,       player_died8    ] {}
void()  player_died8    =       [       $deathd8,       player_died9    ] {}
void()  player_died9    =       [       $deathd9,       player_died9    ] {PlayerDead();}

void()  player_diee1    =       [       $deathe1,       player_diee2    ] {}
void()  player_diee2    =       [       $deathe2,       player_diee3    ] {}
void()  player_diee3    =       [       $deathe3,       player_diee4    ] {}
void()  player_diee4    =       [       $deathe4,       player_diee5    ] {}
void()  player_diee5    =       [       $deathe5,       player_diee6    ] {}
void()  player_diee6    =       [       $deathe6,       player_diee7    ] {}
void()  player_diee7    =       [       $deathe7,       player_diee8    ] {}
void()  player_diee8    =       [       $deathe8,       player_diee9    ] {}
void()  player_diee9    =       [       $deathe9,       player_diee9    ] {PlayerDead();}

void()  player_die_ax1  =       [       $axdeth1,       player_die_ax2  ] {}
void()  player_die_ax2  =       [       $axdeth2,       player_die_ax3  ] {}
void()  player_die_ax3  =       [       $axdeth3,       player_die_ax4  ] {}
void()  player_die_ax4  =       [       $axdeth4,       player_die_ax5  ] {}
void()  player_die_ax5  =       [       $axdeth5,       player_die_ax6  ] {}
void()  player_die_ax6  =       [       $axdeth6,       player_die_ax7  ] {}
void()  player_die_ax7  =       [       $axdeth7,       player_die_ax8  ] {}
void()  player_die_ax8  =       [       $axdeth8,       player_die_ax9  ] {}
void()  player_die_ax9  =       [       $axdeth9,       player_die_ax9  ] {PlayerDead();}

void Headless_Think ()
{
    self.frame = (self.frame + 1);
    if ( ((self.frame == 7) || (self.frame == 18)) ) {
        self.nextthink = ((time + 10) + (random () * 10));
        self.think = SUB_Remove;
        return;
    }
    self.nextthink = (time + 0.100);
}

void player_touch ()
{
    entity Bio;
    entity te;
    float found;

    if (self.deadflag > 0 ) {
        return;
    }
    if ((self.playerclass == 8)) {
        if ( (other.classname == "player") ) {
            if ( ((self.undercover_team != 0) || (self.undercover_skin != 0)) ) {
                if ( (((other.playerclass == 8) || (other.playerclass == 1)) && (other.pteam != self.pteam)) ) {
                    TF_AddFrags (other,1, 0);
                    bprint (1,other.netname);
                    bprint (1," uncovered an enemy spy!\n");
                    Spy_RemoveDisguise (self);
                }
            }
            if ( ((other.undercover_team != 0) || (other.undercover_skin != 0)) ) {
                if ( (((self.playerclass == 8) || (self.playerclass == 1)) && (self.pteam != other.pteam)) ) {
                    TF_AddFrags (self,1, 0);
                    bprint (1,self.netname);
                    bprint (1," uncovered an enemy spy!\n");
                    Spy_RemoveDisguise (other);
                }
            }
        }
    }
    if ( ((self.tfstate & 16) && (!cb_prematch) && (!modetype & 2)) ) {
        if ( ((other.classname == "player") && (te.playerclass)) ) {
            if ( !(other.tfstate & 16) ) {
                if ( (other.playerclass != 5) ) {
                    if ( !(((teamplay & 16) && (self.owner.pteam == self.enemy.pteam)) && (self.owner.pteam.team != 0)) ) {
                        found = 0;
                        te = find (world,classname,"timer");
                        while ( ((te != world) && (found == 0)) ) {
                            if ( ((te.owner == self) && (te.think == BioInfection_Decay)) ) {
                                found = 1;
                            } else {
                                te = find (te,classname,"timer");
                            }
                        }
                        Bio = spawn ();
                        Bio.nextthink = 2;
                        Bio.think = BioInfection_Decay;
                        Bio.owner = other;
                        Bio.classname = "timer";
                        Bio.enemy = te.enemy;
                        other.tfstate = (other.tfstate | 16);
                        other.infection_team_no = self.infection_team_no;
                        sprint (other,1,"You have been infected by ");
                        sprint (other,1,self.netname);
                        sprint (other,1,"!\n");
                        sprint (self,1,"You have infected ");
                        sprint (self,1,other.netname);
                        sprint (self,1,"!\n");
                    }
                }
            }
        }
    }
}

