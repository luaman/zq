/*
    tfort-help.qc

    qwtf's help motd functions/definitions

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

void TeamFortress_MOTD () {
    string ya;
    if ( (self.motd <= 20) ) {
        self.motd = (self.motd + 1);
        return ;
    }
    if ( (!self.get_aliases) ) {
        return ;
    }
    if ( (self.motd == 21) ) {
        if ( ((teamplay != 0) && (self.pteam.team == 0)) ) {
            stuffcmd (self,"color ");
            ya = ftos (0);
            stuffcmd (self,ya);
            stuffcmd (self,"\n");
            stuffcmd (self,"team observe\n");
        }
        if ( (self.get_aliases) ) {
            sprint (self,PRINT_HIGH,"\n\n\n");
        }

        sprint (self,PRINT_HIGH,"Oz Team Fortress v1.77a\nhttp://quakeworld.nu/forum/\n");
        self.menu_displaytime = 0;
        self.current_menu = 5;
        self.menu_count = 25;
        self.motd = 22;
        if ( (!self.get_aliases) ) {
            return ;
        }
        sprint (self,PRINT_HIGH,"binding aliases...\n");
        TeamFortress_Alias ("inv",135,0);
        TeamFortress_Alias ("showtf",136,0);
        TeamFortress_Alias ("changeclass",99,0);
        TeamFortress_Alias ("changeteam",95,0);
        TeamFortress_Alias ("scout",(100 + 1),0);
        if (classtype & 1) {
            TeamFortress_Alias ("technician",(100 + 2),0);
        } else {
            TeamFortress_Alias ("sniper",(100 + 2),0);
        }
        TeamFortress_Alias ("soldier",(100 + 3),0);
        TeamFortress_Alias ("demoman",(100 + 4),0);
        TeamFortress_Alias ("medic",(100 + 5),0);
        TeamFortress_Alias ("hwguy",(100 + 6),0);
        TeamFortress_Alias ("pyro",(100 + 7),0);
        TeamFortress_Alias ("spy",(100 + 8),0);
        TeamFortress_Alias ("engineer",(100 + 9),0);
        TeamFortress_Alias ("randompc",(100 + 10),0);
        return ;
    }
    if ( (self.motd <= 80) ) {
        self.motd = (self.motd + 1);
    }
    if (self.classname == "observer" && self.motd < 60) return;
    if ( (self.motd == 30) ) {
        TeamFortress_Alias ("autozoom",174,0);
        TeamFortress_Alias ("scansound",162,0);
        TeamFortress_Alias ("autoscan",159,0);
        TeamFortress_Alias ("scanf",161,0);
        TeamFortress_Alias ("scane",160,0);
        TeamFortress_Alias ("dropammo",172,0);
        TeamFortress_Alias ("dropitems",194,0);
        TeamFortress_Alias ("saveme",181,0);
        TeamFortress_Alias ("discard",184,0);
        TeamFortress_Alias ("id",185,0);
        TeamFortress_Alias ("detpipe",170,0);
        TeamFortress_Alias ("reload",173,0);
        return ;
    }
    if ( (self.motd == 35) ) {
        TeamFortress_Alias ("gren1", 90,0);
        TeamFortress_Alias ("gren2", 91,0);
        TeamFortress_Alias ("primeone", 150,0);
        TeamFortress_Alias ("primetwo", 151,0);
        TeamFortress_Alias ("throwgren",152,0);
        TeamFortress_Alias ("+gren1",150,0);
        TeamFortress_Alias ("+gren2",151,0);
        TeamFortress_Alias ("-gren1",152,0);
        TeamFortress_Alias ("-gren2",152,0);
        return ;
    }
    if ( (self.motd == 40) ) {
        TeamFortress_Alias ("weapnext",10,0);
        TeamFortress_Alias ("weapprev",11,0);
        if (modetype & 4) {
            TeamFortress_Alias ("+bomb",166,0);
            TeamFortress_Alias ("-bomb",169,0);
            TeamFortress_Alias ("dropbomb",180,0);
            return ;
        } else {
            TeamFortress_Alias ("+det5",164,0);
            TeamFortress_Alias ("-det5",169,0);
            TeamFortress_Alias ("+det20",165,0);
            TeamFortress_Alias ("-det20",169,0);
            TeamFortress_Alias ("+det50",166,0);
            TeamFortress_Alias ("-det50",169,0);
            TeamFortress_Alias ("+det255",167,0);
            TeamFortress_Alias ("-det255",169,0);
            return ;
        }
        return ;
    }
    if ( (self.motd == 50) ) {
        TeamFortress_Alias ("+sbar",182,0);
        TeamFortress_Alias ("-sbar",183,0);
        TeamFortress_Alias ("sbar_on",182,0);
        TeamFortress_Alias ("sbar_off",183,0);
        TeamFortress_Alias ("sbar_200",71,1);
        TeamFortress_Alias ("sbar_240",71,2);
        TeamFortress_Alias ("sbar_300",71,3);
        TeamFortress_Alias ("sbar_350",71,4);
        TeamFortress_Alias ("sbar_384",71,5);
        TeamFortress_Alias ("sbar_400",71,6);
        TeamFortress_Alias ("sbar_480",71,7);
        TeamFortress_Alias ("sbar_600",71,8);
        TeamFortress_Alias ("sbar_768",71,9);
        return ;
    }
    if ( (self.motd == 60) ) {
        TeamFortress_Alias ("showtouches",75,0);
        TeamFortress_Alias ("disguise",177,0);
        TeamFortress_Alias ("feign",178,0);
        TeamFortress_Alias ("sfeign",199,0);
        TeamFortress_Alias ("build",179,0);
        TeamFortress_Alias ("detsentry",188,0);
        TeamFortress_Alias ("detdispenser",187,0);
        TeamFortress_Alias ("voicemenu",67,0);
        TeamFortress_Alias ("voice_def",68,0);
        TeamFortress_Alias ("voice_off",69,0);
        TeamFortress_Alias ("voice_gen",70,0);
        stuffcmd (self,"bind 9 \"impulse 9\"\n");
        return ;
    }
    if ( (self.motd == 70) ) {
        TeamFortress_Alias ("showfrags",72,0);
        TeamFortress_Alias ("showfps",73,0);
        TeamFortress_Alias ("showstats",74,0);
        TeamFortress_Alias ("showspeed",115,0);
        TeamFortress_Alias ("showloc",118,0);
        TeamFortress_Alias ("showclasses",144,0);
        TeamFortress_Alias ("tracking",41,0);
        TeamFortress_Alias ("track_player",42,0);
        TeamFortress_Alias ("track_tfgoal",43,0);
        TeamFortress_Alias ("track_sentry",44,0);
        TeamFortress_Alias ("+movein",112,0);
        TeamFortress_Alias ("+moveout",113,0);
        TeamFortress_Alias ("-movein",114,0);
        TeamFortress_Alias ("-moveout",114,0);
        TeamFortress_Alias ("autotrack",86,0);
    }
    if ( (self.motd == 80) ) {
        TeamFortress_Alias ("commands",88,0);
        TeamFortress_Alias ("agree",77,0);
        TeamFortress_Alias ("scores", 76,0);
        TeamFortress_Alias ("special",171,0);
        TeamFortress_Alias ("id",185,0);
        TeamFortress_Alias ("query",119,0);
        TeamFortress_Alias ("elect",82,0);
        TeamFortress_Alias ("yes",83,0);
        TeamFortress_Alias ("no",84,0);
        TeamFortress_Alias ("break",85,0);
        TeamFortress_Alias ("about",87,0);
        TeamFortress_Alias ("modstatus",89,0);
        TeamFortress_Alias ("flaginfo",23,0);
        TeamFortress_Alias ("maphelp",131,0);
        if ( self.is_admin ) {
            if (self.get_admin_aliases) {
                Admin_Aliases();
            }
        }
        self.get_aliases = 0;
    }
}

void TeamFortress_HelpMap () {
    entity te;
    te = find (world,classname,"info_tfdetect");
    if ( te ) {
        if ( (te.non_team_broadcast != string_null) ) {
            sprint (self,PRINT_HIGH,te.non_team_broadcast);
            return ;
        }
    }
    sprint (self,PRINT_HIGH,"There is no help for this map.\n");
}
