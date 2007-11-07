/*
    demoman.qc

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

void NormalGrenadeTouch ();

void NormalGrenadeExplode ();

void MirvGrenadeTouch ();

void MirvGrenadeExplode ();

void MirvGrenadeLaunch (vector org, entity shooter);

void TeamFortress_DetpackSet ();

void TeamFortress_DetpackTouch ();

void TeamFortress_DetpackDisarm ();

void TeamFortress_DetpackCountDown ();

void TeamFortress_DetonatePipebombs () {
    entity e;
    e = find (world,classname,"pipebomb");
    while ( (e != world) ) {
        if ( (e.owner == self) ) {
            e.nextthink = time;
        }
        e = find (e,classname,"pipebomb");
    }
}

void MirvGrenadeTouch () {
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void MirvGrenadeExplode () {
    float i;
    entity te;
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
    deathmsg = 10;
    T_RadiusDamage (self,self.owner,100,world);
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    self.solid = 0;
    i = 0;
    while ( (i < 4) ) {
        MirvGrenadeLaunch ((self.origin + '0 0 -1'),self.owner);
        i = (i + 1);
    }
    dremove(self);
}

void MirvGrenadeLaunch (vector org, entity shooter) {
    float xdir;
    float ydir;
    float zdir;
    xdir = ((150 * random ()) - 75);
    ydir = ((150 * random ()) - 75);
    zdir = (40 * random ());
    newmis = spawn ();
    newmis.owner = shooter;
    newmis.movetype = 10;
    newmis.solid = 2;
    newmis.classname = "grenade";
    newmis.weapon = 10;
    newmis.touch = NormalGrenadeTouch;
    newmis.think = NormalGrenadeExplode;
    newmis.nextthink = ((time + 2) + random ());
    newmis.velocity_x = (xdir * 2);
    newmis.velocity_y = (ydir * 2);
    newmis.velocity_z = (zdir * 15);
    newmis.avelocity = '250 300 400';
    setmodel (newmis,"progs/grenade2.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,org);
}

void TeamFortress_SetBomb (entity bowner) {
    string stimer;
    float timer;
    entity at_spot;
    float bombarmtime;
    bowner.is_detpacking = 0;
    if ((bowner.pteam.team != 2) ) {
        return ;
    }
    if ( !(bowner.ammo_detpack )) {
        sprint (bowner,PRINT_HIGH,"You need the Bomb!\n");
        return ;
    }
    at_spot = findradius (bowner.origin,65);
    while ( (at_spot != world) ) {
        if ( ((at_spot.classname == "player") && (bowner != at_spot)) ) {
            sprint (bowner,PRINT_HIGH,"You can't set a bomb on someone!\n");
            bowner.is_detpacking = 0;
            return ;
        } else if ( ((at_spot.mdl == "progs/turrbase.mdl") || (at_spot.mdl == "progs/turrgun.mdl")) ) {
			sprint (bowner,PRINT_HIGH,"You can't set a bomb on a sentry gun!\n");
			bowner.is_detpacking = 0;
			return ;
		} else if ( (at_spot.mdl == "progs/disp.mdl") ) {
			sprint (bowner,PRINT_HIGH,"You can't set a bomb on a dispenser!\n");
			bowner.is_detpacking = 0;
			return ;
		} else if ( (at_spot.classname == "detpack") ) {
			sprint (bowner,PRINT_HIGH,"Bombs can't be stacked!\n");
			bowner.is_detpacking = 0;
			return ;
		}
        at_spot = at_spot.chain;
    }
    if ( !(bowner.flags & 512) ) {
        sprint (bowner,PRINT_HIGH,"You can't set the bomb in the air!\n");
        bowner.is_detpacking = 0;
        return ;
    }
    if (!modetype & 2) {
        bowner.ammo_detpack = (bowner.ammo_detpack - 1);
    }
    stuffcmd (bowner,"topcolor ");
    stuffcmd (bowner, ftos(bowner.pteam.colormap));
    stuffcmd (bowner,"\n");

    //bowner.immune_to_check = (time + 5);
    bowner.tfstate = (bowner.tfstate | 65536);
    bowner.weapon = bowner.current;
    bowner.current = 0;
    bowner.weaponmodel = "";
    bowner.weaponframe = 0;
    TeamFortress_SetSpeed (bowner);
    if (bowner.is_unabletospy) {
        bowner.is_unabletospy = 0;
    }
    timer = stof(infokey (world,"bombtime"));
    if (timer < 5 || timer >  90) timer = 50;
    stimer = ftos (timer);
    bombarmtime = stof(infokey (world,"bombarmtime"));
    if (bombarmtime < 1 || bombarmtime >  10) bombarmtime = 3;
    bowner.pausetime = (time + bombarmtime);
    sprint (bowner,PRINT_HIGH,"Setting Bomb...\n");
    newmis = spawn ();
    newmis.owner = bowner;
    newmis.classname = "timer";
    newmis.netname = "detpack_timer";
    newmis.nextthink = (time + bombarmtime);
    newmis.think = TeamFortress_DetpackSet;
    newmis.health = timer;
}

void TeamFortress_SetDetpack (float timer) {
    string stimer;
    entity te;
    entity at_spot;
    if (modetype & 4) {
        self.is_detpacking = 1;
        return;
    }
    self.impulse = 0;
    self.last_impulse = 0;
    if ( (self.ammo_detpack <= 0) ) {
        sprint (self,PRINT_HIGH,"You have no detpacks left!\n");
        return ;
    }

    at_spot = findradius (self.origin,65);
    while ( (at_spot != world) ) {
        if ( ((at_spot.classname == "player") && (self != at_spot)) ) {
            sprint (self,PRINT_HIGH,"You can't set a detpack on someone!\n");
            return ;
        } else if ( ((at_spot.mdl == "progs/turrbase.mdl") || (at_spot.mdl == "progs/turrgun.mdl")) ) {
			sprint (self,PRINT_HIGH,"You can't set a detpack on a sentry gun!\n");
			return ;
		} else if ( (at_spot.mdl == "progs/disp.mdl") ) {
			sprint (self,PRINT_HIGH,"You can't set a detpack on a dispenser!\n");
			return ;
		} else if ( (at_spot.classname == "detpack") ) {
			sprint (self,PRINT_HIGH,"Detpacks can't be stacked!\n");
			return ;
		}
        at_spot = at_spot.chain;
    }
    if ( !(self.flags & FL_ONGROUND) ) {
        sprint (self,PRINT_HIGH,"You can't set detpacks in the air!\n");
        return ;
    }
    te = find (world,classname,"detpack");
    while ( te ) {
        if ( (te.owner == self) ) {
            sprint (self,PRINT_HIGH,"You can only have 1 detpack active at a time.\n");
            return ;
        }
        te = find (te,classname,"detpack");
    }
    if ( (timer < 5) ) {
        sprint (self,PRINT_HIGH,"You can't set detpacks for less than 5 seconds.\n");
        return ;
    }
    self.is_detpacking = 1;
    if (!modetype & 2) {
        self.ammo_detpack = (self.ammo_detpack - 1);
    }
    //self.immune_to_check = (time + 5);
    self.tfstate = (self.tfstate | 65536);
    self.weapon = self.current;
    self.current = 0;
    self.weaponmodel = "";
    self.weaponframe = 0;
    TeamFortress_SetSpeed (self);
    if (self.is_unabletospy) {
        self.is_unabletospy = 0;
    }
    stimer = ftos (timer);
    self.pausetime = (time + 3);
    sprint (self,PRINT_HIGH,"Setting detpack for ");
    sprint (self,PRINT_HIGH,stimer);
    sprint (self,PRINT_HIGH," seconds...\n");

    newmis = spawn ();
    newmis.owner = self;
    newmis.classname = "timer";
    newmis.netname = "detpack_timer";
    newmis.nextthink = (time + 3);
    newmis.think = TeamFortress_DetpackSet;
    newmis.health = timer;
}

void TeamFortress_DetpackStop () {
    entity detpack_timer;
    self.is_detpacking = 0;
    detpack_timer = find (world,netname,"detpack_timer");
    while ( ((detpack_timer.owner != self) && (detpack_timer != world)) ) {
        detpack_timer = find (detpack_timer,netname,"detpack_timer");
    }
    if ( (detpack_timer == world) ) {
        return ;
    }
    sprint (self,PRINT_HIGH,"Detpack retrieved.\n");
    self.ammo_detpack = (self.ammo_detpack + 1);
    dremove (detpack_timer);
    self.tfstate = (self.tfstate - (self.tfstate & 65536));
    self.current = self.weapon;
    W_SetCurrentAmmo ();
    TeamFortress_SetSpeed (self);
    self.pausetime = time;
}

void TeamFortress_DetpackSet () {
    entity countd;
    entity oldself;
    string st;
    self.is_detpacking = 0;
    self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 65536));
    TeamFortress_SetSpeed (self.owner);
    oldself = self;
    self = self.owner;
    self.is_detpacking = 0;
    self.current = self.weapon;
    W_SetCurrentAmmo ();
    self = oldself;
    newmis = spawn ();
    newmis.owner = self.owner;
    newmis.origin = (self.owner.origin - '0 0 23');
    newmis.movetype = 10;
    st = infokey (world,"soliddet");
    if ( (st == "off") ) {
        newmis.solid = 1;
    } else {
        newmis.solid = 2;
    }
    newmis.classname = "detpack";
    newmis.flags = 256;
    newmis.angles = '90 0 0';
    newmis.angles_y = self.owner.angles_y;
    newmis.velocity = '0 0 0';
    newmis.avelocity = '0 0 0';
    newmis.weaponmode = 0;
    newmis.touch = TeamFortress_DetpackTouch;
    setmodel (newmis,"progs/detpack.mdl");
    setsize (newmis,'-16 -16 0','16 16 8');
    setorigin (newmis,self.owner.origin);
    countd = spawn ();
    newmis.linked_list = countd;
    countd.think = TeamFortress_DetpackCountDown;
    countd.health = (self.health - 1);
    countd.owner = self.owner;
    countd.classname = "detpack_timer";
    countd.enemy = newmis;
    newmis.oldenemy = countd;
    if ( (self.health <= 255) ) {
        countd.nextthink = (time + 1);
    } else {
        countd.nextthink = ((time + self.health) - 10);
        countd.health = 9;
    }
    newmis.nextthink = (time + self.health);
    newmis.think = TeamFortress_DetpackExplode;
    if (modetype & 4) {
        newmis.target = self.owner.target;
        self.owner.target = string_null;
        bprint(PRINT_HIGH, "The Bomb has been planted!\n");
        sound(self.owner,2,"speech/bombpl.wav",1,0);
    } else {
        sound (self.owner,2,"doors/medtry.wav",1,1);
        sprint (self.owner,PRINT_HIGH,"Detpack set!\n");
    }
    dremove (self);
}

void TeamFortress_DetpackExplode () {
    float pos;
    float points;
    entity head;
    entity te;
    vector org;
    bprint (PRINT_MEDIUM,"FIRE IN THE HOLE!\n");
    sound (self,CHAN_WEAPON,"weapons/detpack.wav",1,0);
    pos = pointcontents (self.origin);
    if ( (((pos != -2) && (pos != -6)) && (!self.owner.has_disconnected )) ) {
        deathmsg = 12;
        head = findradius (self.origin,1000);
        while ( head ) {
            head.chain2 = head.chain;
            if ( (head.classname == "info_tfgoal") ) {
                if ( ((head.goal_activation & 2) && (head.search_time == 0)) ) {
                    traceline (self.origin,head.origin,1,self);
                    if ( (trace_fraction == 1) ) {
                        if ( Activated (head,self.owner) ) {
                            DoResults (head,self.owner,1);
                        } else  if ( (head.else_goal != 0) ) {
                                te = Findgoal (head.else_goal);
                                if ( te ) {
                                    AttemptToActivate (te,self.owner,head);
                                }
                            }
                        }
                    }
            } else {
                if ( (head.takedamage && (vlen ((head.origin - self.origin)) <= 900)) ) {
                    org = (head.origin + ((head.mins + head.maxs) * 0.500));
                    points = (0.500 * vlen ((self.origin - org)));
                    if ( (points < 0) ) {
                        points = 0;
                    }
                    points = (700 - points);
                    if ( points ) {
                        if (grenradius & 2) {
                            TF_T_Damage (head,self,self.owner,(points * 2),2,4);
                        } else {
                            if ( CanDamage (head,self) ) {
                                TF_T_Damage (head,self,self.owner,(points * 2),2,4);
                            }
                        }
                    }
                }
            }
            head = head.chain2;
        }
        if (modetype & 4) {
            SUB_UseTargets ();
            round_winner = self.owner.pteam;
        }
        WriteByte (4,23);
        WriteByte (4,3);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
    } else {
        sprint (self.owner,PRINT_HIGH,"Your detpack fizzled out.\n");
    }
    if ( (self.weaponmode == 1) ) {
        TeamFortress_SetSpeed (self.enemy);
        dremove (self.oldenemy);
        dremove (self.observer_list);
    }
    dremove(self);
}

void TeamFortress_DetpackTouch () {
    entity disarm;
    vector src;
    float defusetime;

    CheckBelowBuilding (self);
    if ( (other.classname != "player") ) {
        return ;
    }
    if (!modetype & 4) {
        if ( (other.playerclass != 1) ) {
            return ;
        }
    } else {
        if ( (!other.playerclass) || (other.pteam.team == 2) ) {
            return ;
        }
    }
    if ( other.deadflag ) {
        return ;
    }
    if ( (self.weaponmode == 1) ) {
        return ;
    }
    if ( ((other.pteam == self.owner.pteam) && (self.owner.pteam.team != 0)) ) {
        return ;
    }
    makevectors (other.v_angle);
    src = (other.origin + '0 0 16');
    traceline (src,(src + (v_forward * 64)),0,other);

    if (self.solid == 2) {
        if ((trace_fraction == 1) || (trace_ent != self)) {
            return;
        }
    } else {
        if ( (trace_fraction == 1)  ) {

            return ;
        }
    }

    other.tfstate = (other.tfstate | 65536);
    TeamFortress_SetSpeed (other);
    disarm = spawn ();
    disarm.owner = other;
    disarm.enemy = self;
    disarm.classname = "timer";
    if (modetype & 4) {
        defusetime = stof(infokey (world,"bombdefusetime"));
        if (defusetime < 3 || defusetime > 15) defusetime = 8;
        disarm.nextthink = (time + defusetime);
        //disarm.weapon = defusetime;
        sprint (other, PRINT_HIGH,"Defusing Bomb...\n");
    } else {
        disarm.nextthink = (time + 3);
        sprint (other, PRINT_HIGH,"Disarming detpack...\n");
    }
    disarm.think = TeamFortress_DetpackDisarm;
    self.weaponmode = 1;
    self.enemy = other;
    self.observer_list = disarm;
}

void TeamFortress_DetpackDisarm () {
    if ( (self.owner.deadflag) ) {
        dremove (self);
        return ;
    }
    if (modetype & 4) {
        //if (self.weapon > 0) {
        // CenterPrint3(self.owner, "Defusing Bomb in ", ftos(self.weapon), " second(s)\n");
        // self.weapon = self.weapon - 1;
        // self.nextthink = (time + 1);
        // return;
        // }
        bprint (PRINT_MEDIUM,self.enemy.owner.netname);
        bprint (PRINT_MEDIUM,"'s bomb was defused by ");
        bprint (PRINT_MEDIUM,self.owner.netname);
        bprint (PRINT_MEDIUM,"\n");
        round_winner = self.owner.pteam;
    } else {
        bprint (PRINT_MEDIUM,self.enemy.owner.netname);
        bprint (PRINT_MEDIUM,"'s detpack was defused by ");
        bprint (PRINT_MEDIUM,self.owner.netname);
        bprint (PRINT_MEDIUM,"\n");
    }
    self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 65536));
    TF_AddFrags (self.owner,1, 0);
    TeamFortress_SetSpeed (self.owner);
    dremove (self.enemy.oldenemy);
    dremove (self.enemy);
    dremove (self);
}

void TeamFortress_DetpackCountDown () {
    string cd;
    cd = ftos (self.health);
    CheckBelowBuilding (self.enemy);
    self.nextthink = (time + 1);
    self.health = (self.health - 1);
    if ( (self.health < 10) ) {
        sprint (self.owner,PRINT_HIGH,cd);
        sprint (self.owner,PRINT_HIGH,"...\n");
        if ( ((self.health < 5) && (self.has_disconnected == 0)) ) {
            sound (self.enemy,2,"doors/baseuse.wav",1,1);
            self.has_disconnected = 1;
        }
        if ( ((self.health < 5) && (self.enemy.skin == 0)) ) {
            self.enemy.skin = 1;
        } else {
            self.enemy.skin = 0;
        }
        if ( (self.health <= 0) ) {
            dremove (self);
        }
    }
}
