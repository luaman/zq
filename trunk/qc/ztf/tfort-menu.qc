
void TeamFortress_SpyChangeSkin (float class);

void TeamFortress_SpyChangeColor (float teamno);

void TeamFortress_SpyFeignDeath (float issilent);

void Spy_RemoveDisguise (entity spy);

void DestroyBuilding (entity eng, string bld);

void TeamFortress_Build (float objtobuild);

void lvl2_sentry_stand ();

void lvl3_sentry_stand ();

void lvl2_oldsentry_stand ();

void lvl3_oldsentry_stand ();

float TeamFortress_TeamSet (float tno);

float TeamFortress_TeamPutPlayerInTeam ();

float TeamFortress_TeamIsCivilian (float tno);

float TeamFortress_GetNoPlayers ();

void TeamFortress_ChangeClass (float inp);

void TeamFortress_SetSkin (entity p);

void TeamFortress_DropAmmo (float type, float ammo);

void TF_T_Damage (entity targ, entity inflictor, entity attacker, float damage, float T_flags, float T_AttackType);

void W_SetCurrentAmmo ();

void bound_other_ammo (entity p);

float anglemod (float v);

void teamsprint (float tno, entity ignore, string st);

void DisplayMenu (float menu_no);

void Menu_Team ();

void Menu_Class ();

void Menu_Drop ();

void Menu_Intro ();

void Menu_ClassHelp ();

void Menu_ClassHelp2 ();

void Menu_StuffClassHelp ();

void Menu_ClassHelp_Input (float inp);

void Menu_RepeatHelp ();

void Menu_Speech ();

void Menu_Speech_Defensive ();

void Menu_Speech_Offensive ();

void Menu_Speech_General ();

void Menu_Speech_Input (float inp);

void Menu_Speech_Def_Input (float inp);

void Menu_Speech_Off_Input (float inp);

void Menu_Speech_Gen_Input (float inp);

void Menu_Upgrades ();

void Menu_Upgrade_Weapons ();

void Menu_Upgrade_Armor ();

void Menu_Upgrade_Movement ();

void Menu_Upgrade_Other ();

void Menu_Upgrades_Input (float inp);

void Menu_Upgrade_Wea_Input (float inp);

void Menu_Upgrade_Arm_Input (float inp);

void Menu_Upgrade_Mov_Input (float inp);

void Menu_Upgrade_Oth_Input (float inp);

void Menu_Spy ();

void Menu_Spy_Skin ();

void Menu_Spy_Color ();

void Menu_Spy_Input (float inp);

void Menu_Spy_Skin_Input (float inp);

void Menu_Spy_Color_Input (float inp);

void Menu_Engineer ();

void Menu_EngineerFix_Dispenser ();

void Menu_EngineerFix_SentryGun ();

void Menu_Engineer_Input (float inp);

void Menu_EngineerFix_Dispenser_Input (float inp);

void Menu_EngineerFix_SentryGun_Input (float inp);

void Menu_Dispenser ();

void Menu_Dispenser_Input (float inp);

void CenterPrint (entity pl, string s1);

void CenterPrint2 (entity pl, string s1, string s2);

void ResetMenu () {
    if ( (self.StatusBarSize == 0) ) {
        CenterPrint (self,"\n");
    } else {
        self.StatusRefreshTime = (time + 0.100);
    }
    self.menu_count = 25;
    self.current_menu = 1;
}

void Player_Menu () {
    if ( (self.menu_count > 25) ) {
        self.menu_count = 0;
    } else {
        self.menu_count = (self.menu_count + 1);
        return ;
    }
    if ( (self.current_menu == 5) ) {
        Menu_Intro ();
        if ( (self.menu_displaytime > 6) ) {
            self.current_menu = 1;
        } else {
            self.menu_displaytime = (self.menu_displaytime + 1);
        }
    } else if ( (self.current_menu == 6) ) {
            Menu_ClassHelp ();
            if ( (self.menu_displaytime > 8) ) {
                Menu_StuffClassHelp ();
                self.current_menu = 1;
            } else {
				self.menu_displaytime = (self.menu_displaytime + 1);
			}
	} else if ( (self.current_menu == 7) ) {
		Menu_ClassHelp2 ();
		if ( (self.menu_displaytime > 5) ) {
			Menu_StuffClassHelp ();
			self.current_menu = 1;
		} else {
			self.menu_displaytime = (self.menu_displaytime + 1);
		}
	} else if ( (self.current_menu == 4) ) {
		Menu_Drop ();
	} else if ( (self.current_menu == 12) ) {
		Menu_Spy ();
	} else if ( (self.current_menu == 13) ) {
		Menu_Spy_Skin ();
	} else if ( (self.current_menu == 14) ) {
		Menu_Spy_Color ();
	} else if ( (self.current_menu == 15) ) {
		Menu_Engineer ();
	} else if ( (self.current_menu == 16) ) {
		Menu_EngineerFix_Dispenser ();
	} else if ( (self.current_menu == 17) ) {
		Menu_EngineerFix_SentryGun ();
	} else if ( (self.current_menu == 19) ) {
		Menu_Dispenser ();
	} else if ( (self.current_menu == 8) ) {
		Menu_RepeatHelp ();
		self.current_menu = 1;
	} else if ( (self.current_menu == 20) ) {
		Menu_Class ();
	} else if ( (self.current_menu == 2) ) {
		Menu_Team ();
	} else if ( ((self.pteam == world) && teamplay) ) {
		if (round_over >= 2) {
			return;
		}
		self.current_menu = 2;
		Menu_Team ();
	} else if ((self.playerclass == CLASS_NONE) && (self.pteam != store_obs)) {
		if (round_active && !modetype & 64) {
			return;
		}
		if ( TeamFortress_TeamIsCivilian (self.pteam.team) ) {
			PutClientInServer();
			return;
		}
		self.current_menu = 3;
		Menu_Class ();
	} else if ( (self.current_menu == 21) ) {
		Menu_Speech ();
	} else if ( (self.current_menu == 22) ) {
		Menu_Speech_Defensive ();
	} else if ( (self.current_menu == 23) ) {
		Menu_Speech_Offensive ();
	} else if ( (self.current_menu == 24) ) {
		Menu_Speech_General ();
	} else if ( (self.current_menu == 25) ) {
			Menu_Upgrades ();
	} else if ( (self.current_menu == 26) ) {
		Menu_Upgrade_Weapons ();
	} else if ( (self.current_menu == 27) ) {
		Menu_Upgrade_Armor ();
	} else if ( (self.current_menu == 28) ) {
		Menu_Upgrade_Movement ();
	} else if ( (self.current_menu == 29) ) {
		Menu_Upgrade_Other ();
	} else {
		self.current_menu = 0;
	}
}

