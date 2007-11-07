/*
    spy.qc

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

void tfgoalitem_RemoveFromPlayer (entity Item, entity AP, float method);

void TeamFortress_SpyCalcName (entity spy);

void TeamFortress_SpyUndercoverThink ();

void GasGrenadeMakeGas ();

void T_TranqDartTouch ();

void () spy_diea1 = [ 50, spy_diea2 ] {
}

void () spy_diea2 = [ 51, spy_diea3 ] {
}

void () spy_diea3 = [ 52, spy_diea4 ] {
}

void () spy_diea4 = [ 53, spy_diea5 ] {
}

void () spy_diea5 = [ 54, spy_diea6 ] {
}

void () spy_diea6 = [ 55, spy_diea7 ] {
}

void () spy_diea7 = [ 56, spy_diea8 ] {
}

void () spy_diea8 = [ 57, spy_diea9 ] {
}

void () spy_diea9 = [ 58, spy_diea10 ] {
}

void () spy_diea10 = [ 59, spy_diea11 ] {
}

void () spy_diea11 = [ 60, spy_diea11 ] {
}

void () spy_dieb1 = [ 61, spy_dieb2 ] {
}

void () spy_dieb2 = [ 62, spy_dieb3 ] {
}

void () spy_dieb3 = [ 63, spy_dieb4 ] {
}

void () spy_dieb4 = [ 64, spy_dieb5 ] {
}

void () spy_dieb5 = [ 65, spy_dieb6 ] {
}

void () spy_dieb6 = [ 66, spy_dieb7 ] {
}

void () spy_dieb7 = [ 67, spy_dieb8 ] {
}

void () spy_dieb8 = [ 68, spy_dieb9 ] {
}

void () spy_dieb9 = [ 69, spy_dieb9 ] {
}

void () spy_diec1 = [ 70, spy_diec2 ] {
}

void () spy_diec2 = [ 71, spy_diec3 ] {
}

void () spy_diec3 = [ 72, spy_diec4 ] {
}

void () spy_diec4 = [ 73, spy_diec5 ] {
}

void () spy_diec5 = [ 74, spy_diec6 ] {
}

void () spy_diec6 = [ 75, spy_diec7 ] {
}

void () spy_diec7 = [ 76, spy_diec8 ] {
}

void () spy_diec8 = [ 77, spy_diec9 ] {
}

void () spy_diec9 = [ 78, spy_diec10 ] {
}

void () spy_diec10 = [ 79, spy_diec11 ] {
}

void () spy_diec11 = [ 80, spy_diec12 ] {
}

void () spy_diec12 = [ 81, spy_diec13 ] {
}

void () spy_diec13 = [ 82, spy_diec14 ] {
}

void () spy_diec14 = [ 83, spy_diec15 ] {
}

void () spy_diec15 = [ 84, spy_diec15 ] {
}

void () spy_died1 = [ 85, spy_died2 ] {
}

void () spy_died2 = [ 86, spy_died3 ] {
}

void () spy_died3 = [ 87, spy_died4 ] {
}

void () spy_died4 = [ 88, spy_died5 ] {
}

void () spy_died5 = [ 89, spy_died6 ] {
}

void () spy_died6 = [ 90, spy_died7 ] {
}

void () spy_died7 = [ 91, spy_died8 ] {
}

void () spy_died8 = [ 92, spy_died9 ] {
}

void () spy_died9 = [ 93, spy_died9 ] {
}

void () spy_diee1 = [ 94, spy_diee2 ] {
}

void () spy_diee2 = [ 95, spy_diee3 ] {
}

void () spy_diee3 = [ 96, spy_diee4 ] {
}

void () spy_diee4 = [ 97, spy_diee5 ] {
}

void () spy_diee5 = [ 98, spy_diee6 ] {
}

void () spy_diee6 = [ 99, spy_diee7 ] {
}

void () spy_diee7 = [ 100, spy_diee8 ] {
}

void () spy_diee8 = [ 101, spy_diee9 ] {
}

void () spy_diee9 = [ 102, spy_diee9 ] {
}

void () spy_die_ax1 = [ 41, spy_die_ax2 ] {
}

void () spy_die_ax2 = [ 42, spy_die_ax3 ] {
}

void () spy_die_ax3 = [ 43, spy_die_ax4 ] {
}

void () spy_die_ax4 = [ 44, spy_die_ax5 ] {
}

void () spy_die_ax5 = [ 45, spy_die_ax6 ] {
}

void () spy_die_ax6 = [ 46, spy_die_ax7 ] {
}

void () spy_die_ax7 = [ 47, spy_die_ax8 ] {
}

void () spy_die_ax8 = [ 48, spy_die_ax9 ] {
}

void () spy_die_ax9 = [ 49, spy_die_ax9 ] {
}

void () spy_upb1 = [ 69, spy_upb2 ] {
}

void () spy_upb2 = [ 68, spy_upb3 ] {
}

void () spy_upb3 = [ 67, spy_upb4 ] {
}

void () spy_upb4 = [ 66, spy_upb5 ] {
}

void () spy_upb5 = [ 65, spy_upb6 ] {
}

void () spy_upb6 = [ 64, spy_upb7 ] {
}

void () spy_upb7 = [ 63, spy_upb8 ] {
}

void () spy_upb8 = [ 62, spy_upb9 ] {
}

void () spy_upb9 = [ 61, spy_upb9 ] {
    player_stand1 ();
}

void () spy_upc1 = [ 84, spy_upc2 ] {
}

void () spy_upc2 = [ 83, spy_upc3 ] {
}

void () spy_upc3 = [ 82, spy_upc4 ] {
}

void () spy_upc4 = [ 81, spy_upc5 ] {
}

void () spy_upc5 = [ 80, spy_upc6 ] {
}

void () spy_upc6 = [ 79, spy_upc7 ] {
}

void () spy_upc7 = [ 78, spy_upc8 ] {
}

void () spy_upc8 = [ 77, spy_upc9 ] {
}

void () spy_upc9 = [ 76, spy_upc10 ] {
}

void () spy_upc10 = [ 75, spy_upc11 ] {
}

void () spy_upc11 = [ 74, spy_upc12 ] {
}

void () spy_upc12 = [ 73, spy_upc13 ] {
}

void () spy_upc13 = [ 72, spy_upc14 ] {
}

void () spy_upc14 = [ 71, spy_upc15 ] {
}

void () spy_upc15 = [ 70, spy_upc15 ] {
    player_stand1 ();
}

void () spy_upd1 = [ 93, spy_upd2 ] {
}

void () spy_upd2 = [ 92, spy_upd3 ] {
}

void () spy_upd3 = [ 91, spy_upd4 ] {
}

void () spy_upd4 = [ 90, spy_upd5 ] {
}

void () spy_upd5 = [ 89, spy_upd6 ] {
}

void () spy_upd6 = [ 88, spy_upd7 ] {
}

void () spy_upd7 = [ 87, spy_upd8 ] {
}

void () spy_upd8 = [ 86, spy_upd9 ] {
}

void () spy_upd9 = [ 85, spy_upd9 ] {
    player_stand1 ();
}

void () spy_upe1 = [ 94, spy_upe9 ] {
}

void spy_upe9 ();

void () spy_upe2 = [ 95, spy_upe8 ] {
}

void spy_upe8 ();

void () spy_upe3 = [ 96, spy_upe7 ] {
}

void spy_upe7 ();

void () spy_upe4 = [ 97, spy_upe6 ] {
}

void spy_upe6 ();

void () spy_upe5 = [ 98, spy_upe5 ] {
}

void () spy_upe6 = [ 99, spy_upe4 ] {
}

void () spy_upe7 = [ 100, spy_upe3 ] {
}

void () spy_upe8 = [ 101, spy_upe2 ] {
}

void () spy_upe9 = [ 102, spy_upe1 ] {
    player_stand1 ();
}

void () spy_upaxe1 = [ 49, spy_upaxe2 ] {
}

void () spy_upaxe2 = [ 48, spy_upaxe3 ] {
}

void () spy_upaxe3 = [ 47, spy_upaxe4 ] {
}

void () spy_upaxe4 = [ 46, spy_upaxe5 ] {
}

void () spy_upaxe5 = [ 45, spy_upaxe6 ] {
}

void () spy_upaxe6 = [ 44, spy_upaxe7 ] {
}

void () spy_upaxe7 = [ 43, spy_upaxe8 ] {
}

void () spy_upaxe8 = [ 42, spy_upaxe9 ] {
}

void () spy_upaxe9 = [ 41, spy_upaxe9 ] {
    player_stand1 ();
}

void TeamFortress_SpyFeignDeath (float issilent) {
    float i;
    float j;
    entity at_spot;
    entity te;
    if ( self.is_feigning ) {
        at_spot = findradius (self.origin,40);
        i = 1;
        j = 0;
		while ( (at_spot != world) ) {
			if ( (at_spot.mdl == "progs/detpack.mdl") ) {
				j = 1;
			} else  if ( (at_spot.mdl == "progs/turrbase.mdl") ) {
				j = 1;
			} else if ( (at_spot.mdl == "progs/turrgun.mdl") ) {
				j = 1;
			} else if ( (at_spot.mdl == "progs/disp.mdl") ) {
				j = 1;
			} else if ( (((at_spot.classname == "player") && (at_spot.deadflag == 0)) && (self != at_spot)) ) {
				j = 2;
			}

            if ( (j > 0) ) {
                i = 0;
            }
            at_spot = at_spot.chain;
        }
        if ( (i == 1) ) {
            i = (1 + floor ((random () * 5)));
            self.velocity = '0 0 0';
            setsize (self,'-16 -16 -24','16 16 32');
            self.view_ofs = '0 0 22';
            self.movetype = 3;
            self.is_feigning = 0;
            self.current = self.weapon;
            W_SetCurrentAmmo ();
            self.tfstate = (self.tfstate - (self.tfstate & 65536));
            TeamFortress_SetSpeed (self);
            if ( (self.weapon <= 16) ) {
                spy_upaxe1 ();
                return ;
            }
            if ( (i == 1) ) {
                spy_upb1 ();
            } else if ( (i == 2) ) {
				spy_upc1 ();
			} else if ( (i == 3) ) {
				spy_upd1 ();
			} else {
				spy_upe1 ();
			}
        } else {
            if ( (j == 1) ) {
                sprint (self,PRINT_HIGH,"You can't get up with something\non top of you.\n");
            } else {
                sprint (self,PRINT_HIGH,"You can't get up while someone\nis standing on you.\n");
            }
        }
    } else {
        if ( (self.is_unabletospy == 1) ) {
            sprint (self,PRINT_HIGH,"You can't feign right now.\n");
            return ;
        }
        if ( self.hook_out ) {
            sprint (self,PRINT_HIGH,"You can't feign with the hook out.\n");
            return ;
        }
        if ( (!(self.flags & 512) && (self.waterlevel == 0)) ) {
            sprint (self,PRINT_HIGH,"You can't feign in the air.\n");
            return ;
        }
        at_spot = findradius (self.origin,64);
        while ( (at_spot != world) ) {
            if ( (((at_spot.classname == "player") && (self != at_spot)) && (at_spot.is_feigning == 1)) ) {
                sprint (self,PRINT_HIGH,"You can't feign on top of another spy!\n");
                return ;
            }
            at_spot = at_spot.chain;
        }
        //self.immune_to_check = (time + 2);
        self.tfstate = (self.tfstate | 65536);
        TeamFortress_SetSpeed (self);
        self.is_feigning = 1;
        Attack_Finished (0.800);
        self.invisible_finished = 0;
        self.modelindex = modelindex_player;
        self.weapon = self.current;
        self.current = 0;
        self.weaponmodel = "";
        self.weaponframe = 0;
        setsize (self,'-16 -16 -24','16 16 -16');
        self.view_ofs = '0 0 4';
        self.movetype = 6;
        if ( (issilent == 0) ) {
            DeathSound ();
        }
        //self.angles_x = 0;
        //self.angles_z = 0;
        //self.fixangle = 1;
        if ( (self.weapon <= 16) ) {
            spy_die_ax1 ();
            return ;
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
        if (te != world) {
            dremove(te);
        }
        i = (1 + floor ((random () * 6)));
        if ( (i == 1) ) {
            spy_diea1 ();
        } else {
            if ( (i == 2) ) {
                spy_dieb1 ();
            } else {
                if ( (i == 3) ) {
                    spy_diec1 ();
                } else {
                    if ( (i == 4) ) {
                        spy_died1 ();
                    } else {
                        spy_diee1 ();
                    }
                }
            }
        }
    }
}

void TeamFortress_SpyGoUndercover () {
    if ( (self.effects & (8 | 4)) ) {
        sprint (self,PRINT_MEDIUM,"You cannot disguise while glowing.\n");
        return ;
    }
    if ( (self.is_unabletospy == 1) ) {
        sprint (self,PRINT_HIGH,"You can't go undercover right now.\n");
        return ;
    }
    if ( (self.is_undercover != 2) ) {
        self.current_menu = 12;
        self.menu_count = 25;
    } else {
        sprint (self,PRINT_HIGH,"You stop going undercover.\n");
        self.is_undercover = 0;
    }
}

void TeamFortress_SpyCalcName (entity spy) {
    entity te;
    spy.undercover_name = string_null;
    if ( (spy.undercover_team != 0) ) {
        te = player_head;
        while ( te ) {
            if ( ((te.pteam.team == spy.undercover_team) && (te.skin == spy.undercover_skin)) ) {
                spy.undercover_name = te.netname;
                te = world;
            } else {
                te = te.nextp;
            }
        }
        if ( (spy.undercover_name == string_null) ) {
            te = player_head;
            while ( te ) {
                if ( (te.pteam.team == spy.undercover_team) ) {
                    spy.undercover_name = te.netname;
                    te = world;
                } else {
                    te = te.nextp;
                }
            }
        }
    }
}

void TeamFortress_SpyUndercoverThink () {
    float tc;
    string st;
    if ( (self.owner.playerclass != 8) ) {
        return ;
    }
    if ( (self.owner.is_undercover == 2) ) {
        //self.owner.immune_to_check = (time + 2);
        if ( (self.skin != 0) ) {
            sprint (self.owner,PRINT_HIGH,"Skin set to ");
            TeamFortress_PrintClassName (self.owner,self.skin,0);
            self.owner.undercover_skin = self.skin;
            TeamFortress_SetSkin (self.owner);
        }
        if ( (self.team != 0) ) {
            sprint (self.owner,PRINT_HIGH,"Colors set to Team ");
            st = ftos (self.team);
            sprint (self.owner,PRINT_HIGH,st);
            sprint (self.owner,PRINT_HIGH,"\n");
            self.owner.undercover_team = self.team;
            stuffcmd (self.owner,"color ");
            tc = (PTeamGetColor (self.team) - 1);
            st = ftos (tc);
            stuffcmd (self.owner,st);
            stuffcmd (self.owner,"\n");
            TeamFortress_SetSkin (self.owner);
        }
        TeamFortress_SpyCalcName (self.owner);
        if ( (self.owner.StatusBarSize == 0) ) {
            CenterPrint (self.owner,"You are now disguised.\n");
        }
        self.owner.is_undercover = 1;
    }
    self.owner.StatusRefreshTime = (time + 0.100);
    dremove (self);
}

void TeamFortress_SpyChangeSkin (float pclass) {
    entity te;
    if ( (pclass == 8) ) {
        sprint (self,PRINT_HIGH,"Skin reset.\n");
        self.undercover_skin = 0;
        TeamFortress_SetSkin (self);
        if ( (self.undercover_team == 0) ) {
            self.is_undercover = 0;
        }
        return ;
    }
    sprint (self,PRINT_HIGH,"Going undercover...\n");
    self.is_undercover = 2;
    te = spawn ();
    te.classname = "timer";
    te.owner = self;
    te.think = TeamFortress_SpyUndercoverThink;
    te.nextthink = (time + 4);
    te.skin = pclass;
    TeamFortress_SetSkin (self);
}

void TeamFortress_SpyChangeColor (float teamno) {
    entity te;
    if ( (teamno == self.pteam.team) ) {
        sprint (self,PRINT_HIGH,"Colors reset.\n");
        //self.immune_to_check = (time + 2);
        self.undercover_team = 0;
        stuffcmd (self,"color ");
        stuffcmd (self, ftos(self.pteam.colormap));
        stuffcmd (self,"\n");
        if ( (self.undercover_skin == 0) ) {
            self.is_undercover = 0;
        }
        TeamFortress_SetSkin (self);
        return ;
    }
    sprint (self,PRINT_HIGH,"Going undercover...\n");
    self.is_undercover = 2;
    te = spawn ();
    te.classname = "timer";
    te.owner = self;
    te.think = TeamFortress_SpyUndercoverThink;
    te.nextthink = (time + 4);
    te.team = teamno;
}

void GasGrenadeTouch () {
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void GasGrenadeExplode () {
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
    pos = pointcontents (self.origin);
    if ( (pos == -1) ) {
        te = spawn ();
        te.think = GasGrenadeMakeGas;
        te.nextthink = (time + 0.100);
        te.classname = "grentimer";
        te.heat = 0;
        te.origin = self.origin;
        te.owner = self.owner;
        te.pteam = self.owner.pteam;
        te.weapon = 0;
        te.enemy = self;
    } else {
        pos = 0;
        while ( (pos < 10) ) {
            newmis = spawn ();
            setmodel (newmis,"progs/s_bubble.spr");
            setorigin (newmis,self.origin);
            newmis.movetype = 8;
            newmis.solid = 0;
            newmis.velocity = '0 0 15';
            newmis.velocity_z = (10 + (random () * 20));
            newmis.nextthink = (time + 0.500);
            newmis.think = bubble_bob;
            newmis.classname = "bubble";
            newmis.frame = 0;
            newmis.cnt = 0;
            setsize (newmis,'-8 -8 -8','8 8 8');
            pos = (pos + 1);
        }
    }
    dremove (self);
}

void viewsmoke (entity te) {
    string st,st2;
    st = ftos (135 + (crandom() * 80));
    st2 = ftos (100 + (crandom() * 50));
    stuffcmd (te, "v_cshift ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st);
    stuffcmd (te, " ");
    stuffcmd (te, st2);
    stuffcmd (te, "\n");
}

void HallucinationTimer () {
    entity te;
    float tmpx;
    float tmpy;
    float halltype;
    self.health = (self.health - 3);
    if ( (self.owner.playerclass == 5) ) {
        self.health = (self.health - 2);
    }
    if ( (((self.health <= 0) || (self.owner.deadflag != 0)) || (self.owner.has_disconnected == 1)) ) {
        self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 16384));
        stuffcmd (self.owner,"v_cshift; wait; bf\n");
    }
    if ( ((self.owner.deadflag != 0) || (self.owner.has_disconnected == 1)) ) {
        dremove (self);
        return ;
    }
    if ( !(self.owner.tfstate & 16384) ) {
        stuffcmd (self.owner,"v_cshift; wait; bf\n");
        sprint (self.owner,PRINT_HIGH,"You feel a little better now.\n");
        dremove (self);
        return ;
    }
    self.nextthink = (time + 0.300);
    if (self.owner.invincible_finished)  return ;
    if ( (random () < 0.500) ) {
        KickPlayer (-10,self.owner);
    }
    tmpx = ((random () * 800) - 400);
    tmpy = ((random () * 800) - 400);
    halltype = random ();
    msg_entity = self.owner;
    if ( (halltype < 0.400) ) {
        WriteByte (1,23);
        if ( (halltype < 0.250) ) {
            WriteByte (1,3);
        } else {
            if ( (halltype < 0.350) ) {
                WriteByte (1,4);
            } else {
                WriteByte (1,10);
            }
        }
        WriteCoord (1,(msg_entity.origin_x + tmpx));
        WriteCoord (1,(msg_entity.origin_y + tmpy));
        WriteCoord (1,msg_entity.origin_z);
        TF_T_Damage (self.owner,self.owner,self.owner,0,0,0);
    } else {
        WriteByte (1,23);
        WriteByte (1,11);
        WriteCoord (1,(msg_entity.origin_x + tmpx));
        WriteCoord (1,(msg_entity.origin_y + tmpy));
        WriteCoord (1,msg_entity.origin_z);
        halltype = random ();
		if ( (halltype < 0.100) ) {
			stuffcmd (self.owner,"play weapons/r_exp3.wav\n");
		} else if ( (halltype < 0.150) ) {
			stuffcmd (self.owner,"play weapons/rocket1i.wav\n");
		} else if ( (halltype < 0.200) ) {
			stuffcmd (self.owner,"play weapons/sgun1.wav\n");
		} else if ( (halltype < 0.250) ) {
			stuffcmd (self.owner,"play weapons/guncock.wav\n");
		} else if ( (halltype < 0.300) ) {
			stuffcmd (self.owner,"play weapons/ric1.wav\n");
		} else if ( (halltype < 0.350) ) {
			stuffcmd (self.owner,"play weapons/ric2.wav\n");
		} else if ( (halltype < 0.400) ) {
			stuffcmd (self.owner,"play weapons/ric3.wav\n");
		} else if ( (halltype < 0.450) ) {
			stuffcmd (self.owner,"play weapons/spike2.wav\n");
		} else  if ( (halltype < 0.500) ) {
			stuffcmd (self.owner,"play weapons/tink1.wav\n");
		} else if ( (halltype < 0.550) ) {
			CenterPrint (self.owner,"\n\n\nYour team цаптуред the flag!!");
			stuffcmd (self.owner,"play weapons/grenade.wav\n");
		} else if ( (halltype < 0.600) ) {
			stuffcmd (self.owner,"play weapons/bounce.wav\n");
		} else if ( (halltype < 0.650) ) {
			stuffcmd (self.owner,"play weapons/shotgn2.wav\n");
		} else if ( (halltype < 0.700) ) {
			stuffcmd (self.owner,"play wizard/wattack.wav\n");
		} else if ( (halltype < 0.750) ) {
			stuffcmd (self.owner,"play items/r_item1.wav\n");
		} else if ( (halltype < 0.800) ) {
			stuffcmd (self.owner,"play items/r_item2.wav\n");
		} else if ( (halltype < 0.850) ) {
			CenterPrint (self.owner,"You are on fire!\n");
			stuffcmd (self.owner,"play weapons/lhit.wav\n");
		} else if ( (halltype < 0.900) ) {
			stuffcmd (self.owner,"play misc/r_tele1.wav\n");
		} else {
			stuffcmd (self.owner,"play weapons/railgun.wav\n");
		}
        if (te != world) {
            dremove (te);
        }
    }
}

void W_FireTranq () {
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 1);
        self.currentammo = self.ammo_shells;
    }
    KickPlayer (-2,self);
    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = 9;
    newmis.solid = 2;
    makevectors (self.v_angle);
    newmis.velocity = v_forward;
    newmis.velocity = (newmis.velocity * 1500);
    newmis.angles = vectoangles (newmis.velocity);
    newmis.touch = T_TranqDartTouch;
    newmis.think = SUB_Remove;
    newmis.nextthink = (time + 6);
    setmodel (newmis,"progs/spike.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,((self.origin + (v_forward * 8)) + '0 0 16'));
}

void TranquiliserTimer () {
    self.owner.tfstate = (self.owner.tfstate - (self.owner.tfstate & 32768));
    TeamFortress_SetSpeed (self.owner);
    sprint (self.owner,PRINT_HIGH,"You feel more alert now\n");
    dremove (self);
}

void T_TranqDartTouch () {
    entity timer;
    if ( (other.solid == 1) ) {
        return ;
    }
    if ( (pointcontents (self.origin) == -6) ) {
        dremove (self);
        return ;
    }
    if ( other.takedamage ) {
        if ( ((other.classname == "player") && !((other.pteam == self.owner.pteam) && (teamplay & (2 | 4)))) ) {
            if ( (other.tfstate & 32768) || (other.invincible_finished)) {
                timer = find (world,classname,"timer");
                while ( (((timer.owner != other) || (timer.think != TranquiliserTimer)) && (timer != world)) ) {
                    timer = find (timer,classname,"timer");
                }
                if ( (timer != world) ) {
                    timer.nextthink = (time + 15);
                }
            } else {
                sprint (other, PRINT_HIGH,"You feel tired...\n");
                other.tfstate = (other.tfstate | 32768);
                timer = spawn ();
                timer.nextthink = (time + 15);
                timer.think = TranquiliserTimer;
                timer.classname = "timer";
                timer.owner = other;
                timer.pteam = self.owner.pteam;
                TeamFortress_SetSpeed (other);
            }
        }
        spawn_touchblood (9);
        deathmsg = 25;
        TF_T_Damage (other,self,self.owner,20,2,2);
    } else {
        WriteByte (4,23);
        WriteByte (4,0);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,2);
    }
    dremove (self);
}

void Spy_RemoveDisguise (entity spy) {
    if ( (spy.playerclass == 8) ) {
        if ( (spy.undercover_team != 0) ) {
            spy.undercover_team = 0;
            stuffcmd (spy,"color ");
            stuffcmd (spy, ftos(spy.pteam.colormap));
            stuffcmd (spy,"\n");
        }
        if ( (spy.undercover_skin != 0) ) {
            spy.undercover_skin = 0;
            spy.skin = 0;
        }
        spy.is_undercover = 0;
        self.StatusRefreshTime = (time + 0.100);
        TeamFortress_SetSkin (spy);
        TeamFortress_SpyCalcName (spy);
    }
}

void GasGrenadeMakeGas () {
    float nextloop;
    entity te;
    entity timer;
    if ( (self.heat == 0) ) {
        self.owner.no_active_gas_grens = (self.owner.no_active_gas_grens + 1);
        if ( (self.owner.no_active_gas_grens > 0) ) {
            te = find (world,classname,"grentimer");
            while ( te != world) {
                if ( ((te.owner == self.owner) && (te.no_active_gas_grens == 1)) ) {
                    te.weapon = 24;
                    te.think = RemoveGrenade;
                    te.nextthink = (time + 0.100);
                }
                te = find (te,classname,"grentimer");
            }
        }
        self.no_active_gas_grens = self.owner.no_active_gas_grens;
    }
    //self.nextthink = (time + 0.750);
    self.nextthink = (time + 0.200);
    te = findradius (self.origin,200);
    while ( (te != world) ) {
        nextloop = 0;
        if (grenradius & 1) {
            if (!CanDamage (te,self) ) nextloop = 1;
        }

        if (!nextloop) {
            if ( (((te.classname == "player") && (te.deadflag == 0)) && (te.has_disconnected != 1)) ) {
                deathmsg = 24;
                viewsmoke(te);
                if (self.weapon == 1 || self.weapon == 3 || self.weapon == 5)
                    TF_T_Damage (te,world,self.owner,1,(1 | 2),0);
                if ( (te.tfstate & 16384) ) {
                    timer = find (world,classname,"timer");
                    while ( (((timer.owner != te) || (timer.think != HallucinationTimer)) && (timer != world)) ) {
                        timer = find (timer,classname,"timer");
                    }
                    if ( (timer != world) ) {
                        timer.health = (timer.health + 1);

                        if ( (timer.health < 80) ) {
                            timer.health = 80;
                        }
                    }
                } else {
                    sprint (te,PRINT_HIGH,"Run for cover! They're everywhere!\n");
                    te.tfstate = (te.tfstate | 16384);
                    timer = spawn ();

                    timer.nextthink = (time + 0.300);
                    timer.think = HallucinationTimer;
                    timer.classname = "timer";
                    timer.owner = te;
                    timer.health = 120;
                    timer.pteam = self.pteam;
                }
            }
        }
        te = te.chain;
    }
    self.heat = (self.heat + 1);
    if ( (self.heat == 1) ) {
        WriteByte (4,23);
        WriteByte (4,4);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,2);
        return ;
    }
    if ( (self.heat <= 60) ) {
        self.weapon = (self.weapon + 1);
        if ( (self.weapon == 1) ) {
            WriteByte (4,23);
            WriteByte (4,10);
            WriteCoord (4,self.origin_x);
            WriteCoord (4,self.origin_y);
            WriteCoord (4,(self.origin_z - 24));
            multicast (self.origin,2);
        } else {
            if ( (self.weapon == 5) ) {
                self.weapon = 0;
            }
        }
        return ;
    }
    RemoveGrenade ();
}
