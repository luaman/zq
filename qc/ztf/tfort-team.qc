/*
    tfort-team.qc

    qwtf team functions/definitions

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

float TeamFortress_TeamGetWinner ();

float TeamFortress_TeamGetSecond ();

float PTeamGetScore (float tno);

float TeamFortress_TeamGetNoPlayers (float tno);
//
//void (float tno) TeamFortress_TeamSetColor;

void TeamFortress_TeamIncreaseScore (float tno, float scoretoadd);

float PTeamGetMaxPlayers (float tno);
string PTeamGetColorString (float tno);

float TeamFortress_TeamGetIllegalClasses (float tno);
string TeamFortress_GetSkin (entity p);

float TeamFortress_TeamPutPlayerInTeam () {
    float i;
    float j;
    float k, lowscore;
    float lowest;
    float likely_team;
    i = 1;
    likely_team = (random () * store_obs.cnt);
    likely_team = ceil (likely_team);
    if ( (likely_team == 0) ) {
        likely_team = store_obs.cnt;
    }
    lowest = 33;
    while ( (i < (store_obs.cnt + 1)) ) {
        j = TeamFortress_TeamGetNoPlayers (i);
        if ( (j < lowest) ) {
            if ( (PTeamGetMaxPlayers (i) > j) ) {
                lowest = j;
                lowscore = PTeamGetScore (i);
                likely_team = i;
            }
        }
        if ( (j == lowest) ) {
            k = PTeamGetScore (i);
            if ( (k < lowscore) ) {
                lowscore = k;
                likely_team = i;
            }

        }
        i = (i + 1);
    }
    return ( TeamFortress_TeamSet (likely_team) );
}

float PTeamGetColor (float tno) {
    if ( (tno == 1) ) {
        return ( pteam1.colormap );
    } else if ( (tno == 2) ) {
        return ( pteam2.colormap);
    } else if ( (tno == 3) ) {
        return ( pteam3.colormap );
    } else if ( (tno == 4) ) {
        return ( pteam4.colormap );
    } else if (!tno) {
        return ( store_obs.colormap );
    }
    return ( -1 );
}

float PTeamGetMaxPlayers (float tno) {
    if ( (tno == 1) ) {
        return ( pteam1.maxplayers);
    } else if ( (tno == 2) ) {
        return ( pteam2.maxplayers);
    } else if ( (tno == 3) ) {
        return ( pteam3.maxplayers );
    } else if ( (tno == 4) ) {
        return ( pteam4.maxplayers );
    }
    return ( 0 );
}

#if 0
string GetTeamName (float tno) {
	string st;
	if (self.classname == "player") {
		if (!self.playerclass) {
			return "observe";
		}
	}
	if ( (tno == 1) ) {
		st = infokey (world,"team1");
		if ((st == string_null)) {
			return ( "blue" );
		}
	} else if ( (tno == 2) ) {
		st = infokey (world,"team2");
		if ( (st == string_null) ) {
			return ( "red" );
		}
	} else if ( (tno == 3) ) {
		st = infokey (world,"team3");
		if ( (st == string_null) ) {
			return ( "yell" );
		}
	} else if ( (tno == 4) ) {
		st = infokey (world,"team4");
		if ( (st == string_null) ) {
			return ( "gren" );
		}
	} else {
		st = "\"\"";
	}
	return st;
}
#endif

string GetPTeamName (float tno) {
    string st;
    if ( (tno == 1) ) {
        st = pteam1.netname;
    } else if (tno == 2) {
        st = pteam2.netname;
    } else if (tno == 3) {
        st = pteam3.netname;
    } else if (tno == 4) {
        st = pteam4.netname;
    } else if (tno == 0) {
        st = store_obs.netname;
    }
    return ( st );
}

void SetTeamName (entity p) {
    stuffcmd (p,"team ");
    stuffcmd (p, p.pteam.netname);
    stuffcmd (p,"\n");
}

void SetTeam (entity p) {
    string st;
    float fl;
    st = infokey (p,"bottomcolor");
    fl = stof (st);
    if ( (fl != p.pteam.colormap) ) {
        stuffcmd (p,"color ");
        st = ftos (p.pteam.colormap);
        stuffcmd (p,st);
        stuffcmd (p,"\n");
    }
    SetTeamName (p);
}

void TeamFortress_TeamShowMemberClasses (entity Player) {
    entity e;
    float found;
    found = 0;
    e = player_head;
    while ( e ) {
        if ( (((e.pteam == Player.pteam) || (e.pteam.team == 0)) && (e != Player)) ) {
            if ( (e.model != string_null) ) {
                if ( !found ) {
                    found = 1;
                    sprint (self,PRINT_HIGH,"The other members of your team are:\n");
                }
                sprint (Player,PRINT_HIGH,e.netname);
                sprint (Player,PRINT_HIGH," : ");
                TeamFortress_PrintClassName (Player,e.playerclass,(e.tfstate & 8));
            }
        }
        e = e.nextp;
    }
    if ( !found ) {
        sprint (Player,PRINT_HIGH,"There are no other players on your team.\n");
    }
}

float TeamFortress_TeamSet (float tno) {
    string st;
    float tc;
    entity te;
    if ( (teamplay < 1) ) {
        sprint (self,PRINT_HIGH,"Teamplay is not On, so FortressTeams are inactive.\n");
        return ( 0 );
    }
    if (tno > -6 && tno < 0) {
        if ( (self.pteam.team) ) {
            if (!cb_prematch) {
                Engineer_RemoveBuildings (self);
                te = find (world,classname,"detpack");
                while ( te ) {
                    if ( (te.owner == self) ) {
                        dremove (te);
                        te = world;
                    }
                    te = find (te,classname,"detpack");
                }
                te = find (world,classname,"detpack_timer");
                while ( te ) {
                    if ( (te.owner == self) ) {
                        dremove (te);
                        te = world;
                    }
                    te = find (te,classname,"detpack");
                }
                ClientKill();
            }
        }
        bprint (PRINT_HIGH,self.netname);
        /*
           st = strcat( "[OBS] ",self.netname);
           stuffcmd (self, "name ");
           stuffcmd (self, st);
           stuffcmd (self, "\n");
         */
        if (tno == -1) {
            self.pteam = pteam1;
            bprint (PRINT_HIGH," is Observering Team No. 1.\n");
        } else if (tno == -2) {
            self.pteam = pteam2;
            bprint (PRINT_HIGH," is Observering Team No. 2.\n");
        } else if (tno == -3) {
            self.pteam = pteam3;
            bprint (PRINT_HIGH," is Observering Team No. 3.\n");
        } else if (tno == -4) {
            self.pteam = pteam4;
            bprint (PRINT_HIGH," is Observering Team No. 4.\n");
        } else {
            self.pteam = store_obs;
            bprint (PRINT_HIGH," has joined as an Observer.\n");
        }
        SetTeamName (self);
        self.camdist = 160;
        self.playerclass = CLASS_NONE;
        return(1);
    }
    if ( ((tno > store_obs.cnt) && (store_obs.cnt != 0)) ) {
        sprint (self,PRINT_HIGH,"There can be only ");
        st = ftos (store_obs.cnt);
        sprint (self,PRINT_HIGH,st);
        sprint (self,PRINT_HIGH," teams on this map.\nTry again\n");
        return ( 0 );
    }
    if ( (self.pteam.team == tno) ) {
        sprint (self,PRINT_HIGH,"You are already in that team. Pick another.\n");
        return ( 0 );
    }
    if ( (self.pteam) ) {
        if ( (self.respawn_time > time) ) {
            return ( 0 );
        }
        if (!cb_prematch) {
            Engineer_RemoveBuildings (self);
            te = find (world,classname,"detpack");
            while ( te ) {
                if ( (te.owner == self) ) {
                    if ( (te.weaponmode == 1) ) {
                        TeamFortress_SetSpeed (te.enemy);
                        dremove (te.oldenemy);
                        dremove (te.observer_list);
                    }
                    dremove (te);
                    te = world;
                }
                te = find (te,classname,"detpack");
            }
            te = find (world,classname,"detpack_timer");
            while ( te ) {
                if ( (te.owner == self) ) {
                    dremove (te);
                    te = world;
                }
                te = find (te,classname,"detpack");
            }
            self.playerclass = CLASS_NONE;
            ClientKill();
        }
        if ( TeamFortress_TeamIsCivilian (tno) ) {
            self.nextpc = 11;
        } else {
            self.nextpc = 0;
        }
    }
    if (tno < 0) return (1);
    tc = TeamFortress_TeamGetNoPlayers (tno);
    if (tc >= PTeamGetMaxPlayers (tno) ) {
        sprint (self,PRINT_HIGH,"That team is full. Pick another.\n");
        return ( 0 );
    }
    bprint (PRINT_HIGH,self.netname);
    bprint (PRINT_HIGH," has joined Team No ");
    st = ftos (tno);
    bprint (PRINT_HIGH,st);
    bprint (PRINT_HIGH,".\n");
    //self.playerclass = CLASS_NONE;  fixme   already set?
    if (tno == 1) {
        self.pteam = pteam1;
    } else if (tno == 2) {
        self.pteam = pteam2;
    } else if (tno == 3) {
        self.pteam = pteam3;
    } else if (tno == 4) {
        self.pteam = pteam4;
    }
    TeamFortress_TeamShowMemberClasses (self);
    if ( ((toggleflags & 128) || (toggleflags & 2048)) ) {
        self.frags = self.pteam.real_frags;
    }
    SetTeam (self);
    return ( 1 );
}

