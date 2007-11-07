
float spaceoutnum (float num, float digits) {
    float d;
    d = digits - 1;
    if (num < 0) {
        d = d - 1;
        num = 0 - num;
    }
    if (num >= 10) d = d - 1;
    if (num >= 100) d = d - 1;
    if (num >= 1000) d = d - 1;
    if (num >= 10000) d = d - 1;
    if (num >= 100000) d = d - 1;
    if (num >= 1000000) d = d - 1;
    return (d);
}
string spacestring (float num) {
    string st;
    st = strcat (st, " ");
    while (num > 0)  {
        st = strcat (st, " ");
        num =  num - 1;
    }
    return (st);
}
string spacefornum (float num, float digits) {
    string st;
    float fl;
    fl = spaceoutnum(num, digits);
    st = spacestring(fl);
    return (st);
}

void ShowVersion () {
    sprint (self, PRINT_HIGH,"\n\nΤθισ ισ Oz Team Fortress φεςσιοξ 1.77a         βω Mercury\n\nΣπεγιαμ τθαξψ το Omicron, γςεατοςσ οζ Kombat Teams 2.21\nΑξδ ξοξε οτθες τθεξ τθε γςεατοςσ οζ Team Fortress\n\n\nPlease visit θττπΊ――οϊτζ®ρυαλεχοςμδ®ξυ― for more info. \n\n\n");
}
//Special thanx to Rawhide, Omicron, creators of Kombat Teams 2.21\nAnd none other then the creators of Team Fortress\n\n Also thank you to all those test dummies.\n Including the fatty fv nitemare.\n And the annoying sh33p b0y bliP :)\n\nPlease visit ρχτζ®αυσζοςτςεσσ®γον for more info. \n");

void Commands () {
    sprint (self, PRINT_HIGH, "αβουτ...... about the Oztf Mod\nνοδστατυσ.. current settings\nβςεαλ...... vote matchend/stop countdown\nεμεγτ...... toggle admin election\nωεσ........ vote yes for current elective\nξο......... change vote\n");
    if (self.is_admin == 1) {
        if (stof(infokey (world,"adminlevel")) > 0) {
            sprint (self, PRINT_HIGH, "\nAdmin Commands:\n\n");
            sprint (self, PRINT_HIGH, "τινεδοχξ... decrease timelimit\nτινευπ..... increase timelimit\nπνδοχξ..... decrease prematch time\nπνυπ....... increase prematch time\nγζδοχξ..... decrease ceasefire time\nγζυπ....... increase ceasefire time\nοτδοχξ..... decrease overtime\n");
            sprint (self, PRINT_HIGH, "οτυπ....... increase overtime\nζςαησδοχξ.. reduce fraglimit\nζςαησυπ.... increase fraglimit\nσιμεξγε.... toggle spectator talk\nςεσταςτναπ. restart the current map\nσταςτνατγθ. starts clan match (requires clan mode on)\n");
            if (stof(infokey (world,"adminlevel")) > 1) {
                sprint (self, PRINT_HIGH, "ςεσετ...... reset all settings to standard\nγμαξσετυπ.. set clan settings and restart\nγεασεζιςε.. freeze the gameplay\nζςεεϊε..... (un)freeze the map\nζβσλιξσ.... toggle full bright skins\nζςκυνπ..... toggle forward rocketjump\n");
                sprint (self, PRINT_HIGH, "ποιξτιξη... toggle pointing\nεξενω...... toggle enemy printing\nηςεξπαγλ... toggle backpacks\nησπεεδ..... modify maximum ground speed\nτπ......... modify teamplay\nηιβσ....... toggle gibs\nσητωπε..... toggle sentry type\nσηζιςε..... toggle sentry fire\n");
                sprint (self, PRINT_HIGH, "πιπεδεμαω.. (dis)allow pipebomb delay\nσομιδδετ... toggle solid detpacks\n");
            }
            if (stof(infokey (world,"adminlevel")) > 2) {
                sprint (self, PRINT_HIGH, "δεαμ....... kick a player\nμιστιπσ.... list players ip addresses\n");
            }
            sprint (self, PRINT_HIGH, "\n*** The following commands require a map restart ***\n\n");
            sprint (self, PRINT_HIGH, "τεανζςαησ.. toggle teamfrags\nζυμμτσ..... toggle full team score\nηςαππμε.... toggle grapple\n");
            if (stof(infokey (world,"adminlevel")) > 1) {
                sprint (self, PRINT_HIGH, "γμαξ....... toggle clan mode\nτζφσδν..... toggle tfvsdm mode\nτζστςιλε... toggle tfstrike mode\nςουξδσ..... toggle rounds\nδυεμ....... toggle duel mode\nσπεεδγαπ... toggle speed capture mode\nθιηθμαξδες. toggle highlander mode\nπςαγτιγε... toggle practice mode\n");
            }
        }
    }
    if (self.is_admin == 3) {
        sprint (self, PRINT_HIGH, "\nAdmin Commands:\n\n");
        sprint (self, PRINT_HIGH, "τινεδοχξ... decrease timelimit\nτινευπ..... increase timelimit\nπνδοχξ..... decrease prematch time\nπνυπ....... increase prematch time\nγζδοχξ..... decrease ceasefire time\nγζυπ....... increase ceasefire time\nοτδοχξ..... decrease overtime\n");
        sprint (self, PRINT_HIGH, "οτυπ....... increase overtime\nζςαησδοχξ.. reduce fraglimit\nζςαησυπ.... increase fraglimit\nσιμεξγε.... toggle spectator talk\nςεσταςτναπ. restart the current map\nσταςτνατγθ. starts clan match (requires clan mode on)\n");
        sprint (self, PRINT_HIGH, "ςεσετ...... reset all settings to standard\nγμαξσετυπ.. set clan settings and restart\nγεασεζιςε.. freeze the gameplay\nζςεεϊε..... (un)freeze the map\nζβσλιξσ.... toggle full bright skins\nζςκυνπ..... toggle forward rocketjump\n");
        sprint (self, PRINT_HIGH, "ποιξτιξη... toggle pointing\nεξενω...... toggle enemy printing\nηςεξπαγλ... toggle backpacks\nησπεεδ..... modify maximum ground speed\nτπ......... modify teamplay\nηιβσ....... toggle gibs\nσητωπε..... toggle sentry type\n");
        sprint (self, PRINT_HIGH, "σηζιςε..... toggle sentry fire\nπιπεδεμαω.. (dis)allow pipebomb delay\nσομιδδετ... toggle solid detpacks\nδεαμ....... kick a player\nμιστιπσ.... list players ip addresses\n");
        sprint (self, PRINT_HIGH, "\n*** The following commands require a map restart ***\n\n");
        sprint (self, PRINT_HIGH, "γμαξ....... toggle clan mode\nτζφσδν..... toggle tfvsdm mode\nτζστςιλε... toggle tfstrike mode\nτεανζςαησ.. toggle teamfrags\nζυμμτσ..... toggle full team score\nηςαππμε.... toggle grapple\n");
        sprint (self, PRINT_HIGH, "θιηθμαξδες. toggle highlander mode\nςουξδσ..... toggle rounds\nδυεμ....... toggle duel mode\nσπεεδγαπ... toggle speed capture mode\nπςαγτιγε... toggle practice mode\n");
    }
}

