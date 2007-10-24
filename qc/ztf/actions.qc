/*
	actions.qc

	qwtf actions, medic, engineer and id

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

void TeamFortress_SaveMe ()
{
    entity te;
    entity tl;
    if (self.last_sound < time) {
        if (random () < 0.800) {
            sound (self,CHAN_WEAPON,"speech/saveme1.wav",1,1); // XXX: should these be on a different CHAN?
        } else {
            sound (self,CHAN_WEAPON,"speech/saveme2.wav",1,1); // XXX: should these be on a different CHAN?
        }
        self.last_sound = (time + 4);
    }
    te = player_head;
    while (te) {
        if ((((self == te) || (te.playerclass == CLASS_MEDIC)) || (te.playerclass == CLASS_ENGINEER)) || (te.playerclass == CLASS_SPY)) {
            if (((te.pteam == self.pteam) && (self.pteam.team != 0)) || (te.playerclass == CLASS_SPY)) {
                if (visible (te)) {
                    msg_entity = te;
                    tl = spawn ();
                    tl.origin = self.origin;
                    tl.origin_z = (tl.origin_z + 32);
                    WriteByte (1,23);
                    WriteByte (1,9);
                    WriteEntity (1,tl);
                    WriteCoord (1,tl.origin_x);
                    WriteCoord (1,tl.origin_y);
                    WriteCoord (1,(tl.origin_z + 24));
                    WriteCoord (1,self.origin_x);
                    WriteCoord (1,self.origin_y);
                    WriteCoord (1,self.origin_z);
                    dremove (tl);
                }
            }
        }
        te = te.nextp;
    }
}

// TODO: would be nice to optimise this / sync with client support for scr_autoid
void TeamFortress_ID ()
{
    vector src;
    string st;
    string cls;
    src = (self.origin + (v_forward * 10));
    src_z = (self.absmin_z + (self.size_z * 0.700));
    traceline (src,(src + (v_forward * 2048)),0,self);
    if ((trace_ent != world) && (trace_ent.origin != world.origin)) {
        if ((trace_ent.classname == "player") && (trace_ent.health > 0)) {
            if ((trace_ent.is_feigning && (self.pteam.team != 0)) && (self.pteam != trace_ent.pteam)) {
                return ;
            }
            self.StatusRefreshTime = (time + 1.500);
            if (((self.pteam.team != 0) && (self.pteam == trace_ent.pteam)) || (self.classname == "observer")) {
                cls = TeamFortress_GetClassName (trace_ent.playerclass);
                if (self.playerclass == CLASS_MEDIC) {
                    st = ftos ( rint (trace_ent.health));
                    centerprint (self,"\n\n\n\n",trace_ent.netname,"\nFriendly ",cls,"\n",st," health\n");
                    return ;
                } else {
                    if (self.playerclass == CLASS_ENGINEER) {
                        st = ftos( rint (trace_ent.armorvalue));
                        centerprint (self,"\n\n\n\n",trace_ent.netname,"\nFriendly ",cls,"\n",st," armor\n");
                        return ;
                    }
                }
                centerprint (self,"\n\n\n\n",trace_ent.netname,"\nFriendly ",cls);
                return ;
            }
            if (trace_ent.playerclass == CLASS_SPY) {
                cls = TeamFortress_GetClassName (trace_ent.undercover_skin);
                if ((self.pteam.team != 0) && (self.pteam.team == trace_ent.undercover_team)) {
                    if (self.playerclass == CLASS_MEDIC) {
                        st = ftos ( rint (trace_ent.health));
                        if (trace_ent.undercover_skin != 0) {
                            centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly ",cls,"\n",st," health\n");
                        } else {
                            centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly Spy\n",st," health\n");
                        }
                        return ;
                    } else {
                        if (self.playerclass == CLASS_ENGINEER) {
                            st = ftos ( rint (trace_ent.armorvalue));
                            if (trace_ent.undercover_skin != 0) {
                                centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly ",cls,"\n",st," armor\n");
                            } else {
                                centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly Spy\n",st," armor\n");
                            }
                            return ;
                        } else {
                            st = ftos ( rint (trace_ent.armorvalue));
                            if (trace_ent.undercover_skin != 0) {
                                centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly ",cls);
                            } else {
                                centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nFriendly Spy\n");
                            }
                            return ;
                        }
                    }
                }
                if (trace_ent.undercover_name != string_null) {
                    if (trace_ent.undercover_skin != 0) {
                        centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nEnemy ",cls);
                    } else {
                        centerprint (self,"\n\n\n\n",trace_ent.undercover_name,"\nEnemy Spy");
                    }
                } else {
                    if (trace_ent.undercover_skin != 0) {
                        centerprint (self,"\n\n\n\n",trace_ent.netname,"\nEnemy ",cls);
                    } else {
                        centerprint (self,"\n\n\n\n",trace_ent.netname,"\nEnemy Spy");
                    }
                }
            } else {
                cls = TeamFortress_GetClassName (trace_ent.playerclass);
                centerprint (self,"\n\n\n\n",trace_ent.netname,"\nEnemy ",cls);
            }
        } else {
            if (trace_ent.classname == "building_dispenser") {
                self.StatusRefreshTime = (time + 1.500);
                if (self == trace_ent.real_owner) {
                    centerprint (self,"\n\n\n\nYour Dispenser");
                } else {
                    centerprint (self,"\n\n\n\nDispenser made by ",trace_ent.real_owner.netname);
                }
            } else {
                if ((trace_ent.classname == "building_sentrygun") || (trace_ent.classname == "building_sentrygun_base")) {
                    self.StatusRefreshTime = (time + 1.500);
                    if (self == trace_ent.real_owner) {
                        centerprint (self,"\n\n\n\nYour SentryGun");
                    } else {
                        if ( !teamplay ) {
                            centerprint (self,"\n\n\n\nSentrygun made by\n",trace_ent.real_owner.netname);
                        } else {
                            if (((self.pteam.team != 0) && (self.pteam == trace_ent.pteam)) || (!self.playerclass)) {
                                centerprint (self,"\n\n\n\nFriendly Sentrygun made by\n",trace_ent.real_owner.netname);
                            } else {
                                centerprint (self,"\n\n\n\nEnemy Sentrygun made by\n",trace_ent.real_owner.netname);
                            }
                        }
                    }
                }
            }
        }
    }
}

void Medikit_Fire ()
{
    entity te;
    entity BioInfection;
    float healam;
    vector org;
    org = (trace_endpos - (v_forward * 4));
    if (trace_ent.classname == "player") {
        if (((trace_ent.pteam == self.pteam) && (self.pteam.team != 0)) || coop) {
            healam = 200;
            te = find (world,classname,"timer");
            while (((te.owner != trace_ent) || ((te.think != ConcussionGrenadeTimer))) && (te != world)) {
                te = find (te,classname,"timer");
            }
            if (te != world) {
                SpawnBlood (org,20);
                bprint (1,self.netname);
                bprint (1," cured ");
                bprint (1,trace_ent.netname);
                bprint (1,"'s concussion\n");
                if (te.pteam != self.pteam) {
                    TF_AddFrags (self,1, 0);
                }
                dremove (te);
            }
            if (trace_ent.tfstate & 16384) {
                te = find (world,classname,"timer");
                while (((te.owner != trace_ent) || (te.think != HallucinationTimer)) && (te != world)) {
                    te = find (te,classname,"timer");
                }
                if (te != world) {
                    trace_ent.tfstate = (trace_ent.tfstate - (trace_ent.tfstate & 16384));
                    SpawnBlood (org,20);
                    bprint (1,self.netname);
                    bprint (1," healed ");
                    bprint (1,trace_ent.netname);
                    bprint (1," of his hallucinations\n");
                    if (te.pteam != self.pteam) {
                        TF_AddFrags (self,1, 0);
                    }
                    dremove (te);
                } else {
                    dprint ("Warning: Error in Hallucination Timer logic.\n");
                }
            }
            if (trace_ent.tfstate & 32768) {
                te = find (world,classname,"timer");
                while (((te.owner != trace_ent) || (te.think != TranquiliserTimer)) && (te != world)) {
                    te = find (te,classname,"timer");
                }
                if (te != world) {
                    trace_ent.tfstate = (trace_ent.tfstate - (trace_ent.tfstate & 32768));
                    TeamFortress_SetSpeed (trace_ent);
                    SpawnBlood (org,20);
                    bprint (1,self.netname);
                    bprint (1," healed ");
                    bprint (1,trace_ent.netname);
                    bprint (1,"'s tranquilisation\n");
                    if (te.pteam != self.pteam) {
                        TF_AddFrags (self,1, 0);
                    }
                    dremove (te);
                } else {
                    dprint ("Warning: Error in Tranquilisation Timer logic.\n");
                }
            }
            if ((trace_ent.FlashTime > 0)) {
                te = find (world, netname, "flashtimer");
                while ((((te.owner != trace_ent) || (te.classname != "timer")) && (te != world))) {
                    te = find (te, netname, "flashtimer");
                }
                if ((te != world)) {
                    trace_ent.FlashTime = 0;
                    SpawnBlood (org, 20);
                    bprint (1, self.netname);
                    bprint (1, " cured ");
                    bprint (1, trace_ent.netname);
                    bprint (1, "'s blindness\n");
                    if ((te.pteam != self.pteam)) {
                        TF_AddFrags (self, 1, 0);
                    }
                    dremove (te);
                } else {
                    dprint ("Warning: Error in Flash Timer logic.\n");
                    trace_ent.FlashTime = 0;
                }
            }
            if (trace_ent.tfstate & 16) {
                healam = rint ((trace_ent.health / 2));
                trace_ent.tfstate = (trace_ent.tfstate - (trace_ent.tfstate & 16));
                deathmsg = 23;
                TF_T_Damage (trace_ent,self,self,healam, 1, 0);
                SpawnBlood (org,30);
                if (self.classname == "player") {
                    bprint (1,self.netname);
                    bprint (1," cured ");
                    bprint (1,trace_ent.netname);
                    bprint (1,"'s infection\n");
                    if (trace_ent.infection_team_no != self.pteam.team) {
                        TF_AddFrags (self,1, 0);
                    }
                }
                return ;
            }
            if (trace_ent.numflames > 0) {
                sound (trace_ent,CHAN_WEAPON,"items/r_item1.wav",1,1); // XXX: should this be CHAN_ITEM
                trace_ent.numflames = 0;
                if (self.classname == "player") {
                    bprint (1,self.netname);
                    bprint (1," put out ");
                    bprint (1,trace_ent.netname);
                    bprint (1,"'s fire.\n");
                }
                return ;
            }
            if ((healam > 0) && (trace_ent.health < trace_ent.max_health)) {
                sound (trace_ent,CHAN_WEAPON,"items/r_item1.wav",1,1); // XXX: should this be CHAN_ITEM
                trace_ent.axhitme = 1;
                SpawnBlood (org,20);
                T_Heal (trace_ent,healam,0);
            } else {
                if ((trace_ent.health >= trace_ent.max_health) && (trace_ent.health < (trace_ent.max_health + 50))) {
                    healam = 5;
                    if (healam > (self.ammo_medikit * 5)) {
                        healam = (self.ammo_medikit * 5);
                    }
                    if (healam > 0) {
                        sound (trace_ent,CHAN_ITEM,"items/r_item2.wav",1,1);
                        T_Heal (trace_ent,healam,1);
                        self.ammo_medikit = (self.ammo_medikit - rint ((healam / 5)));
                        if (!(trace_ent.items & 65536)) {
                            trace_ent.items = (trace_ent.items | 65536);
                            newmis = spawn ();
                            newmis.nextthink = (time + 5);
                            newmis.think = item_megahealth_rot;
                            newmis.owner = trace_ent;
                        }
                    }
                }
            }
        } else {
            trace_ent.axhitme = 1;
            SpawnBlood (org,20);
            deathmsg = 14;
            TF_T_Damage (trace_ent,self,self,10, 0, 0);
            if (trace_ent.playerclass == CLASS_MEDIC) {
                return ;
            }
            if (cb_prematch) {
                return ;
            }
            if (trace_ent.tfstate & 16) {
                return ;
            }
            trace_ent.tfstate = (trace_ent.tfstate | 16);
            BioInfection = spawn ();
            BioInfection.classname = "timer";
            BioInfection.owner = trace_ent;
            BioInfection.nextthink = (time + 2);
            BioInfection.think = BioInfection_Decay;
            BioInfection.enemy = self;
            trace_ent.infection_team_no = self.pteam.team;
        }
    }
}

void Spanner_Fire ()
{
	float healam;
	vector org;
	org = (trace_endpos - (v_forward * 4));
	if (trace_ent.classname == "building_dispenser") {
		Engineer_UseDispenser (trace_ent);
		return ;
	} else if (trace_ent.classname == "building_sentrygun") {
		Engineer_UseSentryGun (trace_ent);
		return ;
	} else if (trace_ent.classname == "building_sentrygun_base") {
		if ( trace_ent.oldenemy ) {
			Engineer_UseSentryGun (trace_ent.oldenemy);
		}
		return ;
	} else if (trace_ent.classname == "building_antispam") {
		trace_ent.think = T_Antispam;
		trace_ent.nextthink = time + 0.200;
		return ;
	} else if (trace_ent.classname == "player") {
		if ((((trace_ent.pteam == self.pteam) && (self.pteam.team != 0)) && teamplay) || coop) {
			healam = 10;
			if (self.ammo_cells < healam) {
				healam = self.ammo_cells;
			}
			if (trace_ent.armortype == 0) {
				return ;
			}
			if ((trace_ent.maxarmor - trace_ent.armorvalue) < (healam * 4)) {
				healam = ceil (((trace_ent.maxarmor - trace_ent.armorvalue) / 4));
			}
			if (healam > 0) {
				trace_ent.armorvalue = (trace_ent.armorvalue + (healam * 4));
				if (trace_ent.armorvalue > trace_ent.maxarmor) {
					trace_ent.armorvalue = trace_ent.maxarmor;
				}
				self.ammo_cells = (self.ammo_cells - healam);
				sound (trace_ent,CHAN_WEAPON,"items/r_item1.wav",1,1); // XXX: should this be CHAN_ITEM?
				WriteByte (4,23);
				WriteByte (4,2);
				WriteByte (4,3);
				WriteCoord (4,org_x);
				WriteCoord (4,org_y);
				WriteCoord (4,org_z);
				multicast (org,2);
				W_SetCurrentAmmo ();
				stuffcmd( self, "-use\n");
			}
			return ;
		}
	}
	trace_ent.axhitme = 1;
	SpawnBlood (org,20);
	deathmsg = 32;
	TF_T_Damage (trace_ent,self,self,20,2,0);
	stuffcmd( self, "-use\n");
}