#if 0
// mvdsvr
void TeamFortress_CheckTeamCheats () {
	string st;
	string sk;
	float tc;
	if ( (self.immune_to_check > time) ) {
		return ;
	}
	if ( (self.netname == string_null) ) {
		stuffcmd (self,"disconnect\n");
	} else {
		if ( (((self.playerclass) && (self.pteam.team == 0)) && (teamplay )) ) {
			stuffcmd (self,"disconnect\n");
		}
	}
	if ( ((teamplay) && (self.pteam.team == 0)) ) {
		if (self.motd > 65) {
			st = GetTeamName (self.pteam.team);
			if ( (st != infokey (self,"team")) ) {
				SetTeamName (self);
				if ((self.immune_to_check) != floor(time)) {
					self.immune_to_check = (floor(time) + 2);
				} else {
					bprint (PRINT_MEDIUM,self.netname," has been kicked for changing team.\n");
					sprint (self,PRINT_HIGH,"You have been kicked for changing your team. Don't do it.\n");
					stuffcmd (self,"disconnect\n");
					return ;
				}
			}
			st = infokey (self,"bottomcolor");
			tc = stof (st);
			if ( (tc != (TeamFortress_TeamGetColor (self.pteam.team) - 1)) ) {
				stuffcmd (self,"color ");
				tc = (TeamFortress_TeamGetColor (self.pteam.team) - 1);
				st = ftos (tc);
				stuffcmd (self,st);
				stuffcmd (self,"\n");
				if ((self.immune_to_check) != floor(time)) {
					self.immune_to_check = (floor(time) + 2);
				}
			}
		}
	}
	if (tfstrike) {
		if ( ((self.pteam.team > 0) && (teamplay) && (self.playerclass) )) {
			st = infokey (self,"topcolor");
			tc = stof (st);
			if (self.ammo_detpack) {
				if ( tc ) {
					stuffcmd (self,"topcolor 0\n");
					if ((self.immune_to_check) != floor(time)) {
						self.immune_to_check = (floor(time) + 2);
					} else {
						bprint (PRINT_MEDIUM,self.netname," has been kicked for changing top color.\n");
						sprint (self,PRINT_HIGH,"You have been kicked for changing your top color. Don't do it.\n");
						stuffcmd (self,"disconnect\n");
						return ;
					}
				}
			} else {
				if(self.pteam.team == 2  ) {
					if ( (self.playerclass == CLASS_SPY) && (self.undercover_team != 0) ) return;
					if ( (tc != (TeamFortress_GetColor (self.pteam.team) - 1)) ) {
						stuffcmd (self,"topcolor ");
						tc = (TeamFortress_GetColor (self.team_no) - 1);
						st = ftos (tc);
						stuffcmd (self,st);
						stuffcmd (self,"\n");
						if ((self.immune_to_check) != floor(time)) {
							self.immune_to_check = (floor(time) + 2);
						} else {
							bprint (PRINT_MEDIUM,self.netname," has been kicked for changing top color.\n");
							sprint (self,PRINT_HIGH,"You have been kicked for changing your top color. Don't do it.\n");
							stuffcmd (self,"disconnect\n");
							return ;
						}
					}
				}
			}
		}
	}
	if ( ((self.team_no > 0) && (teamplay)) ) {
		st = infokey (self,"bottomcolor");
		tc = stof (st);
		if ( ((self.playerclass == CLASS_SPY) && (self.undercover_team != 0)) ) {
			if ( ((TeamFortress_GetColor (self.undercover_team) - 1) != tc) ) {
				stuffcmd (self,"color ");
				tc = (TeamFortress_GetColor (self.undercover_team) - 1);
				st = ftos (tc);
				stuffcmd (self,st);
				stuffcmd (self,"\n");
				if ((self.immune_to_check) != floor(time)) {
					self.immune_to_check = (floor(time) + 2);
				} else {
					bprint (PRINT_MEDIUM,self.netname," has been kicked for changing color.\n");
					sprint (self,PRINT_HIGH,"You have been kicked for changing your pants color. Don't do it.\n");
					stuffcmd (self,"disconnect\n");
					return ;
				}
			}
		} else {
			if ( (tc != (TeamFortress_TeamGetColor (self.team_no) - 1)) ) {
				stuffcmd (self,"color ");
				tc = (TeamFortress_TeamGetColor (self.team_no) - 1);
				st = ftos (tc);
				stuffcmd (self,st);
				stuffcmd (self,"\n");
				if ((self.immune_to_check) != floor(time)) {
					self.immune_to_check = (floor(time) + 2);
				} else {
					bprint (PRINT_MEDIUM,self.netname," has been kicked for changing color.\n");
					sprint (self,PRINT_HIGH,"You have been kicked for changing your pants color. Don't do it.\n");
					stuffcmd (self,"disconnect\n");
					return ;
				}
			}
		}
		if ( (self.playerclass) ) {
			st = infokey (self,"skin");
			tc = 0;
			sk = TeamFortress_GetSkin (self);
			if ( (st != sk) ) {
				TeamFortress_SetSkin (self);
				if ((self.immune_to_check) != floor(time)) {
					self.immune_to_check = (floor(time) + 2);
				} else {
					bprint (PRINT_MEDIUM,self.netname," has been kicked for changing skin.\n");
					sprint (self,PRINT_HIGH,"You have been kicked for changing your skin. Don't do it.\n");
					stuffcmd (self,"disconnect\n");
					return;
				}
			}
			if (tc == CLASS_SPY) {
				self.playerclass = CLASS_SPY;
			}
		}
		st = GetTeamName (self.team_no);
		if ( (st != infokey (self,"team")) ) {
			SetTeamName (self);
			if ((self.immune_to_check) != floor(time)) {
				self.immune_to_check = (floor(time) + 2);
			} else {
				bprint (PRINT_MEDIUM,self.netname," has been kicked for changing team.\n");
				sprint (self,PRINT_HIGH,"You have been kicked for changing your team. Don't do it.\n");
				stuffcmd (self,"disconnect\n");
				return ;
			}
		}
	}
}
#endif