void DisplayMenu (float menu_no) {
    self.current_menu = menu_no;
    if ( (menu_no == 2) ) {
        Menu_Team ();
    } else {
        if ( (menu_no == 3) ) {
            Menu_Class ();
        }
    }
}

void Menu_Team () {
    if ( ((toggleflags & 64) && teamplay) ) {
        if ( TeamFortress_TeamPutPlayerInTeam () ) {
            ResetMenu ();
            return ;
        }
    }
    if ( (team_menu_string != string_null) ) {
        CenterPrint (self,team_menu_string);
        return ;
    }
    if ( (ctfmap == 1) ) {
        CenterPrint (self,"žžž Choose Your Team žžž\n\n“‘ Blue Team  \n”‘ Red Team   \n\n\n");
    } else {
        if ( (store_obs.cnt == 2) ) {
            if (modetype & 4) {
                CenterPrint (self,"žžž Choose Your Team žžž\n\n“‘ Counter Terrorists \n”‘ Terrorists         \n\n\n—‘ Auto Team          \n˜‘ Observe            ");
            } else {
                CenterPrint (self,"žžž Choose Your Team žžž\n\n“‘ Team One  \n”‘ Team Two  \n\n\n—‘ Auto Team \n˜‘ Observe   ");
            }
        } else {
            if (modetype & 1) {
                CenterPrint (self,"žžž Choose Your Team žžž\n\n“‘ Team One  \n”‘ Team Two  \n•‘ Team Three\n–‘ Team Four \n—‘ Auto Team \n˜‘ Observe T1\n™‘  Observe T2\nš‘ Observe T3\n›‘ Observe T4\n");
            } else {
                CenterPrint (self,"žžž Choose Your Team žžž\n\n“‘ Team One  \n”‘ Team Two  \n•‘ Team Three\n–‘ Team Four \n—‘ Auto Team \n˜‘ Observe   \n");
            }
        }
    }
}

void Menu_Team_Input (float inp) {
    if ((inp  > 5) && (inp < 10)) {
        if (inp <= 5 + store_obs.cnt) {
            if (modetype & 1) {
                TeamFortress_TeamSet ((inp * -1) + 5);
                self.current_menu = 0;
                Menu_StuffClassHelp();
                Menu_ClassHelp();
                self.impulse = 0;
                return;
            }
            TeamFortress_TeamSet (-5);
            self.current_menu = 0;
            Menu_StuffClassHelp();
            Menu_ClassHelp();
            self.impulse = 0;
            return;
        }

    } else if ( (inp == 5) ) {
        TeamFortress_TeamPutPlayerInTeam ();
    } else {
        if ( ((inp <= store_obs.cnt) && (inp > 0)) ) {
            TeamFortress_TeamSet (inp);
        } else {
            if ( ((store_obs.cnt == 0) && (inp <= 4)) ) {
                TeamFortress_TeamSet (inp);
            }
        }
    }
    ResetMenu ();
    self.impulse = 0;
}

void Menu_Class () {
    entity AD;
    AD = find (world,classname,"info_tfdetect");
    if ( AD ) {
        if ( (self.pteam.team == 1) ) {
            if ( (AD.noise1 != string_null) ) {
                CenterPrint (self,AD.noise1);
                return ;
            }
        } else {
            if ( (self.pteam.team == 2) ) {
                if ( (AD.noise2 != string_null) ) {
                    CenterPrint (self,AD.noise2);
                    return ;
                }
            } else {
                if ( (self.pteam.team  == 3) ) {
                    if ( (AD.noise3 != string_null) ) {
                        CenterPrint (self,AD.noise3);
                        return ;
                    }
                } else {
                    if ( (self.pteam.team  == 4) ) {
                        if ( (AD.noise4 != string_null) ) {
                            CenterPrint (self,AD.noise4);
                            return ;
                        }
                    }
                }
            }
        }
    }
    if ( TeamFortress_TeamIsCivilian (self.pteam.team ) ) {
        if (( classtype & 64 )) {
            CenterPrint (self,"Your team can only be Quake Soldiers.\n");
        } else {
            CenterPrint (self,"Your team can only be Civilians.\n");
        }
    } else {
        if (classtype & 1) {
            CenterPrint (self,"žžž Choose Your Class žžž\n\n“‘ Scout     \n”‘ Technician\n•‘ Soldier   \n–‘ Demoman   \n—‘ Medic     \n˜‘ HWGuy     \n™‘ Pyro      \nš‘ Spy       \n›‘ Engineer  \n’‘ RandomPC  \n");
        } else {
            CenterPrint (self,"žžž Choose Your Class žžž\n\n“‘ Scout   \n”‘ Sniper  \n•‘ Soldier \n–‘ Demoman \n—‘ Medic   \n˜‘ HWGuy   \n™‘ Pyro    \nš‘ Spy     \n›‘ Engineer\n’‘ RandomPC\n");
        }
    }
}

void Menu_Class_Input (float inp) {
	dprint("Entering Menu_Class_Input\n");
    float new_class;
    string st;
    if ( ((inp > 11) || (inp < 1)) ) {
        return ;
    }
    if ( (self.playerclass) ) {
        new_class = 1;
    }
    TeamFortress_ChangeClass (inp);
    self.impulse = 0;
    ResetMenu ();
    if ( ((self.playerclass) && (new_class != 1) && (self.playerclass != CLASS_CIVILIAN)) ) {
        st = infokey (self,"ch");
        if ( (st == string_null) ) {
            st = infokey (self,"classhelp");
        }
        if ( (st != "off") && (!(self.tfkey & 1)) ) {
            self.current_menu = 6;
        } else {
            self.current_menu = 1;
        }
    }
    self.menu_displaytime = 0;
	dprint("Leaving Menu_Class_Input\n");
}

void Menu_Drop () {
    if ( (self.playerclass == CLASS_ENGINEER) ) {
        CenterPrint (self,"\nDrop or Make Ammo:            \n“‘ Shells                    \n”‘ Nails                     \n•‘ Rockets                   \n–‘ Cells                     \n—‘ Grenade 1                 \n˜‘ Grenade 2                 \n™‘ Nothing                   \n");
    } else {
        CenterPrint (self,"\nDrop Ammo:                    \n“‘ Shells                    \n”‘ Nails                     \n•‘ Rockets                   \n–‘ Cells                     \n—‘ Grenade 1                 \n˜‘ Grenade 2                 \n™‘ Nothing                   \n");
    }
}

