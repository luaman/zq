
void SUB_CalcMove (vector tdest, float tspeed, void() func);

void SUB_CalcMoveDone ();

void SUB_CalcAngleMove (vector destangle, float tspeed, void() func);

void DoGoalWork (entity Goal, entity AP);

void DoGroupWork (entity Goal, entity AP);

void SUB_Null () {
}

void SUB_Remove () {
    dremove (self);
}

void SetMovedir () {
    if ( (self.angles == '0 -1 0') ) {
        self.movedir = '0 0 1';
    } else {
        if ( (self.angles == '0 -2 0') ) {
            self.movedir = '0 0 -1';
        } else {
            makevectors (self.angles);
            self.movedir = v_forward;
        }
    }

    self.angles = '0 0 0';
}

void InitTrigger () {
    if ( (self.angles != '0 0 0') ) {
        SetMovedir ();
    }
    self.solid = 1;
    setmodel (self,self.model);
    self.movetype = 0;
    self.modelindex = 0;
    self.model = "";
}

void SUB_CalcMove (vector tdest, float tspeed, void() func) {
    vector vdestdelta;
    float len;
    float traveltime;
    if ( !tspeed ) {
        objerror ("No speed is defined!");
    }
    self.think1 = func;
    self.finaldest = tdest;
    self.think = SUB_CalcMoveDone;
    if ( (tdest == self.origin) ) {
        self.velocity = '0 0 0';
        self.nextthink = (self.ltime + 0.100);
        return ;
    }
    vdestdelta = (tdest - self.origin);
    len = vlen (vdestdelta);
    traveltime = (len / tspeed);
    if ( (traveltime < 0.030) ) {
        traveltime = 0.030;
    }
    self.nextthink = (self.ltime + traveltime);
    self.velocity = (vdestdelta * (1 / traveltime));
}

void SUB_CalcMoveDone () {
    setorigin (self,self.finaldest);
    self.velocity = '0 0 0';
    self.nextthink = -1;
    if ( self.think1 ) {
        self.think1 ();
    }
}

void SUB_CalcAngleMove (vector destangle, float tspeed, void() func) {
    vector destdelta;
    float len;
    float traveltime;
    if ( !tspeed ) {
        objerror ("No speed is defined!");
    }
    destdelta = (destangle - self.angles);
    len = vlen (destdelta);
    traveltime = (len / tspeed);
    self.nextthink = (self.ltime + traveltime);
    self.avelocity = (destdelta * (1 / traveltime));
    self.think1 = func;
    self.finalangle = destangle;
    self.think = SUB_CalcAngleMoveDone;
}

void SUB_CalcAngleMoveDone () {
    self.angles = self.finalangle;
    self.avelocity = '0 0 0';
    self.nextthink = -1;
    if ( self.think1 ) {
        self.think1 ();
    }
}

void DelayThink () {
    activator = self.enemy;
    SUB_UseTargets ();
    dremove (self);
}

void SUB_UseTargets () {
    entity t;
    entity stemp;
    entity otemp;
    entity act;
    if ( self.dont_do_triggerwork ) {
        self.dont_do_triggerwork = 0;
        return ;
    }
    if ( self.delay ) {
        t = spawn ();
        t.classname = "DelayedUse";
        t.nextthink = (time + self.delay);
        t.think = DelayThink;
        t.enemy = activator;
        t.message = self.message;
        t.killtarget = self.killtarget;
        t.target = self.target;
        return ;
    }
    if ( ((activator.classname == "player") && (self.message != "")) ) {
        CenterPrint (activator,self.message);
        if ( !self.noise ) {
            sound (activator,2,"misc/talk.wav",1,1);
        }
    }
    if ( (activator.classname == "player") ) {
        DoGroupWork (self,activator);
        DoGoalWork (self,activator);
    }
    if ( self.killtarget ) {
        t = world;
        do {
            t = find (t,targetname,self.killtarget);
            if ( !t ) {
                return ;
            }
            remove (t);
        } while ( 1 );
    }
    if ( self.target ) {
        act = activator;
        t = world;
        do {
            t = find (t,targetname,self.target);
            if ( !t ) {
                return ;
            }
            stemp = self;
            otemp = other;
            self = t;
            other = stemp;
            if ( (self.use != SUB_Null) ) {
                if ( self.use ) {
                    self.use ();
                }
            }
            self = stemp;
            other = otemp;
            activator = act;
        } while ( 1 );
    }
}

void SUB_AttackFinished (float normal) {
    self.cnt = 0;
    if ( (skill < 3) ) {
        self.attack_finished = (time + normal);
    }
}
