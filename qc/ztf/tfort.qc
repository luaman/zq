/*
    tfort.qc

    qwtf core functions/definitions

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

string ItemStatus (entity Goal, entity Player, entity Item);

void TeamFortress_CheckClassStats ();

void TeamFortress_DescribeArmor (entity Player, float Armorclass);

void TeamFortress_Regenerate ();

void TeamFortress_ThrowGrenade ();

void UseSpecialSkill () {
    vector src;
    self.impulse = 0;
    if ( (self.playerclass == 1) ) {
        self.impulse = 159;
        return;
    } else {
        if ( (self.playerclass == 2) ) {
            self.impulse = 174;
            return;
        } else {
            if ( (self.playerclass == 3) ) {
                self.impulse = 173;
                return;
            } else {
                if ( (self.playerclass == 4) ) {
                    self.impulse = 170;
                    return;
                } else {
                    if ( (self.playerclass == 5) ) {
                        if ( (self.current == WEAP_SUPER_NAILGUN) ) {
                            self.impulse = 176;
                            return;
                        } else {
                            self.impulse = 5;
                            return;
                        }
                    } else {
                        if ( (self.playerclass == 6) ) {
                            if ( (self.current == WEAP_ASSAULT_CANNON )) {
                                if ( (self.tfstate & 2048) ) {
                                    sprint (self,PRINT_HIGH,"Cannot switch weapons while firing.\n");
                                    return;
                                } else {
                                    self.impulse = 3;
                                    return;
                                }
                            } else {
                                self.impulse = 8;
                                return;
                            }
                        } else {
                            if ( (self.playerclass == 7) ) {
                                if ( (self.current == WEAP_FLAMETHROWER) ) {
                                    self.impulse = 7;
                                    return;
                                } else {
                                    self.impulse = 5;
                                    return;
                                }
                            } else {
                                if ( (self.playerclass == 8) ) {
                                    self.impulse = 177;
                                    return;
                                } else {
                                    if ( (self.playerclass == 9) ) {
                                        self.impulse = 179;
                                        return;
                                    } else {
                                        if ( (!self.playerclass) ) {
                                            if (CheckClanMode()) return;
                                            src = (self.origin + (v_forward * 10));
                                            src_z = (self.absmin_z + (self.size_z * 0.700));
                                            traceline (src,(src + (v_forward * 2048)),0,self);
                                            if ( (trace_ent != world) ) {
                                                if (trace_ent.netname != string_null) {
                                                    sprint (self,PRINT_HIGH,"Locked onto ",trace_ent.netname,"\n");
                                                } else {
                                                    sprint (self,PRINT_HIGH,"Locked onto ",trace_ent.classname,"\n");
                                                }
                                                self.goalentity = trace_ent;
                                                if (!self.tracking) Toggle_Tracking();
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

void TeamFortress_DisplayLegalClasses () {
    float gotone;
    float ill;
    sprint (self,PRINT_HIGH,"Legal Classes for your team are:\n");
    gotone = 0;
    ill = TeamFortress_TeamGetIllegalClasses (self.pteam.team);
    if ( (!(store_obs.ammo_nails & 1) && !(ill & 1)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Scout");
    }
    if ( (!(store_obs.ammo_nails & 2) && !(ill & 2)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        if (classtype & 1) {
            sprint (self,PRINT_HIGH,"Technician");
        } else {
            sprint (self,PRINT_HIGH,"Sniper");
        }
    }
    if ( (!(store_obs.ammo_nails & 4) && !(ill & 4)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Soldier");
    }
    if ( (!(store_obs.ammo_nails & 8) && !(ill & 8)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Demolitions Man");
    }
    if ( (!(store_obs.ammo_nails & 16) && !(ill & 16)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Combat Medic");
    }
    if ( (!(store_obs.ammo_nails & 32) && !(ill & 32)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Heavy Weapons Guy");
    }
    if ( (!(store_obs.ammo_nails & 64) && !(ill & 64)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Pyro");
    }
    if ( (!(store_obs.ammo_nails & 256) && !(ill & 256)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Spy");
    }
    if ( (!(store_obs.ammo_nails & 512) && !(ill & 512)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"Engineer");
    }
    if ( (!(store_obs.ammo_nails & 128) && !(ill & 128)) ) {
        if ( gotone ) {
            sprint (self,PRINT_HIGH,", ");
        }
        gotone = 1;
        sprint (self,PRINT_HIGH,"RandomPC");
    }
    sprint (self,PRINT_HIGH,"\n");
}

void TeamFortress_ChangeClass (float inp) {
    if ( (!self.playerclass) ) {
        if (round_active && !modetype & 64) {
            if ( !IsLegalClass (inp) ) {

                sprint (self,PRINT_HIGH,"Your team cannot play that class.\n");
                TeamFortress_DisplayLegalClasses ();
                return ;
            }
            if ( ClassIsRestricted (self.pteam.team, inp) ) {
                sprint (self,PRINT_HIGH,"Your team already has enough of that class.\n");
                return ;
            }
            if ( TeamFortress_TeamIsCivilian (self.pteam.team) ) {

                sprint (self,PRINT_HIGH,"You cannot change class.\n");
                self.nextpc = 11;
                return;
            }
            self.nextpc = inp;
            sprint (self,PRINT_HIGH,"Next Round, you will return as a ");
            TeamFortress_PrintClassName (self,self.nextpc,(self.tfstate & 8));
            return ;
        }
    } else {
        if ( !IsLegalClass (inp) ) {
            sprint (self,PRINT_HIGH,"Your team cannot play that class.\n");
            TeamFortress_DisplayLegalClasses ();
            return ;
        }
        if ( ClassIsRestricted (self.pteam.team, inp) ) {
            sprint (self,PRINT_HIGH,"Your team already has enough of that class.\n");
            return ;
        }
        if ( TeamFortress_TeamIsCivilian (self.pteam.team) ) {
            inp = 11;
        }
        self.nextpc = inp;
        if (rounds) {
            sprint (self,PRINT_HIGH,"Next Round, you will return as a ");
        } else {
            sprint (self,PRINT_HIGH,"After dying, you will return as a ");
        }
        TeamFortress_PrintClassName (self,self.nextpc,(self.tfstate & 8));
        return ;
    }
    if ( (teamplay && (self.pteam.team == 0)) ) {
        if ( (toggleflags & 64) ) {
            if ( (TeamFortress_TeamPutPlayerInTeam () == 0) ) {
                return ;
            }
        } else {
            sprint (self,PRINT_HIGH,"You must join a team first. \n");
            return ;
        }
    }
    if ( (self.respawn_time > time) ) {
        return ;
    }
    if (round_over == 2) {
        return;
    }
    if ( (!IsLegalClass (inp ) && (inp != 11)) ) {
        sprint (self,PRINT_HIGH,"You cannot play that playerclass on this map. \n");
        TeamFortress_DisplayLegalClasses ();
        return ;
    }
    if ( ClassIsRestricted (self.pteam.team,inp) ) {
        sprint (self,PRINT_HIGH,"Your team has enough of that class.\n");
        return ;
    }
    if ( (inp > 0) && (inp < 12) ) {
        self.playerclass = (inp);
    } else {
        self.playerclass = CLASS_NONE;
    }
    TeamFortress_ExecClassScript (self);
    if ( (self.playerclass == 10) ) {
        sprint (self,PRINT_HIGH,"Random Playerclass.\n");
        self.tfstate = (self.tfstate | 8);
    }
    self.nextpc = 0;
    PutClientInServer();
}

void TeamFortress_Inventory () {
    entity tg;
    string ac;
    if (teamplay) {
        if (!self.pteam.team ) {
            sprint (self,PRINT_HIGH,"You're an observer\n");
            return;
        }
        sprint (self,PRINT_HIGH,"You're in team ");
        ac = ftos (self.pteam.team);
        sprint (self,PRINT_HIGH,ac);
        sprint (self,PRINT_HIGH,", color ");
        ac = ftos (self.pteam.colormap);
        sprint (self,PRINT_HIGH,ac);
        sprint (self,PRINT_HIGH,".\n");
    }
    if ( (self.no_grenades_1 > 0) ) {
        sprint (self,PRINT_HIGH,"Gren.Type 1 : ");
        ac = Status_GrenTypeToString(self.tp_grenades_1);
        sprint (self,PRINT_HIGH, ac, " (");
        ac = ftos (self.no_grenades_1);
        sprint (self,PRINT_HIGH,ac);
        sprint (self,PRINT_HIGH,")\n");
    }
    if ( (self.no_grenades_2 > 0) ) {
        sprint (self,PRINT_HIGH,"Gren.Type 2 : ");
        ac = Status_GrenTypeToString (self.tp_grenades_2);
        sprint (self,PRINT_HIGH, ac, " (");
        ac = ftos (self.no_grenades_2);
        sprint (self,PRINT_HIGH,ac);
        sprint (self,PRINT_HIGH,")\n");
    }
    if ( (self.tf_items & 1) ) {
        sprint (self,PRINT_HIGH,"Scanner. ");
    }
    if ( (self.carried & 4) ) {
        sprint (self,PRINT_HIGH,"Medikit (");
        ac = ftos (self.ammo_medikit);
        sprint (self,PRINT_HIGH,ac);
        sprint (self,PRINT_HIGH,") ");
    }
    if ( (self.ammo_detpack > 0) ) {
        ac = ftos (self.ammo_detpack);
        sprint (self,PRINT_HIGH,ac);
        if (modetype & 4) {
            sprint (self,PRINT_HIGH," Bomb");
        } else {
            sprint (self,PRINT_HIGH," Detpack");
        }
        if ( (self.ammo_detpack > 1) ) {
            sprint (self,PRINT_HIGH,"s");
        }
        sprint (self,PRINT_HIGH,". ");
    }
    tg = find (world,classname,"item_tfgoal");
    while ( tg ) {
        if ( (tg.owner == self) ) {
            sprint (self,PRINT_HIGH,tg.netname);
            sprint (self,PRINT_HIGH,". ");
        }
        tg = find (tg,classname,"item_tfgoal");
    }
    if ( (self.armorvalue > 0) ) {
        TeamFortress_DescribeArmor (self,self.armorclass);
    }
    if ( self.playerclass == 8  ) {
        sprint (self,PRINT_HIGH,"Skin : ");
        if ( (self.undercover_skin != 0) ) {
            TeamFortress_PrintClassName (self,self.undercover_skin,0);
        } else {
            sprint (self,PRINT_HIGH,"Spy\n");
        }
        sprint (self,PRINT_HIGH,"Colors : Team ");
        if ( (self.undercover_team != 0) ) {
            ac = ftos (self.undercover_team);
        } else {
            ac = ftos (self.pteam.team);
        }
        sprint (self,PRINT_HIGH,ac);
    }
    sprint (self,PRINT_HIGH,"\n");
}

void TeamFortress_ShowTF () {
    string st;
    if ( (toggleflags & 1) ) {
        sprint (self,PRINT_HIGH,"Class Persistence On.\n");
    } else {
        sprint (self,PRINT_HIGH,"Class Persistence Off.\n");
    }
    if ( (toggleflags & 64) ) {
        sprint (self,PRINT_HIGH,"AutoTeam On.\n");
    }
    if ( (toggleflags & 4) ) {
        st = ftos (respawn_delay_time);
    } else {
        st = "No";
    }
    sprint (self,PRINT_HIGH,st);
    if ( (st != "No") ) {
        sprint (self,PRINT_HIGH," second");
    }
    sprint (self,PRINT_HIGH," Respawn Delay.\n");
    if ( (toggleflags & 128) ) {
        sprint (self,PRINT_HIGH,"TeamFrags On.\n");
    } else {
        sprint (self,PRINT_HIGH,"TeamFrags Off.\n");
    }
    if ( allow_hook ) {
        sprint (self,PRINT_HIGH,"Grapple On.\n");
    }
    if ( (toggleflags & 2048) ) {
        sprint (self,PRINT_HIGH,"Full TeamScore On.\n");
    } else {
        sprint (self,PRINT_HIGH,"Full TeamScore Off.\n");
    }
}

void TeamFortress_GrenadePrimed ();

void TeamFortress_PrimeGrenade () {
    float gtype;
    string gs;
    string ptime;
    entity tGrenade;
    if (self.playerclass == 11) return;
    if ( (self.tfstate & 1024) ) {
        return ;
    }
    if ((self.tfstate & 1)) {
        if (self.impulse == 90 || self.impulse == 91)
            TeamFortress_ThrowGrenade ();
        return;
    }

    if (self.impulse == 90) self.impulse = 150;
    if ( (self.impulse == 150) ) {
        gtype = self.tp_grenades_1;
        gs = Status_GrenTypeToString(self.tp_grenades_1);
        if ( (self.no_grenades_1 > 0) ) {
            // stuffcmd(self,"play gren.wav\n");
            if (!modetype & 2) {
                self.no_grenades_1 = (self.no_grenades_1 - 1);
            }
            if ( (gtype == 10) ) {
                ptime = ftos (0.500);
                sprint (self,PRINT_HIGH,"Opening ");
                sprint (self,PRINT_HIGH,gs);
                sprint (self,PRINT_HIGH,"...\n");
            } else {
                ptime = ftos (3);
                sprint (self,PRINT_HIGH,gs);
                sprint (self,PRINT_HIGH," primed, ");
                sprint (self,PRINT_HIGH,ptime);
                sprint (self,PRINT_HIGH," seconds...\n");
            }
        } else {
            sprint (self,PRINT_HIGH,"No ");
            sprint (self,PRINT_HIGH,gs);
            sprint (self,PRINT_HIGH,"s left.\n");
            return ;
        }
    }
    if (self.impulse == 91) self.impulse = 151;
    if ( (self.impulse == 151) ) {
        gtype = self.tp_grenades_2;
        gs = Status_GrenTypeToString(self.tp_grenades_2);
        if ( (self.no_grenades_2 > 0) ) {
            //stuffcmd(self,"play gren.wav\n");
            if (!modetype & 2) {
                self.no_grenades_2 = (self.no_grenades_2 - 1);
            }
            if ( (gtype == 10) ) {
                ptime = ftos (0.500);
                sprint (self,PRINT_HIGH,"Opening ");
                sprint (self,PRINT_HIGH,gs);
                sprint (self,PRINT_HIGH,"...\n");
            } else {
                ptime = ftos (3);
                sprint (self,PRINT_HIGH,gs);
                sprint (self,PRINT_HIGH," primed, ");
                sprint (self,PRINT_HIGH,ptime);
                sprint (self,PRINT_HIGH," seconds...\n");
            }
        } else {
            sprint (self,PRINT_HIGH,"No ");
            sprint (self,PRINT_HIGH,gs);
            sprint (self,PRINT_HIGH,"s left.\n");
            return ;
        }
    }
    self.tfstate = (self.tfstate | 1);
    tGrenade = spawn ();
    tGrenade.owner = self;
    tGrenade.weapon = gtype;
    tGrenade.classname = "timer";
    tGrenade.impulse = self.impulse;
    tGrenade.nextthink = (time + 0.800);
    if ( (gtype == 10) ) {
        tGrenade.heat = ((time + 0.500) + 0.500);
    } else {
        tGrenade.heat = ((time + 3) + 0.800);
    }
    tGrenade.think = TeamFortress_GrenadePrimed;
}

void TeamFortress_GrenadePrimed () {
    entity user;
    entity oldself;
    user = self.owner;
    if ( (!(user.tfstate & 1024) && !user.deadflag) ) {
        self.nextthink = (time + 0.100);
        if ( !self.think ) {
            dremove (self);
        }
        if ( (time > self.heat) ) {
            TeamFortress_ExplodePerson (self);
        }
        return ;
    }
    if ( !(user.tfstate & 1) ) {
        dprint ("GrenadePrimed logic error\n");
    }
    user.tfstate = (user.tfstate - (user.tfstate & 1));
    user.tfstate = (user.tfstate - (user.tfstate & 1024));
    sound (user,CHAN_WEAPON,"weapons/ax1.wav",1,1);
    KickPlayer (-1,user);
    newmis = spawn ();
    newmis.owner = user;
    newmis.movetype = 10;
    newmis.solid = 2;
    newmis.classname = "grenade";
    if (self.impulse == 150) {
        newmis.tp_grenades_1 = self.weapon;
    } else if (self.impulse == 151) {
        newmis.tp_grenades_2 = self.weapon;
    }
    makevectors (user.v_angle);
    if ( user.deadflag ) {
        newmis.velocity = '0 0 200';
    } else {
        if ( user.v_angle_x ) {
            newmis.velocity = ((((v_forward * 600) + (v_up * 200)) + ((crandom () * v_right) * 10)) + ((crandom () * v_up) * 10));
        } else {
            newmis.velocity = aim (user,10000);
            newmis.velocity = (newmis.velocity * 600);
            newmis.velocity_z = 200;
        }
    }
    newmis.angles = vectoangles (newmis.velocity);
    newmis.think = SUB_Null;
    newmis.nextthink = self.heat;
    if ( (self.weapon == 1) ) {
        newmis.touch = NormalGrenadeTouch;
        newmis.think = NormalGrenadeExplode;
        newmis.skin = 0;
        newmis.avelocity = '300 300 300';
        setmodel (newmis,"progs/hgren2.mdl");
    } else {
        if ( (self.weapon == 2) ) {
            newmis.touch = ConcussionGrenadeTouch;
            newmis.think = ConcussionGrenadeExplode;
            newmis.skin = 1;
            newmis.avelocity = '300 300 300';
            setmodel (newmis,"progs/hgren2.mdl");
        } else {
            if ( (self.weapon == 3) ) {
                newmis.touch = NailGrenadeTouch;
                newmis.think = NailGrenadeExplode;
                newmis.skin = 1;
                newmis.avelocity = '0 300 0';
                setmodel (newmis,"progs/biggren.mdl");
            } else {
                if ( (self.weapon == 4) ) {
                    newmis.touch = MirvGrenadeTouch;
                    newmis.think = MirvGrenadeExplode;
                    newmis.skin = 0;
                    newmis.avelocity = '0 300 0';
                    setmodel (newmis,"progs/biggren.mdl");
                } else {
                    if ( (self.weapon == 5) ) {
                        newmis.touch = NapalmGrenadeTouch;
                        //  if (grentype)
                        //    newmis.think = NapalmGrenadeExplode2;
                        //  else
                        newmis.think = NapalmGrenadeExplode;
                        newmis.skin = 2;
                        newmis.avelocity = '0 300 0';
                        setmodel (newmis,"progs/biggren.mdl");
                    } else {
                        if ( (self.weapon == 6) ) {
                            newmis.touch = NormalGrenadeTouch;
                            newmis.think = FreezeGrenadeExplode;
                            newmis.skin = 1;
                            newmis.avelocity = '300 300 300';
                            setmodel (newmis,"progs/hgren2.mdl");
                        } else {
                            if ( (self.weapon == 7) ) {
                                newmis.touch = GasGrenadeTouch;
                                newmis.think = GasGrenadeExplode;
                                newmis.skin = 3;
                                newmis.avelocity = '300 300 300';
                                setmodel (newmis,"progs/grenade2.mdl");
                            } else {
                                if ( (self.weapon == 8) ) {
                                    newmis.touch = EMPGrenadeTouch;
                                    newmis.think = EMPGrenadeExplode;
                                    newmis.skin = 4;
                                    newmis.avelocity = '300 300 300';
                                    setmodel (newmis,"progs/grenade2.mdl");
                                } else {
                                    if ( (self.weapon == 10) ) {
                                        newmis.touch = CanisterTouch;
                                        newmis.think = ScatterCaltrops;
                                        newmis.skin = 0;
                                        newmis.avelocity = '0 0 0';
                                    } else {
                                        if ((self.weapon == 9)) {
                                            newmis.touch = FlashGrenadeTouch;
                                            newmis.think = FlashGrenadeExplode;
                                            newmis.skin = 2;
                                            newmis.avelocity = '300 300 300';
                                            setmodel (newmis, "progs/hgren2.mdl");

                                        }

                                    }
                                }

                            }
                        }
                    }
                }
            }
        }
    }
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,user.origin);
    oldself = self;
    self = self.owner;
    self = oldself;
    dremove (self);
}

void TeamFortress_ThrowGrenade () {
    if ( !(self.tfstate & 1) ) {
        return ;
    }
    self.tfstate = (self.tfstate | 1024);
}

float IsLegalClass (float pc) {
    float bit;
    if ( (pc == 1) ) {
        bit = 1;
    } else {
        if ( (pc == 2) ) {
            bit = 2;
        } else {
            if ( (pc == 3) ) {
                bit = 4;
            } else {
                if ( (pc == 4) ) {
                    bit = 8;
                } else {
                    if ( (pc == 5) ) {
                        bit = 16;
                    } else {
                        if ( (pc == 6) ) {
                            bit = 32;
                        } else {
                            if ( (pc == 7) ) {
                                bit = 64;
                            } else {
                                if ( (pc == 8) ) {
                                    bit = 256;
                                } else {
                                    if ( (pc == 9) ) {
                                        bit = 512;
                                    } else {
                                        if ( (pc == 10) ) {
                                            bit = 128;
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if ( ((store_obs.ammo_nails & bit) || (TeamFortress_TeamGetIllegalClasses (self.pteam.team) & bit)) ) {
        return ( 0 );
    }
    return ( 1 );
}

void TeamFortress_SetSpeed (entity p) {
    //string sp;
    float tf;
    entity te;
    float wpdec;
    float armdec;
    float medspeed;
    if ( (p.tfstate & 65536) ) {
        p.velocity = '0 0 0';
        p.maxspeed = 0;
        if (cease_fire || p.is_frozen) p.gravity = 0;
        return ;
    }
    p.gravity = 1;
    if ( (p.playerclass == 1) ) {
        p.maxspeed = 450;
    } else {
        if ( (p.playerclass == 2) ) {
            p.maxspeed = 300;
        } else {
            if ( (p.playerclass == 3) ) {
                p.maxspeed = 240;
            } else {
                if ( (p.playerclass == 4) ) {
                    p.maxspeed = 280;
                } else {
                    if ( (p.playerclass == 5) ) {
                        p.maxspeed = 320;
                    } else {
                        if ( (p.playerclass == 6) ) {
                            p.maxspeed = 230;
                        } else {
                            if ( (p.playerclass == 7) ) {
                                p.maxspeed = 300;
                            } else {
                                if ( (p.playerclass == 11) ) {

                                    if ((classtype & 64)) {
                                        p.maxspeed = 320;
                                    } else {
                                        p.maxspeed = 240;
                                    }
                                } else {
                                    if ( (p.playerclass == 8) ) {
                                        p.maxspeed = 300;
                                    } else {
                                        if ( (p.playerclass == 9) ) {
                                            p.maxspeed = 300;
                                        } else {
                                            if ( (!p.playerclass) ) {

                                                p.maxspeed = 500;
                                                //p.maxspeed = 0;
                                                return ;

                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    if (aspeedtype) {
        if (!p.waterlevel) {
            if (p.playerclass && !(p.flags & 512)) {
                p.maxspeed = p.maxspeed / (airspeed * p.armortype);
            }
        }
    }
    if (realistic & 4) {

        wpdec = p.num_weaps * 30;
        //bprint(PRINT_HIGH, ftos(wpdec));
        //bprint(PRINT_HIGH,"\n");
        armdec = p.armortype * 50;
        //bprint(PRINT_HIGH, ftos(armdec));
        //bprint(PRINT_HIGH, "\n");

        medspeed = 300 - (wpdec + armdec);
        //p.maxspeed = (p.maxspeed + medspeed / 2);
    }
    tf = 0;
    te = find (world,classname,"item_tfgoal");
    while ( ((te != world) && (tf == 0)) ) {
        if ( (te.owner == p) ) {
            if ( (te.goal_activation & 2) ) {
                tf = 1;
                p.maxspeed = (p.maxspeed / 2);
            }
        }
        te = find (te,classname,"item_tfgoal");
    }
    if ( (p.tfstate & 32768) ) {
        p.maxspeed = (p.maxspeed / 2);
    }
    if ( p.leg_damage ) {
        if ( (p.leg_damage > 6) ) {
            p.leg_damage = 6;
        }
        p.maxspeed = (p.maxspeed * ((10 - p.leg_damage) / 10));
    }
    if ( (p.tfstate & 2048) ) {
        if ( (p.current == WEAP_ASSAULT_CANNON) ) {
            if ( (p.maxspeed > (p.maxspeed / 2)) ) {
                p.maxspeed = (p.maxspeed / 2);
            }
        } else {
            if ( (p.maxspeed > 80) ) {
                p.maxspeed = 80;
            }
        }
    }
}

void TeamFortress_SetHealth () {
    if (modetype & 8) {
        self.max_health = 250;
        return;
    }
    if ( (self.playerclass == 1) ) {
        self.max_health = 75;
    } else {
        if ( (self.playerclass == 2) ) {
            self.max_health = 90;
        } else {
            if ( (self.playerclass == 3) ) {
                self.max_health = 100;
            } else {
                if ( (self.playerclass == 4) ) {
                    if (modetype & 256) {
                        self.max_health = 90;
                    } else {
                        self.max_health = 100;
                    }
                } else {
                    if ( (self.playerclass == 5) ) {
                        self.max_health = 90;
                    } else {
                        if ( (self.playerclass == 6) ) {
                            self.max_health = 100;
                        } else {
                            if ( (self.playerclass == 7) ) {
                                self.max_health = 100;
                            } else {
                                if ( (self.playerclass == 11) ) {
                                    self.max_health = 100;
                                } else {
                                    if ( (self.playerclass == 8) ) {
                                        self.max_health = 90;
                                    } else {
                                        if ( (self.playerclass == 9) ) {
                                            self.max_health = 80;
                                        } else {
                                            if ( (!self.playerclass) ) {
                                                self.max_health = 1;
                                                self.takedamage = 0;
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    self.health = self.max_health;
}
string TeamFortress_GetSkin (entity p) {
    float pc;
    string st;
    if ( ((p.playerclass == 11) || (p.pteam.team == 0)) ) {
        return ( "base" );
    }
    pc = p.playerclass;
    if ( (p.playerclass == 8) ) {
        if ( (p.undercover_skin != 0) ) {
            pc = p.undercover_skin;
        }
    }
    if (TeamFortress_TeamIsCivilian(p.pteam.team)) {

        st = infokey (world,"sk_civilian");
        if ( (st != string_null) ) {
            return ( st );
        }
        return ( "base" );
    } else {
        if ( (pc == 1) ) {
            st = infokey (world,"sk_scout");
            if ( (st != string_null) ) {
                return ( st );
            }
            return ( "tf_scout" );
        } else {
            if ( (pc == 2) ) {
                if (classtype & 1) {
                    st = infokey (world,"sk_plasma");
                    if ( (st != string_null) ) {
                        return ( st );
                    }
                    return ( "tf_plasma" );
                } else {
                    st = infokey (world,"sk_sniper");
                    if ( (st != string_null) ) {
                        return ( st );
                    }
                    return ( "tf_snipe" );
                }
            } else {
                if ( (pc == 3) ) {
                    st = infokey (world,"sk_soldier");
                    if ( (st != string_null) ) {
                        return ( st );
                    }
                    return ( "tf_sold" );
                } else {
                    if ( (pc == 4) ) {
                        st = infokey (world,"sk_demoman");
                        if ( (st != string_null) ) {
                            return ( st );
                        }
                        return ( "tf_demo" );
                    } else {
                        if ( (pc == 5) ) {
                            st = infokey (world,"sk_medic");
                            if ( (st != string_null) ) {
                                return ( st );
                            }
                            return ( "tf_medic" );
                        } else {
                            if ( (pc == 6) ) {
                                st = infokey (world,"sk_hwguy");
                                if ( (st != string_null) ) {
                                    return ( st );
                                }
                                return ( "tf_hwguy" );
                            } else {
                                if ( (pc == 7) ) {
                                    st = infokey (world,"sk_pyro");
                                    if ( (st != string_null) ) {
                                        return ( st );
                                    }
                                    return ( "tf_pyro" );
                                } else {
                                    if ( (pc == 8) ) {
                                        st = infokey (world,"sk_spy");
                                        if ( (st != string_null) ) {
                                            return ( st );
                                        }
                                        return ( "tf_spy" );
                                    } else {
                                        if ( (pc == 9) ) {
                                            st = infokey (world,"sk_engineer");
                                            if ( (st != string_null) ) {
                                                return ( st );
                                            }
                                            return ( "tf_eng" );
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    return ( "base" );
}

void TeamFortress_SetSkin (entity p) {
    string st;
    if ( ((p.playerclass == 8) && (p.undercover_skin != 0)) ) {
        p.skin = p.undercover_skin;
    } else {
        p.skin = p.playerclass;
    }
    if ( (p.skin != 0) ) {
        stuffcmd (p,"skin ");
        st = TeamFortress_GetSkin (p);
        stuffcmd (p,st);
        stuffcmd (p,"\n");
    } else {
        stuffcmd (p,"skin base\n");
    }
}

void TeamFortress_SetEquipment () {
	entity te;
	string st;
	float kept_items;
	float noitems;
	if ( (self.classname != "player") ) {
		return ;
	}
	kept_items = (self.tf_items & (131072 | 262144));
	self.items = 0;
	self.last = 0;
	self.current = 0;
	self.carried = 0;
	self.tf_items = 0;
	if ( (self.playerclass != 1) ) {
		self.tf_items_flags = 0;
	}
	self.armorclass = 0;
	self.impulse = 0;
	self.undercover_skin = 0;
	if ( (self.undercover_team != 0) ) {
		//self.immune_to_check = (time + 5);
		self.undercover_team = 0;
		stuffcmd (self,"color ");
		st = ftos (self.pteam.colormap);
		stuffcmd (self,st);
		stuffcmd (self,"\n");
	}
	self.is_building = 0;
	self.is_detpacking = 0;
	self.is_undercover = 0;
	self.is_feigning = 0;
	self.is_unabletospy = 0;
	self.ammo_medikit = 0;
	self.maxammo_medikit = 0;
	self.ammo_detpack = 0;
	self.maxammo_detpack = 0;
	self.items_allowed = 0;
	self.armor_allowed = 0;
	self.maxarmor = 0;
	self.respawn_time = 0;
	self.heat = 0;
	self.tfstate = (self.tfstate - (self.tfstate & 2));
	self.items = (self.items | kept_items);

	if ( (self.playerclass == 1) ) {
		self.carried = (((self.carried | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_NAILGUN);
		self.ammo_rockets = 0;
		self.ammo_nails = 100;
		self.ammo_shells = 25;
		self.ammo_cells = 50;
		self.maxammo_rockets = 25;
		self.maxammo_nails = 200;
		self.maxammo_shells = 50;
		self.maxammo_cells = 100;
		self.no_grenades_1 = 2;
		self.no_grenades_2 = 3;
		self.tp_grenades_1 = 10;
		self.tp_grenades_2 = 2;
		self.tf_items = 1;
		self.ScannerOn = 0;
		if ( (self.tf_items_flags <= 0) ) {
			self.tf_items_flags = (self.tf_items_flags | 1);
		}
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.300;
		self.armorvalue = 25;
		self.armor_allowed = 0.300;
		self.maxarmor = 50;
		self.current = WEAP_NAILGUN;
		self.items_allowed = ((WEAP_AXE | WEAP_SHOTGUN) | WEAP_NAILGUN);
		self.items = ((self.items | 1) | 4);
		self.num_weaps = 3;
	} else if ( (self.playerclass == 2) ) {
		if (classtype & 1) {
			self.carried = ((((self.carried | WEAP_PLASMAGUN) | WEAP_NAILGUN) | WEAP_SHOTGUN) | WEAP_AXE);
			self.ammo_cells = 100;
			self.ammo_nails = 0;
			self.maxammo_cells = 200;
			self.maxammo_nails = 50;
			self.armortype = 0.600;
			self.armorvalue = 50;
			self.armor_allowed = 0.600;
			self.maxarmor = 130;
			self.current = WEAP_PLASMAGUN;
			self.items_allowed = (((WEAP_PLASMAGUN | WEAP_NAILGUN) | WEAP_SHOTGUN) | WEAP_AXE);
			self.items = (((self.items | 1) | 4) | 16);
			self.num_weaps = 3;
		} else {
			self.carried = ((((self.carried | WEAP_SNIPER_RIFLE) | WEAP_AUTO_RIFLE	) | WEAP_AXE) | WEAP_NAILGUN);
			self.ammo_cells = 0;
			self.ammo_nails = 50;
			self.maxammo_nails = 100;
			self.maxammo_cells = 50;
			self.armortype = 0.300;
			self.armorvalue = 0;
			self.armor_allowed = 0.300;
			self.maxarmor = 50;
			self.current = WEAP_SNIPER_RIFLE;
			self.items_allowed = (((WEAP_SNIPER_RIFLE | WEAP_AUTO_RIFLE	) | WEAP_AXE) | WEAP_NAILGUN);
			self.items = (((self.items | 1) | 2) | 4);
			self.num_weaps = 4;
		}
		self.ammo_rockets = 0;
		self.ammo_shells = 60;
		self.maxammo_rockets = 25;
		self.maxammo_shells = 75;
		self.no_grenades_1 = 2;
		self.no_grenades_2 = 2;
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 9;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
	} else if ( (self.playerclass == 3) ) {
		self.carried = ((((self.carried | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_ROCKET_LAUNCHER);
		self.ammo_rockets = 10;
		self.ammo_nails = 0;
		self.ammo_shells = 50;
		self.ammo_cells = 0;
		self.maxammo_rockets = 50;
		self.maxammo_nails = 50;
		self.maxammo_shells = 100;
		self.maxammo_cells = 50;
		self.no_grenades_1 = 4;
		self.no_grenades_2 = 1; //2
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 3;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.800;
		self.armorvalue = 100;
		self.armor_allowed = 0.800;
		self.maxarmor = 200;
		self.current = WEAP_ROCKET_LAUNCHER;
		self.items_allowed = (((WEAP_AXE | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_ROCKET_LAUNCHER);
		self.items = (((self.items | 1) | 2) | 32);
		self.num_weaps = 4;
	} else if ( (self.playerclass == 4) ) {
		self.carried = ((((self.carried | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_GRENADE_LAUNCHER) | WEAP_PIPEBOMB_LAUNCHER);
		self.ammo_rockets = 20;
		self.ammo_nails = 0;
		self.ammo_shells = 30;
		self.ammo_cells = 0;
		self.maxammo_rockets = 50;
		self.maxammo_nails = 50;
		self.maxammo_shells = 70;
		self.maxammo_cells = 50;
		self.no_grenades_1 = 4;
		if (modetype & 256) {
			self.no_grenades_2 = 4;
		} else {
			self.no_grenades_2 = 2; //4
		}
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 4;
		self.tf_items = 0;
		self.ammo_detpack = 1;
		self.maxammo_detpack = 1;
		self.armorclass = (self.armorclass | 2);
		self.armortype = 0.600;
		self.armorvalue = 50;
		self.armor_allowed = 0.600;
		self.maxarmor = 120;
		self.current = WEAP_GRENADE_LAUNCHER;
		self.items_allowed = (((WEAP_AXE | WEAP_SHOTGUN) | WEAP_GRENADE_LAUNCHER) | WEAP_PIPEBOMB_LAUNCHER);
		self.items = (((self.items | 1) | 16) | 32);
		self.num_weaps = 3;
	} else if ( (self.playerclass == 5) ) {
		self.carried = ((((self.carried | WEAP_MEDIKIT) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_SUPER_NAILGUN);
		self.ammo_rockets = 0;
		self.ammo_nails = 50;
		self.ammo_shells = 50;
		self.ammo_cells = 0;
		self.maxammo_rockets = 25;
		self.maxammo_nails = 150;
		self.maxammo_shells = 80;
		self.maxammo_cells = 50;
		self.no_grenades_1 = 3;
		if (modetype & 256) {
			self.no_grenades_2 = 2;
		} else {
			self.no_grenades_2 = 3;
		}
		self.tp_grenades_1 = 1;
		if (grentype)
			self.tp_grenades_2 = 6; //2
		else
			self.tp_grenades_2 = 2;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.300;
		self.armorvalue = 50;
		self.armor_allowed = 0.600;
		self.maxarmor = 100;
		self.current = WEAP_SUPER_NAILGUN;
		self.ammo_medikit = 50;
		self.maxammo_medikit = 100;
		te = spawn ();
		te.nextthink = (time + 3);
		te.think = TeamFortress_Regenerate;
		te.owner = self;
		te.classname = "timer";
		self.items_allowed = ((((WEAP_MEDIKIT ) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_SUPER_NAILGUN);
		self.items = (((self.items | 1) | 2) | 8 );
		self.num_weaps = 4;
	} else if ( (self.playerclass == 6) ) {
		self.carried = ((((self.carried | WEAP_ASSAULT_CANNON) | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN);
		self.ammo_rockets = 0;
		self.ammo_nails = 0;
		self.ammo_shells = 200;
		self.ammo_cells = 30;
		self.maxammo_rockets = 25;
		self.maxammo_nails = 200;
		self.maxammo_shells = 200;
		self.maxammo_cells = 56;
		self.no_grenades_1 = 4;
		self.no_grenades_2 = 1;
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 4;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.800;
		self.armorvalue = 150;
		self.armor_allowed = 0.800;
		self.maxarmor = 300;
		self.current = WEAP_ASSAULT_CANNON;
		self.items_allowed = (((WEAP_ASSAULT_CANNON | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN);
		self.items = (((self.items | 1) | 2) | 64);
		self.num_weaps = 4;
	} else if ( (self.playerclass == 7) ) {
		self.carried = ((((self.carried | WEAP_INCENDIARY) | WEAP_FLAMETHROWER) | WEAP_AXE) | WEAP_SHOTGUN);
		self.ammo_rockets = 20;
		self.ammo_nails = 0;
		self.ammo_shells = 20;
		self.ammo_cells = 120;
		self.maxammo_rockets = 60;
		self.maxammo_nails = 50;
		self.maxammo_shells = 40;
		self.maxammo_cells = 200;
		if (modetype & 256) {
			self.no_grenades_1 = 1;
			self.no_grenades_2 = 4;
		} else {
			self.no_grenades_1 = 2;
			self.no_grenades_2 = 3;
		}
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 5;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 16);
		self.armortype = 0.600;
		self.armorvalue = 50;
		self.armor_allowed = 0.600;
		self.maxarmor = 150;
		self.current = WEAP_FLAMETHROWER;
		self.items_allowed = (((WEAP_INCENDIARY | WEAP_FLAMETHROWER) | WEAP_AXE) | WEAP_SHOTGUN);
		self.items = (((self.items | 1) | 8) | 32);
		self.num_weaps = 4;
	} else if ( (self.playerclass == 11) ) {
		if (( classtype & 64 || rounds)) {
			self.ammo_rockets = 10;
			self.ammo_nails = 60;
			self.ammo_shells = 40;
			self.ammo_cells = 8;
			self.maxammo_rockets = 25;
			self.maxammo_nails = 200;
			self.maxammo_shells = 100;
			self.maxammo_cells = 20;
			self.armortype = 0.600;
			self.maxarmor = 140;
			self.current = WEAP_ROCKET_LAUNCHER;
			self.items_allowed = ((((((((self.carried | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_NAILGUN) | WEAP_SUPER_NAILGUN) | WEAP_GRENADE_LAUNCHER) | WEAP_ROCKET_LAUNCHER) | WEAP_LIGHTNING);
			self.carried = ((((((((self.carried | WEAP_AXE) | WEAP_SHOTGUN) | WEAP_SUPER_SHOTGUN) | WEAP_NAILGUN) | WEAP_SUPER_NAILGUN) | WEAP_GRENADE_LAUNCHER) | WEAP_ROCKET_LAUNCHER) | WEAP_LIGHTNING);
			self.items = (((((((self.items | 1) | 2) | 4) | 8) | 16) | 32) | 64);
			self.armor_allowed = 0.600;
			self.num_weaps = 8;

		} else {
			self.ammo_rockets = 0;
			self.ammo_nails = 0;
			self.ammo_shells = 0;
			self.ammo_cells = 0;
			self.maxammo_rockets = 0;
			self.maxammo_nails = 0;
			self.maxammo_shells = 0;
			self.maxammo_cells = 0;
			self.armortype = 0;
			self.armor_allowed = 0;
			self.maxarmor = 0;
			self.current = WEAP_AXE;
			self.items_allowed = 16;
			self.items = 0;
		}
		self.no_grenades_1 = 0;
		self.no_grenades_2 = 0;
		self.tp_grenades_1 = 0;
		self.tp_grenades_2 = 0;
		self.tf_items = 0;
		self.armorvalue = 0;
		self.armorclass = (self.armorclass | 0);

	} else if ( (self.playerclass == 8) ) {
		self.carried = ((((self.carried | WEAP_AXE) | WEAP_TRANQ) | WEAP_SUPER_SHOTGUN) | WEAP_NAILGUN);
		self.ammo_rockets = 0;
		self.ammo_nails = 50;
		self.ammo_shells = 40;
		self.ammo_cells = 10;
		self.maxammo_rockets = 15;
		self.maxammo_nails = 100;
		self.maxammo_shells = 40;
		self.maxammo_cells = 30;
		if (modetype & 256) {
			self.no_grenades_1 = 2;
			self.no_grenades_2 = 2;
		} else {
			self.no_grenades_1 = 3;
			self.no_grenades_2 = 2;
		}
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 7;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.600;
		self.armorvalue = 25;
		self.armor_allowed = 0.600;
		self.maxarmor = 100;
		self.current = WEAP_TRANQ;
		self.items_allowed = (((WEAP_AXE | WEAP_TRANQ) | WEAP_SUPER_SHOTGUN) | WEAP_NAILGUN);
		self.items = (((self.items | 1) | 2) | 4);
		self.num_weaps = 4;
	} else if ( (self.playerclass == 9) ) {
		self.carried = (((self.carried | WEAP_SPANNER) | WEAP_RAILGUN) | WEAP_SUPER_SHOTGUN);
		self.ammo_rockets = 0;
		self.ammo_nails = 25;
		self.ammo_shells = 20;
		self.ammo_cells = 100;
		self.maxammo_rockets = 30;
		self.maxammo_nails = 50;
		self.maxammo_shells = 50;
		self.maxammo_cells = 200;
		self.no_grenades_1 = 2;
		self.no_grenades_2 = 2;
		self.tp_grenades_1 = 1;
		self.tp_grenades_2 = 8;
		self.tf_items = 0;
		self.armorclass = (self.armorclass | 0);
		self.armortype = 0.300;
		self.armorvalue = 25;
		self.armor_allowed = 0.600;
		if (classtype & 32) {
			self.maxarmor = 70;
		} else {
			self.maxarmor = 50;
		}
		self.current = WEAP_RAILGUN;
		self.items_allowed = ((WEAP_SPANNER | WEAP_RAILGUN) | WEAP_SUPER_SHOTGUN);
		self.items = ((self.items | 1) | 2);
		self.num_weaps = 3;
	} else if ( (!self.playerclass) ) {
		self.items = 0;
		self.ammo_rockets = 0;
		self.ammo_nails = 0;
		self.ammo_shells = 0;
		self.ammo_cells = 0;
		self.no_grenades_1 = 0;
		self.no_grenades_2 = 0;
		self.tp_grenades_1 = 0;
		self.tp_grenades_2 = 0;
		self.armorclass = 0;
		self.armortype = 0;
		self.armorvalue = 0;
		self.weapon = 0;
		self.current = 0;
		self.carried = 0;
		self.flags = 8;
		self.gravity = 1;
		self.waterlevel = -1;
		self.takedamage = 0;
		self.solid = 0;
		self.model = string_null;
		self.mdl = string_null;
		self.modelindex = 0;
		self.weaponmodel = string_null;
		modelindex_player = 0;
		self.tfstate = (self.tfstate | 2);
		setmodel (self,string_null);
	}

    if (self.playerclass) {
        if (modetype & 8) {
            self.armorvalue = 200;
            self.maxarmor = 200;
            self.armortype = 0.8;
            self.armor_allowed = 0.800;
            self.maxammo_rockets = 999;
            self.maxammo_nails = 999;
            self.maxammo_shells = 999;
            self.maxammo_cells = 999;
            self.ammo_rockets = 120;
            self.ammo_nails = 250;
            self.ammo_shells = 250;
            self.ammo_cells = 200;
            self.health = 250;
        } else {
            if (rounds) {
                if (!modetype & 64 ) {
                    self.armorvalue = self.maxarmor;
                    self.ammo_detpack = self.maxammo_detpack;
                    self.no_grenades_1 = 4;
                    self.ammo_rockets = ceil(self.maxammo_rockets / 2);
                    if (self.playerclass == 5) {
                        self.ammo_nails = 100;
                    } else {
                        self.ammo_nails = ceil(self.maxammo_nails / 2);
                    }
                    if ((self.playerclass != 6) && (self.playerclass != 8))
                        self.ammo_shells = ceil(self.maxammo_shells / 2);
                    self.ammo_cells = ceil(self.maxammo_cells / 2);
                }
            }
            if (stamina) self.stamina = 1000;
            if (realdm) {
                self.carried = (WEAP_AXE | WEAP_SHOTGUN);
                self.armor_allowed = 0.800;
                self.num_weaps = 2;
                self.armor_allowed = 0.800;
                self.maxarmor = 200;
                self.armorvalue = 0;
                self.armortype = 0;
                self.maxammo_rockets = 100;
                self.maxammo_nails = 200;
                self.maxammo_shells = 100;
                self.maxammo_cells = 100;
                self.current = WEAP_SHOTGUN;
                self.items = (0 | 1);
            }
            if ( modetype & 4 ) {
                self.ammo_detpack = 0;
                if (self.pteam == pteam2) {
                    self.maxammo_detpack = 1;
                } else {
                    self.maxammo_detpack = 0;
                }
            }
        }
        if (deathmatch == 4) {
            self.armorvalue = 200;
            self.maxarmor = 200;
            self.armortype = 0.8;
            self.armor_allowed = 0.800;
            self.maxammo_rockets = 100;
            self.maxammo_nails = 200;
            self.maxammo_shells = 100;
            self.maxammo_cells = 100;
            self.health = 250;
            self.items = (self.items | 1048576);
            self.invisible_time = 1;
            self.invincible_finished = (time + 4);
        }
        if ( allow_hook  ) {
            self.carried = (self.carried | WEAP_HOOK);
        }
    }

    if ( (self.armortype >= 0.800) ) {
        self.items = (self.items | 32768);
    } else {
        if ( (self.armortype >= 0.600) ) {
            self.items = (self.items | 16384);
        } else {
            if ( (self.armortype >= 0.300) ) {
                self.items = (self.items | 8192);
            }
        }
    }
    noitems = (stof(infokey(world,"noitems")));
    if ( noitems & 1 ) {
        self.no_grenades_1 = 0;
        self.tp_grenades_1 = 0;
    }
    if (noitems & 2) {
        self.no_grenades_2 = 0;
        self.tp_grenades_2 = 0;
    }
    if (noitems & 4) {
        self.ammo_detpack = 0;
        self.maxammo_detpack = 0;
    }
    if (modetype & 2) {
        self.armorvalue = 0;
        self.health = 1000;
        self.ammo_rockets = self.maxammo_rockets;
        self.ammo_nails = self.maxammo_nails;
        self.ammo_shells = self.maxammo_shells;
        self.ammo_cells = self.maxammo_cells;
    }
    W_SetCurrentAmmo ();
}

float TeamFortress_GetMaxAmmo (entity Retriever, float AmmoType) {
    if ( (AmmoType == 256) ) {
        return ( Retriever.maxammo_shells );
    } else {
        if ( (AmmoType == 512) ) {
            return ( Retriever.maxammo_nails );
        } else {
            if ( (AmmoType == 2048) ) {
                return ( Retriever.maxammo_cells );
            } else {
                if ( (AmmoType == 1024) ) {
                    return ( Retriever.maxammo_rockets );
                } else {
                    if ( (AmmoType == 4) ) {
                        return ( Retriever.maxammo_medikit );
                    } else {
                        if ( (AmmoType == 131072) ) {
                            return ( Retriever.maxammo_detpack );
                        }
                    }
                }
            }
        }
    }
    dprint ("Error in TeamFortress_GetMaxAmmo()\n");
    dprint ("Invalid ammo type passed.\n");
    return ( 0 );
}

float TeamFortress_CanGetWeapon (entity Retriever, float WeaponType) {
    //if (modetype & 8) return 1;
    if ( (Retriever.items_allowed & WeaponType) ) {
        return ( 1 );
    }
    return ( 0 );
}

void TeamFortress_DescribeArmor (entity Player, float Armorclass) {
    if ( (Armorclass == 0) ) {
        return ;
    }
    if ( (Armorclass & 16) ) {
        sprint (Player,PRINT_HIGH,"Asbestos ");
    }
    if ( (Armorclass & 2) ) {
        sprint (Player,PRINT_HIGH,"Wooden ");
    }
    if ( (Armorclass & 4) ) {
        sprint (Player,PRINT_HIGH,"Blast ");
    }
    if ( (Armorclass & 8) ) {
        sprint (Player,PRINT_HIGH,"Shockproof ");
    }
    if ( (Armorclass & 1) ) {
        sprint (Player,PRINT_HIGH,"Kevlar ");
    }
    sprint (Player,PRINT_HIGH,"armor\n");
}

void TeamFortress_AddBackpackItems (entity Retriever, entity Items) {
    return ;
}
string TeamFortress_GetClassName (float pc) {
    if ( (pc == 1) ) {
        return ( "Scout" );
    } else if ( (pc == 2) ) {
        if (classtype & 1) {
            return ( "Technician" );
        } else {
            return ( "Sniper" );
        }
    } else if ( (pc == 3) ) {
        return ( "Soldier" );
    } else if ( (pc == 4) ) {
        return ( "Demolitions Man" );
    } else if ( (pc == 5) ) {
        return ( "Combat Medic" );
    } else if ( (pc == 6) ) {
        return ( "Heavy Weapons Guy" );
    } else if ( (pc == 7) ) {
        return ( "Pyro" );
    } else if ( (pc == 8) ) {
        return ( "Spy" );
    } else if ( (pc == 9) ) {
        return ( "Engineer" );
    } else if ( (pc == 10) ) {
        return ( "Random Playerclass" );
    } else if ( (pc == 11) ) {
        if (( classtype & 64 )) {
            return ( "Quake Soldier" );
        } else {
            return ( "Civilian" );
        }
    } else if ( (pc == 13) ) {
        return ( "Sentry Gun" );
    } else if ( (pc == 14) ) {
        return ( "Goal Item" );
    } else if ( (pc == 0) ) {
        return ( "Observer" );
    }
    return ( "" );
}

void TeamFortress_PrintClassName (entity Viewer, float pc, float rpc) {
    string st;
    st = TeamFortress_GetClassName (pc);
    sprint (Viewer,PRINT_HIGH,st);
    if ( (rpc != 0) ) {
        sprint (Viewer,PRINT_HIGH," (Random)");
    }
    sprint (Viewer,PRINT_HIGH,"\n");
}

void TeamFortress_RemoveTimers () {
    entity te;
    self.leg_damage = 0;
    self.is_undercover = 0;
    self.is_building = 0;
    self.building = world;
    if ( (self.tfstate & 2048) ) {
        self.tfstate = (self.tfstate - 2048);
        TeamFortress_SetSpeed (self);
        self.heat = 0;
    }
    if ( (self.tfstate & 16) ) {
        self.tfstate = (self.tfstate - (self.tfstate & 16));
    }
    if ( (self.tfstate & 16384) ) {
        self.tfstate = (self.tfstate - (self.tfstate & 16384));
    }
    te = find (world,classname,"timer");
    while ( (te != world) ) {
        if ( ((te.owner == self) && (te.no_active_gas_grens <= 0)) ) {
            dremove (te);
            te = find (world,classname,"timer");
        } else {
            te = find (te,classname,"timer");
        }
    }
    te = find (world,classname,"grentimer");
    while ( (te != world) ) {
        if ( ((te.owner == self) && (te.no_active_napalm_grens <= 0)) ) {
            dremove (te);
            te = find (world,classname,"grentimer");
        } else {
            te = find (te,classname,"grentimer");
        }
    }
    te = find (world,classname,"item_tfgoal");
    while ( te ) {
        if ( (te.owner == self) ) {
            if ( (!(te.goal_activation & 256) || (self.has_disconnected == 1)) ) {
                tfgoalitem_RemoveFromPlayer (te,self,0);
            }
            if ( ((ctfmap == 1) && (te.goal_no == 1)) ) {
                bprint (PRINT_HIGH,self.netname);
                bprint (PRINT_HIGH," лост the блуе flag!\n");
            } else {
                if ( ((ctfmap == 1) && (te.goal_no == 2)) ) {
                    bprint (PRINT_HIGH,self.netname);
                    bprint (PRINT_HIGH," лост the ред flag!\n");
                }
            }
        }
        te = find (te,classname,"item_tfgoal");
    }
    te = find (world,classname,"detpack");
    while ( te ) {
        if ( ((te.weaponmode == 1) && (te.enemy == self)) ) {
            te.weaponmode = 0;
        }
        te = find (te,classname,"detpack");
    }
    TeamFortress_DetonatePipebombs ();
    if ( (self.has_disconnected == 1) ) {
        te = find (world,classname,"grenade");
        while ( te ) {
            if ( ((te.owner == self) && (te.model == "progs/caltrop.mdl")) ) {
                dremove (te);
                te = find (world,classname,"grenade");
            } else {
                te = find (te,classname,"grenade");
            }
        }
    }
    self.FlashTime = 0;
    self.item_list = 0;
    self.is_frozen = 0;
    stuffcmd (self, "v_idlescale 0\n");
    CenterPrint (self,"\n");
    if (!round_active) {
        self.menu_count = 25;
        self.current_menu = 1;
    }
    self.impulse = 0;
}

void TeamFortress_SetupRespawn () {
    float restime;
    string db;
    if ( (self.respawn_time > time) ) {
        return ;
    }
    if ( (toggleflags & 4) ) {
        restime = respawn_delay_time;
    } else {
        restime = 0;
    }
    if (!restime ) {
        self.respawn_time = 0;
    } else {
        self.respawn_time = (time + restime);
        if ( (restime > 3) ) {
            db = ftos (restime);
            sprint (self,PRINT_HIGH,db);
            sprint (self,PRINT_HIGH," seconds till respawn.\n");
        }
    }
}

void TeamFortress_CheckClassStats () {
    if ( (self.armortype > self.armor_allowed) ) {
        self.armortype = self.armor_allowed;
    }
    if ( (self.armorvalue > self.maxarmor) ) {
        self.armorvalue = self.maxarmor;
    }
    if ( (self.armortype < 0) ) {
        self.armortype = 0;
    }
    if ( (self.armorvalue < 0) ) {
        self.armorvalue = 0;
    }
    if ( (self.ammo_shells > TeamFortress_GetMaxAmmo (self,256)) ) {
        self.ammo_shells = TeamFortress_GetMaxAmmo (self,256);
    }
    if ( (self.ammo_shells < 0) ) {
        self.ammo_shells = 0;
    }
    if ( (self.ammo_nails > TeamFortress_GetMaxAmmo (self,512)) ) {
        self.ammo_nails = TeamFortress_GetMaxAmmo (self,512);
    }
    if ( (self.ammo_nails < 0) ) {
        self.ammo_nails = 0;
    }
    if ( (self.ammo_rockets > TeamFortress_GetMaxAmmo (self,1024)) ) {
        self.ammo_rockets = TeamFortress_GetMaxAmmo (self,1024);
    }
    if ( (self.ammo_rockets < 0) ) {
        self.ammo_rockets = 0;
    }
    if ( (self.ammo_cells > TeamFortress_GetMaxAmmo (self,2048)) ) {
        self.ammo_cells = TeamFortress_GetMaxAmmo (self,2048);
    }
    if ( (self.ammo_cells < 0) ) {
        self.ammo_cells = 0;
    }
    if ( (self.ammo_medikit > TeamFortress_GetMaxAmmo (self,4)) ) {
        self.ammo_medikit = TeamFortress_GetMaxAmmo (self,4);
    }
    if ( (self.ammo_medikit < 0) ) {
        self.ammo_medikit = 0;
    }
    if ( (self.ammo_detpack > TeamFortress_GetMaxAmmo (self,131072)) ) {
        self.ammo_detpack = TeamFortress_GetMaxAmmo (self,131072);
    }
    if ( (self.ammo_detpack < 0) ) {
        self.ammo_detpack = 0;
    }
    if ( (self.no_grenades_1 < 0) ) {
        self.no_grenades_1 = 0;
    }
    if ( (self.no_grenades_2 < 0) ) {
        self.no_grenades_2 = 0;
    }
    if ( ((self.health > self.max_health) && !(self.items & 65536)) ) {
        TF_T_Damage (self,world,world,(self.max_health - self.health),0,256);
    }
    if ( (self.health < 0) ) {
        T_Heal (self,(self.health - self.health),0);
    }
    self.items = (self.items - (self.items & ((8192 | 16384) | 32768)));
    if ( (self.armortype >= 0.800) ) {
        self.items = (self.items | 32768);
    } else {
        if ( (self.armortype >= 0.600) ) {
            self.items = (self.items | 16384);
        } else {
            if ( (self.armortype >= 0.300) ) {
                self.items = (self.items | 8192);
            }
        }
    }
}

void TeamFortress_AssaultWeapon () {
    self.impulse = 0;
    if ( (self.tfstate & 2) ) {
        return ;
    }
    if ( !(self.carried & 32768) ) {
        return ;
    }
    if ( (self.heat > 0) ) {
        sprint (self,PRINT_HIGH,"the assault cannon is still overheated.\n");
        return ;
    }
    if ( (self.ammo_shells < 1) ) {
        sprint (self,PRINT_HIGH,"not enough ammo.\n");
        return ;
    }
    if ( (self.ammo_cells < 6) ) {
        sprint (self,PRINT_HIGH,"not enough cells to power the assault cannon.\n");
        return ;
    }
    self.current = WEAP_ASSAULT_CANNON;
    W_SetCurrentAmmo ();
}

void TeamFortress_ExplodePerson (entity Gren) {
    Gren.owner.tfstate = (Gren.owner.tfstate - (Gren.owner.tfstate & 1));
    KickPlayer (-2,Gren.owner);
    newmis = spawn ();
    newmis.movetype = 10;
    newmis.solid = 2;
    newmis.classname = "grenade";
    newmis.pteam = Gren.owner.pteam;
    newmis.owner = Gren.owner;
    newmis.velocity = '0 0 0';
    newmis.angles = vectoangles (newmis.velocity);
    if (Gren.impulse == 150) {
        newmis.tp_grenades_1 = Gren.weapon;
    } else if (Gren.impulse == 151) {
        newmis.tp_grenades_2 = Gren.weapon;
    }
    newmis.think = SUB_Null;
    newmis.nextthink = (time + 0.100);
    if ( (Gren.weapon == 1) ) {
        newmis.touch = NormalGrenadeTouch;
        //newmis.volume = 2;
        newmis.think = NormalGrenadeExplode;
        newmis.skin = 0;
        newmis.avelocity = '300 300 300';
        setmodel (newmis,"progs/hgren2.mdl");
    } else {
        if ( (Gren.weapon == 2) ) {
            newmis.touch = ConcussionGrenadeTouch;
            newmis.think = ConcussionGrenadeExplode;
            newmis.skin = 1;
            newmis.avelocity = '300 300 300';
            setmodel (newmis,"progs/hgren2.mdl");
        } else {
            if ( (Gren.weapon == 3) ) {
                newmis.touch = NailGrenadeTouch;
                newmis.think = NailGrenadeExplode;
                newmis.skin = 1;
                newmis.avelocity = '0 300 0';
                setmodel (newmis,"progs/biggren.mdl");
            } else {
                if ( (Gren.weapon == 4) ) {
                    newmis.touch = MirvGrenadeTouch;
                    newmis.think = MirvGrenadeExplode;
                    newmis.skin = 0;
                    newmis.avelocity = '0 300 0';
                    setmodel (newmis,"progs/biggren.mdl");
                } else {
                    if ( (Gren.weapon == 5) ) {
                        newmis.touch = NapalmGrenadeTouch;
                        //if (grentype)
                        //   newmis.think = NapalmGrenadeExplode2;
                        //else
                        newmis.think = NapalmGrenadeExplode;
                        newmis.skin = 2;
                        newmis.avelocity = '0 300 0';
                        setmodel (newmis,"progs/biggren.mdl");
                    } else {
                        if ( (Gren.weapon == 6) ) {
                            newmis.touch = NormalGrenadeTouch;
                            newmis.think = FreezeGrenadeExplode;
                            newmis.skin = 1;
                            newmis.avelocity = '300 300 300';
                            setmodel (newmis,"progs/hgren2.mdl");
                        } else {
                            if ( (Gren.weapon == 7) ) {
                                newmis.touch = GasGrenadeTouch;
                                newmis.think = GasGrenadeExplode;
                                newmis.skin = 2;
                                newmis.avelocity = '300 300 300';
                                setmodel (newmis,"progs/grenade2.mdl");
                            } else {
                                if ( (Gren.weapon == 8) ) {
                                    newmis.touch = EMPGrenadeTouch;
                                    newmis.think = EMPGrenadeExplode;
                                    newmis.skin = 4;
                                    newmis.avelocity = '300 300 300';
                                    setmodel (newmis,"progs/grenade2.mdl");
                                } else {
                                    if ( (Gren.weapon == 10) ) {
                                        newmis.touch = CaltropTouch;
                                        newmis.think = ScatterCaltrops;
                                    } else {
                                        if ((Gren.weapon == 9)) {
                                            newmis.touch = FlashGrenadeTouch;
                                            newmis.think = FlashGrenadeExplode;
                                            newmis.skin = 2;
                                            newmis.avelocity = '300 300 300';
                                            setmodel (newmis, "progs/grenade2.mdl");
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,Gren.owner.origin);
    if ( ((Gren.owner.playerclass == 1) && (Gren.weapon != 10)) ) {
        bprint (PRINT_MEDIUM,"No ",Gren.owner.netname,", swallowing the grenade isn't very effective!\n");
    } else {
        if ( (Gren.owner.playerclass == 2) ) {
            bprint (PRINT_MEDIUM,"Well ",Gren.owner.netname,", don't quit your day job!\n");
        } else {
            if ( (Gren.owner.playerclass == 3) ) {
                bprint (PRINT_MEDIUM,"Ummm, ",Gren.owner.netname,", you're supposed to THROW the grenade!\n");
            } else {
                if ( (Gren.owner.playerclass == 4) ) {
                    bprint (PRINT_MEDIUM,"Ack! ",Gren.owner.netname,"! The grenade is your friend for another reason!\n");
                } else {
                    if ( (Gren.owner.playerclass == 5) ) {
                        bprint (PRINT_MEDIUM,"No ",Gren.owner.netname,"! Assist your own suicide some other time!\n");
                    } else {
                        if ( (Gren.owner.playerclass == 6) ) {
                            bprint (PRINT_MEDIUM,"Hey ",Gren.owner.netname,", you're not THAT heavy!\n");
                        } else {
                            if ( (Gren.owner.playerclass == 7) ) {
                                bprint (PRINT_MEDIUM,"Yes ",Gren.owner.netname,", the grenade does explode on '3'!\n");
                            } else {
                                if ( (Gren.owner.playerclass == 8) ) {
                                    bprint (PRINT_MEDIUM,"You do realize ",Gren.owner.netname,", you can blow your cover in easier ways!\n");
                                } else {
                                    if ( (Gren.owner.playerclass == 9) ) {
                                        bprint (PRINT_MEDIUM,"Hey ",Gren.owner.netname,", study grenade dynamics on your own time!\n");
                                    } else {
                                        bprint (PRINT_MEDIUM,"No ",Gren.owner.netname,", throw the grenade, not the pin!\n");
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    dremove (Gren);
}

void NormalGrenadeTouch () {
    if ( (other == self.owner) ) {
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void NormalGrenadeExplode () {
    deathmsg = 8;
    T_RadiusDamage (self,self.owner,180,world);
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    dremove (self);
}

void TeamFortress_DisplayDetectionItems () {
    entity Goal;
    entity te;
    if (!self.playerclass) return;
    Goal = find (world,classname,"info_tfdetect");
    if ( !Goal ) {
        return ;
    }
    if ( (Goal.display_item_status1) ) {
        te = Finditem (Goal.display_item_status1);
        if ( te ) {
            sprint (self,PRINT_HIGH, ItemStatus (Goal,self,te));
        } else {
            sprint (self,PRINT_HIGH,"Item is missing.\n");
        }
    } else {
        sprint (self,PRINT_HIGH,"\n");
        return ;
    }
    if ( (Goal.display_item_status2) ) {
        te = Finditem (Goal.display_item_status2);
        if ( te ) {
            sprint (self,PRINT_HIGH, ItemStatus (Goal,self,te));
        } else {
            sprint (self,PRINT_HIGH,"Item is missing.\n");
        }
    } else {
        sprint (self,PRINT_HIGH,"\n");
        return ;
    }
    if ( (Goal.display_item_status3) ) {
        te = Finditem (Goal.display_item_status3);
        if ( te ) {
            sprint (self,PRINT_HIGH, ItemStatus (Goal,self,te));
        } else {
            sprint (self,PRINT_HIGH,"Item is missing.\n");
        }
    } else {
        sprint (self,PRINT_HIGH,"\n");
        return ;
    }
    if ( (Goal.display_item_status4) ) {
        te = Finditem (Goal.display_item_status4);
        if ( te ) {
            sprint (self,PRINT_HIGH, ItemStatus (Goal,self,te));
        } else {
            sprint (self,PRINT_HIGH,"Item is missing.\n");
        }
    }
}

void BioInfection_Decay () {
    entity te;
    entity Bio;
    if ( (((teamplay & 16) && (self.owner.pteam == self.enemy.pteam)) && (self.owner.pteam.team != 0)) ) {
        self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 16));
        dremove (self);
        return ;
    } else {
        if ( (self.invincible_finished > time) ) {
            self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 16));
            dremove (self);
            return ;
        }
    }
    if ( (!(self.owner.tfstate & 16) || (self.owner.playerclass == 5)) ) {
        dremove (self);
        return ;
    }
    te = findradius (self.owner.origin,80);
    while ( ((te != world) && (te != self.owner)) ) {
        if ( (((te.classname == "player") && (te.deadflag == 0)) && (te.playerclass)) ) {
            if ( !(te.tfstate & 16) ) {
                if ( (te.playerclass != 5) ) {
                    if ( !(((teamplay & 16) && (self.owner.pteam == self.enemy.pteam)) && (self.owner.pteam.team != 0)) ) {
                        Bio = spawn ();
                        Bio.nextthink = 2;
                        Bio.think = BioInfection_Decay;
                        Bio.owner = te;
                        Bio.classname = "timer";
                        Bio.enemy = self.enemy;
                        te.tfstate = (te.tfstate | 16);
                        te.infection_team_no = self.owner.infection_team_no;
                        sprint (te,PRINT_MEDIUM,"You have been infected by ");
                        sprint (te,PRINT_MEDIUM,self.owner.netname);
                        sprint (te,PRINT_MEDIUM,"!\n");
                        sprint (self.owner,PRINT_MEDIUM,"You have infected ");
                        sprint (self.owner,PRINT_MEDIUM,te.netname);
                        sprint (self.owner,PRINT_MEDIUM,"!\n");
                    }
                }
            }
        }
        te = te.chain;
    }
    self.nextthink = (time + 3);
    deathmsg = 13;
    TF_T_Damage (self.owner,self,self.enemy,8,1,0);
    SpawnBlood (self.owner.origin,30);
}

void TeamFortress_Alias (string halias, float himpulse1, float himpulse2) {
    string imp;
    stuffcmd (self,"alias ");
    stuffcmd (self,halias);
    stuffcmd (self," \"impulse ");
    imp = ftos (himpulse1);
    stuffcmd (self,imp);
    if ( (himpulse2 != 0) ) {
        stuffcmd (self,";wait; impulse ");
        imp = ftos (himpulse2);
        stuffcmd (self,imp);
    }
    stuffcmd (self,"\"\n");
}

void TeamFortress_Regenerate () {
    float value;
    if (modetype & 256)
        value = 2;
    else
        value = 4;
    if ( (self.owner.playerclass == 5) ) {
        self.nextthink = (time + 3);
        if ( (self.owner.has_disconnected == 1) ) {
            dremove (self);
            return ;
        }
        if ( (self.owner.health >= self.owner.max_health) ) {
            return ;
        }
        if ( (self.owner.ammo_medikit == 0) ) {
            return ;
        }
        if ( (self.owner.ammo_medikit < value) ) {
            self.owner.health = (self.owner.health + self.owner.ammo_medikit);
            self.owner.ammo_medikit = 0;
        } else {
            self.owner.health = (self.owner.health + value);
            self.owner.ammo_medikit = (self.owner.ammo_medikit - value);
        }
        if ( (self.owner.health > self.owner.max_health) ) {
            self.owner.health = self.owner.max_health;
        }
    }
}

float crossproduct (vector veca, vector vecb) {
    float result;
    result = ((veca_x * vecb_y) - (vecb_x * veca_y));
    return ( result );
}

void TF_AddFrags (entity pl, float fr, float type) {
    entity e;
    if ( ((intermission_running != 0) || (intermission_exittime > time)) ) {
        return ;
    }
    if (type == 1) {
        pl.real_frags = (pl.real_frags + fr);
    }
    if ( !pl.pteam.team ) {
        return ;
    }
    if ( (toggleflags & 2048) ) {
        pl.pteam.frags = (pl.pteam.frags + fr);
    }
    pl.pteam.real_frags = (pl.pteam.real_frags + fr);
    if ( (toggleflags & 2048) ) {
        e = player_head;
        while ( e ) {
            if ( (e.pteam == pl.pteam) ) {
                e.frags = e.pteam.frags;
            }
            e = e.nextp;
        }
    } else {
        if ( !(toggleflags & 128) ) {
            pl.frags = pl.frags + fr;
        }
    }
}

void TeamFortress_ExecClassScript (entity p) {
    string st;
    st = infokey (p,"ec");
    if ( (st == string_null) ) {
        st = infokey (p,"exec_class");
    }
	if ( (st == "on") || (self.tfkey & 2) ) {
		if ( (p.playerclass == CLASS_SCOUT) ) {
			stuffcmd (p,"exec scout.cfg\n");
		} else if ( (p.playerclass == CLASS_SNIPER) ) {
			stuffcmd (p,"exec sniper.cfg\n");
		} else if ( (p.playerclass == CLASS_SOLDIER) ) {
			stuffcmd (p,"exec soldier.cfg\n");
		} else if ( (p.playerclass == CLASS_DEMOMAN) ) {
			stuffcmd (p,"exec demoman.cfg\n");
		} else if ( (p.playerclass == CLASS_MEDIC) ) {
			stuffcmd (p,"exec medic.cfg\n");
		} else if ( (p.playerclass == CLASS_HWGUY) ) {
			stuffcmd (p,"exec hwguy.cfg\n");
		} else if ( (p.playerclass == CLASS_PYRO) ) {
			stuffcmd (p,"exec pyro.cfg\n");
		} else if ( (p.playerclass == CLASS_SPY) ) {
			stuffcmd (p,"exec spy.cfg\n");
		} else if ( (p.playerclass == CLASS_ENGINEER) ) {
			stuffcmd (p,"exec engineer.cfg\n");
		} else if ( (p.playerclass == CLASS_CIVILIAN) ) {
			stuffcmd (p,"exec dm.cfg\n");
		}
	}
}

void TeamFortress_ExecMapScript (entity p) {
    string st;
    st = infokey (p,"em");
    if ( (st == string_null) ) {
        st = infokey (p,"exec_map");
    }
    if ( (st == "on") || (self.tfkey & 4) ) {
        stuffcmd (p,"exec mapdefault.cfg\n");
        stuffcmd (p,"exec ");
        stuffcmd (p,mapname);
        stuffcmd (p,".cfg\n");
    }
}
