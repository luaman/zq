/*
    track.qc

    tracking functions/definitions

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

float EntityNum (entity ent) {
    float num = 1;
    entity e;

    e = world;
    do {
        e = nextent(e);

    } while (e != ent);
    return num;
}
entity NumEntity (float num) {
    float fl;
    entity e;
    fl  = 1;
    e = world;
    do {
        e = nextent(e);
        fl = fl + 1;
    } while (fl != num);
    return e;
}

void Spect_Track () {
    float num;
    num = EntityNum(self.goalentity);
    stuffcmd(self,"track #");
    stuffcmd(self,ftos(num));
    stuffcmd(self,"\n");
}

void Flymode () {
    entity spot;
    spot = find (world,classname,"info_player_start");
    self.origin = spot.origin;
    if (self.classname == "observer" && self.tracking == 2.000) {
        stuffcmd(self, "+attack; wait; -attack\n");
    }
    self.tracking = 0.000;
    self.gravity = 1.000;
}

void Toggle_Tracking () {
    if (self.playerclass) return;
    if (self.goalentity == world) return;
    if (!self.tracking) {
        self.tracking = 1.000;
        self.gravity = 0.000;
        sprint (self, PRINT_HIGH, "Tracking mode: 3rd Person.\n");
    } else if ((self.goalentity.classname == "player") || (self.goalentity.classname == "building_sentrygun") && (self.tracking == 1.000)) {
        self.tracking = 2.000;
        if (self.classname == "observer" && self.goalentity.classname == "player") Spect_Track();
        sprint (self, PRINT_HIGH, "Tracking mode: 1st Person.\n");
    } else  {
        Flymode();
        sprint (self, PRINT_HIGH, "Tracking mode: Flymode.\n");
    }
}

void Track_Object () {
    vector v1,v2,v3;
    entity goal;
    float new;
    if ( (self.goalentity != world) ) {
        if (self.goalentity.solid == 0.000) {
            goal = self.goalentity.owner;
            new = 1.000;
        } else if ((self.goalentity.classname == "player") && (self.goalentity.health <= 0.000)) {
            goal = self.goalentity.enemy;
        } else {
            goal = self.goalentity;
        }
        if (self.a_c) {
            if (self.goalentity != store_obs.goalentity) {
                if (store_obs.goalentity != world) {
                    goal = store_obs.goalentity;
                    self.goalentity = store_obs.goalentity;
                    if (self.classname == "observer" && self.goalentity.classname == "player") Spect_Track();
                }
            }
        }
        if ( (goal.classname == "player") || (goal.classname == "building_sentrygun") && (self.tracking == 2)) {
            if (self.classname == "player") {
                self.origin = goal.origin + self.goalentity.view_ofs;
                if (goal.classname == "player") {
                    self.angles_x = goal.angles_x * -1.000;
                    self.angles_y = goal.angles_y;
                } else  if (goal.classname == "building_sentrygun") {
                    self.angles = goal.angles;
                }
                self.fixangle = 1.000;
                return;
            }
        }  else  if (self.tracking) {

            v1 = goal.origin;
            v2 = self.v_angle;
            makevectors(v2);
            v2 = v_forward * self.camdist;
            traceline(v1, v1 - v2, 1.000, goal);
            v2 = v2 * trace_fraction;
            v3 = v1 - (v2 * 0.6);
            v2 = v1 - v2;
            traceline(self.origin, v2, 1.000, goal);
            if (trace_fraction == 1.0) {
                v1 = v3 - self.origin;
                v1 = v1 * 10;
                self.velocity = v1;
            }
            self.origin = v3;
        }
        if (goal.classname == "player") {
            self.items = goal.items;
            self.armorvalue = goal.armorvalue;
            if (goal.health <= 0) {
                self.health = 1.000;
            } else {
                self.health = goal.health;
            }
            self.weapon = goal.weapon;
            self.currentammo = goal.currentammo;
        } else if (goal.classname == "building_sentrygun") {
            if (goal.health <= 0) {
                self.health = 1.000;
            } else {
                self.health = goal.health;
            }
            self.weapon = goal.weapon;
            self.currentammo = goal.ammo_shells;
        } else if (goal.classname == "item_tfgoal") {
            if (goal.origin != goal.oldorigin) {
                self.armorvalue = goal.nextthink - time;
            } else {
                self.armorvalue = 0.000;
            }
            self.health = 1.000;
            self.currentammo = 0.000;
        }
    }
}

void Track_Tfgoal () {
    entity te;
    if (self.classname == "observer") Flymode();
    if (self.pteam != store_obs) {
        while (te != world) {
            te = find (te,classname,"item_tfgoal");
            if (te.owned_by == self.pteam.team) {
                break;
            }
        }
    } else {
        te = find (self.goalentity,classname,"item_tfgoal");
        if ( (te == world) ) {
            te = find (te,classname,"item_tfgoal");
        }
    }
    if ( (te != world) ) {
        self.goalentity = te;
        if (!self.tracking) Toggle_Tracking();
        CenterPrint3(self,"You are tracking: ", self.goalentity.netname, ".\n");
    } else {
        CenterPrint(self,"No TF Goals in game to track.\n");
        Flymode();
    }
}

void Track_Player () {
    entity te;
    te = self.goalentity.nextp;
    if (( te == world)  )  {
        te = player_head;
    }
    while (( te != world)) {
        if ((!te.playerclass) || (te.deadflag) )  {
            te = te.nextp;
        } else {
            break;
        }
    }

    if ( (te != world) ) {
        self.goalentity = te;
        if (!self.tracking) Toggle_Tracking();
        //if (self.classname == "observer") Spect_Track();
        CenterPrint3(self,"You are tracking: ", self.goalentity.netname, ".\n");
    } else {
        te = player_head;
        if ( te) {
            if ((!te.playerclass) || (te.deadflag) )  {
                CenterPrint(self,"No Players in game to track.\n");
                Flymode();
                return;
            }
            self.goalentity = te;
            if (!self.tracking) Toggle_Tracking();
            //if (self.classname == "observer") Spect_Track();
            CenterPrint3(self,"You are tracking: ", self.goalentity.netname, ".\n");
        } else {
            CenterPrint(self,"No Players in game to track.\n");
            Flymode();
        }
    }
}

void Track_Sentry () {
    entity te;
    if (self.classname == "observer") Flymode();
    te = find (self.goalentity,classname,"building_sentrygun");
    if ( (te == world) ) {
        te = find (te,classname,"building_sentrygun");
    }
    if (self.pteam != store_obs) {
        if (te.pteam != self.pteam) {
            te = find (te,classname,"building_sentrygun");
        }
    }
    if (te != world) {
        self.goalentity = te;
        if (!self.tracking) Toggle_Tracking();
        CenterPrint3(self,"You are tracking: ", self.goalentity.owner.netname, "'s Sentry Gun.\n");
    } else {
        CenterPrint(self,"No Sentry Gun's in game to track.\n");
        Flymode();
    }
}

void Toggle_Autotrack () {
    entity te;
    entity autotrack;
    entity exception;
    float pfrags;
    self.a_c = 1.000;
    if (store_obs.goalentity == world) {
        te = player_head;
        while (te) {
            if (te.playerclass) {
                if (!te.deadflag) {
                    exception = te;
                    if (te.real_frags > pfrags)
                        autotrack = te;
                    if (te.items & (4194304.000 | 1048576.000 | 524288.000))
                        autotrack = te;
                    if (te.effects & (8.000 | 4.000))
                        autotrack = te;
                }
            }
            te = te.nextp;
        }
        if (autotrack != world)
            store_obs.goalentity = autotrack;

        else {
            if (exception != world) {
                store_obs.goalentity = exception;
            }
        }
    }
    self.goalentity = store_obs.goalentity;
    if (!self.tracking) Toggle_Tracking();
    CenterPrint3(self,"You are tracking: ", self.goalentity.netname, ".\n");
}

void Check_Track () {
    if (self.tracking) {
        if ((self.goalentity != world) ) {
            Track_Object();
        }
        if (self.campan == 1) {
            self.camdist = self.camdist - (self.fAverageFrameTime / self.fFrameCount) * 100;
            if ( self.camdist < 50) self.camdist = 50;
        }
        if (self.campan == -1) {
            self.camdist = self.camdist + (self.fAverageFrameTime / self.fFrameCount) * 100;
            if ( self.camdist > 500) self.camdist = 500;
        }
    }
}