void TeamFortress_TeamIncreaseScore (float tno, float scoretoadd) {
    entity e;
    if ( ((tno == 0) || (scoretoadd == 0)) ) {
        return ;
    }
    if ( (tno == 1) ) {
        pteam1.frags = (pteam1.frags + scoretoadd);
    }
    if ( (tno == 2) ) {
        pteam2.frags = (pteam2.frags + scoretoadd);
    }
    if ( (tno == 3) ) {
        pteam3.frags = (pteam3.frags + scoretoadd);
    }
    if ( (tno == 4) ) {
        pteam4.frags = (pteam4.frags + scoretoadd);
    }
    if ( ((toggleflags & 128) || (toggleflags & 2048)) ) {
        e = player_head;
        while ( e ) {
            stuffcmd(e, "team");
            stuffcmd(e, ftos(tno));
            stuffcmd(e, "_score ");
            stuffcmd(e, ftos(scoretoadd));
            stuffcmd(e, "\n");
            if ( (e.pteam.team == tno) ) {
                e.frags = e.pteam.frags;
            }
            e = e.nextp;
        }
    }
}

float PTeamGetScore (float tno) {
    if ( (tno == 1) ) {
        return ( pteam1.frags);
    }
    if ( (tno == 2) ) {
        return ( pteam2.frags );
    }
    if ( (tno == 3) ) {
        return ( pteam3.frags );
    }
    if ( (tno == 4) ) {
        return ( pteam4.frags );
    }
    return ( 0 );
}

