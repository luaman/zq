/*
    engineer.qc

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

void Rail_Touch ();

void EMPExplode ();

void EMPGrenadeTouch ();

void EMPGrenadeExplode ();

void TeamFortress_FinishedBuilding ();

void TeamFortress_ExplodePerson (entity Gren);

void Dispenser_Die ();

void CheckDistance ();
float CheckArea (entity obj, entity builder);

void T_Dispenser ();

void Rail_Think () {
    self.solid = 1;
    self.movetype = 9;
    self.velocity = self.oldorigin;
    self.touch = Rail_Touch;
    setmodel (self,"progs/e_spike2.mdl");
    self.nextthink = (time + 1);
    self.think = SUB_Remove;
}

void Rail_Touch () {
    vector org;
    if ( (other == self.owner) ) {
        return ;
    }
    if ( ((other == self.enemy) && (self.enemy != world)) ) {
        return ;
    }
    if ( (pointcontents (self.origin) == -6) ) {
        dremove (self);
        return ;
    }
    org = (self.origin - (8 * normalize (self.velocity)));
    if ( other.health ) {
        SpawnBlood (org,15);
        deathmsg = 26;
        TF_T_Damage (other,self,self.enemy, self.heat ,2,8);
        self.velocity = self.oldorigin;
        self.owner = other;
        setmodel (self,string_null);
        self.touch = SUB_Null;
        self.nextthink = (time + 0.100);
        self.think = Rail_Think;
        return ;
    } else {
        WriteByte (4,23);
        WriteByte (4,0);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
    }
    dremove (self);
}

void W_FireRail () {
    vector vec;
    vector org;
    float heattime;
    if (!modetype & 2) {
        self.ammo_nails = (self.ammo_nails - 1);
        self.currentammo = self.ammo_nails;
    }
    makevectors (self.v_angle);
    org = (self.origin + (v_forward * 8));
    vec = aim (self,10000);
    vec = normalize (vec);
    newmis = spawn ();
    newmis.owner = self;
    newmis.enemy = self;
    newmis.movetype = 9;
    newmis.solid = 1;
    setmodel (newmis,"progs/e_spike1.mdl");
    //setmodel (newmis, "progs/w_spike.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,(org + '0 0 16'));
    newmis.velocity = (vec * 1500);
    newmis.angles = vectoangles (newmis.velocity);
    newmis.oldorigin = newmis.velocity;
    newmis.nextthink = (time + 5);
    newmis.think = SUB_Remove;
    if (classtype & 32) {
        heattime = time - self.heat;
        newmis.heat = (heattime * (20 * 3)) + 20;
        if (newmis.heat > 200) newmis.heat = 200;
    } else {
        newmis.heat = 25;
    }
    newmis.touch = Rail_Touch;
}

void W_FireRailgun () {
    float num;
    vector org;
    float damg;
    if ( (self.ammo_nails < 1) ) {
        self.last = self.current;
        self.current = W_BestWeapon ();
        W_SetCurrentAmmo ();
        W_PrintWeaponMessage ();
        return ;
    }
    num = EntityNum (self);
    if (classtype & 32) {
        damg = time - self.heat;
        damg = (damg * (20 * 3)) + 20;
        if (damg > 200) damg = 200;
    } else {
        damg = 25;
    }
    KickPlayer (-2,self);
    if (!modetype & 2) {
        self.ammo_nails = (self.ammo_nails - 1);
        self.currentammo = self.ammo_nails;
        if (allow_stamina)
            self.stamina = self.stamina - 40;
    }
    org = (self.origin + '0 0 16');
    traceline (org,(org + (v_forward * 850)),1,self);
    WriteByte (4, 23);
    WriteByte (4, 5);
    WriteShort (4, -1 - num); // because player entity numbers are 1 based
    WriteCoord (4, org_x);
    WriteCoord (4, org_y);
    WriteCoord (4, org_z);
    WriteCoord (4, trace_endpos_x);
    WriteCoord (4, trace_endpos_y);
    WriteCoord (4, trace_endpos_z);
    multicast (org, 1);
    LightningDamage (self.origin,(trace_endpos + (v_forward * 4)),self, damg);
}

void EMPExplode () {
    float expsize;
    expsize = 10;
    if ( (self.touch == weapon_touch) ) {
        expsize = 60;
    } else {
        if ( (self.classname == "item_shells") ) {
            expsize = (50 + self.aflag);
        } else {
            if ( (self.classname == "item_spikes") ) {
                expsize = 40;
            } else {
                if ( (self.classname == "item_rockets") ) {
                    expsize = (100 + (self.aflag * 4));
                } else {
                    if ( (self.classname == "item_cells") ) {
                        expsize = (60 + (self.aflag * 3));
                    } else {
                        if ( (self.classname == "item_weapon") ) {
                            expsize = 60;
                        } else {
                            dprint ("EMPExplode: Attempting to explode a ");
                            dprint (self.classname);
                            dprint ("\n");
                            return ;
                        }
                    }
                }
            }
        }
    }
    deathmsg = 31;
    T_RadiusDamage (self,self.enemy,expsize,world);
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    Respawn_Item (self,self.enemy);
}

void EMPGrenadeTouch () {
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void EMPGrenadeExplode () {
    float expsize;
    entity te;
    entity oldself;
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
    WriteByte (4,23);
    WriteByte (4,4);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    te = findradius (self.origin,240);
    while ( te ) {
        te.chain2 = te.chain;
        if ( (te.classname != "item_spikes") ) {
            if ( ((te.touch == ammo_touch) || (te.touch == weapon_touch)) ) {
                te.solid = 0;
                te.enemy = self.owner;
                te.nextthink = (time + (random () * 0.800));
                te.think = EMPExplode;
            } else if ( ((te.classname == "player") || (te.touch == BackpackTouch)) ) {
                if ( !(((teamplay & 16) && (te.pteam.team > 0)) && (te.pteam == self.owner.pteam)) ) {
                    expsize = 0;
                    expsize = (expsize + (te.ammo_shells * 0.750));
                    expsize = (expsize + ((te.ammo_rockets * 0.750) * 2));
                    if ( (te.playerclass != 9) ) {
                        expsize = (expsize + (te.ammo_cells * 0.750));

                    }
                    if ( (expsize > 0) ) {
                        deathmsg = 30;
                        T_RadiusDamage (te,self.owner,expsize,te);
                        if ( (te.touch != BackpackTouch) ) {
                            TF_T_Damage (te,self,self.owner,expsize,2,4);
                            if (!modetype & 2) {
                                te.ammo_shells = ceil ((te.ammo_shells * 0.250));
                                te.ammo_rockets = ceil ((te.ammo_rockets * 0.250));
                            }
                            if ( (te.playerclass != 9) ) {
                                if (!modetype & 2) {
                                    te.ammo_cells = ceil ((te.ammo_cells * 0.250));
                                }
                            }
                            oldself = self;
                            self = te;
                            W_SetCurrentAmmo ();
                            self = oldself;
                        } else {
                            te.think = SUB_Remove;
                            te.nextthink = (time + 0.100);
                        }
                        WriteByte (4,23);
                        WriteByte (4,3);
                        WriteCoord (4,te.origin_x);
                        WriteCoord (4,te.origin_y);
                        WriteCoord (4,te.origin_z);
                        multicast (te.origin,1);
                    }

                }
            } else if ((te.classname == "pipebomb")) {
                te.nextthink = time + (random() * 0.400);
            } else if (grenradius & 4) {
                if ((te.classname == "grenade") || (te.classname == "rocket") ) {
                    te.nextthink = time;
                }
            } else if ( ((te.classname == "building_dispenser") || (te.classname == "building_sentrygun")) ) {
                if ( !(((teamplay & 16) && (te.pteam.team > 0)) && (te.pteam == self.owner.pteam)) ) {
                    TF_T_Damage (te,self,self.owner,200,0,4);
                }
            } else if ( (te.classname == "ammobox") ) {
                expsize = 0;
                expsize = (expsize + (te.ammo_shells * 0.750));
                expsize = (expsize + ((te.ammo_rockets * 0.750) * 2));
                expsize = (expsize + ((te.ammo_cells * 0.750) * 2));
                if ( (expsize > 0) ) {
                    te.solid = 0;
                    deathmsg = 30;
                    T_RadiusDamage (te,self.owner,expsize,te);
                    te.think = SUB_Remove;
                    te.nextthink = (time + 0.100);
                    WriteByte (4,23);
                    WriteByte (4,3);
                    WriteCoord (4,te.origin_x);
                    WriteCoord (4,te.origin_y);
                    WriteCoord (4,te.origin_z);
                    multicast (te.origin,1);
                }
            } else if (!modetype & 4) {
                if ((te.think == TeamFortress_DetpackExplode) ) {
                    te.solid = 0;
                    te.nextthink = (time + (random () * 2));
                    dremove (te.oldenemy);
                }
            }
        }
        te = te.chain2;
        //te = te.chain;
    }
    dremove (self);
}

void nobuild_touch () {
    if (other.classname != "player") return;
    if (other.playerclass == 9) {
        if (other.current_menu == 15) {
            sprint (other, PRINT_HIGH, "You can't build in this area.\n");
            CenterPrint (other,"\n");
            other.menu_count = 25;
            other.current_menu = 1;

        }
    }
}

void TeamFortress_EngineerBuild () {
    entity te;
    if ( !(self.flags & 512) ) {
        CenterPrint (self,"You can't build in the air!\n\n");
        return ;
    }
    if ( (self.is_building == 0) ) {
        if ( (((self.ammo_cells < 100) && !self.has_dispenser) && !self.has_sentry) ) {
            CenterPrint (self,"You don't have enough metal to \nbuild anything.\n\n");
            return ;
        }
        self.current_menu = 15;
        self.menu_count = 25;
    } else {
        if ( (self.is_building == 1) ) {
            sprint (self,PRINT_HIGH,"You stop building.\n");
            self.tfstate = (self.tfstate - (self.tfstate & 65536));
            TeamFortress_SetSpeed (self);
            te = find (world,netname,"build_timer");
            while ( te ) {
                if ( (te.owner == self) ) {
                    dremove (te);
                    te = world;
                } else {
                    te = find (te,netname,"build_timer");
                }
            }
            self.is_building = 0;
            self.current = self.weapon;
            W_SetCurrentAmmo ();
        }
    }
}

void T_Antispam () {
    if ( (other.classname != "player") ) {
        return ;
    }
    if (!other.pteam.team)  {
        return;
    }
    if ( ((other.pteam.team != 0) && (other.pteam != self.pteam)) ) {
        centerprint (self.real_owner,"Enemies are touching your Anti-Spam device!\n");
    }
    centerprint(other, "Current Health: ");
    centerprint(other, ftos(self.health));
    centerprint(other, "\n");

}

void AntiSpamDie ();
float CheckArea (entity obj, entity builder) {
    vector src;
    vector end;
    float pos;
    entity te;
    pos = pointcontents (obj.origin);
    if ( ((pos == -2) || (pos == -6)) ) {
        return ( 0 );
    }
    src_x = ((obj.origin_x + obj.maxs_x) + 24);
    src_y = ((obj.origin_y + obj.maxs_y) + 24);
    src_z = ((obj.origin_z + obj.maxs_z) + 16);
    pos = pointcontents (src);
    if ( ((pos == -2) || (pos == -6)) ) {
        return ( 0 );
    }
    end_x = ((obj.origin_x + obj.mins_x) - 16);
    end_y = ((obj.origin_y + obj.mins_y) - 16);
    end_z = ((obj.origin_z + obj.mins_z) - 16);
    traceline (src,end,1,obj);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    pos = pointcontents (end);
    if ( ((pos == -2) || (pos == -6)) ) {
        return ( 0 );
    }
    src_x = ((obj.origin_x + obj.mins_x) - 16);
    src_y = ((obj.origin_y + obj.maxs_y) + 16);
    src_z = ((obj.origin_z + obj.maxs_z) + 16);
    pos = pointcontents (src);
    if ( ((pos == -2) || (pos == -6)) ) {
        return ( 0 );
    }
    end_x = ((obj.origin_x + obj.maxs_x) + 16);
    end_y = ((obj.origin_y + obj.mins_y) - 16);
    end_z = ((obj.origin_z + obj.mins_z) - 16);
    traceline (src,end,1,obj);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    pos = pointcontents (end);
    if ( ((pos == -2) || (pos == -6)) ) {
        return ( 0 );
    }
    traceline (builder.origin,obj.origin,1,builder);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    te = findradius (obj.origin,64);
    if ( (te != world) ) {
        return ( 0 );
    }
    return ( 1 );
}

void TeamFortress_Build (float objtobuild) {
    float btime;
    entity te;
    vector tmp1;
    vector tmp2;
    string st;
    float maxblds;
    float nomisc;
    newmis = spawn ();
    makevectors (self.v_angle);
    v_forward_z = 0;
    v_forward = (normalize (v_forward) * 64);
    newmis.origin = (self.origin + v_forward);
    if ( (CheckArea (newmis,self) == 0) ) {
        sprint (self,PRINT_HIGH,"Not enough room to build here\n");
        dremove (newmis);
        return ;
    }
    if ( (objtobuild == 1) ) {
        if ( self.has_dispenser ) {
            sprint (self,PRINT_HIGH,"You can only have one dispenser.\nTry dismantling your old one.\n");
            return ;
        }
        tmp1 = '-16 -16 0';
        tmp2 = '16 16 48';
        newmis.mdl = "progs/disp.mdl";
        newmis.netname = "dispenser";
        btime = (time + 2);
    } else {
        if ( (objtobuild == 2) ) {
            if ( self.has_sentry ) {
                sprint (self,PRINT_HIGH,"You can only have one sentry gun.\nTry dismantling your old one.\n");
                return ;
            }
            st = infokey (world,"max_teamsgs");

            maxblds = stof(st);
            if (maxblds == -1) {
                sprint (self,PRINT_HIGH,"You cannot have sentry guns on your team.\nDisabled by Administrator.\n");
                return ;
            }
            if (maxblds > 0) {

                te = find (world,classname,"building_sentry");
                while ( te != world) {
                    if (te.pteam == self.pteam) {
                        nomisc = nomisc + 1;
                    }
                    te = find (te,classname,"building_sentry");
                }
                if ( nomisc >= maxblds) {
                    sprint (self,PRINT_HIGH,"You can only have ", st, " sentry guns on your team.\n");
                    return ;
                }
            }
            tmp1 = '-16 -16 0';
            tmp2 = '16 16 48';
            newmis.mdl = "progs/turrbase.mdl";
            newmis.netname = "sentrygun";
            btime = (time + 5);
        } else {

            if (objtobuild == 3) {
                te = find (world,classname,"info_player_teamspawn");
                while ( te ) {
                    if ( (vlen (te.origin - self.origin) <= 300) ) {
                        btime = 1;
                        //break;
                    }
                    te = find (te,classname,"info_player_teamspawn");
                }
                if ( !btime) {
                    sprint (self,PRINT_HIGH,"You must build the Anti-Spam device within 300 units of your team-spawn\n");
                    return ;
                }
                if (maxblds > 0) {

                    te = find (world,classname,"building_antispam");
                    while ( te != world) {
                        if (te.pteam == self.pteam) {
                            nomisc = nomisc + 1;
                        }
                        te = find (te,classname,"building_antispam");
                    }
                    if ( nomisc >= 2) {
                        sprint (self,PRINT_HIGH,"You can only have two anti spam devices on your team.\n");
                        return ;
                    }
                }
                tmp1 = '-16 -16 0';
                tmp2 = '16 16 48';
                newmis.mdl = "progs/turrbase.mdl";
                newmis.netname = "antispam";
                btime = (time + 8);
            }
        }
    }
    if ( !(self.flags & 512) ) {
        CenterPrint (self,"You can't build in the air!\n\n");
        return ;
    }
    self.is_building = 1;
    //self.immune_to_check = (time + 5);
    self.tfstate = (self.tfstate | 65536);
    self.weapon = self.current;
    self.current = 0;
    self.weaponmodel = "";
    self.weaponframe = 0;
    TeamFortress_SetSpeed (self);
    newmis.owner = self;
    newmis.classname = "timer";
    newmis.netname = "build_timer";
    newmis.nextthink = btime;
    newmis.think = TeamFortress_FinishedBuilding;
    newmis.colormap = self.colormap;
    newmis.weapon = objtobuild;
    newmis.angles_y = anglemod ((self.angles_y + 180));
    newmis.velocity = '0 0 8';
    newmis.movetype = 6;
    newmis.solid = 2;
    setmodel (newmis,newmis.mdl);
    setsize (newmis,tmp1,tmp2);
    setorigin (newmis,newmis.origin);
    newmis.flags = (newmis.flags - (newmis.flags & 512));
}

void CheckBelowBuilding (entity bld) {
    vector below;
    below = bld.origin;
    if ( (bld.classname == "detpack") ) {
        below_z = (below_z - 8);
    } else {
        below_z = (below_z - 24);
    }
    traceline (bld.origin,below,1,bld);
    if ( (trace_fraction == 1) ) {
        bld.movetype = 6;
        bld.flags = (bld.flags - (bld.flags & 512));
    }
}

void DispenserThink () {
    CheckBelowBuilding (self);
    if ( (self.hook_out > 3) ) {
        self.ammo_shells = (self.ammo_shells + rint ((400 / 20)));
        self.ammo_cells = (self.ammo_cells + rint ((400 / 20)));
        self.ammo_nails = (self.ammo_nails + rint ((600 / 20)));
        self.ammo_rockets = (self.ammo_rockets + rint ((300 / 20)));
        self.armorvalue = (self.armorvalue + rint ((500 / 20)));
        if ( (self.ammo_shells > 400) ) {
            self.ammo_shells = 400;
        }
        if ( (self.ammo_nails > 600) ) {
            self.ammo_nails = 600;
        }
        if ( (self.ammo_rockets > 300) ) {
            self.ammo_rockets = 300;
        }
        if ( (self.ammo_cells > 400) ) {
            self.ammo_cells = 400;
        }
        if ( (self.armorvalue > 500) ) {
            self.armorvalue = 500;
        }
        self.hook_out = 0;
    }
    self.hook_out = (self.hook_out + 1);
    self.nextthink = (time + 3);
}

void TeamFortress_FinishedBuilding () {
    entity oldself;
    if ( (self.owner.is_building != 1) ) {
        return ;
    }
    oldself = self;
    self = self.owner;
    oldself.owner = world;
    oldself.real_owner = self;
    self.is_building = 0;
    self.tfstate = (self.tfstate - (self.tfstate & 65536));
    self.current = self.weapon;
    self.StatusRefreshTime = (time + 0.100);
    TeamFortress_SetSpeed (self);
    if ( (oldself.weapon == 1) ) {
        self.has_dispenser = 1;
        sprint (self,PRINT_HIGH,"You finish building the dispenser.\n");
        teamsprint (self.pteam.team,self,self.netname);
        teamsprint (self.pteam.team,self," has built a Dispenser.\n");

        if (!modetype & 2) {
            self.ammo_cells = (self.ammo_cells - 100);
        }
        oldself.classname = "building_dispenser";
        oldself.killtarget = "building";
        oldself.netname = "dispenser";
        oldself.blocked = T_Dispenser;
        oldself.touch = T_Dispenser;
        oldself.max_health = 150;
        oldself.health = 150;
        oldself.hook_out = 1;
        oldself.think = DispenserThink;
        oldself.nextthink = (time + 3);
        oldself.th_die = Dispenser_Die;
        oldself.mdl = "progs/disp.mdl";
        oldself.pteam = self.pteam;
        oldself.real_owner = self;
        oldself.colormap = self.colormap;
        oldself.takedamage = 2;
        oldself.owner = world;
        oldself.movetype = 6;
        oldself.velocity = '0 0 8';
        oldself.flags = (oldself.flags - (oldself.flags & 512));
        oldself.ammo_shells = ceil ((self.ammo_shells * 0.250));
        oldself.ammo_nails = ceil ((self.ammo_nails * 0.250));
        oldself.ammo_rockets = ceil ((self.ammo_rockets * 0.250));
        oldself.ammo_cells = ceil ((self.ammo_cells * 0.250));
        oldself.armorvalue = ceil ((self.armorvalue * 0.250));
        self.ammo_shells = ceil ((self.ammo_shells * 0.750));
        self.ammo_nails = ceil ((self.ammo_nails * 0.750));
        self.ammo_rockets = ceil ((self.ammo_rockets * 0.750));
        self.ammo_cells = ceil ((self.ammo_cells * 0.750));
        self.armorvalue = ceil ((self.armorvalue * 0.750));
        oldself.solid = 2;
        setmodel (oldself,oldself.mdl);
        setsize (oldself,'-8 -8 0','8 8 24');
        setorigin (oldself,(oldself.origin + '0 0 8'));
    } else {
        if ((oldself.weapon == 2)) {
            self.has_sentry = 1;
            sprint (self,PRINT_HIGH, "You finish building the sentry gun.\n");
            teamsprint (self.pteam.team, self, self.netname);
            teamsprint (self.pteam.team, self, " has built a Sentry Gun.\n");
            oldself.classname = "building_sentrygun_base";
            oldself.netname = "sentry gun";
            oldself.takedamage = 0;
            oldself.th_die = Sentry_Die;
            oldself.pteam = self.pteam;
            if (!modetype & 2) {
                self.ammo_cells = (self.ammo_cells - 130);
            }
            setsize (oldself, '-16 -16 0', '16 16 4');
            newmis = spawn ();
            newmis.classname = "building_sentrygun";
            newmis.killtarget = "building";
            newmis.health = 150;
            newmis.max_health = newmis.health;
            newmis.weapon = 1;
            newmis.th_die = Sentry_Die;
            newmis.th_pain = Sentry_Pain;
            newmis.mdl = "progs/turrgun.mdl";
            sound (oldself, 3, "weapons/turrset.wav", 1, 1);
            newmis.solid = 2;
            setmodel (newmis, newmis.mdl);
            setsize (newmis, '-16 -16 0', '16 16 48');
            setorigin (newmis, (oldself.origin + '0 0 8'));
            newmis.view_ofs = '0 0 22';
            newmis.real_owner = oldself.real_owner;
            newmis.trigger_field = oldself;
            oldself.oldenemy = newmis;
            newmis.movetype = 4;
            oldself.colormap = self.colormap;
            newmis.colormap = self.colormap;
            newmis.takedamage = 2;
            newmis.velocity = '0 0 -8';
            newmis.flags = (newmis.flags - (newmis.flags & 512));
            oldself.flags = (oldself.flags - (oldself.flags & 512));
            newmis.pteam = self.pteam;
            //newmis.think = lvl1_sentry_stand;
            if (sgtype) {
                newmis.think = lvl1_sentry_stand;
                newmis.yaw_speed = 15 - (sentry_speed * 35);
            } else {
                newmis.think = lvl1_oldsentry_stand;
                newmis.yaw_speed = 10;
            }
            newmis.nextthink = (time + 0.5);
            //newmis.yaw_speed = 10;
            newmis.heat = 0;
            newmis.angles_x = 0;
            newmis.angles_y = rint (oldself.angles_y);
            newmis.angles_z = 0;
            newmis.waitmin = rint ((newmis.angles_y - 50));
            newmis.waitmin = anglemod (newmis.waitmin);
            newmis.waitmax = rint ((newmis.angles_y + 50));
            newmis.waitmax = anglemod (newmis.waitmax);
            if ((newmis.waitmin > newmis.waitmax)) {
                newmis.waitmin = newmis.waitmax;
                newmis.waitmax = anglemod ((newmis.angles_y - 50));
            }
            newmis.ammo_shells = 25;
            newmis.maxammo_shells = 100;
            newmis.maxammo_rockets = 20;

        } else {
            if ( (oldself.weapon == 3) ) {
                sprint (self,PRINT_HIGH,"You finish building the anti-spam Device.\n");
                teamsprint (self.pteam.team,self,self.netname);
                teamsprint (self.pteam.team,self," has built a Anti-Spam Device.\n");

                if (!modetype & 2) {
                    self.ammo_cells = (self.ammo_cells - 180);
                }
                oldself.classname = "building_antispam";
                oldself.killtarget = "building";
                oldself.netname = "antispam";
                oldself.blocked = T_Antispam;
                oldself.touch = T_Antispam;
                oldself.max_health = 400;
                oldself.health = 400;
                oldself.hook_out = 1;
                //oldself.think = AntiThink;
                //oldself.nextthink = (time + 3);
                oldself.th_die = AntiSpamDie;
                //oldself.mdl = "progs/disp.mdl";
                oldself.pteam = self.pteam;
                oldself.real_owner = self;
                oldself.colormap = self.colormap;
                oldself.takedamage = 2;
                oldself.owner = world;
                oldself.movetype = 6;
                oldself.velocity = '0 0 8';
                oldself.flags = (oldself.flags - (oldself.flags & 512));
            }
        }
    }
    W_SetCurrentAmmo ();
    self = oldself;
}

void T_Dispenser () {
    entity dist_checker;
    if ( (other.classname != "player") ) {
        return ;
    }
    if (!other.pteam.team)  {
        return;
    }
    if ( ((other.pteam.team != 0) && (other.pteam != self.pteam)) ) {
        centerprint (self.real_owner,"Enemies are using your dispenser!\n");
    }
    if ( ((other.building == world) && (other.building_wait < time)) ) {
        other.current_menu = 19;
        other.menu_count = 25;
        other.building = self;
        dist_checker = spawn ();
        dist_checker.classname = "timer";
        dist_checker.owner = other;
        dist_checker.enemy = self;
        dist_checker.think = CheckDistance;
        dist_checker.nextthink = (time + 0.300);
    }
}

void Dispenser_Explode () {
    float sdmg;
    if ( (self.real_owner.has_disconnected != 1) ) {
        deathmsg = 39;
        sdmg = ((25 + (self.ammo_rockets * 1.500)) + self.ammo_cells);
        if ( (sdmg > 250) ) {
            sdmg = 250;
        }
        T_RadiusDamage (self,self.real_owner,sdmg,self);
    }
    //ThrowGib ("progs/dgib1.mdl",-30);
    //ThrowGib ("progs/dgib2.mdl",-50);
    //ThrowGib ("progs/dgib3.mdl",-50);
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    dremove(self);
}

void Dispenser_Die () {
    self.real_owner.has_dispenser = 0;
    self.think = Dispenser_Explode;
    self.nextthink = (time + 0.100);
}

void AntiSpamDie () {
    self.think = Dispenser_Explode;
    self.nextthink = (time + 0.100);
}

void Engineer_UseDispenser (entity disp) {
    entity dist_checker;
    string st;
    sprint (self,PRINT_HIGH,"Dispenser has ");
    st = ftos (disp.health);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," health\n");
    st = ftos (disp.ammo_shells);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," shells, ");
    st = ftos (disp.ammo_nails);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," nails,");
    st = ftos (disp.ammo_rockets);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," rockets\n");
    st = ftos (disp.ammo_cells);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," cells, and ");
    st = ftos (disp.armorvalue);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," armor\n");
    self.current_menu = 16;
    self.menu_count = 25;
    self.building = disp;
    dist_checker = spawn ();
    dist_checker.classname = "timer";
    dist_checker.owner = self;
    dist_checker.enemy = disp;
    dist_checker.think = CheckDistance;
    dist_checker.nextthink = (time + 0.300);
}

void Engineer_UseSentryGun (entity gun) {
    entity dist_checker;
    string st;
    sprint (self,PRINT_HIGH,"Level ");
    st = ftos (gun.weapon);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," Sentry Gun has ");
    st = ftos (gun.health);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," health, ");
    st = ftos (gun.ammo_shells);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH," shells");
    if ( (gun.weapon == 3) ) {
        st = ftos (gun.ammo_rockets);
        sprint (self,PRINT_HIGH,", ");
        sprint (self,PRINT_HIGH,st);
        sprint (self,PRINT_HIGH," rockets");
    }
    sprint (self,PRINT_HIGH,"\n");
    self.current_menu = 17;
    self.menu_count = 25;
    self.building = gun;
    dist_checker = spawn ();
    dist_checker.classname = "timer";
    dist_checker.owner = self;
    dist_checker.enemy = gun;
    dist_checker.think = CheckDistance;
    dist_checker.nextthink = (time + 0.300);
}

void CheckSentry (entity gunhead) {
    vector dist;
    entity gunbase;
    gunbase = gunhead.trigger_field;
    dist = (gunbase.origin - gunhead.origin);
    if ( (vlen (dist) > 15) ) {
        bprint (PRINT_MEDIUM,self.real_owner.netname);
        bprint (PRINT_MEDIUM,"'s sentry gun malfunctioned\n");
        Sentry_Die ();
    }
}

void CheckDistance () {
    vector dist;
    if ( (self.owner.building != self.enemy) ) {
        dremove (self);
        return ;
    }
    dist = (self.enemy.origin - self.owner.origin);
    if ( (vlen (dist) > 64) ) {
        CenterPrint (self.owner,"\n");
        self.owner.menu_count = 25;
        self.owner.current_menu = 1;
        self.owner.building = world;
        dremove (self);
        return ;
    }
    self.nextthink = (time + 0.300);
}

void DestroyBuilding (entity eng, string bld) {
    entity te;
    entity oldself;
    float pos;
    te = find (world,classname,bld);
    while ( te ) {
        if ( (te.real_owner == eng) ) {
            pos = pointcontents (te.origin);
            if ( ((pos == -2) || (pos == -6)) ) {
                oldself = self;
                self = eng;
                self.ammo_cells = (self.ammo_cells + 100);
                bound_other_ammo (self);
                W_SetCurrentAmmo ();
                self = oldself;
            }
            if ( (te.real_owner.building == te) ) {
                if ( (te.real_owner.StatusBarSize == 0) ) {
                    CenterPrint (te.real_owner,"\n");
                } else {
                    te.real_owner.StatusRefreshTime = (time + 0.100);
                }
                te.real_owner.menu_count = 25;
                te.real_owner.current_menu = 1;
                te.real_owner.building = world;
            }
            TF_T_Damage (te,world,world,500,0,0);
        }
        te = find (te,classname,bld);
    }
}

void Engineer_RemoveBuildings (entity eng) {
    DestroyBuilding (eng,"building_dispenser");
    DestroyBuilding (eng,"building_sentrygun");
    DestroyBuilding (eng,"building_antispam");
}
