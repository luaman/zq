/*
    spect.qc

    spectator functions/definitions

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

void SpectatorDisconnect ();

void SpectatorImpulseCommand ();

void SpectatorThink ();

void SpectatorConnect () {

    string st;
    self.classname = "observer";
    self.flags = 8;

    stuffcmd (self,"on_spec_connect\n");
    st = infokey (self,"em");
    if ( (st == string_null) ) {
        st = infokey (self,"exec_map");
    }
    if ( (st == "on") ) {
        stuffcmd (self,"exec spectator.cfg\n");
        stuffcmd (self,"exec ");
        stuffcmd (self,mapname);
        stuffcmd (self,".cfg\n");
    }
    self.motd = 0;
    st = infokey (self,"adminpwd");
    Admin_Check(st);
    if (self.is_admin) {
        self.get_admin_aliases = 1;
    }
    self.nexts = spec_head;
    spec_head = self;
    if (!self.camdist) {
        self.camdist = 160;
    }
    CheckConnectRate();
}

void SpectatorDisconnect () {
    entity te;
    if (spec_head == self)
        spec_head = self.nexts;
    else {
        te = spec_head;
        while (te) {
            if (te.nexts == self)
                te.nexts = self.nexts;
            te = te.nexts;
        }
    }
}

void SpectatorImpulseCommand () {
    if ( (self.impulse == 1) ) {
        self.goalentity = find (self.goalentity,classname,"info_player_deathmatch");
        if ( (self.goalentity == world) ) {
            self.goalentity = find (self.goalentity,classname,"info_player_deathmatch");
        }
        if ( (self.goalentity != world) ) {
            setorigin (self,self.goalentity.origin);
            self.angles = self.goalentity.angles;
            self.fixangle = 1;
            self.last_impulse = self.impulse;
        }
        self.impulse = 0;
        return ;
    } else {
        if ( (self.impulse == 9) ) {
            fadetoblack();
            self.impulse = 0;
            return ;
        } else {
            if ( (self.impulse == 10) ) {
                fadefromblack();
                self.impulse = 0;
                return ;
            } else {
                if ( (self.impulse == 185) ) {
                    TeamFortress_ID ();
                    self.impulse = 0;
                    return ;
                } else {
                    if ( (self.impulse == 131) ) {
                        TeamFortress_HelpMap ();
                        self.impulse = 0;
                        return ;
                    } else {
                        if ( (self.impulse == 119) ) {
                            TeamFortress_StatusQuery ();
                            self.impulse = 0;
                            return ;
                        } else {
                            if ( (self.impulse == 145) ) {
                                TeamFortress_TeamShowScores (0);
                                self.impulse = 0;
                                return ;
                            } else {
                                if ( (self.impulse == 23) ) {
                                    if ( (ctfmap == 1) ) {
                                        TeamFortress_CTF_FlagInfo ();
                                    } else {
                                        TeamFortress_DisplayDetectionItems ();
                                    }
                                    self.impulse = 0;
                                    return;
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    CommandImpulses();
    self.impulse = 0;
}

void SpectatorThink () {
    Check_Track();
    if ( self.impulse ) {
        SpectatorImpulseCommand ();
    }
    if ( (self.motd <= 65) ) {
        TeamFortress_MOTD ();
    }
    if ( ((time > self.StatusRefreshTime) && (self.StatusBarSize != 0)) ) {
        RefreshStatusBar() ;
    }
    if (self.is_admin) {
        if (self.get_admin_aliases) {
            Admin_Aliases();
        }
    }

}