float PTeamGetScoreFrags (float tno) {
    if ( ((toggleflags & 128) || (toggleflags & 2048)) ) {
        PTeamGetScore (tno);
    } else {
        if ( (tno == 1) ) {
            return ( pteam1.real_frags );
        }
        if ( (tno == 2) ) {
            return ( pteam2.real_frags );
        }
        if ( (tno == 3) ) {
            return ( pteam3.real_frags );
        }
        if ( (tno == 4) ) {
            return ( pteam4.real_frags );
        }
    }
    return ( 0 );
}

float TeamFortress_TeamGetNoPlayers (float tno) {
    float size_team;
    entity search;
    search = player_head;
    while ( (search != world) ) {
        if ( (search.pteam.team == tno) ) {
            size_team = (size_team + 1);
        }
        search = search.nextp;
    }
    if ( (tno == 0) ) {
        search = find (world,classname,"observer");
        while ( (search != world) ) {
            if ( (search.pteam.team == tno) ) {
                size_team = (size_team + 1);
            }
            search = find (search,classname,"observer");
        }
    }
    return ( size_team );
}

float TeamFortress_GetNoPlayersClass (float tno) {
    float size_team;
    entity search;
    search = player_head;
    while ( (search != world) ) {
        if ( (search.pteam.team == tno) ) {
            if (search.playerclass && !search.deadflag) {
                size_team = (size_team + 1);
            }
        }
        search = search.nextp;
    }
    return ( size_team );
}

