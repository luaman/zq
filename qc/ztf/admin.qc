/*
    admin.qc

    admin functions/definitions

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

void StopTimer ();

void Admin_CountPlayers () {
    string st;
    float nump;
    nump = TeamFortress_GetNoPlayers ();
    st = ftos (nump);
    sprint (self,PRINT_HIGH,"Players In Game : ",st,"\n");
    if ( (store_obs.cnt > 0) ) {
        nump = TeamFortress_TeamGetNoPlayers (1);
        st = ftos (nump);
        sprint (self,PRINT_HIGH,"Players In Team1: ",st,"\n");
    }
    if ( (store_obs.cnt > 1) ) {
        nump = TeamFortress_TeamGetNoPlayers (2);
        st = ftos (nump);
        sprint (self,PRINT_HIGH,"Players In Team2: ",st,"\n");
    }
    if ( (store_obs.cnt > 2) ) {
        nump = TeamFortress_TeamGetNoPlayers (3);
        st = ftos (nump);
        sprint (self,PRINT_HIGH,"Players In Team3: ",st,"\n");
    }
    if ( (store_obs.cnt > 3) ) {
        nump = TeamFortress_TeamGetNoPlayers (4);
        st = ftos (nump);
        sprint (self,PRINT_HIGH,"Players In Team4: ",st,"\n");
    }
}

void Admin_ListPlayers () {
    entity pl;
    float num;
    string st;
    if ( (TeamFortress_GetNoPlayers () <= 1) ) {
        sprint (self,PRINT_HIGH,"No other players in the game.\n");
        return ;
    }
    pl = player_head;
    while ( (pl != world) ) {
        if ( ((pl.netname != string_null) && (pl != self)) ) {
            num = EntityNum (pl);
            st = ftos(num);
            sprint (self,PRINT_HIGH,pl.netname);
            sprint (self,PRINT_HIGH,"   ");
            sprint (self,PRINT_HIGH, st);
            sprint (self,PRINT_HIGH,"\n");
        }
        pl = pl.nextp;
    }
    pl = spec_head;
    while ( (pl != world) ) {
        if ( ((pl.netname != string_null) && (pl != self)) ) {
            num = EntityNum (pl);
            st = ftos(num);
            sprint (self,PRINT_HIGH,pl.netname);
            sprint (self,PRINT_HIGH,"   ");
            sprint (self,PRINT_HIGH, st);
            sprint (self,PRINT_HIGH,"\n");
            sprint (self,PRINT_HIGH," (SPECTATOR)\n");
        }
        pl = pl.nexts;
    }
    sprint (self,PRINT_HIGH,"End of player list\n");
    pl = world;
}

void Admin_ListIPs () {
    entity pl;
    if ( (TeamFortress_GetNoPlayers () <= 1) ) {
        sprint (self,PRINT_HIGH,"No other players in the game.\n");
        return ;
    }
    pl = player_head;
    while ( (pl != world) ) {
        if ( ((pl.netname != string_null) && (pl != self)) ) {
            pl.ip = infokey (pl,"ip");
            sprint (self,PRINT_HIGH,pl.netname);
            sprint (self,PRINT_HIGH," (");
            sprint (self,PRINT_HIGH,pl.ip);
            sprint (self,PRINT_HIGH,")");
            sprint (self,PRINT_HIGH,"\n");
        }
        pl = pl.nextp;
    }
    pl = spec_head;
    while ( (pl != world) ) {
        if ( ((pl.netname != string_null) && (pl != self)) ) {
            pl.ip = infokey (pl,"ip");
            sprint (self,PRINT_HIGH,pl.netname);
            sprint (self,PRINT_HIGH," (");
            sprint (self,PRINT_HIGH,pl.ip);
            sprint (self,PRINT_HIGH,")");
            sprint (self,PRINT_HIGH," (SPECTATOR)\n");
        }
        pl = pl.nexts;
    }
    sprint (self,PRINT_HIGH,"End of player list\n");
    pl = world;
}

void Admin_DoKick () {
    bprint (PRINT_HIGH,self.admin_use.netname," was kicked by ",self.netname,"\n");
    stuffcmd (self.admin_use,"disconnect\n");
    stuffcmd (self.admin_use,"cmd drop\n");
    self.admin_mode = 0;
    self.admin_use = world;
}

void Admin_KickNum (float num) {
    if ( (TeamFortress_GetNoPlayers () <= 1) ) {
        sprint (self,PRINT_HIGH,"No other players in the game.\n");
        return ;
    }
    if (num < 1) {
        sprint (self,PRINT_HIGH,"Number invalid - player not found.\n");
        self.admin_use = world;
        return ;
    }
    self.admin_use = NumEntity(num);
    if ( self.admin_use.classname == "player" || self.admin_use.classname == "observer") {
        Admin_DoKick();
    } else {
        sprint (self,PRINT_HIGH,"Number invalid - player not found.\n");
        self.admin_use = world;
        self.admin_mode = 0;
        return ;
    }
}

void Admin_CycleDeal () {
    if ( (TeamFortress_GetNoPlayers () <= 1) ) {
        sprint (self,PRINT_HIGH,"No other players in the game.\n");
        self.admin_use = world;
        self.admin_mode = 0;
        return ;
    }
    if ( (self.admin_use.classname != "observer") ) {
        self.admin_use = player_head;
        while ( ((self.admin_use != world) && ((self.admin_use.netname == string_null) || (self.admin_use == self))) ) {
            self.admin_use = self.admin_use.nextp;
        }
        if ( (self.admin_use == world) ) {
            self.admin_use = spec_head;
            while ( ((self.admin_use != world) && ((self.admin_use.netname == string_null) || (self.admin_use == self))) ) {
                self.admin_use = self.admin_use.nexts;
            }
        }
    } else {
        self.admin_use = spec_head;
        while ( ((self.admin_use != world) && ((self.admin_use.netname == string_null) || (self.admin_use == self))) ) {
            self.admin_use = self.admin_use.nexts;
        }
    }
    if ( self.admin_use ) {
        self.admin_use.ip = infokey (self.admin_use,"ip");
        self.admin_mode = 1;
        sprint (self,PRINT_HIGH,"�   ");
        sprint (self,PRINT_HIGH,self.admin_use.netname);
        sprint (self,PRINT_HIGH," (",self.admin_use.ip,")");
        if ( (self.admin_use.classname == "observer") ) {
            sprint (self,PRINT_HIGH," (SPECTATOR)");
        }
        sprint (self,PRINT_HIGH,"\n");
        sprint (self,PRINT_HIGH,"   KICK/NEXT?\n");
    } else {
        self.admin_mode = 0;
        sprint (self,PRINT_HIGH,"End of player list\n");
    }
}

void CeaseFire_think () {
    entity te;
    if ( !cease_fire ) {
        dremove (self);
        return ;
    }
    te = player_head;
    while ( te ) {
        CenterPrint3 (te,"CEASE FIRE\nCalled by: ",self.owner.netname,"\n");
        te = te.nextp;
    }
    self.nextthink = (time + 5);
}

void Admin_CeaseFire () {
    entity te;
    if ( !cease_fire ) {
        if (cb_prematch) {
            StopTimer();
        }
        cease_fire = 1;
        bprint (PRINT_HIGH,"CEASE FIRE\n");
        te = player_head;
        while ( te ) {
            CenterPrint3 (te,"CEASE FIRE\nCalled by: ",self.netname,"\n");
            //te.immune_to_check = (time + 5);
            te.tfstate = (te.tfstate | 65536);
            TeamFortress_SetSpeed (te);
            te = te.nextp;
        }
        te = spawn ();
        te.owner = self;
        te.classname = "ceasefire";
        te.think = CeaseFire_think;
        te.nextthink = (time + 5);
    } else {
        te = find (world,classname,"ceasefire");
        if ( te ) {
            dremove (te);
        }
        cease_fire = 0;
        if (cb_prematch) {
            pmtime = 0;
            StartTimer();
        }
        bprint (PRINT_HIGH,"RESUME FIRE\n");
        te = player_head;
        while ( te ) {
            CenterPrint3 (te,"RESUME FIRE\nCalled by: ",self.netname,"\n");
            //te.immune_to_check = (time + 5);
            te.tfstate = (te.tfstate - (te.tfstate & 65536));
            TeamFortress_SetSpeed (te);
            te = te.nextp;
        }
    }
}

void autokick_think () {
    self.owner.teamkills = 0;
    dremove (self);
}

void CheckAutoKick (entity p) {
    float rnum;
    entity te;
    if ( ((p.teamkills >= autokick_kills) && (autokick_kills != 0)) ) {
        bprint (PRINT_HIGH,p.netname," was kicked for killing teammates.\n");
        sprint (p,PRINT_HIGH,"You were kicked for killing teammates.\n");
        stuffcmd (p,"disconnect\n");
    } else {
        if ( (autokick_kills != 0) ) {
            if ( (p.teamkills == (autokick_kills - 1)) ) {
                sprint (p,PRINT_HIGH,"Kill one more teammate, and you're outta here.\n");
            }
            rnum = 0;
            te = find (world,classname,"ak_timer");
            while ( te ) {
                if ( (te.owner == p) ) {
                    rnum = 1;
                    te = world;
                } else {
                    te = find (te,classname,"ak_timer");
                }
            }
            if ( (rnum == 0) ) {
                te = spawn ();
                te.classname = "ak_timer";
                te.owner = p;
                te.think = autokick_think;
                te.nextthink = (time + autokick_time);
            }
        }
    }
}

void AbortElect () {
    entity p;
    elect = 0;
    p = find(world, classname, "player");
    while (p != world) {
        if (p.netname != "") {
            p.vote = 0;
            if (p.is_admin == 2) p.is_admin = 0;
        }
        p = find(p, classname, "player");
    }
    p = find(world, classname, "spectator");
    while (p != world) {
        if (p.netname != "" && p.is_admin == 2)	p.is_admin = 0;
        p = find(p, classname, "spectator");
    }
    p = find(world, classname, "electguard");
    // Kill timeout checker entity
    if (p.classname == "electguard") dremove(p);
}

void ElectThink () {
    bprint(PRINT_HIGH, "The voting has timed out.\nElection aborted\n");
    self.nextthink = -1;
    AbortElect();
}

void VoteAdmin () {
    float f1, f2, f3;
    string tmp;
    entity electguard;
    if (self.electtime > time) {
        sprint (self, PRINT_HIGH, "You cannot elect at this time.\n");
        return;
    }
    self.electtime = time + 3;
    if ((self.is_admin == 1) || (self.is_admin == 3)) {
        sprint (self, PRINT_HIGH, "You are already an admin\n");
        return;
    }
    if (self.is_admin == 2) {
        bprint(PRINT_HIGH, self.netname, " aborts election!");
        bprint(PRINT_CHAT, "\n");
        AbortElect();
        return;
    }
    // Only one election per server because otherwise we wouldn't know how to count
    // "yes"s or "no"s
    if (elect != 0) {
        sprint (self, PRINT_HIGH, "An election is already in progress\n");
        return;
    }
    bprint(PRINT_HIGH, self.netname, " has requested admin rights!\n");
    self.is_admin = 2;
    elect = 1;
    tmp = infokey (world,"votespercentage");
    f3 = stof(tmp);
    if (f3 < 5 || f3 > 95) {
        f3 = 50;
    }
    f3 = f3 / 100;
    f1 = TeamFortress_GetNoPlayers ();
    f2 = (elect / f1);
    if (f2 > f3) {
        if (self.is_admin == 2) {
            bprint(PRINT_HIGH, self.netname, " ����� ����� ������!");
            bprint(PRINT_CHAT, "\n");
            sprint (self, PRINT_HIGH, "Type �������� for admin commands.\n");
            self.is_admin = 1;
            self.get_admin_aliases = 1;
            elect = 0;
        }
    } else {
        bprint(PRINT_HIGH, "Type");
        bprint(PRINT_CHAT, " yes");
        bprint(PRINT_HIGH, " in console to approve\n");
        sprint (self, PRINT_HIGH, "Type ����� to abort election\n");
        electguard = spawn(); // Check the 1 minute timeout for election
        electguard.owner = world;
        electguard.classname = "electguard";
        electguard.think = ElectThink;
        electguard.nextthink = time + 60;
    }
}

void VoteYes () {
    float f1, f2, f3;
    string tmp;
    entity p;
    if ( !elect) {
        return;
    }
    if (self.is_admin == 2) {
        sprint (self, PRINT_HIGH, "You cannot vote for yourself\n");
        return;
    }
    if (self.vote) {
        sprint (self, PRINT_HIGH, "--- your vote is still good ---\n");
        return;
    }
    // register the vote
    elect = elect + 1;
    bprint(PRINT_HIGH, self.netname, " gives ");
    if (infokey(self, "gender") == "f") bprint(PRINT_HIGH, "her");
    else bprint(PRINT_HIGH, "his");
    bprint(PRINT_HIGH, " vote\n");
    self.vote = 1;
    tmp = infokey (world,"votespercentage");
    f3 = stof(tmp);
    if (f3 < 5 || f3 > 95) {
        f3 = 50;
    }
    f3 = f3 / 100;
    f1 = TeamFortress_GetNoPlayers ();
    f2 = (elect / f1);
    if (f2 >= f3) {
        p = find(world, classname, "player");
        while (p.is_admin != 2) p = find(p, classname, "player");
        if (p.is_admin == 2) {
            // s: election was admin election
            bprint(PRINT_HIGH, p.netname, " ����� ����� ������!");
            bprint(PRINT_CHAT, "\n");
            sprint (p,PRINT_HIGH, "Type �������� for admin commands.\n");
            p.is_admin = 1;
            p.get_admin_aliases = 1;
            AbortElect();
        }
        self.vote = 0;
    }
    // calculate how many more votes are needed
    if ( elect != 0 ) {
        f1 = f2 - elect;
        tmp = ftos(rint(f1));
        bprint(PRINT_HIGH, "�", tmp, "� more vote");
        if (f1 > 1) bprint(PRINT_HIGH, "s");
        bprint(PRINT_HIGH, " needed\n");
    }
}

void VoteNo () {
    float f1, f2;
    string tmp;
    // withdraw one's vote
    if (self.is_admin == 1)  {
        return;
    }
    if (elect == 0 || self.is_admin == 2 || self.vote == 0) return;
    bprint(PRINT_HIGH, self.netname, " withdraws ");
    if (infokey(self, "gender") == "f") bprint(PRINT_HIGH, "her");
    else bprint(PRINT_HIGH, "his");
    bprint(PRINT_HIGH, " vote\n");
    self.vote = 0;
    elect = elect - 1;
    f1 = TeamFortress_GetNoPlayers ();
    f2 = (floor(f1 / 2)) + 1;
    f1 = f2 - elect;
    tmp = ftos(f1);
    bprint(PRINT_HIGH, "�", tmp, "� more vote");
    if (f1 > 1) bprint(PRINT_HIGH, "s");
    bprint(PRINT_HIGH, " needed\n");
}
