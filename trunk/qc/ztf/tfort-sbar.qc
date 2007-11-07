/*
    tfort-sbar.qc

    qwtf status bar functions/definitions

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

void Status_StartWrite ();

void Status_EndWrite ();

void WriteStr (string str);

void WriteRep (float f1, float len);
string Status_TeamNumToTeamString (float tno);
string TeamFortress_GetClassName (float pc);
//
//void (float f,float c) WriteIntXX;
//
//void (float f,float c) WriteIntXXX;

void WriteIntXXXX (float f,float c);

void WriteSIntXXXX (float f);	// == -WriteRIntXXX or WriteRIntXXXX

void WriteSpace (float i);

void WriteBar (float v, float vmax);

void RefreshStatusBar () {
    float x; // max 30
    entity te;
    float num;

    if (self.current_menu)
        return;
    if (self.deadflag)
        return;
    if ((infokey(world, "status") == "Countdown"))
        return;
    msg_entity = self;
    Status_StartWrite();
    if (round_active) {
        if ((!self.ScannerOn)) {
            if ((self.is_undercover != 2)) {
                te = find (te, classname, "round");
                WriteSIntXXXX(te.cnt);
                WriteByte (MSG_ONE, 58);
                WriteSIntXXXX(te.cnt2);
                WriteSpace(4);
            }
        }
        if (modetype & 4) {
            if (self.is_detpacking) {
                WriteStr("setting BOMB");
                num = stof(infokey (world,"bombarmtime"));
                if (num < 1 || num >  10) num = 3;
                WriteBar (time - self.pausetime, num);
                WriteSpace(13);
            }
        }
    } else if (!self.playerclass) {
        Status_EndWrite();
        return;
    }
    if (self.sbar_type & 4) {
        //WriteSpace(23);
        WriteStr("SF:");
        WriteSIntXXXX (self.real_frags);
        WriteStr(" SD:");
        WriteSIntXXXX (self.deaths);
        //WriteByte (MSG_ONE,10);
        WriteSpace(1);
    }
    if (self.sbar_type & 8) {
        //WriteSpace(23);
        WriteStr("DR:");
        WriteSIntXXXX (self.dmg_inflicted);
        WriteStr(" DT:");
        WriteSIntXXXX (self.dmg_recieved);
        //WriteByte (MSG_ONE,10);
        WriteSpace(1);
    }
    if (self.sbar_type & 16) {
        //WriteSpace(23);
        WriteStr("FT:");
        WriteSIntXXXX (self.flag_touches);
        WriteStr(" FC:");
        WriteSIntXXXX (self.flag_captures);
        WriteByte (MSG_ONE,10);
        //WriteSpace(1);
    }
    if (self.sbar_type & 32) {
        if (store_obs.cnt == 2) {
            te = find (world,classname,"item_tfgoal");
            while ((te != world) && (te.camdist != -1) && (te.team_no == self.pteam.team)) {
                te = find (te, classname, "item_tfgoal");
            }
            //WriteSpace(23);
            if ((te.owned_by == 1) && (te.nextthink - time > 0)) {
                WriteStr("Blue Flag:");
                WriteSIntXXXX (rint(te.nextthink - time));
            }
            if ((te.owned_by == 2) && (te.nextthink - time > 0)) {
                WriteStr(" Red Flag:");
                WriteSIntXXXX (rint(te.nextthink - time));
            }
            WriteByte (MSG_ONE,10);
        }
    } else if (self.stamina && allow_stamina) {
        WriteStr("stamina: ");
        WriteBar (self.stamina, 1000);
    } else if (self.playerclass == CLASS_SCOUT) {
        te = find (world,netname,"scanner");
        while ((te != world) && (te.owner != self)) {
            te = find (te, classname, "scanner");
        }
        if ( (self.ScannerOn == 1) ) {
            x = 0;
            if (te.health > 0) {
                WriteStr(Status_TeamNumToTeamString(te.pteam.team));
                WriteSpace(1);
                WriteStr(TeamFortress_GetClassName (te.playerclass));
                x = x + 15;
            } else {
                WriteStr("No Blips");
                x=x+8;
            }
            if (x) {
                WriteSpace(18-x);
            }
            WriteStr("Range: ");
            WriteSIntXXXX(te.health);
        }
    } else if (self.playerclass == CLASS_DEMOMAN) {
        if (self.is_detpacking) {
            WriteStr("setting detpack");
            WriteSpace(15);
        }
    } else if (self.playerclass == CLASS_SPY) {
        if (self.is_undercover)
            if (self.is_undercover == 2) {
                WriteStr("going undercover ");
                WriteSpace(14);
            } else {
                x = 0;
                WriteStr(Status_TeamNumToTeamString(self.undercover_team));
                WriteSpace(1);
                WriteStr(TeamFortress_GetClassName (self.undercover_skin));
                x = x + 20;
                if (x)
                    WriteSpace(30-x);
            }
    } else if (self.playerclass == CLASS_ENGINEER) {
        x = 0;
        if (self.has_sentry) {
            te = find (world, classname, "building_sentrygun");
            while ((te != world) && (te.real_owner != self))
                te = find (te, classname, "building_sentrygun");
            WriteStr("Sentry: ");
            //W8C (_S,_e,_n,_t,_r,_y,dperiod,space);
            WriteSIntXXXX (te.health);
            x = x + 11;
            if (!self.sbar_type & 1) {
                if ((te.ammo_rockets == 0) && (te.ammo_shells == 0)) {
                    WriteStr(" no ammo");
                    x = x + 8;
                } else if (!te.ammo_shells) {
                    WriteStr(" no shells");
                    x = x + 10;
                } else if ((!te.ammo_rockets) && (te.weapon == 3)) {
                    WriteStr(" no rockets");
                    x = x + 11;
                } else if (te.health != te.max_health) {
                    WriteStr(" damaged");
                    x = x + 8;
                }
#if 0
				else if ((te.ammo_shells != te.maxammo_shells) || ((te.ammo_rockets != te.maxammo_rockets) && (te.weapon == 3)))
				{
					W8C (space,_n,_o,_t,space,_f,_u,_l);
					WriteByte (MSG_ONE, _l);
					x = x + 9;
				}
#endif
            } else {
                WriteByte (MSG_ONE,47);
                WriteSIntXXXX(te.ammo_shells);
                x = x + 4;
                if (te.weapon == 3) {
                    WriteByte (MSG_ONE,47);
                    WriteSIntXXXX(te.ammo_rockets);
                    x = x + 3;
                }
            }
        }
        if ((self.has_dispenser) && (self.sbar_type & 1)) {
            newmis = find (world, classname, "building_dispenser");
            while ((newmis != world) && (newmis.real_owner != self))
                newmis = find (newmis, classname, "building_dispenser");
            WriteStr("Dispenser: ");
            WriteSIntXXXX (newmis.health);
            x = x + 14;
        }
        if ((x >= 0) && (x < 35))
            WriteSpace(35-x);
    } else if (self.playerclass == CLASS_MEDIC) {
        WriteStr("Medikit: ");
        WriteSIntXXXX (self.ammo_medikit);
        WriteSpace(19);
    }

    WriteByte (MSG_ONE,10);

    if (store_obs.cnt == 2) {
        WriteStr("Blue:");
        WriteSIntXXXX (pteam1.frags);
        WriteStr(" Red:");
        WriteSIntXXXX (pteam2.frags);
    } else {
        WriteSIntXXXX (pteam1.frags);
        WriteByte (MSG_ONE,47);
        WriteSIntXXXX (pteam2.frags);
        WriteByte (MSG_ONE,47);
        WriteSIntXXXX (pteam3.frags);
        WriteByte (MSG_ONE,47);
        WriteSIntXXXX (pteam4.frags);
    }

    if ( (self.playerclass == CLASS_CIVILIAN) ) {
        Status_EndWrite();
        return;
    }

    if (!self.sbar_type & 1) {
		// XXX: these first two were previously 128 and 256 which
		// doesn't match WEAP_SHOTGUN and WEAP_SUPER_SHOTGUN, but
		// SUPER_SHOTGUN and NAILGUN... a bug?
        if (self.current == WEAP_SHOTGUN) {
            if ((8 - self.reload_shotgun) > self.ammo_shells) // FIXME: ???
                self.reload_shotgun = (8 - self.ammo_shells);
            num =(8 - self.reload_shotgun);
        } else if (self.current == WEAP_SUPER_SHOTGUN) {
            if ((16 - self.reload_super_shotgun) > self.ammo_shells)
                self.reload_super_shotgun = (16 - self.ammo_shells);
            num =(16 - self.reload_super_shotgun);
        } else if (self.current == WEAP_GRENADE_LAUNCHER || self.current == WEAP_PIPEBOMB_LAUNCHER) {
            if ((6 - self.reload_grenade_launcher) > self.ammo_rockets)
                self.reload_grenade_launcher = (6 - self.ammo_rockets);
            num =(6 - self.reload_grenade_launcher);
        } else if (self.current == WEAP_ROCKET_LAUNCHER) {
            if ((4 - self.reload_rocket_launcher) > self.ammo_rockets)
                self.reload_rocket_launcher = (4 - self.ammo_rockets);
            num =(4 - self.reload_rocket_launcher);
        } else	{
			num = -1;
		}
        if (num >= 0) {
            //clip
            WriteStr("  √Ã…–∫");
            WriteIntXXXX(num,48);
        } else	WriteSpace(9);
    }
    //grens
    WriteStr(" «±∫");
    WriteSIntXXXX(self.no_grenades_1);
    WriteStr(" «≤∫");
    WriteSIntXXXX(self.no_grenades_2);
    Status_EndWrite();
}

void Status_StartWrite () {
    float i;
    if (self.sbar_type & 2) {
        self.StatusRefreshTime = (time + 1);
        WriteByte (MSG_ONE, SVC_PRINT);
        WriteByte (MSG_ONE, PRINT_HIGH);
    } else {
        WriteByte (MSG_ONE, SVC_CENTERPRINT);
#if 0
		if (time < self.CenterPrintTime)
		{
			if (self.b_b != string_null)
			{
				i = i - 1;
				WriteStr(self.b_b);
			}
			if (self.b_t != string_null)
			{
				i = i - 1;
				WriteStr(self.b_t);
			}
			if (self.b_n != string_null)
			{
				i = i - 1;
				WriteStr(self.b_n);
			}
		}
#endif
        self.StatusRefreshTime = (time + 1.500);
        i = self.StatusBarRes  + self.StatusBarSize;
        if (self.sbar_type & 4) {
            i = i - 1;
        }
        if (self.sbar_type & 8) {
            i = i - 1;
        }
        if (self.sbar_type & 16) {
            i = i - 1;
        }
        if (self.sbar_type & 32) {
            i = i - 1;
        }
        while (i > 0) {
            WriteByte (MSG_ONE, 10); // = \n
            i = i - 1;
        }
    }
}

void WriteBar (float v, float vmax) {
    if (v > vmax * 7 / 8) {
        WriteRep(gled,8);
    } else if (v > vmax * 6 / 8) {
        WriteSpace(1);
        WriteRep(gled,7);
    } else if (v > vmax * 5 / 8) {
        WriteSpace(2);
        WriteRep(gled,6);
    } else if (v > vmax * 4 / 8) {
        WriteSpace(3);
        WriteRep(yled,5);
    } else if (v > vmax * 3 / 8) {
        WriteSpace(4);
        WriteRep(yled,4);
    } else if (v > vmax * 2 / 8) {
        WriteSpace(5);
        WriteRep(rled,5);
    } else if (v > vmax * 1 / 8) {
        WriteSpace(6);
        WriteShort (1, rled*256 + rled);
    } else {
        WriteSpace(7);
        WriteByte (MSG_ONE, rled);
    }
}

void WriteStr (string str) {
    float len;
    float i;
    string nwstr;
    len = strlen (str);
	/*
    for (i = 0; i < len - 1; i = i + 2) {
        nwstr = substr(str , i , 2);
        WriteShort(1,str2short(nwstr));
    }
	*/
    if (i == len - 1) {
        nwstr = substr(str , i , 1);
        WriteByte (MSG_ONE,str2byte(nwstr));
    }
}

