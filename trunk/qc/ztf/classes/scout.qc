/*
    scout.qc

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

void CaltropTouch ();

void CaltropScatterThink ();

void ScatterCaltrops ();

void ConcussionGrenadeTouch ();

void ConcussionGrenadeExplode ();

void FlashGrenadeTouch ();

void FlashTimer ();

void FlashGrenadeExplode ();

void T_RadiusBounce (entity inflictor, entity attacker, float bounce, entity ignore);
entity T_RadiusScan (entity scanner, float scanrange, float enemies, float friends);

void CanisterTouch () {
    sound (self,CHAN_WEAPON,"weapons/tink1.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void CaltropTouch () {
    if ( (((other.classname != "player") || !(other.flags & 512)) || other.deadflag) ) {
        return ;
    }
    if ( ((((teamplay & 16) && (other != self.owner)) && (other.pteam == self.owner.pteam)) && (self.owner.pteam.team != 0)) ) {
        return ;
    }
    sprint (other, PRINT_HIGH,"Ow, Ow, Ow! Caltrops!\n");
    if (!modetype & 2) {
        other.leg_damage = (other.leg_damage + 2);
        TeamFortress_SetSpeed (other);
        deathmsg = 41;
        TF_T_Damage (other,self,self.owner,10,0, 0);
    }
    dremove (self);
}

void CaltropScatterThink () {
    self.nextthink = (time + 0.200);
    if ( (self.velocity == '0 0 0') ) {
        if ( (self.flags & 512) ) {
            self.nextthink = ((time + 10) + (random () * 5));
            self.think = SUB_Remove;
            self.solid = 1;
            self.movetype = 6;
            self.touch = CaltropTouch;
            self.angles = '90 90 90';
            sound (self,0,"weapons/tink1.wav",1,1);
            setorigin (self,self.origin);
            return ;
        } else {
            self.nextthink = ((time + 10) + (random () * 5));
            self.think = SUB_Remove;
            self.solid = 1;
            self.movetype = 6;
            self.touch = CanisterTouch;
            setorigin (self,self.origin);
            return ;
        }
    }
    traceline (self.movedir,self.origin,1,self);
    if ( (trace_fraction == 1) ) {
        self.movedir = self.origin;
        return ;
    }
    self.velocity = (self.velocity * -1);
    self.heat = (self.heat + 1);
    if ( (self.heat > 10) ) {
        remove (self);
        return ;
    }
}

void ScatterCaltrops () {
    float num;
    entity e;
    num = 6;
    while ( (num > 0) ) {
        e = spawn ();
        e.classname = "grenade";
        e.weapon = 10;
        e.owner = self.owner;
        e.pteam = self.owner.pteam;
        setmodel (e,"progs/caltrop.mdl");
        e.mins = '-4 -4 -8';
        e.maxs = '4 4 4';
        e.angles = '0 0 0';
        e.angles_x = (random () * 360);
        e.velocity_x = (crandom () * 100);
        e.velocity_y = (crandom () * 100);
        e.velocity_z = (200 + (random () * 100));
        e.avelocity_x = (crandom () * 400);
        e.avelocity_y = (crandom () * 400);
        e.avelocity_z = (crandom () * 400);
        setorigin (e,self.owner.origin);
        e.movedir = e.origin;
        e.heat = 0;
        e.movetype = 10;
        e.solid = 0;
        e.nextthink = (time + 0.200);
        e.think = CaltropScatterThink;
        num = (num - 1);
    }
    dremove (self);
}

void ConcussionGrenadeTouch () {
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void ConcussionGrenadeExplode () {
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
    T_RadiusBounce (self,self.owner,240,world);
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    dremove (self);
}

void ConcussionGrenadeTimer () {
    string st;
    vector src;
    float pos, stumble, fl;
    if ( (self.owner.invincible_finished > time) ) {
        sprint (self.owner,PRINT_HIGH,"Your head feels better now.\n");
        dremove (self);
        return ;
    }
    if ( (self.owner.deadflag > 0) ) {
        dremove (self);
        return ;
    }
    self.cnt = self.cnt + 1;
    fl = self.cnt / 15;
    if ((fl == 1) || (fl == 2) || (fl == 3) || (fl == 4) || (fl == 5)) {
        newmis = spawn ();
        setmodel (newmis,"progs/s_bubble.spr");
        setorigin (newmis,self.owner.origin);
        newmis.movetype = 8;
        newmis.solid = 0;
        newmis.velocity = '0 0 15';
        newmis.nextthink = (time + 0.500);
        newmis.think = bubble_bob;
        newmis.touch = bubble_remove;
        newmis.classname = "bubble";
        newmis.frame = 0;
        newmis.cnt = 0;
        setsize (newmis,'0 0 0','0 0 0');
    }

    if (conctype) {
        self.health = (self.health - 20);
        if (self.owner.playerclass == 5) {
            self.health = (self.health - 20);
        }
        self.nextthink = (time + 0.500);
        if (!self.spawnflags) {
            stuffcmd (self.owner, "v_iroll_cycle 0.5\n");
            stuffcmd (self.owner, "v_ipitch_cycle 1\n");
            stuffcmd (self.owner, "v_iyaw_cycle 2\n");
            self.spawnflags = 1;
        }
        st = ftos (self.health / 7.500);
        stuffcmd (self.owner, "v_idlescale ");
        stuffcmd (self.owner, st);
        stuffcmd (self.owner, "\n");
    } else {
        self.health = (self.health - 10);
        if (self.owner.playerclass == 5) {
            self.health = (self.health - 10);
        }
        self.nextthink = (time + 0.250);
        pos = pointcontents (self.owner.origin);
        src_x = ((self.owner.origin_x + self.owner.maxs_x) + 2);
        src_y = ((self.owner.origin_y + self.owner.maxs_y) + 2);
        src_z = self.owner.origin_z;
        pos = pointcontents (src);
        if ( ((self.owner.flags & 512) || (self.owner.flags & 16)) ) {
            if ( (!self.owner.is_feigning) || (!self.owner.invincible_finished)) {
                makevectors (self.owner.v_angle);
                stumble = (crandom () * self.health);
                if (self.owner.playerclass == 6) stumble = stumble / 3;
                if ( !((pos == -2) && (self.owner.velocity == '0 0 0')) ) {
                    if ( (crandom () < 0) ) {
                        self.owner.velocity_x = (self.owner.velocity_y + stumble);
                        self.owner.velocity_y = (self.owner.velocity_x + stumble);
                    } else {
                        self.owner.velocity_x = ((-1 * self.owner.velocity_y) + stumble);
                        self.owner.velocity_y = ((-1 * self.owner.velocity_x) + stumble);
                    }
                }
            }
        }
    }
    if ( (self.health <= 0) ) {
        sprint (self.owner,PRINT_HIGH,"Your head feels better now.\n");
        if (conctype)  stuffcmd (self.owner, "v_idlescale 0\n");
        dremove (self);
    }
}

void TeamFortress_Scan () {
    entity list;
    float scancost;
    float scanrange;
    float scen;
    float scfr;
    float num;
    vector lightningvec;
    float enemy_detected;
    float any_detected;
    scanrange = 100;
    self.owner.impulse = 0;
    self.owner.last_impulse = 0;
    if ( (self.owner.classname == "player") ) {
        if ( !(self.owner.tf_items & 1) ) {
            return ;
        }
        scancost = 2;
        if ( (self.owner.ammo_cells <= 0) ) {
            sprint (self.owner,PRINT_HIGH,"Not enough cells to run scanner.\n");
            self.owner.ammo_cells = 0;
            W_SetCurrentAmmo ();
            self.owner.ScannerOn = 0;
            dremove (self);
            return ;
        }
        if ( (scancost > self.owner.ammo_cells) ) {
            scanrange = (self.owner.ammo_cells * 20);
            scancost = self.owner.ammo_cells;
            W_SetCurrentAmmo ();
        }
        scen = 0;
        scfr = 0;
        if ( (self.owner.tf_items_flags & 1) ) {
            scen = 1;
        }
        if ( (self.owner.tf_items_flags & 2) ) {
            scfr = 1;
        }
        if ( ((scen == 0) && (scfr == 0)) ) {
            sprint (self.owner,PRINT_HIGH,"No target specified.\n");
            self.owner.ScannerOn = 0;
            dremove (self);
            return ;
        }
        self.owner.ammo_cells = (self.owner.ammo_cells - 2);
        if ( (self.owner.ammo_cells < 0) ) {
            self.owner.ammo_cells = 0;
        }
        W_SetCurrentAmmo ();
        scanrange = (scanrange * 25);
        list = T_RadiusScan (self.owner,scanrange,scen,scfr);
    }
    scen = 0;
    scfr = 0;
    makevectors (self.owner.v_angle);
    if ( (list != world) ) {
        any_detected = 1;
        if ( ((((list.pteam.team > 0) && (self.owner.pteam.team > 0)) && (list.pteam == self.owner.pteam)) && ((list.classname == "player") || (list.classname == "building_sentrygun"))) ) {
            scfr = (scfr + 1);
            enemy_detected = 0;
        } else {
            if ( ((((list.goal_no > 0) && (self.owner.pteam.team > 0)) && (list.goal_no == self.owner.pteam.team)) && (list.classname == "item_tfgoal")) ) {
                scfr = (scfr + 1);
                enemy_detected = 0;
            } else {
                scen = (scen + 1);
                enemy_detected = 1;
            }
        }
        if ( any_detected ) {
            lightningvec = normalize ((list.origin - self.owner.origin));
            lightningvec = (lightningvec * (vlen ((list.origin - self.owner.origin)) / 5));
            lightningvec = (lightningvec + self.owner.origin);
            msg_entity = self.owner;
            WriteByte (1,23);
            WriteByte (1,5);
            WriteEntity (1,self.owner);
            WriteCoord (1,self.owner.origin_x);
            WriteCoord (1,self.owner.origin_y);
            WriteCoord (1,(self.owner.origin_z + 8));
            WriteCoord (1,lightningvec_x);
            WriteCoord (1,lightningvec_y);
            WriteCoord (1,(lightningvec_z + 8));
            if ( (self.owner.tf_items_flags & 4) ) {
                stuffcmd (self.owner,"play misc/basekey.wav\n");
            }
            num = vlen ((list.origin - self.owner.origin));
            num = (num / 10);
            num = (num / 3);
            num = rint (num);
            self.health = num;
            if ( (list.classname == "player") ) {
                if ( ((list.playerclass == 8) && (list.pteam != self.owner.pteam)) ) {
                    if ( (list.undercover_skin != 0) ) {
                        self.playerclass = list.undercover_skin;
                    } else {
                        self.playerclass = list.playerclass;
                    }
                    if ( (list.undercover_team != 0) ) {
                        self.pteam.team = list.undercover_team;
                    } else {
                        self.pteam = list.pteam;
                    }
                } else {
                    self.playerclass = list.playerclass;
                    self.pteam = list.pteam;
                }
            } else {
                if ( (list.classname == "building_sentrygun") ) {
                    self.playerclass = 13;
                    self.pteam = list.pteam;
                } else {
                    if ( (list.classname == "item_tfgoal") ) {
                        self.playerclass = 14;
                        self.pteam.team = list.goal_no;
                    }
                }
            }
            self.owner.StatusRefreshTime = (time + 0.200);
        }
    }
    if ( ((scen == 0) && (scfr == 0)) ) {
        self.health = 0;
        self.owner.StatusRefreshTime = (time + 0.200);
        self.nextthink = (time + 2);
        return ;
    }
    W_SetCurrentAmmo ();
    self.nextthink = (time + 2);
    return ;
}

void ScannerSwitch () {
    entity te;
    if ( (self.ScannerOn != 1) ) {
        te = spawn ();
        te.nextthink = (time + 2);
        te.think = TeamFortress_Scan;
        te.owner = self;
        te.classname = "timer";
        te.netname = "scanner";
        sprint (self,PRINT_HIGH,"Scanner On.\n");
        self.ScannerOn = 1;
    } else {
        te = find (world,netname,"scanner");
        while ( te ) {
            if ( (te.owner == self) ) {
                dremove (te);
            }
            te = find (te,netname,"scanner");
        }
        sprint (self,PRINT_HIGH,"Scanner Off.\n");
        self.ScannerOn = 0;
    }
}

void T_RadiusBounce (entity inflictor, entity attacker, float bounce, entity ignore) {
    float points;
    float accel;
    float length;
    float nextloop;
    entity head;
    entity te;
    vector org;
    head = findradius (inflictor.origin,(bounce + 40));
    while ( head ) {
        head.chain2 = head.chain;
        nextloop = 0;
        if ( (head != ignore) ) {
            if ( head.takedamage ) {
                org = (head.origin + ((head.mins + head.maxs) * 0.500));
                points = (0.500 * vlen ((org - inflictor.origin)));
                if ( (points < 0) ) {
                    points = 0;
                }
                accel = (bounce - points);
                if ( ((((head.classname != "building_dispenser") && (head.classname != "building_sentrygun")) && (head.classname != "building_sentrygun_base")) && (points > 0)) ) {
                    head.velocity = (org - inflictor.origin);
                    head.velocity = (head.velocity * (accel / 20));
                    if ( (head.classname == "player") ) {
                        te = find (world,classname,"timer");
                        while ( (((te.owner != head) || (te.think != ConcussionGrenadeTimer)) && (te != world)) ) {
                            te = find (te,classname,"timer");
                        }
                        if (grenradius & 1) {
                            if ( !CanDamage (head,te) ) nextloop = 1;
                        }
                        if (modetype & 2) nextloop = 1;
                        if (!nextloop) {
                            if (conctype) {
                                length = 800 - points;
                            } else {
                                length = 750 - points;
                            }
                            if ( (te != world) ) {
                                te.health = length;
                                te.nextthink = (time + frametime);
                            } else {
                                te = spawn ();
                                te.nextthink = (time + frametime);
                                te.think = ConcussionGrenadeTimer;
                                te.pteam = attacker.pteam;
                                te.classname = "timer";
                                te.owner = head;
                                te.health = length;
                            }
                        }
                    }
                }
            }
        }
        head = head.chain2;
    }
}

entity T_RadiusScan (entity scanner, float scanrange, float enemies, float friends) {
    entity head;
    float rangedist;
    rangedist = 0;
    head = world;
    while ( (rangedist <= scanrange) ) {
        if ( (rangedist <= 0) ) {
            rangedist = 1;
        }
        head = findradius (scanner.origin,rangedist);
        while ( head ) {
            if ( (head != scanner) ) {
                if ( (((head.takedamage != 0) && (head.health > 0)) || (head.classname == "item_tfgoal")) ) {
                    if ( (((head.classname == "player") || (head.classname == "building_sentrygun")) && (friends || enemies)) ) {
                        if ( teamplay ) {
                            if ( (((friends != 0) && (head.pteam.team > 0)) && (scanner.pteam.team > 0)) ) {
                                if ( ((head.playerclass == 8) && (head.pteam != scanner.pteam)) ) {
                                    if ( (head.is_feigning != 1 ) ) {
                                        if ( (head.undercover_team == scanner.pteam.team) ) {
                                            return ( head );
                                        }
                                    }
                                } else {
                                    if ( (head.pteam == scanner.pteam) ) {
                                        return ( head );
                                    }
                                }
                            }
                            if ( (((enemies != 0) && (head.pteam.team > 0)) && (scanner.pteam.team > 0)) ) {
                                if ( ((head.playerclass == 8) && (head.pteam != scanner.pteam)) ) {
                                    if ( (head.is_feigning != 1) ) {
                                        if ( (head.undercover_team != scanner.pteam.team) ) {
                                            return ( head );
                                        }
                                    }
                                } else {
                                    if ( (head.pteam != scanner.pteam) ) {
                                        return ( head );
                                    }
                                }
                            }
                        } else {
                            return ( head );
                        }
                    } else {
                        if ( ((head.classname == "item_tfgoal") && (friends || enemies)) ) {
                            if ( teamplay ) {
                                if ( ((((friends != 0) && (head.goal_no > 0)) && (scanner.pteam.team > 0)) && (head.goal_no == scanner.pteam.team)) ) {
                                    return ( head );
                                }
                                if ( ((((enemies != 0) && (head.pteam.team > 0)) && (scanner.pteam.team > 0)) && (head.goal_no != scanner.pteam.team)) ) {
                                    return ( head );
                                }
                            }
                        }
                    }
                }
            }
            head = head.chain;
        }
        rangedist = (rangedist + 100);
    }
    return ( world );
}

void FlashGrenadeTouch () {
    sound (self, 1, "weapons/bounce.wav", 1, 1);
    if ((self.velocity == '0 0 0')) {
        self.avelocity = '0 0 0';
    }
}

void FlashTimer () {
    entity te;
    string st;
    te = self.owner;
    te.FlashTime = (te.FlashTime - 0.6);
    if ((te.FlashTime < 3)) {
        te.FlashTime = 0;
        stuffcmd (te, "v_cshift 0 0 0 0\n");
        remove (self);
        return;
    }
    st = ftos ((te.FlashTime * 10));
    stuffcmd (te, "v_cshift ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st);
    stuffcmd (te, "\n");
    self.nextthink = (time + 0.6);
}

void FlashGrenadeExplode () {
    entity te;
    string st;
    float dist;
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
    self.effects = (self.effects | 4);
    WriteByte (4, 23);
    WriteByte (4, 4);
    WriteCoord (4, self.origin_x);
    WriteCoord (4, self.origin_y);
    WriteCoord (4, self.origin_z);
    multicast (self.origin, 1);
    te = findradius (self.origin, 300);
    while (te) {
        if ((te.classname == "player")) {
            traceline (self.origin, te.origin, 1, self);
            if ((trace_fraction == 1)) {
                dist = vlen ((self.origin - te.origin));
                if (dist <= 200) {
                    deathmsg = 35;
                    TF_T_Damage (te, self, self.owner, 60, 2, (16 | 4));
                }
                if ((te.health > 0)) {
                    if (grenradius & 1) {
                        if ( !CanDamage (te,self) ) return;
                    }

                    if ((te.FlashTime == 0)) {
                        newmis = spawn ();
                        newmis.classname = "timer";
                        newmis.netname = "flashtimer";
                        newmis.pteam = self.owner.pteam;
                        newmis.owner = te;
                        newmis.think = FlashTimer;
                        newmis.nextthink = (time + 1);
                    }
                    if ((te == self.owner)) {
                        if (dist > 40) {
                            te.FlashTime  = 16 - (16 * dist / 200);
                        } else {
                            te.FlashTime = 16;
                        }
                    } else {
                        if (dist > 40) {
                            te.FlashTime  = 20 - (20 * dist / 200);
                        } else {
                            te.FlashTime = 20;
                        }
                    }
                    st = ftos ((te.FlashTime * 10));
                    stuffcmd (te, "v_cshift ");
                    stuffcmd (te, st);
                    stuffcmd (te, " ");
                    stuffcmd (te, st);
                    stuffcmd (te, " ");
                    stuffcmd (te, st);
                    stuffcmd (te, " ");
                    stuffcmd (te, st);
                    stuffcmd (te, "\n");
                }
            }
        }
        te = te.chain;
    }
    dremove (self);
}
