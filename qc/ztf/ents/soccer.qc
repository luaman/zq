#ifndef SOCCER
#define SOCCER

void DecrementQue () {
    local entity te;
    te = player_head;
    while (( te != world)  ) {
        if (te.a_n > 1.000) te.a_n = te.a_n - 1.000;
        te = te.nextp;
    }
};

float ping (entity Player) {
    local string st;
    local float fl;
    st = infokey (Player, "ping");
    fl = stof (st);
    fl = fl / 1000.000000;
    return (fl);
};

void ball_reset () {
    self.solid = 1.000;
    self.velocity = '0 0 0';
    self.origin = self.oldorigin;
    setorigin (self,self.origin);
    if ( !droptofloor () ) {
        dprint ("GoalItem fell out of level at ");
        dprint (vtos (self.origin));
        dprint ("\n");
        dremove (self);
        return ;
    }
};

void ball_spin () {
    local float vel_x;
    local float vel_y;
    if (self.velocity) {

        if (self.velocity_x < 0.000) {
            vel_x = self.velocity_x * -1.000;
        } else {
            vel_x = self.velocity_x;
        }
        if (self.velocity_y < 0.000) {
            vel_y = self.velocity_y * -1.000;
        } else {
            vel_y = self.velocity_y;
        }
        self.avelocity_x = (vel_x + vel_y) * 2.000;
    }
};

void ball_kick (vector o, float z) {
    local vector v;
    v_x = ((o_x * 1.65) + (random() * 20) );
    v_y = ((o_y * 1.65) + (random() * 20) );
    if (o_x < 0.000) {
        o_x = o_x * -1.000;
    }
    if (o_y < 0.000) {
        o_y = o_y * -1.000;
    }
    v_z = ((100 + (random() * 30))  + ((o_y + o_x) * 0.20) + (z * 2.5)  );
    self.flags = self.flags - ( self.flags & 512.000);
    self.velocity = v;
    self.angles = vectoangles (self.velocity);
    ball_spin();
};

void ball_fly (vector o) {
    local vector v;
    v_x = (o_x * 0.600) + (crandom() * 40);
    v_y = (o_y * 0.600) + (crandom() * 40);
    if (o_x < 0.000) {
        o_x = o_x * -1.000;
    }
    if (o_y < 0.000) {
        o_y = o_y * -1.000;
    }
    v_z = (140 + (crandom() * 40))  + ((o_y + o_x) * 0.20);
    self.flags = self.flags - ( self.flags & 512.000);
    self.velocity = v;
    self.angles = vectoangles (self.velocity);
    ball_spin();
};

void ball_touch () {
    if (other.classname == "worldspawn") {
        return;
    }
    if (round_over) {
        return;
    }
    if (other.classname == "player") {
        self.oldenemy = other;
        ball_kick(other.velocity, (other.v_angle_x * -1.000));
        return;
    }
    self.oldenemy = other.owner;
    ball_fly(other.velocity);
    return;
};

void item_ball () {
    self.solid = 1.000;
    self.movetype = 10.000;
    //self.flags= 256.000;
    if ( self.mdl ) {
        precache_model (self.mdl);
        setmodel (self,self.mdl);
    } else {
        precache_model ("progs/ball.mdl");
        self.mdl = "progs/ball.mdl";
        setmodel (self,self.mdl);
    }
    if ( !self.netname ) {
        self.netname = "ball";
    }
    if ( (self.goal_min == '0.000 0.000 0.000') ) {
        self.goal_min = '-12.000 -12.000 -12.000';
    }
    if ( (self.goal_max == '0.000 0.000 0.000') ) {
        self.goal_max = '12.000 12.000 12.000';
    }
    setsize (self,self.goal_min,self.goal_max);
    setorigin (self,self.origin );
    self.oldorigin = self.origin;
    self.touch = ball_touch;
};

void soccer_goal_touch () {
    if (round_over)  return;
    if (cb_prematch) return;
    if (other.classname == "item_ball") {
        if (other.solid) {
            TeamFortress_TeamIncreaseScore (self.owned_by,self.count);
            TeamFortress_TeamShowScores (2.000);
            sound (self,2.000,self.noise,1.000,0.000);
            round_winner = self.pteam;
            other.solid = 0.000;
        }
        return;
    }
};

void info_soccer_goal () {

    if (!self.noise ) {
        self.noise = "items/tf2kfgc.wav";
    }
    precache_sound (self.noise);

    if (self.owned_by == 1.000) {
        self.pteam = pteam1;
    } else if (self.owned_by == 2.000) {
        self.pteam = pteam2;
    } else if (self.owned_by == 3.000) {
        self.pteam = pteam3;
    } else if (self.owned_by == 4.000) {
        self.pteam = pteam4;
    }
    InitTrigger();
    self.touch = soccer_goal_touch;
};

void func_glass () {
    self.solid = 2.000;
    setmodel (self,self.model);
    self.movetype = 0.000;
    self.modelindex = 0.000;
    self.model = "";
};
// ===============================================================
// RAIN CODE
// ===============================================================

void() rain_touch = {

    // remove rain when it hits ground or any other object
    dremove(self);
};

void() rain_think = {
    local float temp1,temp2;
    local vector rain_org, rain_vel;
    rain_org = self.origin + '0 0 64';
    temp1 = random();
    temp2 = random();
    // random direction from func_rain origin
    if (temp1 < 0.5)
        rain_org_x = rain_org_x - 64*random();
    else
        rain_org_x = rain_org_x + 64*random();
    if (temp2 < 0.5)
        rain_org_y = rain_org_y - 64*random();
    else
        rain_org_y = rain_org_y + 64*random();
    newmis = spawn();
    setorigin (newmis, rain_org);
    setmodel (newmis, "progs/s_rain.spr");
    newmis.classname = "raindrop";
    newmis.movetype = 6.000;
    newmis.solid = 1.000;
    setsize (newmis, '0 0 0', '0 0 0');
    rain_vel = '0 0 0';
    rain_vel_z = -20*random();
    newmis.touch = rain_touch;
    self.nextthink = time + 0.5;
    self.think = rain_think;
};

void() func_rain = {
    precache_model ("progs/s_rain.spr");
    precache_sound("ambience/rain.wav");
    ambientsound (self.origin, "ambience/rain.wav", 0.5, 3.000);
    self.think = rain_think;
    //self.touch = func_rain_touch;
    self.nextthink = time  + random();
};

void nogren_touch () {

    if (other.classname == "grenade") {
        if (self.spawnflags == 1.000) {
            if (other.tp_grenades_1) {
                other.think = SUB_Remove;
            }
        } else if (self.spawnflags == 2.000) {
            if (other.tp_grenades_2) {
                other.think = SUB_Remove;
            }
        }
        return;
    }
    if (other.classname == "grentimer") {
        if (self.spawnflags == 1.000) {
            if (other.tp_grenades_1) {
                other.think = SUB_Remove;
            }
        } else if (self.spawnflags == 2.000) {
            if (other.tp_grenades_2) {
                other.think = SUB_Remove;
            }
        }
        return;
    }
};

void func_nogrenades () {
    InitTrigger ();
    self.touch = nogren_touch;
};

void func_nobuild () {
    InitTrigger ();
    self.touch = nobuild_touch;
};
#endif