void ShowScores () {
    string st;
    stuffcmd(self, "scores ");
    stuffcmd(self, self.netname);
    stuffcmd(self, " ");
    stuffcmd(self, ftos(pteam1.frags));
    stuffcmd(self, " ");
    stuffcmd(self, ftos(pteam2.frags));
    stuffcmd(self, "\n");
    if (store_obs.cnt == 2) {
        sprint (self, PRINT_HIGH, "\n\n");
        sprint (self, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (self, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (self, PRINT_HIGH,  st, "\n");
    } else {
        sprint (self, PRINT_HIGH, "\n\n");
        sprint (self, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (self, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (self, PRINT_HIGH,  st, "\n Team3:   ");
        st =  ftos(pteam3.frags);
        sprint (self, PRINT_HIGH,  st, "     Team4:   ");
        st =  ftos(pteam4.frags);
        sprint (self, PRINT_HIGH,  st, "\n");
    }
    if ((modetype & 1) && (!cb_prematch)) {
        st = infokey (world, "status");
        sprint (self, PRINT_HIGH,  "\n Time: ");
        sprint (self, PRINT_HIGH,   st );
        sprint (self, PRINT_HIGH,  "\n");
    }
    sprint (self, PRINT_HIGH, "\n\n");
}

void ShowFrags (entity print) {
    entity te;
    float eff;
    string st, sp;
    sprint (print, PRINT_HIGH, "\n\n");
    sprint (print, PRINT_HIGH, " Frags  TK's  Deaths  Eff  Name\n");
    sprint (print, PRINT_HIGH, "\n");
    te = player_head;
    while (te) {
        if (te.real_frags <= 0) {
            eff = 0;
        } else {
            eff = (te.real_frags / (te.real_frags + te.deaths)) * 100;
            eff = rint(eff);
        }
        st = ftos(te.real_frags );
        sp = spacefornum(te.real_frags, 4);
        sprint (print, PRINT_HIGH, "  ", st, sp);
        st = ftos(te.teamkills );
        sp = spacefornum(te.teamkills, 3);
        sprint (print, PRINT_HIGH, "  ", st, sp);
        st = ftos(te.deaths );
        sp = spacefornum(te.deaths, 5);
        sprint (print, PRINT_HIGH, "  ", st, sp);
        st = ftos(eff);
        sp = spacefornum(eff, 3);
        sprint (print, PRINT_HIGH, "  ", st, sp);
        /*
           st = ftos(te.real_frags);
           if ( te.real_frags < 10)
           {
           sprint (print, PRINT_HIGH, "  ", st, "     ");
           }
           else if (te.real_frags < 100)
           {
           sprint (print, PRINT_HIGH, "  ", st, "    ");
           }
           else
           {
           sprint (print, PRINT_HIGH, "  ", st, "   ");
           }
           st =  ftos(te.teamkills);
           if ( te.teamkills < 10)
           {
           sprint (print, PRINT_HIGH,  st, "      ");
           }
           else if (te.teamkills < 100)
           {
           sprint (print, PRINT_HIGH,  st, "     ");
           }
           else
           {
           sprint (print, PRINT_HIGH,  st, "    ");
           }
           st =  ftos(te.deaths);
           if (te.deaths < 10)
           {
           sprint (print, PRINT_HIGH,  st, "      ");
           }
           else if ( te.deaths < 100)
           {
           sprint (print, PRINT_HIGH,  st, "     ");
           }
           else
           {
           sprint (print, PRINT_HIGH,  st, "    ");
           }
           st =  ftos(eff);
           if (eff < 10)
           {
           sprint (print, PRINT_HIGH,  st, "     ");
           }
           else if ( eff < 100)
           {
           sprint (print, PRINT_HIGH,  st, "    ");
           }
           else
           {
           sprint (print, PRINT_HIGH,  st, "   ");
           }*/
        sprint (print, PRINT_HIGH,  te.netname , "\n");
        te = te.nextp;
    }
    if (store_obs.cnt == 2) {
        sprint (print, PRINT_HIGH, "\n\n");
        sprint (print, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (print, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (print, PRINT_HIGH,  st, "\n");
    } else {
        sprint (print, PRINT_HIGH, "\n\n");
        sprint (print, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (print, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (print, PRINT_HIGH,  st, "\n Team3:   ");
        st =  ftos(pteam3.frags);
        sprint (print, PRINT_HIGH,  st, "     Team4:   ");
        st =  ftos(pteam4.frags);
        sprint (print, PRINT_HIGH,  st, "\n");
    }
    sprint (print, PRINT_HIGH, "\n\n");
}

void ShowTouches () {
    entity te;
    string st, sp;
    sprint (self, PRINT_HIGH, "\n Flag running:\n");
    sprint (self, PRINT_HIGH, "\n");
    sprint (self, PRINT_HIGH, " Touched  Captured  Dropped  Name\n");
    sprint (self, PRINT_HIGH, "\n");
    te = player_head;
    while (te) {
        if (te.flag_touches ) {
            st = ftos(te.flag_touches );
            sp = spacefornum(te.flag_touches, 6);
            sprint (self, PRINT_HIGH, "  ", st, sp);
            st = ftos(te.flag_captures );
            sp = spacefornum(te.flag_captures, 7);
            sprint (self, PRINT_HIGH, "  ", st, sp);
            st = ftos(te.flag_fumbles );
            sp = spacefornum(te.flag_fumbles, 7);
            sprint (self, PRINT_HIGH, "  ", st, sp);
            /*
               if ( te.flag_touches  < 10)
               {
               sprint (self, PRINT_HIGH, "  ", st, "       ");
               }
               else if (te.flag_touches < 100)
               {
               sprint (self, PRINT_HIGH, "  ", st, "      ");
               }
               else
               {
               sprint (self, PRINT_HIGH, "  ", st, "     ");
               }
               st =  ftos(te.flag_captures);
               if ( te.flag_captures < 10)
               {
               sprint (self, PRINT_HIGH,  st, "         ");
               }
               else if (te.flag_captures < 100)
               {
               sprint (self, PRINT_HIGH,  st, "        ");
               }
               else
               {
               sprint (self, PRINT_HIGH,  st, "       ");
               }
               st =  ftos(te.flag_fumbles);
               if (te.flag_fumbles < 10)
               {
               sprint (self, PRINT_HIGH,  st, "         ");
               }
               else if ( te.flag_fumbles < 100)
               {
               sprint (self, PRINT_HIGH,  st, "        ");
               }
               else
               {
               sprint (self, PRINT_HIGH,  st, "       ");
               }
             */
            sprint (self, PRINT_HIGH,  te.netname , "\n");
        }
        te = te.nextp;
    }
    if (store_obs.cnt == 2) {
        sprint (self, PRINT_HIGH, "\n\n");
        sprint (self, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (self, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (self, PRINT_HIGH,  st, "\n");
    } else {
        sprint (self, PRINT_HIGH, "\n\n");
        sprint (self, PRINT_HIGH,  " Team Scores:\n Team1:   ");
        st =  ftos(pteam1.frags);
        sprint (self, PRINT_HIGH,  st, "     Team2:   ");
        st =  ftos(pteam2.frags);
        sprint (self, PRINT_HIGH,  st, "\n Team3:   ");
        st =  ftos(pteam3.frags);
        sprint (self, PRINT_HIGH,  st, "     Team4:   ");
        st =  ftos(pteam4.frags);
        sprint (self, PRINT_HIGH,  st, "\n");
    }
    sprint (self, PRINT_HIGH, "\n\n");
}

void ShowFps () {
    entity te;
    float r;
    float fps;
    string st;
    sprint (self, PRINT_HIGH, "\n\n");
    sprint (self, PRINT_HIGH, " Fps    Speed       Name\n");
    sprint (self, PRINT_HIGH, "\n");
    te = player_head;
    while (te) {
        fps = rint( 1000 / ( te.fAverageFrameTime / te.fFrameCount * 1000 ) );
        st = ftos( fps );
        sprint (self, PRINT_HIGH, " ", st, "     ");
        r = fabs(te.fAverageFrameTime * 100 / (time - te.real_time));
        st = ftos(r);
        sprint (self, PRINT_HIGH,  st, "%       ");
        sprint (self, PRINT_HIGH,  te.netname , "\n");
        te = te.nextp;
    }
    sprint (self, PRINT_HIGH, "\n\n");
}

void ShowSpeed () {
    float dist;
    string st;
    if (self.speed) {
        st = ftos(rint(self.speed));
        sprint (self, PRINT_HIGH, " Current Speed:  ", st,"\n");
    }
    if (self.a_speed) {
        /*  ends up all 3.69 / 0.36 which is 10.25
        	no need to waste calculation if its always
        	speed / 10.25
        	dist = (self.speed / 36.9 ) / 1000;
        	dist = dist * 3600;
         */
        dist = self.speed / 10.25;
        st = ftos(rint(dist));
        sprint (self, PRINT_HIGH, " Metric Speed:   ", st," km/h\n");
    }
}

void ShowStats () {
    string st;
    float eff;
    sprint (self, PRINT_HIGH, "\n\n");
    sprint (self, PRINT_HIGH, " ", self.netname, "'s Statistics\n");
    sprint (self, PRINT_HIGH, "\n");
    if (self.enemy)
        sprint (self, PRINT_HIGH, " Last enemy: ", self.enemy.netname,"\n");
    st = ftos(self.real_frags);
    sprint (self, PRINT_HIGH, " Frags:      ", st,"\n");
    st = ftos(self.deaths);
    sprint (self, PRINT_HIGH, " Deaths:     ", st,"\n");
    st = ftos(self.teamkills);
    sprint (self, PRINT_HIGH, " Teamkills:  ", st,"\n");
    if (self.real_frags <= 0) {
        eff = 0;
    } else {
        eff = (self.real_frags / (self.real_frags + self.deaths)) * 100;
        eff = rint(eff);
    }
    st = ftos(eff);
    sprint (self, PRINT_HIGH, " Efficiency: ", st,"\n\n");
    st = ftos(rint(self.dmg_inflicted));
    sprint (self, PRINT_HIGH, " Damage given:  ", st,"\n");
    st = ftos(rint(self.dmg_recieved));
    sprint (self, PRINT_HIGH, " Damage taken:  ", st,"\n");
    st = ftos(rint(self.dmg_self));
    sprint (self, PRINT_HIGH, " Damage self:   ", st,"\n");
    st = ftos(rint(self.dmg_team));
    sprint (self, PRINT_HIGH, " Damage team:   ", st,"\n\n");
    st = ftos(self.flag_touches);
    sprint (self, PRINT_HIGH, " Touches:    ", st,"\n");
    st = ftos(self.flag_captures);
    sprint (self, PRINT_HIGH, " Captures:   ", st,"\n");
    st = ftos(self.flag_fumbles);
    sprint (self, PRINT_HIGH, " Fumbles:    ", st,"\n\n");
    if (self.a_speed) {
        eff = (self.a_speed / self.cnt);
        st = ftos(rint(eff));
        sprint (self, PRINT_HIGH, " Average Speed:       ", st,"\n");
        if (self.a_gspeed) {
            eff = (self.a_gspeed / self.g_count);
            st = ftos(rint(eff));
            sprint (self, PRINT_HIGH, " Average Groundspeed: ", st,"\n");
            eff = ((self.a_speed - self.a_gspeed) / (self.cnt - self.g_count));
            st = ftos(rint(eff));
            sprint (self, PRINT_HIGH, " Average Airspeed:    ", st,"\n");
        }
        eff = (self.a_speed / (81.63 * 72));  // assume * 72 fps
        st = ftos(rint(eff));
        sprint (self, PRINT_HIGH, " Distance Travelled:  ", st," metres\n");
    }
    sprint (self, PRINT_HIGH, "\n\n");
}

void ModStatus () {
    string tmp;
    float f1;
    tmp = ftos(teamplay);
    sprint (self, PRINT_HIGH, "Τεανπμαω        ", tmp, "\n");
    tmp = ftos((timelimit/60));
    sprint (self, PRINT_HIGH, "Τινεμινιτ       ", tmp, "  ");
    if (timelimit < 10) sprint (self, PRINT_HIGH, " ");
    tmp = ftos(fraglimit);
    sprint (self, PRINT_HIGH, "\nΖςαημινιτ       ", tmp, "\n");
    if ( (modetype & 1 )) {
        sprint (self, PRINT_HIGH, "Clan Mode       on\n");
    } else {
        sprint (self, PRINT_HIGH, "Clan Mode       off\n");
    }
    tmp = infokey (world,"overtime");
    if ( stof (tmp)) {
        sprint (self, PRINT_HIGH, "Overtime        ", tmp, "\n");
    } else {
        sprint (self, PRINT_HIGH, "Overtime        off\n");
    }
    tmp = infokey (world,"teamfrags");
    if ( (tmp == "on") ) {
        sprint (self, PRINT_HIGH, "Teamfrags       ", tmp, "\n");
    } else {
        sprint (self, PRINT_HIGH, "Teamfrags       off\n");
    }
    tmp = infokey (world,"fullteamscore");
    if ( (tmp == "on") ) {
        sprint (self, PRINT_HIGH, "Full Team Score ", tmp, "\n");
    } else {
        sprint (self, PRINT_HIGH, "Full Team Score off\n");
    }
    tmp = ftos(gspeed);
    sprint (self, PRINT_HIGH, "Ground speed    ", tmp, "\n");
    /*
       if ( tfvsdm ) {
       sprint (self, PRINT_HIGH, "ΤΖφσΔΝ:         on\n");
       } else {
       sprint (self, PRINT_HIGH, "ΤΖφσΔΝ:         off\n");
       }
     */
    if ( modetype & 4 ) {
        sprint (self, PRINT_HIGH, "TFStrike:       on\n");
    } else {
        sprint (self, PRINT_HIGH, "TFStrike:       off\n");
    }
    if (allow_grenpack) {
        sprint (self, PRINT_HIGH, "Gren Backpacks: on\n");
    }
    if ( (pipedelay)) {
        sprint (self, PRINT_HIGH, "Pipebomb Delay: on\n");
    } else {
        sprint (self, PRINT_HIGH, "Pipebomb Delay: off\n");
    }
    tmp = infokey (world,"gibs");
    if ( (tmp == "off") ) {
        sprint (self, PRINT_HIGH, "Player Gibs     ", tmp, " \n");
    }
    if (allow_hook) {
        sprint (self, PRINT_HIGH, "Grapple:        on\n");
    } else {
        sprint (self, PRINT_HIGH, "Grapple:        off\n");
    }
    if (!sentry_fire) {
        sprint (self, PRINT_HIGH, "Sentry Fire: Normal\n");
    } else if (sentry_fire == 1) {
        sprint (self, PRINT_HIGH, "Sentry Fire: Lightning\n");
    } else if (sentry_fire == 2) {
        sprint (self, PRINT_HIGH, "Sentry Fire: Laser\n");
    }
    tmp = infokey (world,"highlander");
    if ( (tmp == "on") ) {
        sprint (self, PRINT_HIGH, "Highlander mode on\n");
    }
    if (modetype & 32) {
        sprint (self, PRINT_HIGH, "Duel mode:      on\n");
    }
    if (modetype & 16) {
        sprint (self, PRINT_HIGH, "Speed capture:  on\n");
    }
    if (modetype & 2) {
        sprint (self, PRINT_HIGH, "Practice:       on\n");
    }
    if (rounds < 0) {
        sprint (self, PRINT_HIGH, "Rounds:         on\n");
    } else if (rounds > 1) {
        tmp = ftos(rounds);
        sprint (self, PRINT_HIGH, "Rounds:        ", tmp ,"\n");
    }
    f1 = stof(infokey(world, "fpd"));
    if (f1 & 256) {
        sprint (self, PRINT_HIGH, "ζυμμβςιηθτ σλιξσ disabled\n");
    } else {
        sprint (self, PRINT_HIGH, "ζυμμβςιηθτ σλιξσ enabled\n");
    }
    f1 = stof(infokey(world, "fpd"));
    if (f1 & 128) {
        sprint (self, PRINT_HIGH, "ποιξτιξη disabled\n");
    } else {
        sprint (self, PRINT_HIGH, "ποιξτιξη enabled\n");
    }
    if (elect) {
        tmp = ftos(elect);
        sprint (self, PRINT_HIGH, "\nElection in progress\n", tmp, "‘ votes received\n");
    }
}

void TimeDown (float t) {
    string tmp;
    float lowest;
    float tl;
    lowest = 0;
    tl = (timelimit / 60) - t;
    if (tl < 1) {
        tl = lowest;
    }
    tmp = ftos(tl);
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Νατγθ μεξητθ σετ το ", tmp, " νιξυτεσ\n");
    timelimit = (tl * 60);
    cvar_set("timelimit", tmp);
}

void TimeUp (float t) {
    string tmp;
    float highest;
    float tl;
    highest = 70;
    tl = (timelimit / 60) + t;
    if (tl > highest) {
        tl = highest;
    }
    tmp = ftos(tl);
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Νατγθ μεξητθ σετ το ", tmp, " νιξυτεσ\n");
    timelimit = (tl * 60);
    cvar_set("timelimit", tmp);
}

void MiscTimeDown (float t, string option) {
    string tmp;
    float lowest;
    float ml;
    lowest = 0;
    tmp = infokey (world, option);
    ml = stof(tmp) - t;
    if (ml < lowest) ml = lowest;
    tmp = ftos(ml);
    bprint(PRINT_HIGH, " ");
    if (option == "cft") {
        bprint(PRINT_HIGH, "Ceasefire time σετ το ", tmp, " νιξυτεσ\n");
    } else {
        bprint(PRINT_HIGH, option, " μεξητθ σετ το ", tmp, " νιξυτεσ\n");
    }
    localcmd("localinfo ");
    localcmd(option);
    localcmd(" ");
    localcmd(tmp);
    localcmd("\n");
}

void MiscTimeUp (float t, string option) {
    string tmp;
    float highest;
    float ml;
    highest = 15;
    tmp = infokey (world, option);
    ml = stof(tmp);
    ml = ml + t;
    if (ml > highest) {
        ml = highest;
    }
    tmp = ftos(ml);
    bprint(PRINT_HIGH, " ");
    if (option == "cft") {
        bprint(PRINT_HIGH, "Ceasefire time σετ το ", tmp, " νιξυτεσ\n");
    } else {
        bprint(PRINT_HIGH, option, " μεξητθ σετ το ", tmp, " νιξυτεσ\n");
    }
    localcmd("localinfo ");
    localcmd(option);
    localcmd(" ");
    localcmd(tmp);
    localcmd("\n");
}

void FragLimit (float add) {
    string tmp;
    fraglimit = fraglimit + add;
    if (fraglimit < 0) fraglimit = 0;
    tmp = ftos(fraglimit);
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Ζςαημινιτ σετ το ", tmp, "\n");
    cvar_set("fraglimit", tmp);
}

void ChangeTP () {
    string tmp;
    string desc;
    if (teamplay ==  1) {
        teamplay = 11;
        tmp = "11?TeamFortress";
        desc = "Team-members inflict half damamge.\n";
    } else {
        if (teamplay ==  11) {
            teamplay = 13;
            tmp = "13?TeamFortress";
            desc = "Team-members take half damage from area effects, No damage from direct fire.\n";
        } else {
            if (teamplay == 13) {
                teamplay = 19;
                tmp = "19?TeamFortress";
                desc = "Team-members take half damage from direct fire.\n";
            } else {
                if (teamplay == 19) {
                    teamplay = 21;
                    tmp = "21?TeamFortress";
                    desc = "Team-members inflicts armor damage only.\n";
                } else {
                    if (teamplay == 21) {
                        teamplay = 641;
                        tmp = "641?TeamFortress";
                        desc = "Team-members inflict half damage to armor.\n";
                    } else {
                        if (teamplay == 641) {
                            teamplay = 1301;
                            tmp = "1301?TeamFortress";
                            desc = "Team-members inflict no damage.\n";
                        } else {
                            teamplay = 1;
                            tmp = "1?TeamFortress";
                            desc = "Teamplay On\n";
                        }
                    }
                }
            }
        }
    }
    cvar_set("teamplay", tmp);
    bprint(PRINT_HIGH, " Teamplay set to: ", ftos(teamplay), " - ");
    bprint(PRINT_HIGH,  desc);
}

void RestartMap () {
    localcmd("map ");
    localcmd(mapname);
    localcmd("\n");
}

void ToggleSpecTalk () {
    float tmp, tmp2;
    string s1;
    tmp2 = stof(infokey(world, "fpd"));
    tmp2 = tmp2 - (tmp2 & 64);
    tmp = stof(infokey(world, "spectalk"));
    bprint(PRINT_HIGH, " Spectalk ");
    if (tmp != 0) {
        localcmd("sv_spectalk 0\nserverinfo fpd ");
        tmp2 = tmp2 + 64;
        s1 = ftos(tmp2);
        localcmd(s1);
        localcmd("\nlocalinfo spectalk 0\n");
        bprint(PRINT_HIGH, "off: πμαωεςσ γαξ ξο μοξηες θεας σπεγτατοςσ\n");
        return;
    }
    localcmd("sv_spectalk 1\nserverinfo fpd ");
    s1 = ftos(tmp2);
    localcmd(s1);
    localcmd("\nlocalinfo spectalk 1\n");
    bprint(PRINT_HIGH, "on: πμαωεςσ γαξ ξοχ θεας σπεγτατοςσ\n");
    return;
}

void GroundSpeed () {
    string desc;
    if (gspeed == 0) {
        gspeed = 1;
        desc = "Maximum Ground Speed set to maximum Class Speed.";
    } else if (gspeed ==  1) {
        gspeed = 1.250;
        desc = "Maximum Ground Speed set to 1.25 times the maximum Class Speed.";
    } else if (gspeed ==  1.250) {
        gspeed = 1.500;
        desc = "Maximum Ground Speed set to 1.5 times the maximum Class Speed.";
    } else if (gspeed ==  1.500) {
        gspeed = 1.750;
        desc = "Maximum Ground Speed set to 1.75 times the maximum Class Speed.";
    } else if (gspeed ==  1.750) {
        gspeed = 2;
        desc = "Maximum Ground Speed set to 2 times the maximum Class Speed.";
    } else {
        gspeed = 0;
        desc = "Ground Speed Normal.";
    }
    bprint(PRINT_HIGH, " ",  desc,"\n");
    localcmd("localinfo pm_gspeed ");
    localcmd(ftos(gspeed));
    localcmd("\n");
}

void ToggleFreeze () {
    bprint(PRINT_HIGH, " ");
    if (( freeze == 0 )) {
        freeze = 1;
        localcmd("localinfo freeze on\n");
        bprint(PRINT_HIGH, self.netname, " freezes map\n");
    } else {
        freeze = 0;
        localcmd("localinfo freeze off\n");
        bprint(PRINT_HIGH, self.netname, " unfreezes map\n");
    }
}

void Toggle_Misc (string option) {
    string st;
    st = infokey (world, option);
    if ( (st == "on") ) {
        st = "off";
    } else {
        st = "on";
    }
    localcmd("localinfo ");
    localcmd(option);
    localcmd(" ");
    localcmd(st);
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, option, " set to ", st, " \n");
}
/*

   void() ClanMode =
   localcmd("localinfo clan on\n");
   bprint(PRINT_HIGH, "Map Restart needed to take affect!\n")

   void() Toggle_TFvsDM =
   bprint(PRINT_HIGH, "TFvsDM Mode set to ", st, "\n"

   void() Toggle_SpeedCap
   bprint(PRINT_HIGH, "Speed Capture Mode set to ", st, "\n");

   void() Toggle_Practice =
   bprint(PRINT_HIGH, "Practice Mode set to ", st, "\n");

   void() Toggle_TFStrike =
   bprint(PRINT_HIGH, "TFStrike Mode set to ", st, "\n");

   void() Toggle_Duel =
   bprint(PRINT_HIGH, "Duel Mode set to ", st, "\n");

   void() Toggle_Rounds =

   void Toggle_Teamfrags () {
   bprint(PRINT_HIGH, "Teamfrags set to ", st, " \n");

   void Toggle_Fullts () {
   bprint(PRINT_HIGH, "Full Team Score set to ", st, " \n");

   void Toggle_Grapple () {
   bprint(PRINT_HIGH, "Grapple set to ", st, " \n");

   void Toggle_Gibs () {
   bprint(PRINT_HIGH, "Gibs set to ", st, " \n");

   void Toggle_Highlander () {
   bprint(PRINT_HIGH, "Highlander mode set to ", st, " \n");
 */

void ResetSetup () {
    cvar_set("teamplay", "21?TeamFortress");
    cvar_set("timelimit", "40");
    localcmd("localinfo sentrytype 0\n");
    localcmd("localinfo pipedelay on\n");
    localcmd("localinfo tfvsdm off\n");
    localcmd("localinfo clan off\n");
    localcmd("localinfo teamfrags on\n");
    localcmd("localinfo fullteamscore off\n");
    localcmd("localinfo grapple off\n");
    localcmd("localinfo rounds off\n");
    localcmd("localinfo duel off\n");
    localcmd("localinfo speedcap off\n");
    RestartMap();
}

void ClanSetup () {
    float f1;
    cvar_set("teamplay", "1?TeamFortress");
    cvar_set("timelimit", "35");
    localcmd("localinfo prematch 5\n");
    localcmd("localinfo sentrytype 0\n");
    localcmd("localinfo pipedelay on\n");
    localcmd("localinfo clan on\n");
    localcmd("localinfo teamfrags on\n");
    localcmd("localinfo fullteamscore off\n");
    localcmd("localinfo grapple off\n");
    localcmd("localinfo rounds off\n");
    localcmd("localinfo duel off\n");
    localcmd("localinfo speedcap off\n");
    f1 = stof(infokey(world, "fpd"));
    if (!(f1 & 256)) {
        localcmd("serverinfo fpd ");
        f1 = (f1 | 256);
        localcmd(ftos(f1));
        localcmd("\n");
    }
    localcmd("serverinfo fbskins 0\n");
    localcmd("localinfo observermode off\n");
    RestartMap();
}

void Toggle_Quad () {
    cvar_set("teamplay", "1?TeamFortress");
    cvar_set("timelimit", "10");
    localcmd("localinfo prematch 3\n");
    localcmd("localinfo clan on\n");
    localcmd("localinfo teamfrags on\n");
    localcmd("localinfo fullteamscore off\n");
    localcmd("localinfo duel off\n");
    localcmd("localinfo speedcap off\n");
    // localcmd("localinfo cr_soldier 1\n");
    localcmd("localinfo quadmode on\n");
    RestartMap();
}
/*

   void Toggle_Observer () {
   string st;
   if (( !allow_ttrack )) {
   allow_ttrack = 1;
   st = "on";
   localcmd("localinfo obs_teamtrack on\n");
   } else {
   allow_ttrack = 0;
   st = "off";
   localcmd("localinfo obs_teamtrack off\n");
   }
   bprint(PRINT_HIGH, " ");
   bprint(PRINT_HIGH, "Observer Team-Only Tracking set to ", st, " \n");
   };
 */

void TogglePointing () {
    float f1, f2;
    string s1;
    bprint(PRINT_HIGH, " ");
    f1 = stof(infokey(world, "fpd"));
    f2 = f1 - (f1 & 128);
    if (f1 & 128) {
        localcmd("serverinfo fpd ");
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "ποιξτιξη enabled\n");
        return;
    } else {
        localcmd("serverinfo fpd ");
        f2 = f2 + 128;
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "ποιξτιξη disabled\n");
    }
}

void ToggleEnemy () {
    float f1, f2;
    string s1;
    bprint(PRINT_HIGH, " ");
    f1 = stof(infokey(world, "fpd"));
    f2 = f1 - (f1 & 32);
    if (f1 & 32) {
        localcmd("serverinfo fpd ");
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "enemy reporting allowed\n");
        return;
    } else {
        localcmd("serverinfo fpd ");
        f2 = f2 + 32;
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "enemy reporting disallowed\n");
    }
}

void ToggleFbskins () {
    float f1, f2;
    string s1;
    bprint(PRINT_HIGH, " ");
    f1 = stof(infokey(world, "fpd"));
    f2 = f1 - (f1 & 256);
    if (f1 & 256) {
        localcmd("serverinfo fpd ");
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        localcmd("serverinfo fbskins 1\n");
        bprint(PRINT_HIGH, "Fullbright skins enabled\n");
        return;
    } else {
        localcmd("serverinfo fpd ");
        f2 = f2 + 256;
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        localcmd("serverinfo fbskins 0\n");
        bprint(PRINT_HIGH, "Fullbright skins disabled\n");
    }
}

void Toggle_Frj () {
    float f1, f2;
    string s1;
    bprint(PRINT_HIGH, " ");
    f1 = stof(infokey(world, "fpd"));
    f2 = f1 - (f1 & 32768);
    if (f1 & 32768) {
        localcmd("serverinfo fpd ");
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "Forward Rocketjump enabled\n");
        return;
    } else {
        localcmd("serverinfo fpd ");
        f2 = f2 + 32768;
        s1 = ftos(f2);
        localcmd(s1);
        localcmd("\n");
        bprint(PRINT_HIGH, "Forward Rocketjump disabled\n");
    }
}

void Toggle_flag_emu () {
    string st;
    float fl;
    fl = stof(infokey (world,"flag_model"));
    if (fl == 0) {
        fl = 1;
        st = "TF Flag.";
    } else if (fl == 1) {
        fl = 2;
        st = "TF Standard.";
    } else if (fl == 2) {
        fl = 3;
        st = "CTF Flag.";
    } else {
        fl = 0;
        st = "Map default.";
    }
    localcmd("localinfo flag_model ");
    localcmd(ftos(fl));
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Goal Item model set to ", st, " \n");
}

void Toggle_Grenpacks () {
    string st;
    st = infokey (world,"grenpacks");
    bprint(PRINT_HIGH, " ");
    if ( (st == "on") ) {
        st = "off";
        allow_grenpack = 0;
        bprint(PRINT_HIGH, "Backpacks Normal.\n");
    } else {
        st = "on";
        allow_grenpack = 1;
        bprint(PRINT_HIGH, "Backpacks now Include Grenades / Detpack.\n");
    }
    localcmd("localinfo grenpacks ");
    localcmd(st);
    localcmd("\n");
}

void Toggle_SentryType () {
    string st;
    bprint(PRINT_HIGH, " ");
    if (sgtype == 0) {
        sgtype = 1;
        bprint(PRINT_HIGH, "Sentries Special (Oztf).\n");
    } else {
        sgtype = 0;
        bprint(PRINT_HIGH, "Sentries Normal (TF 2.9).\n");
    }
    st = ftos(sgtype);
    localcmd("localinfo sentrytype ");
    localcmd(st);
    localcmd("\n");
}

void Toggle_SentryFire () {
    string st;
    float fl;
    if (!sgtype) {
        if (self == world) {
            dprint("Sentry type is currently Normal. Change sentry type to enable firing mode.\n");
        } else {
            sprint (self, PRINT_HIGH, "Sentry type is currently Normal. Change sentry type to enable firing mode.\n");
        }
        return;
    }
    st = infokey (world,"sentryfire");
    fl = stof(st);
    if ( (fl < 1) || (fl > 2) ) {
        st = "Lightning";
        sentry_fire = 1;
    } else if (fl == 1) {
        st = "Laser";
        sentry_fire = 2;
    } else {
        st = "Normal";
        sentry_fire = 0;
    }
    localcmd("localinfo sentryfire ");
    localcmd(ftos(sentry_fire));
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Sentry Fire set to ", st, " \n");
}

void Toggle_PipeDelay () {
    string st;
    st = infokey (world,"pipedelay");
    if ( (st == "off") ) {
        st = "on";
        pipedelay = 1;
    } else {
        st = "off";
        pipedelay = 0;
    }
    localcmd("localinfo pipedelay ");
    localcmd(st);
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Demoman Pipebomb Delay set to ", st, " \n");
}

void Toggle_Detpack () {
    string st;
    st = infokey (world,"soliddet");
    if ( (st == "on") ) {
        st = "off";
    } else {
        st = "on";
    }
    localcmd("localinfo soliddet ");
    localcmd(st);
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Solid Detpacks σετ το ", st, " \n");
}

void Toggle_Lighting () {
    if (lights) {
        Deluminate();
    } else {
        Eluminate();
    }
}

void Give_Quad () {
    if (!self.playerclass || self.deadflag) return;
    sound (self,2,"items/damage.wav",1,1);
    stuffcmd (self,"bf\n");
    self.items = (self.items | 4194304);
    self.super_time = 1;
    self.super_damage_finished = (time + 300);
}

void Give_Eyes () {
    if (!self.playerclass || self.deadflag) return;
    sound (self,2,"items/inv1.wav",1,1);
    stuffcmd (self,"bf\n");
    self.items = (self.items | 524288);
    self.invisible_time = 1;
    self.invisible_finished = (time + 30);
}

void Give_Pent () {
    if (!self.playerclass || self.deadflag) return;
    sound (self,2,"items/protect.wav",1,1);
    stuffcmd (self,"bf\n");
    self.items = (self.items | 1048576);
    self.invincible_time = 1;
    self.invincible_finished = (time + 300);
}

void AbortMiscVote () {
    entity p;
    v_misc = 0;
    p = player_head;
    while (p) {
        if (p.netname != "") {
            p.mvote = 0;
        }
        p = p.nextp;
    }
    p = find(world, classname, "miscvote");
    // Kill timeout checker entity
    if (p.classname == "miscvote") dremove(p);
}

void MiscVoteThink () {
    bprint(PRINT_HIGH, "The voting has timed out.\nVote aborted\n");
    self.nextthink = -1;
    AbortMiscVote();
}

void AgreeMiscVote () {
    float f1, f2;
    string tmp;
    entity mv;
    if (intermission_running) return;
    if (self.classname != "player") return;
    if (self.allowvote > time) {
        return;
    }
    self.allowvote = time + 3;
    if (self.mvote) {
        bprint(PRINT_HIGH, self.netname, " χιτθδςαχσ ");
        if (infokey(self, "gender") == "f") bprint(PRINT_HIGH, "θες ");
        else bprint(PRINT_HIGH, "θισ ");
        bprint(PRINT_CHAT, "vote\n");
        self.mvote = 0;
        v_misc = v_misc - 1;
        return;
    }
    self.mvote = 1;
    v_misc = v_misc + 1;
    f1 = TeamFortress_GetNoPlayers ();
    f2 = (floor(f1 / 2)) + 1;
    if (v_misc >= f2) {
        mv = find(world, classname, "miscvote");
        if (mv.classname == "miscvote") {
            if (mv.weapon == 1) {
                localcmd("map ");
                localcmd(mv.netname);
                localcmd("\n");
            } else if (mv.weapon == 2) {
                Toggle_Misc(mv.netname);
            }
            AbortMiscVote();
            return;
        }
    }
    if ( v_misc != 0 ) {
        f1 = f2 - v_misc;
        tmp = ftos(f1);
        bprint(PRINT_HIGH, "", tmp, "‘ more vote");
        if (f1 > 1) bprint(PRINT_HIGH, "s");
        bprint(PRINT_HIGH, " needed\n");
    }
}

void PlayerMiscVote (string Misc, float type) {
    float f1, f2;
    string st, tmp;
    entity miscvote;
    if (intermission_running) return;
    if (self.classname != "player")
        return;
    if ((modetype & 1) && (!cb_prematch))
        return;
    if (v_misc) {
        sprint (self, PRINT_HIGH, "Vote currently active. You cannot vote at this time.\n");
        return;
    }
    tmp = infokey (world,"votetime");
    f1 = (stof(tmp) * 60);
    if (f1 > time) {
        sprint (self, PRINT_HIGH, "You cannot vote at this time.\n");
        return;
    }
    if (self.mvote == 2) {
        bprint(PRINT_HIGH, self.netname, " χιτθδςαχσ ");
        if (infokey(self, "gender") == "f") bprint(PRINT_HIGH, "θες ");
        else bprint(PRINT_HIGH, "θισ ");
        bprint(PRINT_CHAT, "vote\n");
        self.mvote = 0;
        v_misc = v_misc - 1;
        AbortMiscVote ();
        return;
    }
    if (Misc != string_null) {
        bprint(PRINT_HIGH, self.netname);
        if (type == 1)   bprint(PRINT_CHAT, " votes for map ");
        else if (type == 2)  bprint(PRINT_CHAT, " votes for mode ");
        else if (type == 3)  bprint(PRINT_CHAT, " votes for setting ");
        bprint(PRINT_HIGH, Misc, "\n");
        miscvote = spawn();
        miscvote.owner = world;
        miscvote.classname = "miscvote";
        miscvote.think = MiscVoteThink;
        miscvote.weapon = type;
        tmp = infokey (world,"vote_timeout");
        f1 = stof(tmp);
        if ((f1 > 10) && (f1 < 120)) {
            miscvote.nextthink = time + f1;
        } else {
            miscvote.nextthink = time + 30;
        }
    }
    if (type == 1) {
        st = strstr (Misc, ".bsp");
        if (st != string_null) {
            f1 = strlen (Misc);
            tmp = substr(Misc , 0 , f1 - 4);
        }
    }
    miscvote.netname = Misc;
    self.mvote = 2;
    v_misc = v_misc + 1;
    f1 = TeamFortress_GetNoPlayers ();
    f2 = (floor(f1 / 2)) + 1;
    if (v_misc >= f2) {
        if (type == 1) {
            localcmd("map ");
            localcmd(Misc);
            localcmd("\n");
        } else if (type == 2) {
            Toggle_Misc(Misc);
        }
        v_misc = 0;
        self.mvote = 0;
        dremove (miscvote);
        return;
    }
    sprint (self, PRINT_HIGH, "Type cmd abort, to abort vote\n");
    if ( v_misc != 0 ) {
        f1 = f2 - v_misc;
        st = ftos(f1);
        bprint(PRINT_HIGH, "", tmp, "‘ more vote");
        if (f1 > 1) bprint(PRINT_HIGH, "s");
        bprint(PRINT_HIGH, " needed\n");
    }
}

void RandomPickup () {
    entity te;
    float fl;
    float fl2;
    float fl3;
    float fl4;
    float fl5;
    float fl6;
    float fl7;
    if (!cb_prematch) {
        return;
    }
    if (!teamplay) {
        sprint (self,PRINT_HIGH, "Teamplay is not set.\n");
        return;
    }
    if (store_obs.cnt != 2) {
        sprint (self,PRINT_HIGH, "This command can only be used with 2 teams.\n");
        return;
    }
    fl2 = 1;
    fl3 = 0;
    fl4 = 0;
    fl = TeamFortress_GetNoPlayers  ();
    if ((fl < 3)) {
        sprint (self,PRINT_HIGH, "You need at least 3 players to do this\n");
        return;
    }
    fl3 = fl / 2;
    te = player_head;
    while (te) {
        if ((te.netname != "")) {
            //stuffcmd (te, "color 0\nteam \"\"\n");
            fl5 = random ();
            fl5 = random ();
            if ((fl6 >= fl3)) {
                te.pteam = pteam2;
            } else {
                if ((fl7 >= fl3)) {
                    te.pteam = pteam1;
                } else {
                    if ((fl5 < 0.500000)) {
                        fl6 =  fl6 + 1;
                        te.pteam = pteam1;
                    } else {
                        fl7 = fl7 + 1;
                        te.pteam = pteam2;
                    }
                }
            }
        }
        SetTeam(te);
        te = te.nextp;
    }
}

void TogglePowerups () {
    string st;
    bprint (PRINT_HIGH, " Ποχεςυπσ ");
    if (powerups) {
        bprint (PRINT_HIGH, "disabled\n");
        PowerupsOff ();
        powerups = 0;
        st = "off";
    } else {
        bprint (PRINT_HIGH, "enabled\n");
        PowerupsOn ();
        powerups = 1;
        st = "on";
    }
    localcmd("localinfo powerups ");
    localcmd(st);
    localcmd("\n");
}

void ToggleSpecMsgs () {
    string st;
    if (!spec_msgs) {
        spec_msgs = 1;
        st = "on";
    } else {
        spec_msgs = 0;
        st = "off";
    }
    localcmd("localinfo spec_msgs ");
    localcmd(st);
    localcmd("\n");
    bprint(PRINT_HIGH, " ");
    bprint(PRINT_HIGH, "Messages for spectators  σετ το ", st, " \n");
}

void unpause_player (entity p) {
    msg_entity = p;
    WriteByte (1, 24);
    WriteByte (1, 0);
}

void pause_player (entity p) {
    msg_entity = p;
    WriteByte (1, 24);
    WriteByte (1, 1);
}

void PausePlayers () {
    entity te;
    te = find (world, classname, "player");
    while (te) {
        if ((te.netname != "")) {
            pause_player (te);
        }
        te = find (te, classname, "player");
    }
    te = find (world, classname, "spectator");
    while (te) {
        if ((te.netname != "")) {
            pause_player (te);
        }
        te = find (te, classname, "spectator");
    }
}