void WriteRep (float f1, float len) {
    float i;
	/*
    for (i = 0; i < len - 1; i = i + 2) {
        WriteShort(1, f1 * 256 + f1);
    }
	*/
    if (i == len - 1) {
        WriteByte (MSG_ONE,f1);
    }
}

void WriteIntXXXX (float f, float c) {
    float y;
    float print;

    if (f >= 100000) {
        y = floor(f/100000);
        WriteByte (MSG_ONE,y + c);
        f = f - y * 100000;
        print = 1;
    }
    if (f >= 10000 || print) {
        y = floor(f/10000);
        WriteByte (MSG_ONE,y + c);
        f = f - y * 10000;
        print = 1;
    }
    if (f >= 1000 || print) {
        y = floor(f/1000);
        WriteByte (MSG_ONE,y + c);
        f = f - y * 1000;
        print = 1;
    }
    if (f >= 100 || print) {
        y = floor(f/100);
        WriteByte (MSG_ONE,y + c);
        f = f - y * 100;
        print = 1;
    }
    if (f >= 10 || print) {
        y = floor(f/10);
        WriteByte (MSG_ONE,y + c);
        f = f - y * 10;
        WriteByte (MSG_ONE,f + c);

    } else {
        WriteByte (MSG_ONE, 32);
        WriteByte (MSG_ONE,f + c);
    }

}