float TeamFortress_NoActiveTeams () {
    float no_teams;
    float i;
    float p;
    i = 1;

    while (( i <= store_obs.cnt) ) {
        p = TeamFortress_GetNoPlayersClass(i);
        if (p > 0) {
            no_teams = no_teams + 1;
        }
        i = i + 1;
    }
    return(no_teams);
}

float TeamFortress_NoTeams () {
    float no_teams;
    float i;
    float p;
    i = 1;

    while (( i <= store_obs.cnt) ) {
        p = TeamFortress_TeamGetNoPlayers(i);
        if (p > 0) {
            no_teams = no_teams + 1;
        }
        i = i + 1;
    }
    return(no_teams);
}

float TeamFortress_GetNoPlayers () {
    float nump;
    entity search;
    search = player_head;
    while ( (search != world) ) {
        if ( (search.netname != string_null) ) {
            nump = (nump + 1);
        }
        search = search.nextp;
    }
    return ( nump );
}

float TeamFortress_TeamGetWinner () {
    float i;
    float j;
    float highest;
    float highestteam;
    i = 1;
    highest = 0;
    highestteam = 0;
    while ( (i <= store_obs.cnt) ) {
        j = PTeamGetScoreFrags (i);
        if ( (j > highest) ) {
            highest = j;
            highestteam = i;
        }
        i = (i + 1);
    }
    return ( highestteam );
}

float TeamFortress_TeamGetSecond () {
    float i;
    float j;
    float highest;
    float highestteam;
    float secondteam;
    float second;
    i = 1;
    highestteam = TeamFortress_TeamGetWinner ();
    highest = PTeamGetScoreFrags (highestteam);
    secondteam = 0;
    second = 0;
    while ( (i <= store_obs.cnt) ) {
        j = PTeamGetScoreFrags (i);
        if ( ((j < highest) && (j > second)) ) {
            second = j;
            secondteam = i;
        }
        i = (i + 1);
    }
    return ( secondteam );
}

