
void Reset_Grapple (entity rhook) {
    sound (rhook.owner,1,"weapons/bounce.wav",1,0);
    rhook.owner.on_hook = 0;
    rhook.owner.gravity = 1;
    rhook.owner.hook_out = 0;
    rhook.owner.fire_held_down = 0;
    rhook.owner.weaponframe = 0;
    rhook.think = SUB_Remove;
    rhook.nextthink = time;
}

void Grapple_Track () {
    //vector org;
    if ( (!self.owner.on_hook || (self.owner.health <= 0)) ) {
        Reset_Grapple (self);
        return ;
    } else {
        self.velocity = self.enemy.velocity;
    }
    self.nextthink = (time + 0.100);
}

entity MakeLink () {
    newmis = spawn ();
    newmis.movetype = 9;
    newmis.solid = 0;
    newmis.owner = self;
    newmis.avelocity = '200 200 200';
    setmodel (newmis,"progs/s_spike.mdl");
    setorigin (newmis,self.origin);
    setsize (newmis,'0 0 0','0 0 0');
    return ( newmis );
}

void Remove_Chain () {
    self.think = SUB_Remove;
    self.nextthink = time;
    if ( self.goalentity ) {
        self.goalentity.think = SUB_Remove;
        self.goalentity.nextthink = time;
        if ( self.goalentity.goalentity ) {
            self.goalentity.goalentity.think = SUB_Remove;
            self.goalentity.goalentity.nextthink = time;
        }
    }
}

void Update_Chain () {
    vector temp;
    if ( !self.owner.hook_out ) {
        self.think = Remove_Chain;
        self.nextthink = time;
        return ;
    }
    temp = (self.owner.hook.origin - self.owner.origin);
    setorigin (self,(self.owner.origin + (temp * 0.250)));
    setorigin (self.goalentity,(self.owner.origin + (temp * 0.500)));
    setorigin (self.goalentity.goalentity,(self.owner.origin + (temp * 0.750)));
    self.nextthink = (time + 0.100);
}

void Build_Chain () {
    self.goalentity = MakeLink ();
    self.goalentity.think = Update_Chain;
    self.goalentity.nextthink = (time + 0.100);
    self.goalentity.owner = self.owner;
    self.goalentity.goalentity = MakeLink ();
    self.goalentity.goalentity.goalentity = MakeLink ();
}

float Check_Overhead () {
    vector src;
    vector end;
    makevectors (self.owner.angles);
    src = (self.owner.origin - '0 0 24');
    end = (self.owner.origin - '0 0 24');
    traceline (src,end,0,self.owner);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    src = ((self.owner.origin - '0 0 24') - (v_forward * 16));
    end = (((self.owner.origin - '0 0 24') - (v_forward * 16)) + '0 0 58');
    traceline (src,end,0,self.owner);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    src = ((self.owner.origin - '0 0 24') + (v_forward * 16));
    end = (((self.owner.origin - '0 0 24') + (v_forward * 16)) + '0 0 58');
    traceline (src,end,0,self.owner);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    src = ((self.owner.origin - '0 0 24') - (v_right * 16));
    end = (((self.owner.origin - '0 0 24') - (v_right * 16)) + '0 0 58');
    traceline (src,end,0,self.owner);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    src = ((self.owner.origin - '0 0 24') + (v_right * 16));
    end = (((self.owner.origin - '0 0 24') + (v_right * 16)) + '0 0 58');
    traceline (src,end,0,self.owner);
    if ( (trace_fraction != 1) ) {
        return ( 0 );
    }
    return ( 1 );
}

void Anchor_Grapple () {
    float test;
    if ( (other == self.owner) ) {
        return ;
    }
    if ((other.hook.enemy == self) ) {
        return ;
    }
    if ( ((((other.classname == "missile") || (other.classname == "grenade")) || (other.classname == "spike")) || (other.classname == "hook")) ) {
        return ;
    }
    if ( (pointcontents (self.origin) == -6) ) {
        Reset_Grapple (self);
        return ;
    }
    if ( (other.classname == "player") ) {
        sound (self,1,"player/axhit2.wav",1,1);
        if ( other.takedamage ) {
            deathmsg = 21;
            TF_T_Damage (other,self,self.owner,1, 0, 0);
        }
        //self.velocity = '0 0 0';
        //self.avelocity = '0 0 0';

    }
    sound (self.owner,1,"weapons/tink1.wav",1,1);
    if ( !self.owner.button0 ) {
        Reset_Grapple (self);
        return ;
    }
    test = Check_Overhead ();
    if ( !test ) {
        Reset_Grapple (self);
        return ;
    }
    self.owner.on_hook = 1;
    if ( (self.owner.flags & 512) ) {
        self.owner.flags = (self.owner.flags - 512);
        setorigin (self.owner,(self.owner.origin + '0 0 1'));
    }
    self.owner.gravity = 0;
    self.owner.lefty = 1;
    self.enemy = other;
    self.think = Grapple_Track;
    self.nextthink = time;
    self.solid = 0;
    self.touch = SUB_Null;
}

void Throw_Grapple () {
    if ( self.hook_out ) {
        return ;
    }
    KickPlayer (-1,self);
    newmis = spawn ();
    newmis.movetype = 9;
    newmis.solid = 2;
    newmis.owner = self;
    self.hook = newmis;
    newmis.classname = "hook";
    makevectors (self.v_angle);
    newmis.velocity = (v_forward * 800);
    newmis.angles = vectoangles (newmis.velocity);
    newmis.touch = Anchor_Grapple;
    newmis.think = Build_Chain;
    newmis.nextthink = (time + 0.100);
    setmodel (newmis,"progs/hook.mdl");
    setorigin (newmis,((self.origin + (v_forward * 16)) + '0 0 16'));
    setsize (newmis,'0 0 0','0 0 0');
    self.hook_out = 1;
    self.fire_held_down = 1;
}

void Service_Grapple () {
    vector hook_dir;
    if ( !self.button0 ) {
        self.fire_held_down = 0;
        if ( (self.current == 1) ) {
            Reset_Grapple (self.hook);
        }
    }
    if ( (self.hook.enemy.classname == "player") ) {
        hook_dir = (self.hook.enemy.origin - self.origin);
    } else {
        if ( (self.hook.enemy.classname != "player") ) {
            hook_dir = (self.hook.origin - self.origin);
        }
    }
    self.velocity = ((normalize (hook_dir) * self.maxspeed) * 2);
    if ( ((vlen (hook_dir) <= 100) && self.lefty) ) {
        if ( self.hook.goalentity ) {
            self.hook.goalentity.think = Remove_Chain;
            self.hook.goalentity.nextthink = time;
        }
        self.lefty = 0;
    }
}