void WriteSIntXXXX (float f) {
    float i;

    if (f >= 0) {
        WriteIntXXXX(f,COLOR_WHITE);
        return;
    }
    f = 0 - f;

    if (f > 99) {
        WriteByte (MSG_ONE, 45 + 128);
        WriteIntXXXX(i, COLOR_WHITE);
        return;
    }
    if (f > 9) {
        WriteByte (MSG_ONE, 32);
        WriteByte (MSG_ONE, 45 + 128);
        WriteIntXXXX(i,COLOR_WHITE);
        return;
    }

    WriteByte (MSG_ONE, 32);
    WriteByte (MSG_ONE, 45);
    WriteByte (MSG_ONE, i + 48);
    WriteByte (MSG_ONE, 32);
}

void WriteSpace (float i) {
    while (i) {
        WriteByte (MSG_ONE, 32);
        i = i - 1;
    }
}

void Status_EndWrite () {
    WriteByte (MSG_ONE, 0);		// TODO: merc will put some more code later :)
}


void StatusBar_On () {
    if (self.StatusBarSize) {
		self.StatusRefreshTime = (time + 0.100);
    } else {
        self.StatusRefreshTime = (time + 60);
	}
}

// END status bar

float Impulse2Res (float f) {
    if (f == 1)
        return SBAR_200;
    if (f == 2)
        return SBAR_240;
    if (f == 3)
        return SBAR_300;
    if (f == 4)
        return SBAR_350;
    if (f == 5)
        return SBAR_384;
    if (f == 6)
        return SBAR_400;
    if (f == 7)
        return SBAR_480;
    if (f == 8)
        return SBAR_600;
    if (f == 9)
        return SBAR_768;
    return f;
}