float TeamFortress_CheckDraw () {
    float i;
    float j;
    float score;
    float score2;
    float result;
    float no_teams;
    i = 1;
    score2 = 0;
    result = 0;
    no_teams = TeamFortress_NoActiveTeams();
    while ( (i <= no_teams ) ) {
        j = PTeamGetScore (i);
        if ( ( i > 1 )) {
            score2 = j;
            if (( score != score2 )) {
                result = 0;
            } else {
                result = 1;
            }
        } else {
            score = j;

        }
        i = (i + 1);
    }
    return ( result );
}

void TeamFortress_TeamShowScores (float all) {
    string st;
    float i;
    float j;
    i = 1;
    if ( (all == 2) ) {
        while ( (i <= store_obs.cnt) ) {
            if ( (PTeamGetColor (i) > 0) ) {
                j = PTeamGetScore (i);
                st = PTeamGetColorString (i);
                bprint (PRINT_HIGH,st);
                bprint (PRINT_HIGH,": ");
                st = ftos (j);
                bprint (PRINT_HIGH,st);
                bprint (PRINT_HIGH," ");
            }
            i = (i + 1);
        }
        bprint (PRINT_HIGH,"\n");
        return ;
    }
    while ( (i <= store_obs.cnt) ) {
        if ( (PTeamGetColor (i) > 0) ) {
            if ( all ) {
                bprint (PRINT_HIGH,"Team ");
            } else {
                sprint (self,PRINT_HIGH,"Team ");
            }
            st = ftos (i);
            if ( all ) {
                bprint (PRINT_HIGH,st);
            } else {
                sprint (self,PRINT_HIGH,st);
            }
            if ( all ) {
                bprint (PRINT_HIGH," (");
            } else {
                sprint (self,PRINT_HIGH," (");
            }
            st = PTeamGetColorString (i);
            if ( all ) {
                bprint (PRINT_HIGH,st);
            } else {
                sprint (self,PRINT_HIGH,st);
            }
            if ( all ) {
                bprint (PRINT_HIGH,") : ");
            } else {
                sprint (self,PRINT_HIGH,") : ");
            }
            j = PTeamGetScore (i);
            st = ftos (j);
            if ( all ) {
                bprint (PRINT_HIGH,st);
            } else {
                sprint (self,PRINT_HIGH,st);
            }
            if ( all ) {
                bprint (PRINT_HIGH,"\n");
            } else {
                sprint (self,PRINT_HIGH,"\n");
            }
        }
        i = (i + 1);
    }
}
string PTeamGetColorString (float tno) {
    float col;
    col = PTeamGetColor (tno);
    if ( (col == 0) ) {
        return ( "White" );
    }
    if ( (col == 1) ) {
        return ( "Brown" );
    }
    if ( (col == 2) ) {
        return ( "Blue" );
    }
    if ( (col == 3) ) {
        return ( "Green" );
    }
    if ( (col == 4) ) {
        return ( "Red" );
    }
    if ( (col == 5) ) {
        return ( "Tan" );
    }
    if ( (col == 6) ) {
        return ( "Pink" );
    }
    if ( (col == 7) ) {
        return ( "Orange" );
    }
    if ( (col == 8) ) {
        return ( "Purple" );
    }
    if ( (col == 9) ) {
        return ( "DarkPurple" );
    }
    if ( (col == 10) ) {
        return ( "Grey" );
    }
    if ( (col == 11) ) {
        return ( "DarkGreen" );
    }
    if ( (col == 12) ) {
        return ( "Yellow" );
    }
    return ( "DarkBlue" );
}

void TeamFortress_StatusQuery () {
    float ft;
    string st;
    sprint (self,PRINT_HIGH,"players per team: ");
    ft = TeamFortress_TeamGetNoPlayers (1);
    st = ftos (ft);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH,"  ");
    ft = TeamFortress_TeamGetNoPlayers (2);
    st = ftos (ft);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH,"  ");
    ft = TeamFortress_TeamGetNoPlayers (3);
    st = ftos (ft);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH,"  ");
    ft = TeamFortress_TeamGetNoPlayers (4);
    st = ftos (ft);
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH,"\n");
    st = ftos (teamplay);
    sprint (self,PRINT_HIGH,"Teamplay is ");
    sprint (self,PRINT_HIGH,st);
    sprint (self,PRINT_HIGH,"\n");
}