void Menu_RepeatHelp () {
    CenterPrint (self,"Press › to see this help again\n");
}

void Menu_Drop_Input (float inp) {
    if ( ((inp > 0) && (inp < 7)) ) {
        TeamFortress_DropAmmo (inp, 10);
    }

    ResetMenu ();
    self.impulse = 0;
}

void Menu_Input (float inp) {
    if ( (self.current_menu == 2) ) {
        Menu_Team_Input (inp);
    } else {
        if ( ((self.current_menu == 3) || (self.current_menu == 20)) ) {
            Menu_Class_Input (inp);
        } else {
            if ( (self.current_menu == 4) ) {
                Menu_Drop_Input (inp);
            } else {
                if ( (self.current_menu == 12) ) {
                    Menu_Spy_Input (inp);
                } else {
                    if ( (self.current_menu == 13) ) {
                        Menu_Spy_Skin_Input (inp);
                    } else {
                        if ( (self.current_menu == 14) ) {
                            Menu_Spy_Color_Input (inp);
                        } else {
                            if ( (self.current_menu == 15) ) {
                                Menu_Engineer_Input (inp);
                            } else {
                                if ( (self.current_menu == 16) ) {
                                    Menu_EngineerFix_Dispenser_Input (inp);
                                } else {
                                    if ( (self.current_menu == 17) ) {
                                        Menu_EngineerFix_SentryGun_Input (inp);
                                    } else {
                                        if ( (self.current_menu == 19) ) {
                                            Menu_Dispenser_Input (inp);
                                        } else {
                                            if ( (self.current_menu == 6) ) {
                                                Menu_ClassHelp_Input (inp);
                                            } else {
                                                if ( (self.current_menu == 21) ) {
                                                    Menu_Speech_Input (inp);
                                                } else {
                                                    if ( (self.current_menu == 22) ) {
                                                        Menu_Speech_Def_Input (inp);
                                                    } else {
                                                        if ( (self.current_menu == 23) ) {
                                                            Menu_Speech_Off_Input (inp);
                                                        } else {
                                                            if ( (self.current_menu == 24) ) {
                                                                Menu_Speech_Gen_Input (inp);
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
            }
        }
    }
}

void Menu_Intro () {
    string st1;
    string st2;
    st1 = infokey (world,"motd1");
    if ( (st1 != string_null) ) {
        st2 = infokey (world,"motd2");
        centerprint (self,st1,"\n",st2);
    } else {
        CenterPrint (self,"Welcome to Oz Team Fortress 1.77a\nžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžžŸ\nhttp://quakeworld.nu/forum/\n");
    }
}

void Menu_ClassHelp () {
	if ( (self.menu_displaytime < 5) ) {
		if ( (self.playerclass == CLASS_SCOUT) ) {
			CenterPrint (self,"ÓÃÏÕÔ Details:               \n\n×ÅÁÐÏÎÓ:                     \n”‘ Shotgun                  \n–‘ Nailgun                  \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_SNIPER) ) {
			CenterPrint (self,"ÓÎÉÐÅÒ Details:              \n\n×ÅÁÐÏÎÓ:                     \n”‘ Sniper Rifle/Auto Rifle  \n–‘ Nailgun                  \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_SOLDIER) ) {
			CenterPrint (self,"ÓÏÌÄÉÅÒ Details:             \n\n×ÅÁÐÏÎÓ:                     \n”‘ Shotgun                  \n•‘ Super Shotgun            \n™‘ Rocket Launcher          \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_DEMOMAN) ) {
			CenterPrint (self,"ÄÅÍÏÌÉÔÉÏÎÓ ÍÁÎ Details:     \n\n×ÅÁÐÏÎÓ:                     \n”‘ Shotgun                  \n˜‘ Grenade Launcher         \n™‘ Pipebomb Launcher        \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_MEDIC) ) {
			CenterPrint (self,"ÍÅÄÉÃ Details:               \n\n×ÅÁÐÏÎÓ:                     \n“‘ Medikit/BioWeapon        \n”‘ Shotgun                  \n•‘ Super Shotgun            \n—‘ Super Nailgun            \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_HWGUY) ) {
			CenterPrint (self,"ÈÅÁÖÙ ×ÅÁÐÏÎÓ ÇÕÙ Details:   \n\n×ÅÁÐÏÎÓ:                     \n”‘ Shotgun                  \n•‘ Super Shotgun            \n™‘ Assault Cannon           \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_PYRO) ) {
			if (classtype & 16) {
				CenterPrint (self,"ÐÙÒÏ Details:          \n\n×ÅÁÐÏÎÓ:               \n”‘ Shotgun            \n—‘ Flamethrower       \n™‘ Incendiary Cannon  \n\nPress › for alias help\n");
			} else {
				CenterPrint (self,"ÐÙÒÏ Details:                \n\n×ÅÁÐÏÎÓ:                     \n”‘ Shotgun                  \n—‘ Flamethrower             \n˜‘ Light Incendiary Cannon  \n™‘ Heavy Incendiary Cannon  \n\nPress › for alias help\n");
			}
		} else if ( (self.playerclass == CLASS_SPY) ) {
			CenterPrint (self,"ÓÐÙ Details:                 \n\n×ÅÁÐÏÎÓ:                     \n”‘ Tranquiliser Gun         \n•‘ Super Shotgun            \n–‘ Nailgun                  \n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_ENGINEER) ) {
			CenterPrint (self,"ÅÎÇÉÎÅÅÒ Details:            \n\n×ÅÁÐÏÎÓ:                     \n“‘ Spanner                  \n”‘ RailGun                  \n•‘ Super Shotgun            \n\nPress › for alias help\n");
		} else if ( (!self.playerclass) ) {
			CenterPrint (self,"\n\n\nObserver Details:             \n\nÃÏÍÍÁÎÄÓ:                     \ntracking: toggle tracking mode\ntrack_player: player camera   \ntrack_sentry: sentrygun camera\ntrack_tfgoal: flag camera     \nspecial: camera lock-on       \n");
		}
	} else {
		if ( (self.playerclass == CLASS_SCOUT) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nCaltrops            \nConcussion Grenade  \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nScanner: autoscan,scansound,scane,scanf\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_SNIPER) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nFlash               \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nautozoom : Toggle Rifle Autozooming\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_SOLDIER) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nNail Grenade        \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nNone\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_DEMOMAN) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nMirv Grenade        \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nThe Detpack : +det5,+det20,+det50,+det255\nDetonate Pipebombs : detpipe  \n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_MEDIC) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nConcussion Grenade  \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nNone\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_HWGUY) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nMirv Grenade        \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nNone\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_PYRO) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nNapalm Grenade      \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nNone\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_SPY) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nHallucinogen Grenade\n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nGo Undercover : disguise\nFeign Death : feign, sfeign\n\n\nPress › for alias help\n");
		} else if ( (self.playerclass == CLASS_ENGINEER) ) {
			CenterPrint (self,"ÇÒÅÎÁÄÅÓ:            \nHand Grenade        \nEMP Grenade         \n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:   \nStart Building : build  \n\n\nPress › for alias help\n");
		}
	}
}

void Menu_StuffClassHelp () {
	if ( (self.playerclass == CLASS_SCOUT) ) {
		sprint (self,PRINT_HIGH,"ÓÃÏÕÔ Details:\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   –‘ Nailgun\n");
		sprint (self,PRINT_HIGH,"ÇÒÅÎÁÄÅÓ:\n   Concussion Grenade\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n");
		sprint (self,PRINT_HIGH,"Scanner: autoscan,scansound,scane,scanf\n\n\n");
	} else if ( (self.playerclass == CLASS_SNIPER) ) {
		sprint (self,PRINT_HIGH,"ÓÎÉÐÅÒ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Sniper Rifle/Auto Rifle\n");
		sprint (self,PRINT_HIGH,"–‘ Nailgun\nÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n\n\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n");
		sprint (self,PRINT_HIGH,"  autozoom : Toggle Rifle Autozooming\n\n\n");
	} else if ( (self.playerclass == CLASS_SOLDIER) ) {
		sprint (self,PRINT_HIGH,"ÓÏÌÄÉÅÒ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   •‘ Super Shotgun\n");
		sprint (self,PRINT_HIGH,"   ™‘ Rocket Launcher\nÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   Nail Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   None\n\n\n");
	} else if ( (self.playerclass == CLASS_DEMOMAN) ) {
		sprint (self,PRINT_HIGH,"ÄÅÍÏÌÉÔÉÏÎÓ ÍÁÎ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   ˜‘ Grenade/Pipebomb Launcher\n");
		sprint (self,PRINT_HIGH,"ÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   Mirv Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   The Detpack : +det5,+det20,+det50,+det255\n   Detonate Pipebombs : detpipe\n\n\n");
	} else if ( (self.playerclass == CLASS_MEDIC) ) {
		sprint (self,PRINT_HIGH,"ÍÅÄÉÃ Details:\n\n×ÅÁÐÏÎÓ:\n   “‘ Medikit/BioWeapon\n   ”‘ Shotgun\n   •‘ Super Shotgun\n");
		sprint (self,PRINT_HIGH,"   —‘ Super Nailgun\nÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   Concussion Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   None\n\n\n");
	} else if ( (self.playerclass == CLASS_HWGUY) ) {
		sprint (self,PRINT_HIGH,"ÈÅÁÖÙ ×ÅÁÐÏÎÓ ÇÕÙ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   •‘ Super Shotgun\n");
		sprint (self,PRINT_HIGH,"   ™‘ Assault Cannon\nÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n");
		sprint (self,PRINT_HIGH,"   Mirv Grenade\nÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   None\n\n\n");
	} else if ( (self.playerclass == CLASS_PYRO) ) {
		if (classtype & 16) {
			sprint (self,PRINT_HIGH,"ÐÙÒÏ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   —‘ Flamethrower\n   ™‘ Incendiary Cannon\n");
		} else {
			sprint (self,PRINT_HIGH,"ÐÙÒÏ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Shotgun\n   —‘ Flamethrower\n   ˜‘ Light Incendiary Cannon\n   ™‘ Heavy Incendiary Cannon\n");
		}
		sprint (self,PRINT_HIGH,"ÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   Napalm Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   None\n\n\n");
	} else if ( (self.playerclass == CLASS_SPY) ) {
		sprint (self,PRINT_HIGH,"ÓÐÙ Details:\n\n×ÅÁÐÏÎÓ:\n   ”‘ Tranquiliser Gun\n   •‘ Super Shotgun\n   –‘ Nailgun\n");
		sprint (self,PRINT_HIGH,"ÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   Hallucinogenic Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   Go Undercover : disguise\n   Feign Death : feign, sfeign\n\n\n");
	} else if ( (self.playerclass == CLASS_ENGINEER) ) {
		sprint (self,PRINT_HIGH,"ÅÎÇÉÎÅÅÒ Details:\n\n×ÅÁÐÏÎÓ:\n   “‘ Spanner\n   ”‘ RailGun\n   •‘ Super Shotgun\n");
		sprint (self,PRINT_HIGH,"ÇÒÅÎÁÄÅÓ:\n   Hand Grenade\n   EMP Grenade\n");
		sprint (self,PRINT_HIGH,"ÓÐÅÃÉÁÌ ÃÏÍÍÁÎÄÓ:\n   Start Building : build\n\n\n");
	} else if ( (!self.playerclass) ) {
		sprint (self,PRINT_HIGH,"\n\nObserver Details:\n\n\nÃÏÍÍÁÎÄÓ: \n   tracking:     toggle tracking mode\n   track_player: observe a player\n   track_sentry: observe a sentrygun\n   track_tfgoal: observe a team's flag\n   special:      lock onto and observe an object\n");
	}
}

void Menu_ClassHelp2 () {
    CenterPrint (self,"Commands:\ninv       : Show inventory \n+gren1    : Throw grenade 1\n+gren2    : Throw Grenade 2\nreload    : Force a reload \ndropammo  : drop some ammo \n\n");
}

void Menu_ClassHelp_Input (float inp) {
    if (TeamFortress_TeamIsCivilian(self.pteam.team)) {
        return;
    }
    if ( (inp == 9) ) {
        Menu_ClassHelp2 ();
        self.menu_count = 25;
        self.current_menu = 7;
        self.menu_displaytime = 0;
        self.impulse = 0;
    }
}

void Menu_Speech_Sound (float type, float num) {
    string snd;
    entity te;
    if (type == 1) {
        if (num == 1) {
            snd = "speech/def_incflag1.wav";
        } else if (num == 2) {
            snd = "speech/def_flagdanger.wav";
        } else if (num == 3) {
            snd = "speech/def_flag.wav";
        } else if (num == 4) {
            snd = "speech/def_fixsenty.wav";
        }
    }
    if (type == 2) {
        if (num == 1) {
            snd = "speech/off_flaghave.wav";
        } else if (num == 2) {
            snd = "speech/off_imatt.wav";
        } else if (num == 3) {
            snd = "speech/off_flagtake.wav";
        } else if (num == 4) {
            snd = "speech/off_coverme.wav";
        } else if (num == 5) {
            snd = "speech/off_attsentry.wav";
        }
    }
    if (type == 3) {
        if (num == 1) {
            snd = "speech/saveme1.wav";
        } else if (num == 2) {
            snd = "speech/engineer2.wav";
        } else if (num == 3) {
            snd = "speech/gen_noprob.wav";
        } else if (num == 4) {
            snd = "speech/gen_gogogo.wav";
        } else if (num == 5) {
            snd = "speech/gen_giveammo.wav";
        } else if (num == 6) {
            snd = "speech/gen_movepls.wav";
        }
    }
    te = player_head;
    while ( te ) {
        if ( (te.pteam == self.pteam) ) {
            if (te.pteam.last_sound < time ) {
                stuffcmd(te,"play ");
                stuffcmd(te,snd);
                stuffcmd(te,"\n");
            }
        }
        te = te.nextp;
    }
    self.pteam.last_sound = time + 2;
}

void Menu_Speech_Defensive () {
    CenterPrint (self,"žžž Defensive Commands: žžž\n\n“‘ Incoming Flag!\n”‘ Flag in Danger\n•‘ Defend Flag!  \n–‘ Repair Sentry \n’‘ Cancel        \n");
}

void Menu_Speech_Offensive () {
    CenterPrint (self,"žžž Offensive Commands: žžž\n\n“‘ I Have the Flag!\n”‘ I'm Attacking   \n•‘ Take the Flag   \n–‘ Cover me        \n—‘ Attack Sentry   \n’‘ Cancel          \n");
}

void Menu_Speech_General () {
    CenterPrint (self,"žžž General Commands: žžž\n\n“‘ Save Me!     \n”‘ Need Engineer\n•‘ No Problem   \n–‘ GO GO GO!    \n—‘ Give me ammo \n˜‘ Move Please  \n’‘ Cancel       \n");
}

void Menu_Speech_Def_Input (float inp) {
    if ((inp == 10) || (self.pteam.last_sound > time )) {
        ResetMenu ();
        return ;
    } else if ( (inp > 0) && (inp < 5) ) {
        Menu_Speech_Sound(1 , inp);
        ResetMenu ();
        self.impulse = 0;
        return ;
    }

}

void Menu_Speech_Off_Input (float inp) {
    if ((inp == 10) || (self.pteam.last_sound > time )) {
        ResetMenu ();
        return ;
    } else if ( (inp > 0) && (inp < 6) ) {
        Menu_Speech_Sound(2 , inp);
        ResetMenu ();
        self.impulse = 0;
        return ;
    }

}

void Menu_Speech_Gen_Input (float inp) {
    if ((inp == 10) || (self.pteam.last_sound > time )) {
        ResetMenu ();
        return ;
    } else if ( (inp > 0) && (inp < 7) ) {
        Menu_Speech_Sound(3 , inp);
        ResetMenu ();
        self.impulse = 0;
        return ;
    }

}

void Menu_Speech () {
    CenterPrint (self,"žžž Speech Command: žžž\n\n“‘ Defensive  \n”‘ Offensive  \n•‘ General    \n’‘ Cancel     \n");
}

void Menu_Speech_Input (float inp) {
    if (inp == 10) {
        ResetMenu ();
        return ;
    } else if ( (inp == 1) ) {
        Menu_Speech_Defensive ();
        self.menu_count = 25;
        self.current_menu = 22;
        self.menu_displaytime = 0;
        self.impulse = 0;
    } else if ( (inp == 2) ) {
        Menu_Speech_Offensive ();
        self.menu_count = 25;
        self.current_menu = 23;
        self.menu_displaytime = 0;
        self.impulse = 0;
    } else if ( (inp == 3) ) {
        Menu_Speech_General ();
        self.menu_count = 25;
        self.current_menu = 24;
        self.menu_displaytime = 0;
        self.impulse = 0;
    }
}

// ************** UPGRADES ***************
void Menu_Upgrade_Weapons () {
    CenterPrint (self,"žžž Defensive Commands: žžž\n\n“‘ Incoming Flag!\n”‘ Flag in Danger\n•‘ Defend Flag!  \n–‘ Repair Sentry \n’‘ Cancel        \n");
}

void Menu_Upgrade_Armor () {
    CenterPrint (self,"žžž Offensive Commands: žžž\n\n“‘ I Have the Flag!\n”‘ I'm Attacking   \n•‘ Take the Flag   \n–‘ Cover me        \n—‘ Attack Sentry   \n’‘ Cancel          \n");
}

void Menu_Upgrade_Movement () {
    CenterPrint (self,"žžž General Commands: žžž\n\n“‘ Save Me!     \n”‘ Need Engineer\n•‘ No Problem   \n–‘ GO GO GO!    \n—‘ Give me ammo \n˜‘ Move Please  \n’‘ Cancel       \n");
}

void Menu_Upgrade_Other () {
    CenterPrint (self,"žžž General Commands: žžž\n\n“‘ Save Me!     \n”‘ Need Engineer\n•‘ No Problem   \n–‘ GO GO GO!    \n—‘ Give me ammo \n˜‘ Move Please  \n’‘ Cancel       \n");
}

void Menu_Upgrade_Wea_Input (float inp) {
    if ((inp == 10)) {
        ResetMenu ();
        return ;
    }
}

void Menu_Upgrade_Arm_Input (float inp) {
    if ((inp == 10)) {
        ResetMenu ();
        return ;
    }
}

void Menu_Upgrade_Mov_Input (float inp) {
    if ((inp == 10)) {
        ResetMenu ();
        return ;
    }
}

void Menu_Upgrade_Oth_Input (float inp) {
    if ((inp == 10)) {
        ResetMenu ();
        return ;
    }
}

void Menu_Upgrades () {
    CenterPrint (self,"žžž Upgrade Command: žžž\n\n“‘ Weapons  \n”‘ Armor  \n•‘ Movement   \n4. Other    \n’‘ Cancel     \n");
}

void Menu_Upgrades_Input (float inp) {
    if (inp == 10) {
        ResetMenu ();
        return ;
    } else if ( (inp == 1) ) {
        Menu_Upgrade_Weapons ();
        self.menu_count = 25;
        self.current_menu = 26;
        self.menu_displaytime = 0;
        self.impulse = 0;
    } else if ( (inp == 2) ) {
        Menu_Upgrade_Armor ();
        self.menu_count = 25;
        self.current_menu = 27;
        self.menu_displaytime = 0;
        self.impulse = 0;
    } else if ( (inp == 3) ) {
        Menu_Upgrade_Movement ();
        self.menu_count = 25;
        self.current_menu = 28;
        self.menu_displaytime = 0;
        self.impulse = 0;
    } else if ( (inp == 4) ) {
        Menu_Upgrade_Other ();
        self.menu_count = 25;
        self.current_menu = 29;
        self.menu_displaytime = 0;
        self.impulse = 0;
    }
}

void Menu_Spy () {
    if ( ((self.effects & (8 | 4)) || (self.is_unabletospy == 1)) ) {
        ResetMenu ();
        return ;
    }
    if ( self.is_feigning ) {
        if ( ((self.undercover_team != 0) && (self.undercover_skin != 0)) ) {
            CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Stop Feigning               \n–‘ Reset Skin and Color        \n—‘ Nothing                     \n\n");
        } else if ( (self.undercover_team != 0) ) {
                CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Stop Feigning               \n–‘ Reset Color                 \n—‘ Nothing                     \n\n");
		} else if ( (self.undercover_skin != 0) ) {
			CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Stop Feigning               \n–‘ Reset Skin                  \n—‘ Nothing                     \n\n");
		} else {
			CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Stop Feigning               \n–‘ Nothing                     \n\n");
		}
    } else {
        if ( ((self.undercover_team != 0) && (self.undercover_skin != 0)) ) {
            CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Start Feigning              \n–‘ Reset Skin and Color        \n—‘ Nothing                     \n\n");
        } else if ( (self.undercover_team != 0) ) {
			CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Start Feigning              \n–‘ Reset Color                 \n—‘ Nothing                     \n\n");
		} else if ( (self.undercover_skin != 0) ) {
			CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Start Feigning              \n–‘ Reset Skin                  \n—‘ Nothing                     \n\n");
		} else {
			CenterPrint (self,"Action:                           \n“‘ Change Skin                 \n”‘ Change Color                \n•‘ Start Feigning              \n–‘ Nothing                     \n\n");
		}
	}
}

void Menu_Spy_Input (float inp) {
	if ( ((inp == 1) || (inp == 2)) ) {
		if ( (self.effects & (8 | 4)) ) {
			sprint (self,PRINT_HIGH,"You can't go undercover while glowing.\n");
			ResetMenu ();
			self.impulse = 0;
			return ;
		}
		if ( (self.is_unabletospy == 1) ) {
			sprint (self,PRINT_HIGH,"You can't go undercover right now.\n");
			ResetMenu ();
			self.impulse = 0;
			return ;
		}
	}
	if ( (inp == 1) ) {
		Menu_Spy_Skin ();
		self.menu_count = 25;
		self.current_menu = 13;
		self.menu_displaytime = 0;
		self.impulse = 0;
	} else if ( (inp == 2) ) {
		Menu_Spy_Color ();
		self.menu_count = 25;
		self.current_menu = 14;
		self.menu_displaytime = 0;
		self.impulse = 0;
	} else if ( (inp == 3) ) {
		TeamFortress_SpyFeignDeath (0);
		ResetMenu ();
		self.impulse = 0;
	} else if ( (inp == 4) ) {
		Spy_RemoveDisguise (self);
		ResetMenu ();
		self.impulse = 0;
	} else if ( ((inp == 5) && ((self.undercover_team != 0) || (self.undercover_skin != 0))) ) {
		ResetMenu ();
		self.impulse = 0;
	} else if ( (inp == 6) ) {
		if (self.alpha == 0.400) {
			sprint (self, PRINT_HIGH, "self.alpha 1\n");
			self.alpha = 1;
		} else {
			sprint (self, PRINT_HIGH, "self.alpha 0.4\n");
			self.alpha = 0.400;
		}
		ResetMenu ();
		self.impulse = 0;
	}
}

void Menu_Spy_Skin () {
    if (TeamFortress_TeamIsCivilian(self.undercover_team)) {
        CenterPrint (self,"žžž Change Skin to: žžž\n“‘ Base" ) ;
        return;
    }
    CenterPrint (self,"žžž Change Skin to: žžž\n“‘ Scout   \n”‘ Sniper  \n•‘ Soldier \n–‘ Demoman \n—‘ Medic   \n˜‘ Hvwep   \n™‘ Pyro    \nš‘ Spy     \n›‘ Engineer\n\n");
}

void Menu_Spy_Skin_Input (float inp) {
    if (TeamFortress_TeamIsCivilian(self.undercover_team)) {
        if ( (inp == 1)) {
            TeamFortress_SpyChangeSkin (inp);
            ResetMenu ();
            self.impulse = 0;

        }
        return;
    }
    if ( ((inp < 10) && (inp > 0)) ) {
        TeamFortress_SpyChangeSkin (inp);
        ResetMenu ();
        self.impulse = 0;
    }
}

void Menu_Spy_Color () {
    if ( (store_obs.cnt == 0) ) {
        sprint (self,PRINT_HIGH,"No Color changing allowed in deathmatch.\n");
        ResetMenu ();
        self.impulse = 0;
        return ;
    }
    if ( (store_obs.cnt == 2) ) {
        CenterPrint (self,"žžž Change Color to the Same Color as: žžž\n\n“‘ Team One  \n”‘ Team Two  \n\n");
    } else {
        CenterPrint (self,"žžž Change Color to the Same Color as: žžž\n\n“‘ Team One  \n”‘ Team Two  \n•‘ Team Three\n–‘ Team Four \n\n");
    }
}

void Menu_Spy_Color_Input (float inp) {
    if ( ((inp >= 1) && (inp <= store_obs.cnt)) ) {
        if (( self.undercover_skin != 0)) {
            if (TeamFortress_TeamIsCivilian(inp)) {
                CenterPrint (self,"žžž Cannot change Color, You must Reset your Skin. žžž\n");
                return;
            }
        }

        TeamFortress_SpyChangeColor (inp);
        ResetMenu ();
        self.impulse = 0;
    }
}

void Menu_Engineer () {
    string s_action;
    string s_disp;
    string s_sentry;
    string s_nothing;
    s_action = "Action:                           \n";
    s_nothing = "—‘ Nothing                      \n\n";
    if ( self.has_dispenser ) {
        s_disp = "™‘ Remotely Detonate Dispenser  \n";
    } else {
        if ( (self.ammo_cells >= 100) ) {
            s_disp = "“‘ Build Ammo&Armor Dispenser   \n";
        } else {
            s_disp = "\n";
        }
    }
    if ( self.has_sentry ) {
        s_sentry = "š‘ Remotely Detonate Sentry Gun \n";
    } else {
        if ( (self.ammo_cells >= 130) ) {
            s_sentry = "”‘ Build Sentry Gun             \n";
        } else {
            s_sentry = "\n";
        }
    }
    centerprint (self,s_action,s_disp,s_sentry,s_nothing);
}

void Menu_Engineer_Input (float inp) {
	if ( (((inp == 1) && (self.ammo_cells >= 100)) && (self.has_dispenser != 1)) ) {
		TeamFortress_Build (1);
		ResetMenu ();
		self.impulse = 0;
	} else if ( (((inp == 2) && (self.ammo_cells >= 130)) && (self.has_sentry != 1)) ) {
		TeamFortress_Build (2);
		ResetMenu ();
		self.impulse = 0;
	} else if ( (((inp == 3) && (self.ammo_cells >= 180)) && (self.has_sentry != 1)) ) {
		TeamFortress_Build (3);
		ResetMenu ();
		self.impulse = 0;
	} else if ( ((inp == 7) && (self.has_dispenser == 1)) ) {
		DestroyBuilding (self,"building_dispenser");
		ResetMenu ();
		self.impulse = 0;
	} else if ( ((inp == 8) && (self.has_sentry == 1)) ) {
		DestroyBuilding (self,"building_sentrygun");
		ResetMenu ();
		self.impulse = 0;
	} else if ( (inp == 5) ) {
		ResetMenu ();
		self.impulse = 0;
	}
}

void Menu_EngineerFix_Dispenser () {
    CenterPrint (self,"Action:                            \n“‘ Put Ammo into Dispenser     \n”‘ Put Armor into Dispenser    \n•‘ Repair Dispenser            \n–‘ Dismantle Dispenser         \n—‘ Nothing                     \n\n");
}

float SetAttribute (float cur_ammo, float new_ammo);

void Menu_EngineerFix_Dispenser_Input (float inp) {
	float metalcost;
	float am;
	if ( ((self.classname != "player") || (self.building == world)) ) {
		return ;
	}
	if ( (inp == 1) ) {
		am = (20 * 2);
		if ( (am > self.ammo_shells) ) {
			am = self.ammo_shells;
		}
		if ( (am > (400 - self.building.ammo_shells)) ) {
			am = (400 - self.building.ammo_shells);
		}
		self.ammo_shells = SetAttribute(self.ammo_shells, self.ammo_shells - am);
		self.building.ammo_shells = (self.building.ammo_shells + am);
		am = (20 * 2);
		if ( (am > self.ammo_nails) ) {
			am = self.ammo_nails;
		}
		if ( (am > (600 - self.building.ammo_nails)) ) {
			am = (600 - self.building.ammo_nails);
		}
		self.ammo_nails = SetAttribute(self.ammo_nails, self.ammo_nails - am);
		self.building.ammo_nails = (self.building.ammo_nails + am);
		am = (10 * 2);
		if ( (am > self.ammo_rockets) ) {
			am = self.ammo_rockets;
		}
		if ( (am > (300 - self.building.ammo_rockets)) ) {
			am = (300 - self.building.ammo_rockets);
		}
		self.ammo_rockets  = SetAttribute(self.ammo_rockets, self.ammo_rockets - am);
		self.building.ammo_rockets = (self.building.ammo_rockets + am);
		am = (10 * 2);
		if ( (am > self.ammo_cells) ) {
			am = self.ammo_cells;
		}
		if ( (am > (400 - self.building.ammo_cells)) ) {
			am = (400 - self.building.ammo_cells);
		}
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells - am);
		self.building.ammo_cells = (self.building.ammo_cells + am);
	} else if ( (inp == 2) ) {
		am = (40 * 2);
		if ( (am > self.armorvalue) ) {
			am = self.armorvalue;
		}
		if ( (am > (500 - self.building.armorvalue)) ) {
			am = (500 - self.building.armorvalue);
		}
		self.armorvalue = SetAttribute(self.armorvalue, self.armorvalue - am);
		self.building.armorvalue = (self.building.armorvalue + am);
	} else if ( (inp == 3) ) {
		metalcost = ((self.building.max_health - self.building.health) / 5);
		if ( (metalcost > self.ammo_cells) ) {
			metalcost = self.ammo_cells;
		}
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells - am);
		self.building.health = (self.building.health + (metalcost * 5));
	} else if ( (inp == 4) ) {
		sprint (self,PRINT_HIGH,"You dismantle the Dispenser.\n");
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells + (100 / 2));
		if ( (self.building.real_owner != self) ) {
			sprint (self.building.real_owner,PRINT_HIGH,self.netname," dismantled your Dispenser.\n");
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,self.netname);
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner," dismantled ");
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,self.building.real_owner.netname);
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,"'s Dispenser.\n");
		}
		dremove (self.building);
		self.building.real_owner.has_dispenser = 0;
	}
    if ( ((inp >= 1) && (inp <= 5)) ) {
        ResetMenu ();
        self.impulse = 0;
        self.building = world;
        bound_other_ammo (self);
        if ( (self.armorvalue == 0) ) {
            self.armortype = 0;
            self.armorclass = 0;
            self.items = (self.items - (self.items & ((8192 | 16384) | 32768)));
        }
        W_SetCurrentAmmo ();
    }
}

void Menu_EngineerFix_SentryGun () {
    if ( ((self.building.weapon < 3) && (self.ammo_cells >= 130)) ) {
        CenterPrint (self,"Action:                            \n“‘ Put Ammo into Sentry Gun    \n”‘ Upgrade Sentry Gun          \n•‘ Repair Sentry Gun           \n–‘ Dismantle Sentry Gun        \n—‘ Nothing                     \n\n˜‘ Rotate SentryGun            \n");
    } else {
        CenterPrint (self,"Action:                            \n“‘ Put Ammo into Sentry Gun    \n\n•‘ Repair Sentry Gun           \n–‘ Dismantle Sentry Gun        \n—‘ Nothing                     \n\n˜‘ Rotate SentryGun            \n");
    }
}

void Menu_EngineerFix_SentryGun_Input (float inp) {
	float am;
	float metalcost;
	string st;
	if ( (self.building.real_owner.has_sentry == 0) ) {
		return ;
	}
	if ( ((self.classname != "player") || (self.building == world)) ) {
		return ;
	}
	if ( (inp == 1) ) {
		am = (20 * 2);
		if ( (am > self.ammo_shells) ) {
			am = self.ammo_shells;
		}
		if ( (am > (self.building.maxammo_shells - self.building.ammo_shells)) ) {
			am = (self.building.maxammo_shells - self.building.ammo_shells);
		}
		self.ammo_shells = SetAttribute(self.ammo_shells, self.ammo_shells - am);
		self.building.ammo_shells = (self.building.ammo_shells + am);
		if ( (self.building.weapon == 3) ) {
			am = (10 * 2);
			if ( (am > self.ammo_rockets) ) {
				am = self.ammo_rockets;
			}
			if ( (am > (self.building.maxammo_rockets - self.building.ammo_rockets)) ) {
				am = (self.building.maxammo_rockets - self.building.ammo_rockets);
			}
			self.ammo_rockets = SetAttribute(self.ammo_rockets, self.ammo_rockets - am);
			self.building.ammo_rockets = (self.building.ammo_rockets + am);
		}
	} else if ( (((self.building.weapon < 3) && (inp == 2)) && (self.ammo_cells >= 130)) ) {
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells - 130);
		self.building.weapon = (self.building.weapon + 1);
		if (sgtype) {
			self.building.max_health = floor(self.building.max_health * 1.250);
		} else {
			self.building.max_health = floor(self.building.max_health * 1.200);
		}
		self.building.health = self.building.max_health;
		self.building.maxammo_shells = (self.building.maxammo_shells * 1.200);
		if ( (self.building.weapon == 2) ) {
			sound (self.building,CHAN_ITEM,"weapons/turrset.wav",1,1);
			if (sgtype) {
				self.building.think = lvl2_sentry_stand;
			} else {
				self.building.think = lvl2_oldsentry_stand;
			}
			self.building.skin = 1;
		} else {
			sound (self.building,CHAN_ITEM,"weapons/turrset.wav",1,1);
			if (sgtype) {
				self.building.think = lvl3_sentry_stand;
			} else {
				self.building.think = lvl3_oldsentry_stand;
			}
			self.building.skin = 2;
		}
		sprint (self,PRINT_HIGH,"You upgrade the Sentry Gun to level ");
		st = ftos (self.building.weapon);
		sprint (self,PRINT_HIGH,st);
		sprint (self,PRINT_HIGH,"\n");
	} else if ( (inp == 3) ) {
		metalcost = ((self.building.max_health - self.building.health) / 5);
		if ( (metalcost > self.ammo_cells) ) {
			metalcost = self.ammo_cells;
		}
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells - metalcost);
		self.building.health = (self.building.health + (metalcost * 5));
	} else if ( (inp == 4) ) {
		sprint (self,PRINT_HIGH,"You dismantle the Sentry Gun.\n");
		self.ammo_cells = SetAttribute(self.ammo_cells, self.ammo_cells - 130);
		if ( (self.building.real_owner != self) ) {
			sprint (self.building.real_owner,PRINT_HIGH,self.netname," dismantled your Sentry Gun.\n");
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,self.netname);
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner," dismantled ");
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,self.building.real_owner.netname);
			teamsprint (self.building.real_owner.pteam.team ,self.building.real_owner,"'s Sentry Gun.\n");
		}
		dremove (self.building.trigger_field);
		dremove (self.building);
		self.building.real_owner.has_sentry = 0;
	} else if ( (inp == 6) ) {
		sprint (self,PRINT_HIGH,"Rotating 45 degrees to the left...\n");
		self.building.waitmin = anglemod ((self.building.waitmin + 45));
		self.building.waitmax = anglemod ((self.building.waitmax + 45));
	}
    if ( ((inp >= 1) && (inp <= 6)) ) {
        ResetMenu ();
        self.impulse = 0;
        bound_other_ammo (self);
        if ( (self.armorvalue == 0) ) {
            self.armortype = 0;
            self.armorclass = 0;
            self.items = (self.items - (self.items & ((8192 | 16384) | 32768)));
        }
        W_SetCurrentAmmo ();
    }
}

