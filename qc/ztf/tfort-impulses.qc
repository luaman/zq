/*
    tfort-impulses.qc

    qwtf impulse command functions/definitions

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

void MsgAdminDis () {
    sprint (self, PRINT_HIGH,"Administrators disabled by server.\n");
}

void ImpulseCommands () {
	float imp;
	imp = self.impulse;
	if (self.last_impulse) {
		if (imp) {
			if (self.last_impulse == 71) {
				StatusRes (imp);
			} else if (self.last_impulse == 168) {
				TeamFortress_SetDetpack (imp);
			}
			self.impulse = 0;
			return;
		}
	}
	if (cb_prematch || cease_fire || round_over) {
		if (PreMatchImpulses()) return;
		if (DeadImpulses()) return;
		CommandImpulses();
		self.impulse = 0;
		return;
	}
	if (imp == 171) {
		UseSpecialSkill ();
		self.impulse = 0;
		return;
	}
	if ((imp == 9) && (self.current_menu != 6)) {
		self.current_menu = 6;
		self.menu_count = 25;
		self.menu_displaytime = 0;
		self.impulse = 0;
		return;
	}

#if 0
	if (self.impulse == 13)  {
		if (!allow_crouch)   return;

		if (self.is_feigning) return;
		if (!self.crouch) {
			self.crouch = 1;
			setsize(self, VEC_HULL3_MIN, VEC_HULL3_MAX);
			self.maxspeed = self.maxspeed / 3;
		}
	} else  if (self.impulse == 14) {
		if (!allow_crouch)   return;
		if (self.crouch) {
			pos = self.origin;
			traceline(pos, pos, 0, self, VEC_HULL_MIN, VEC_HULL_MAX);
			if (trace_allsolid)	//if player would be stuck
			{
				self.crouch = 2;
				pos = self.origin+'0 0 18';	//can we move them up a little
				traceline(pos, pos, 0, self, VEC_HULL_MIN, VEC_HULL_MAX);
				if (trace_allsolid)
				{
					self.impulse = 0;
					return;
				}
				self.origin = pos;
			}
			self.crouch = 0;
			setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
			TeamFortress_SetSpeed (self);
			//self.maxspeed = self.maxspeed * 3;
		}
	}
#endif

	if (imp == 135) {
		TeamFortress_Inventory ();
		self.impulse = 0;
		return;
	} else if (imp == 168) {
		self.last_impulse = imp;
		self.impulse = 0;
		return;
	} else if (imp == 170) {
		if (pipedelay) {
			if (time < self.attack_finished) {
				return ;
			}
		}
		TeamFortress_DetonatePipebombs ();
		self.impulse = 0;
		return;
	} else if (imp == 185) {
		TeamFortress_ID ();
		self.impulse = 0;
		return;
	} else if ((self.playerclass) && (imp == 181)) {
		TeamFortress_SaveMe ();
		self.impulse = 0;
		return;
	} else if (imp == 23) {
		if ((ctfmap == 1) || (!server_type)) {
			TeamFortress_CTF_FlagInfo ();
		} else {
			TeamFortress_DisplayDetectionItems ();
		}
		self.impulse = 0;
		return;
	} else if (imp == 118) {
		display_location ();
		self.impulse = 0;
		return;
	}

	if (!self.is_building && !self.is_detpacking && !self.is_feigning) {
		if (holdlimit) {
			if (time < self.attack_finished) {
				self.impulse = 0;
				return ;
			}
		}
		if (((imp >= 1) && (imp < 9)) || (imp == 176)) {
			W_ChangeWeapon ();
			self.impulse = 0;
			return;
		} else if (allow_hook && ((imp == 22) || (imp == 39))) {
			W_ChangeWeapon ();
			self.impulse = 0;
			return;
		} else if (imp == 40) {
			W_ChangeWeapon ();
			self.impulse = 0;
			return;
		} else if (imp == 10) {
			NextWeaponCmd ();
			self.impulse = 0;
			return;
		} else if (imp == 11) {
			PrevWeaponCmd ();
			self.impulse = 0;
			return;
		} else if ((imp == 12) && (self.last != 0)) {
			W_ChangeWeapon ();
			self.impulse = 0;
			return;
		} else if ((imp == 150) || (imp == 90))  {
			TeamFortress_PrimeGrenade ();
			self.impulse = 0;
			return;
		} else if ((imp == 151) || (imp ==  91)) {
			TeamFortress_PrimeGrenade ();
			self.impulse = 0;
			return;
		} else if (imp == 173) {
			if (time < self.attack_finished) {
				return ;
			}
			TeamFortress_ReloadCurrentWeapon ();
			self.impulse = 0;
			return;
		} else if (imp == 164) {
			TeamFortress_SetDetpack (5);
			self.impulse = 0;
			return;
		} else if (imp == 165) {
			TeamFortress_SetDetpack (20);
			self.impulse = 0;
			return;
		} else if (imp == 166) {
			TeamFortress_SetDetpack (50);
			self.impulse = 0;
			return;
		} else if (imp == 167) {
			TeamFortress_SetDetpack (255);
			self.impulse = 0;
			return;
		} else if (imp == 172) {
			self.current_menu = 4;
			self.menu_count = (25);
			self.impulse = 0;
			return;
		} else if (imp == 184) {
			TeamFortress_Discard ();
			self.impulse = 0;
			return;
		}
	}

	if (imp == 152) {
		TeamFortress_ThrowGrenade ();
	} else if ((self.playerclass) && (imp == 194)) {
		DropGoalItems ();
	} else if (imp == 169) {
		TeamFortress_DetpackStop ();
	} else if ((imp == 177) && (self.playerclass == CLASS_SPY)) {
		TeamFortress_SpyGoUndercover ();
	} else if ((imp == 178) && (self.playerclass == CLASS_SPY)) {
		TeamFortress_SpyFeignDeath (0);
	} else if ((imp == 179) && (self.playerclass == CLASS_ENGINEER)) {
		TeamFortress_EngineerBuild ();
	} else if ((imp == 187) && (self.playerclass == CLASS_ENGINEER)) {
		DestroyBuilding (self,"building_dispenser");
	} else if ((imp == 188) && (self.playerclass == CLASS_ENGINEER)) {
		DestroyBuilding (self,"building_sentrygun");
	} else if ((imp == 199) && (self.playerclass == CLASS_SPY)) {
		TeamFortress_SpyFeignDeath (1);
	} else {
		if (DeadImpulses()) return;
		CommandImpulses();
	}
    self.impulse = 0;
}

#if 0
void MsgLimitedAcc () {
	sprint (self, PRINT_HIGH,"You have limited Access, You cannot use this command.\n");
}

float AdminComVal3 () {
	if (self.is_admin != 3) {
		if (stof(infokey (world,"adminlevel")) < 3)
		{
			MsgLimitedAcc();
			return (0);
		}
	}
	return(1);
}

float AdminComVal2 () {
	if (self.is_admin != 3) {
		if (stof(infokey (world,"adminlevel")) < 2)
		{
			MsgLimitedAcc();
			return (0);
		}
	}
	return(1);
}

float AdminComVal () {
	if (self.is_admin != 3) {
		if(!stof(infokey(world, "adminlevel")))
		{
			MsgAdminDis();
			return (0);
		}
		if (CheckClanMode()) return(0);
	}
	return(1);
}
#endif

void CommandImpulses () {
    float imp;
    imp = self.impulse;
    if (imp == 41) {
        Toggle_Tracking();
        self.impulse = 0;
        return ;
    } else if (imp == 95) {
        if (CheckClanMode()) return;
        self.current_menu = 2;
        self.menu_count = 25;
        self.impulse = 0;
        return;
    } else if (imp == 112) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }

        if (self.playerclass) return;
        if (self.tracking != 1) return;
        self.campan = 1;
        self.impulse = 0;
        return ;
    } else if (imp == 113) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if (self.playerclass) return;
        if (self.tracking != 1) return;
        self.campan = -1;
        self.impulse = 0;
        return ;
    } else if (imp == 114) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if (self.playerclass) return;
        if (self.tracking != 1) return;
        self.campan = 0;
        self.impulse = 0;
        return ;
    } else if (imp == 42) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if ((self.playerclass) || (self.deadflag)) return;
        Track_Player();
        self.last_impulse = imp;
        self.impulse = 0;
        return ;
    } else if (imp == 43) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if ((self.playerclass) || (self.deadflag)) return;
        Track_Tfgoal();
        self.last_impulse = imp;
        self.impulse = 0;
        return ;
    } else if (imp == 44) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if ((self.playerclass) || (self.deadflag)) return;
        Track_Sentry();
        if (!self.tracking) Toggle_Tracking();
        self.last_impulse = imp;
        self.impulse = 0;
        return ;
    } else if (imp == 86) {
        if (self.classname != "observer") {
            if (CheckClanMode()) return;
        }
        if ((self.playerclass) || (self.deadflag)) return;
        Toggle_Autotrack();
        if (!self.tracking) Toggle_Tracking();
        self.impulse = 0;
        return;
    } else if (imp == 180) {
        Drop_detpack ();
        self.impulse = 0;
        return;
    } else if (imp == 67) {
        self.current_menu = 21;
        self.menu_count = 25;
        self.impulse = 0;
        return;
    } else if (imp == 68) {
        self.current_menu = 22;
        self.menu_count = 25;
        self.impulse = 0;
        return;
    } else if (imp == 69) {
        self.current_menu = 23;
        self.menu_count = 25;
        self.impulse = 0;
        return;
    } else if (imp == 70) {
        self.current_menu = 24;
        self.menu_count = 25;
        self.impulse = 0;
        return;
    } else if (imp == 72) {
        ShowFrags (self);
        self.impulse = 0;
        return;
    } else if (imp == 73) {
        ShowFps ();
        self.impulse = 0;
        return;
    } else if (imp == 74) {
        ShowStats ();
        self.impulse = 0;
        return;
    } else if (imp == 115) {
        ShowSpeed ();
        self.impulse = 0;
        return;
    } else if (imp == 75) {
        ShowTouches ();
        self.impulse = 0;
        return;
    } else if (imp == 76) {
        ShowScores ();
        self.impulse = 0;
        return;
    } else if (imp == 77) {
        AgreeMiscVote ();
        self.impulse = 0;
        return;
    } else if (imp == 83) {
        VoteYes();
        self.impulse = 0;
        return;
    } else if (imp == 84) {
        VoteNo();
        self.impulse = 0;
        return;
    } else if (imp == 85) {
        PlayerBreak();
        self.impulse = 0;
        return;
    } else if (imp == 125) {
        stuffcmd(self,"menu_options\n");
        self.impulse = 0;
        return;
    } else if (imp == 126) {
        stuffcmd(self,"menu_view\n");
        self.impulse = 0;
        return;
    } else if (imp == 88) {
        Commands();
        self.impulse = 0;
        return;

    } else if (imp == 87) {
        ShowVersion ();
        self.impulse = 0;
        return;

    } else if (imp == 89) {
        ModStatus();
        self.impulse = 0;
        return;
    } else if (imp == 255) {
        if (infokey(world, "*cheats") == string_null) {
            sprint (self, PRINT_HIGH, "Cheats are disabled on this server.\n");
            self.impulse = 0;
            return;
        }
        Give_Quad ();
        self.impulse = 0;
        return;
    } else if (imp == 254) {
        if (infokey(world, "*cheats") == string_null) {
            sprint (self, PRINT_HIGH, "Cheats are disabled on this server.\n");
            self.impulse = 0;
            return;
        }
        Give_Eyes ();
        self.impulse = 0;
        return;
    } else if (imp == 253) {
        if (infokey(world, "*cheats") == string_null) {
            sprint (self, PRINT_HIGH, "Cheats are disabled on this server.\n");
            self.impulse = 0;
            return;
        }
        Give_Pent ();
        self.impulse = 0;
        return;
    } else if (imp == 82) {
        if (!stof(infokey(world, "adminlevel"))) {
            MsgAdminDis();
        } else {
            VoteAdmin();
        }
        self.impulse = 0;
        return;
    }
    self.impulse = 0;
    return;

}

float PreMatchImpulses () {
    float imp;
    imp = self.impulse;
    if ((imp == 9) && (self.current_menu != 6)) {
        self.current_menu = 6;
        self.menu_count = 25;
        self.menu_displaytime = 0;
        self.impulse = 0;
        return(1);
    }

    if (((imp >= 1) && (imp < 9)) || (imp == 176)) {
        W_ChangeWeapon ();
        self.impulse = 0;
        return(1);
    } else {
        if (allow_hook && ((imp == 22) || (imp == 39))) {
            W_ChangeWeapon ();
            self.impulse = 0;
            return(1);
        } else {
            if (imp == 40) {
                W_ChangeWeapon ();
                self.impulse = 0;
                return(1);
            } else {
                if (imp == 10) {
                    NextWeaponCmd ();
                    self.impulse = 0;
                    return(1);

                } else {
                    if (imp == 11) {
                        PrevWeaponCmd ();
                        self.impulse = 0;
                        return(1);
                    }
                }
            }
        }
    }
    if (imp == 135) {
        TeamFortress_Inventory ();
        self.impulse = 0;
        return(1);
    } else {
        if (imp == 185) {
            TeamFortress_ID ();
            self.impulse = 0;
            return(1);
        } else {
            if (imp == 23) {
                if (ctfmap == 1) {
                    TeamFortress_CTF_FlagInfo ();
                } else {
                    TeamFortress_DisplayDetectionItems ();
                }
                self.impulse = 0;
                return(1);
            } else {
                if (imp == 118) {
                    display_location ();
                    self.impulse = 0;
                    return(1);
                }
            }
        }
    }
    return(0);
}

float DeadImpulses () {
    string st;
    float imp;
    imp = self.impulse;
    if (imp == 136) {
        TeamFortress_ShowTF ();
        self.impulse = 0;
        return(1);
    } else {
        if (imp == 174) {
            TeamFortress_AutoZoomToggle ();
            self.impulse = 0;
            return(1);
        } else {
            if (imp == 137) {
                TeamFortress_DisplayLegalClasses ();
                self.impulse = 0;
                return(1);
            } else {
                if ((imp > 100) && (imp <= (100 + 11))) {
                    TeamFortress_ChangeClass (imp - 100);
                    self.impulse = 0;
                    return(1);

                } else {
                    if (((self.playerclass) && (imp == 99))  && (!cb_prematch)) {
                        self.current_menu = 20;
                        self.menu_count = 25;
                        self.impulse = 0;
                        return(1);

                    } else {
                        if (imp == 71) {
                            self.last_impulse = imp;
                            return(1);
                        }

                    }
                }
            }
        }
    }
	if (imp == 131) {
		TeamFortress_HelpMap ();
		self.impulse = 0;
		return(1);
	} else if (imp == 119) {
		TeamFortress_StatusQuery ();
		self.impulse = 0;
		return(1);
	} else if (imp == 140) {
		if (CheckClanMode()) return(1);
		TeamFortress_TeamSet (1);
		self.impulse = 0;
		return(1);
	} else if (imp == 141) {
		if (CheckClanMode()) return(1);
		TeamFortress_TeamSet (2);
		self.impulse = 0;
		return(1);
	} else if (imp == 142) {
		if (CheckClanMode()) return(1);
		TeamFortress_TeamSet (3);
		self.impulse = 0;
		return(1);
	} else if (imp == 143) {
		if (CheckClanMode()) return(1);
		TeamFortress_TeamSet (4);
		self.impulse = 0;
		return(1);
	} else if (imp == 145) {
		TeamFortress_TeamShowScores (0);
		self.impulse = 0;
		return(1);
	} else if (imp == 144) {
		TeamFortress_TeamShowMemberClasses (self);
		self.impulse = 0;
		return(1);
	} else if ((self.playerclass == 1) && (imp == 159)) {
		ScannerSwitch ();
		self.impulse = 0;
		return(1);
	} else if ((self.playerclass == 1) && (imp == 162)) {
		sprint (self,PRINT_HIGH,"Scanner sound: ");

		if (self.tf_items_flags & 4) {
			self.tf_items_flags = (self.tf_items_flags - 4);
			sprint (self,PRINT_HIGH,"Off\n");
		} else {
			self.tf_items_flags = (self.tf_items_flags | 4);
			sprint (self,PRINT_HIGH,"On\n");
		}
		self.impulse = 0;
		return(1);
	} else if ((self.playerclass == 1) && (imp == 160)) {
		sprint (self,PRINT_HIGH,"Scanning for: ");
		if (self.tf_items_flags & 1) {
			self.tf_items_flags = (self.tf_items_flags - 1);
			if (self.tf_items_flags & 2) {
				sprint (self,PRINT_HIGH,"Friendlies Only.\n");
			} else {
				sprint (self,PRINT_HIGH,"Nothing\n");
			}
		} else {
			self.tf_items_flags = (self.tf_items_flags | 1);
			if (self.tf_items_flags & 2) {
				sprint (self,PRINT_HIGH,"Friendlies and Enemies\n");
			} else {
				sprint (self,PRINT_HIGH,"Enemies Only\n");
			}
		}
		self.impulse = 0;
		return(1);
	} else if ((self.playerclass == 1) && (imp == 161)) {
		sprint (self,PRINT_HIGH,"Scanning for: ");
		if (self.tf_items_flags & 2) {
			self.tf_items_flags = (self.tf_items_flags - 2);
			if (self.tf_items_flags & 1) {
				sprint (self,PRINT_HIGH,"Enemies Only.\n");
			} else {
				sprint (self,PRINT_HIGH,"Nothing\n");
			}
		} else {
			self.tf_items_flags = (self.tf_items_flags | 2);
			if (self.tf_items_flags & 1) {
				sprint (self,PRINT_HIGH,"Friendlies and Enemies\n");
			} else {
				sprint (self,PRINT_HIGH,"Friendlies Only\n");
			}

		}
		self.impulse = 0;
		return(1);
	} else if (imp == 182) {
		if (!server_type) {
			sprint (self, PRINT_HIGH, "Server incompatible - Unable to activate status bar.\n");
			self.impulse = 0;
			return(1);
		}
		if (self.StatusBarSize) {
			self.impulse = 0;
			return(1);
		}
		st = infokey (self,"sbs");
		if (st == string_null) {
			st = infokey (self,"sbar_size");
		}
		self.StatusBarSize = stof (st);
		if ((self.StatusBarSize > 10) || (self.StatusBarSize < 1)) {
			self.StatusBarSize = 3;
		}
		StatusBar_On();
		self.impulse = 0;
		return(1);
	} else if (imp == 183) {
		if (!self.StatusBarSize) {
			self.impulse = 0;
			return(1);
		}
		self.StatusBarSize = 0;
		StatusBar_On();
		self.impulse = 0;
		return(1);
	}
    return(0);
}