float TeamFortress_TeamGetIllegalClasses (float tno) {
    entity te;
    te = find (world,classname,"info_tfdetect");
    if ( (te != world) ) {
        if ( (tno == 1) ) {
            return ( te.maxammo_shells );
        }
        if ( (tno == 2) ) {
            return ( te.maxammo_nails );
        }
        if ( (tno == 3) ) {
            return ( te.maxammo_rockets );
        }
        if ( (tno == 4) ) {
            return ( te.maxammo_cells );
        }
    }
    return ( 0 );
}

float TeamFortress_TeamIsCivilian (float tno) {
    if ( (tno == 1) ) {
        if ( (store_obs.maxammo_shells & 1) ) {
            return ( 1 );
        }
    } else {
        if ( (tno == 2) ) {
            if ( (store_obs.maxammo_shells & 2) ) {
                return ( 1 );
            }
        } else {
            if ( (tno == 3) ) {
                if ( (store_obs.maxammo_shells & 4) ) {
                    return ( 1 );
                }
            } else {
                if ( (store_obs.maxammo_shells & 8) ) {
                    return ( 1 );
                }
            }
        }
    }
    return ( 0 );
}

float CheckClassAvailable (float tno) {
    float pc;
    pc = 1;

    while (pc < 10) {
        if (!ClassIsRestricted(tno,pc)) {
            return(1);
        }
        pc = pc + 1;
    }
    return(0);
}

float ClassIsRestricted (float tno, float pc) {
	float num;
	float pmax;
	entity te;
	string st;
	if ( (tno == 0) ) {
		return ( 0 );
	}
	if ( (pc == 1) ) {
		st = infokey (world,"cr_scout");
		pmax = stof (st);
	} else if ( (pc == 2) ) {
		st = infokey (world,"cr_sniper");
		pmax = stof (st);
	} else if ( (pc == 3) ) {
		st = infokey (world,"cr_soldier");
		pmax = stof (st);
	} else if ( (pc == 4) ) {
		st = infokey (world,"cr_demoman");
		pmax = stof (st);
	} else if ( (pc == 5) ) {
		st = infokey (world,"cr_medic");
		pmax = stof (st);
	} else if ( (pc == 6) ) {
		st = infokey (world,"cr_hwguy");
		pmax = stof (st);
	} else if ( (pc == 7) ) {
		st = infokey (world,"cr_pyro");
		pmax = stof (st);
	} else if ( (pc == 8) ) {
		st = infokey (world,"cr_spy");
		pmax = stof (st);
	} else if ( (pc == 9) ) {
		st = infokey (world,"cr_engineer");
		pmax = stof (st);
	} else if ( (pc == 10) ) {
		st = infokey (world,"cr_random");
		pmax = stof (st);
	}

    if (!pmax) {
        st = infokey (world,"highlander");
        if ( (st == "on") ) {
            pmax = 1;
        }
    }
    if ( (pmax == -1) ) {
        return ( 1 );
    }
    if ( (pmax > 0) ) {
        num = 0;
        te = player_head;
        while ( te ) {
            if ( (te.pteam.team == tno) ) {
                if ( (pc == 10) ) {
                    if ( (te.tfstate & 8) ) {
                        num = (num + 1);
                    }
                } else {
                    if ( ((te.playerclass == pc) || (te.nextpc == pc)) ) {
                        if ( !(te.tfstate & 8) ) {
                            num = (num + 1);
                        }
                    }
                }
            }
            te = te.nextp;
        }
        if ( (num >= pmax) ) {
            return ( 1 );
        }
    }
    return ( 0 );
}

void teamsprint (float tno, entity ignore, string st) {
    entity te;
    if ( (tno == 0) ) {
        return ;
    }
    te = player_head;
    while ( te ) {
        if ( ((te.pteam.team == tno) && (te != ignore)) ) {
            sprint (te,PRINT_HIGH,st);
        }
        te = te.nextp;
    }
}

#if 0
entity TeamFortress_TopFragger () {
	entity te;
	float j;
	entity highest;
	te = player_head;
	while (te != world) {
		j = te.real_frags;
		if (j > highest.real_frags){
			highest = te;
		}
		te = te.nextp;
	}
	return ( highest );
};
#endif