void Menu_Dispenser () {
    CenterPrint (self,"Use Dispenser:                     \n“‘ Withdraw some ammo          \n”‘ Withdraw some Armor         \n•‘ Nothing                     \n\n");
}

void Menu_Dispenser_Input (float inp) {
	float am;
	float empty;
	empty = 0;
	if ( (inp == 1) ) {
		if ( ((((self.building.ammo_shells == 0) && (self.building.ammo_nails == 0)) && (self.building.ammo_rockets == 0)) && (self.building.ammo_cells == 0)) ) {
			empty = 1;
		} else {
			am = (self.maxammo_shells - self.ammo_shells);
			if ( (am > self.building.ammo_shells) ) {
				am = self.building.ammo_shells;
			}
			self.building.ammo_shells = (self.building.ammo_shells - am);
			self.ammo_shells = (self.ammo_shells + am);
			am = (self.maxammo_nails - self.ammo_nails);
			if ( (am > self.building.ammo_nails) ) {
				am = self.building.ammo_nails;
			}
			self.building.ammo_nails = (self.building.ammo_nails - am);
			self.ammo_nails = (self.ammo_nails + am);
			am = (self.maxammo_rockets - self.ammo_rockets);
			if ( (am > self.building.ammo_rockets) ) {
				am = self.building.ammo_rockets;
			}
			self.building.ammo_rockets = (self.building.ammo_rockets - am);
			self.ammo_rockets = (self.ammo_rockets + am);
			am = (self.maxammo_cells - self.ammo_cells);
			if ( (am > self.building.ammo_cells) ) {
				am = self.building.ammo_cells;
			}
			self.building.ammo_cells = (self.building.ammo_cells - am);
			self.ammo_cells = (self.ammo_cells + am);
		}
	} else if ( (inp == 2) ) {
		if ( (self.building.armorvalue == 0) ) {
			empty = 1;
		} else {
			am = (self.maxarmor - self.armorvalue);
			if ( (am > self.building.armorvalue) ) {
				am = self.building.armorvalue;
			}
			if ( (self.armortype == 0) ) {
				self.armortype = 0.300;
				self.items = (self.items | 8192);
			}
			self.building.armorvalue = (self.building.armorvalue - am);
			self.armorvalue = (self.armorvalue + am);
		}
	}
    if ( ((inp >= 1) && (inp <= 3)) ) {
        if ( empty ) {
            sprint (self,PRINT_HIGH,"The dispenser is empty.\n");
        }
        ResetMenu ();
        self.impulse = 0;
        self.building = world;
        self.building_wait = (time + 0.500);
        bound_other_ammo (self);
        if ( (self.armorvalue == 0) ) {
            self.armortype = 0;
            self.armorclass = 0;
            self.items = (self.items - (self.items & ((8192 | 16384) | 32768)));
        }
        W_SetCurrentAmmo ();
    }
}