void StatusRes (float res) {
	self.last_impulse = 0;
	if (!res) return;
	self.StatusBarRes = Impulse2Res(res);
	if ( (res == 9) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 1024x768.\n");
	} else if ( (res == 8) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 800x600.\n");
	} else if ( (res == 7) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 640x480.\n");
	} else if ( (res == 6) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 640x400.\n");
	} else if ( (res == 5) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 512x384.\n");
	} else if ( (res == 4) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 320x350.\n");
	} else if ( (res == 3) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 400x300.\n");
	} else if ( (res == 2) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 320x240.\n");
	} else if ( (res == 1) ) {
		sprint (self,PRINT_HIGH,"Status Bar Res set to 320x200.\n");
	}
}

void CenterPrint (entity pl, string s1) {
    //pl.b_b = s1;
    //pl.b_t = string_null;
    //pl.b_n = string_null;
    //pl.CenterPrintTime = (time + 1.500);
    centerprint (pl,s1);
    pl.StatusRefreshTime = (time + 1.500);
}

void CenterPrint2 (entity pl, string s1, string s2) {
    //pl.b_b = s1;
    //pl.b_t = s2;
    //pl.b_n = string_null;
    centerprint (pl,s1,s2);
    pl.StatusRefreshTime = (time + 1.500);
}

void CenterPrint3 (entity pl, string s1, string s2, string s3) {
    //pl.b_b = s1;
    //pl.b_t = s2;
    //pl.b_n = s3;
    centerprint (pl,s1,s2,s3);
    pl.StatusRefreshTime = (time + 1.500);
}

void PrintPlayers (string s1, string s2, string s3) {
    entity te;
    te = player_head;
    while (te) {
        if (s1 != string_null) {
            sprint (te,PRINT_HIGH, s1);
            if (s2 != string_null) {
                sprint (te,PRINT_HIGH, s2);
                if (s3 != string_null) {
                    sprint (te,PRINT_HIGH, s3);
                }
            }
        }
        te = te.nextp;
    }
}

void PrintSpecs (string s1, string s2, string s3) {
    entity te;
    te = spec_head;
    while (te) {
        if (s1 != string_null) {
            sprint (te,PRINT_HIGH, s1);
            if (s2 != string_null) {
                sprint (te,PRINT_HIGH, s2);
                if (s3 != string_null) {
                    sprint (te,PRINT_HIGH, s3);
                }
            }
        }
        te = te.nexts;
    }
}

string Status_GrenTypeToString (float type) {
    if (type == 1)
        return "Grenade";
    if (type == 2)
        return "Concussion grenade";
    if (type == 3)
        return "Nail grenade";
    if (type == 4)
        return "Mirv grenade";
    if (type == 5)
        return "Napalm grenade";
    if (type == 6)
        return "Freeze grenade";
    if (type == 7)
        return "Gas grenade";
    if (type == 8)
        return "EMP grenade";
    if (type == 9)
        return "Flash grenade";
    if (type == 10)
        return "Caltrop canister";
    return "N/A";

}

string Status_TeamNumToTeamString (float tno) {
    if (tno == 1)
        return "blue";
    if (tno == 2)
        return "red";
    if (tno == 3)
        return "yellow";
    if (tno == 4)
        return "green";
    return "observer";
}
