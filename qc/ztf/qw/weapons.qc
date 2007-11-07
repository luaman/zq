
void ImpulseCommands ();

void player_run ();

float crossproduct (vector veca, vector vecb);

void SpawnBlood (vector org, float damage);

void Reset_Grapple (entity rhook);

void W_PrintWeaponMessage ();

void button_touch ();

void button_fire ();

void RemoveGrenade ();

void SniperSight_Create ();

void TF_zoom (float zoom_level);

void W_FireFlame ();

void W_FireIncendiaryCannon ();

void W_FireTranq ();

void W_FireRail ();

void W_FireRailgun ();

void W_Precache () {
    precache_sound ("weapons/r_exp3.wav");
    precache_sound ("weapons/rocket1i.wav");
    precache_sound ("weapons/sgun1.wav");
    precache_sound ("weapons/guncock.wav");
    precache_sound ("weapons/ric1.wav");
    precache_sound ("weapons/ric2.wav");
    precache_sound ("weapons/ric3.wav");
    precache_sound ("weapons/spike2.wav");
    precache_sound ("weapons/tink1.wav");
    precache_sound ("weapons/grenade.wav");
    precache_sound ("weapons/bounce.wav");
    precache_sound ("weapons/shotgn2.wav");
    precache_sound ("wizard/wattack.wav");
    precache_sound ("items/r_item1.wav");
    precache_sound ("items/r_item2.wav");
    precache_model ("progs/flame2.mdl");
    precache_sound ("ambience/fire1.wav");
    precache_sound ("blob/land1.wav");
    precache_model ("progs/v_spike.mdl");
    precache_sound ("hknight/hit.wav");
    precache_sound ("weapons/detpack.wav");
    precache_sound ("weapons/turrset.wav");
    precache_sound ("weapons/turrspot.wav");
    precache_sound ("weapons/turridle.wav");
    precache_sound ("weapons/sniper.wav");
    precache_sound ("weapons/hyperb1.wav");
    precache_sound ("weapons/laserhit.wav");
    precache_sound ("weapons/autorifle.wav");
    precache_sound ("weapons/sg_draw.wav");
    precache_sound ("weapons/sg_reload.wav");
    precache_sound ("weapons/gl_draw.wav");
    precache_sound ("weapons/rl_draw.wav");
    precache_sound ("weapons/flmfire2.wav");
    precache_sound ("weapons/flmgrexp.wav");
    precache_sound ("misc/vapeur2.wav");
    precache_sound ("weapons/asscan1.wav");
    precache_sound ("weapons/asscan2.wav");
    precache_sound ("weapons/asscan3.wav");
    precache_sound ("weapons/asscan4.wav");
    precache_sound ("weapons/railgun.wav");
    precache_sound ("weapons/dartgun.wav");
    precache_model ("progs/shell.mdl");
    precache_model ("progs/20mmcase.mdl");
    precache_sound ("weapons/shell2.wav");
    precache_sound ("weapons/tink1.wav");
    precache_sound ("weapons/tink2.wav");
}

void W_FireAxe () {
    vector source;
    vector org;
    vector def;
    makevectors (self.v_angle);
    source = (self.origin + '0 0 16');
    traceline (source,(source + (v_forward * 64)),0,self);
    if ( (trace_fraction == 1) ) {
        return ;
    }
    if (allow_stamina)
        self.stamina = self.stamina - 15;
    org = (trace_endpos - (v_forward * 4));
    if ( trace_ent.takedamage ) {
        trace_ent.axhitme = 1;
        SpawnBlood (org,20);
        if ( ((self.playerclass != 8) || (trace_ent.classname != "player")) ) {
            deathmsg = 17;
            TF_T_Damage (trace_ent,self,self,20,2,0);
        } else {
            self.weaponmode = 1;
            self.weaponmodel = "progs/v_knife.mdl";
            makevectors (trace_ent.v_angle);
            def = v_right;
            makevectors (self.v_angle);
            if ( (crossproduct (def,v_forward) > 0) ) {
                deathmsg = 22;
                TF_T_Damage (trace_ent,self,self,120,(2 | 1),0);
            } else {
                deathmsg = 17;
                TF_T_Damage (trace_ent,self,self,40,2,0);
            }
        }
    } else {
        sound (self,CHAN_WEAPON,"player/axhit2.wav",1,1);
        WriteByte (4,23);
        WriteByte (4,2);
        WriteByte (4,3);
        WriteCoord (4,org_x);
        WriteCoord (4,org_y);
        WriteCoord (4,org_z);
        multicast (org,2);
    }
}

void W_FireSpanner () {
    vector source;
    vector org;
    entity te;
    makevectors (self.v_angle);
    source = (self.origin + '0 0 16');
    traceline (source,(source + (v_forward * 64)),0,self);
    if ( (trace_fraction == 1) ) {
        return ;
    }
    if (allow_stamina)
        self.stamina = self.stamina - 15;
    org = (trace_endpos - (v_forward * 4));
    if ( (trace_ent.goal_activation & 8) ) {
        if ( Activated (trace_ent,self) ) {
            DoResults (trace_ent,self,1);
            if ( (trace_ent.classname == "func_button") ) {
                trace_ent.enemy = self;
                other = self;
                self = trace_ent;
                self.dont_do_triggerwork = 1;
                button_fire ();
                self = other;
            }
        } else {
            if ( (trace_ent.else_goal != 0) ) {
                te = Findgoal (trace_ent.else_goal);
                if ( te ) {
                    AttemptToActivate (te,self,trace_ent);
                }
            } else {
                sound (self,CHAN_WEAPON,"player/axhit2.wav",1,1);
                WriteByte (4,23);
                WriteByte (4,2);
                WriteByte (4,3);
                WriteCoord (4,org_x);
                WriteCoord (4,org_y);
                WriteCoord (4,org_z);
                multicast (org,2);
            }
        }
        return ;
    }
    if ( trace_ent.takedamage ) {
        Spanner_Fire();
    } else {
        sound (self,CHAN_WEAPON,"player/axhit2.wav",1,1);
        WriteByte (4,23);
        WriteByte (4,2);
        WriteByte (4,3);
        WriteCoord (4,org_x);
        WriteCoord (4,org_y);
        WriteCoord (4,org_z);
        multicast (org,2);
    }
}

void W_FireMedikit () {
    vector org;
    vector source;
    source = (self.origin + '0 0 16');
    traceline (source,(source + (v_forward * 64)),0,self);
    if ( (trace_fraction == 1) ) {
        return ;
    }
    if (allow_stamina)
        self.stamina = self.stamina - 15;
    org = (trace_endpos - (v_forward * 4));
    if ( trace_ent.takedamage ) {
        Medikit_Fire ();
    } else {
        sound (self,CHAN_WEAPON,"player/axhit2.wav",1,1);
        WriteByte (4,23);
        WriteByte (4,2);
        WriteByte (4,3);
        WriteCoord (4,org_x);
        WriteCoord (4,org_y);
        WriteCoord (4,org_z);
        multicast (org,2);
    }
}
#ifdef CSQC
.float starttime;

float SendShell (entity toplayer) {
    WriteByte(MSG_ENTITY, CLASS_SHELL);
    WriteByte(MSG_ENTITY, self.skin);
    WriteCoord(MSG_ENTITY, self.origin_x);
    WriteCoord(MSG_ENTITY, self.origin_y);
    WriteCoord(MSG_ENTITY, self.origin_z);
    WriteAngle(MSG_ENTITY, self.angles_x);
    WriteAngle(MSG_ENTITY, self.angles_y);
    return 1;
}
#endif

void ShellHit () {
    if ((self.skin == 1)) {
        sound (self, 3, "weapons/shell2.wav", 0.500, 1);
    } else {
        if ((random () < 0.500)) {
            sound (self, 3, "weapons/tink1.wav", 0.500, 1);
        } else {
            sound (self, 3, "weapons/tink2.wav", 0.600, 1);
        }
    }
    return;
}

void EjectShell () {
    newmis = spawn ();
    newmis.movetype = MOVETYPE_BOUNCE;
    newmis.solid = SOLID_TRIGGER;
    newmis.angles = self.angles;
    setsize (newmis, '0 0 0', '0 0 0');
    setorigin (newmis, ((self.origin + (v_forward * 10)) + '0 0 20'));
    makevectors (self.v_angle);
    if (self.v_angle_x) {
        newmis.velocity = (((v_forward * 70) + (v_up * 90)) + ((random () * v_right) * 150));
    } else {
        newmis.velocity = ((newmis.velocity * 70) + ((random () * v_right) * 150));
        newmis.velocity_z = (random () * 90);
    }
    if ((random () < 0.300)) {
        newmis.avelocity = '20 30 40';
    } else {
        if ((random () < 0.6)) {
            newmis.avelocity = '40 20 30';
        } else {
            newmis.avelocity = '70 50 10';
        }
    }
    if ((self.playerclass == CLASS_HWGUY) && (self.current == WEAP_ASSAULT_CANNON)) {
        newmis.nextthink = (time + 1.500000);
        setmodel (newmis, "progs/20mmcase.mdl");
    } else {
        newmis.nextthink = (time + 3);
        setmodel (newmis, "progs/shell.mdl");
    }
    newmis.think = SUB_Remove;
    newmis.touch = ShellHit;
#ifdef CSQC
    newmis.SendEntity = SendShell;
    newmis.Version+=1;
#endif
}
vector wall_velocity () {
    vector vel;
    vel = normalize (self.velocity);
    vel = normalize (((vel + (v_up * (random () - 0.500))) + (v_right * (random () - 0.500))));
    vel = (vel + (2 * trace_plane_normal));
    vel = (vel * 200);
    return ( vel );
}

void SpawnMeatSpray (vector org, vector vel) {
    entity missile;
    missile = spawn ();
    missile.owner = self;
    missile.movetype = MOVETYPE_BOUNCE;
    missile.solid = 0;
    makevectors (self.angles);
    missile.velocity = vel;
    missile.velocity_z = ((missile.velocity_z + 250) + (50 * random ()));
    missile.avelocity = '3000 1000 2000';
    missile.nextthink = (time + 1);
    missile.think = SUB_Remove;
    setmodel (missile,"progs/zom_gib.mdl");
    setsize (missile,'0 0 0','0 0 0');
    setorigin (missile,org);
}

void SpawnBlood (vector org, float damage) {
    WriteByte (4,23);
    WriteByte (4,12);
    WriteByte (4,1);
    WriteCoord (4,org_x);
    WriteCoord (4,org_y);
    WriteCoord (4,org_z);
    multicast (org,2);
}

void spawn_touchblood (float damage) {
    vector vel;
    vel = (wall_velocity () * 0.200);
    SpawnBlood ((self.origin + (vel * 0.010)),damage);
}

#if 0
void SpawnChunk (vector org, vector vel) {
	particle (org,(vel * 0.020),0,10);
}
#endif

entity multi_ent;

float multi_damage /* = 0 */;
vector blood_org /* = '0 0 0' */;

float blood_count /* = 0 */;
vector puff_org /* = '0 0 0' */;

float puff_count /* = 0 */;

void ClearMultiDamage () {
    multi_ent = world;
    multi_damage = 0;
    blood_count = 0;
    puff_count = 0;
}

void ApplyMultiDamage () {
    if ( !multi_ent ) {
        return ;
    }
    TF_T_Damage (multi_ent,self,self,multi_damage,2,1);
}

void AddMultiDamage (entity hit, float damage) {
    if ( !hit ) {
        return ;
    }
    if ( (hit != multi_ent) ) {
        ApplyMultiDamage ();
        multi_damage = damage;
        multi_ent = hit;
    } else {
        multi_damage = (multi_damage + damage);
    }
}

void Multi_Finish () {
    if ( puff_count ) {
        WriteByte (4,23);
        WriteByte (4,2);
        WriteByte (4,puff_count);
        WriteCoord (4,puff_org_x);
        WriteCoord (4,puff_org_y);
        WriteCoord (4,puff_org_z);
        multicast (puff_org,2);
    }
    if ( blood_count ) {
        WriteByte (4,23);
        WriteByte (4,12);
        WriteByte (4,blood_count);
        WriteCoord (4,blood_org_x);
        WriteCoord (4,blood_org_y);
        WriteCoord (4,blood_org_z);
        multicast (puff_org,2);
    }
}

void TraceAttack (float damage, vector dir) {
    vector vel;
    vector org;
    vel = normalize (((dir + (v_up * crandom ())) + (v_right * crandom ())));
    vel = (vel + (2 * trace_plane_normal));
    vel = (vel * 200);
    org = (trace_endpos - (dir * 4));
    if ( trace_ent.takedamage ) {
        blood_count = (blood_count + 1);
        blood_org = org;
        AddMultiDamage (trace_ent,damage);
    } else {
        puff_count = (puff_count + 1);
    }
}

void FireBullets (float shotcount, vector dir, vector spread) {
    vector direction;
    vector src;
    makevectors (self.v_angle);
    src = (self.origin + (v_forward * 10));
    src_z = (self.absmin_z + (self.size_z * 0.700));
    ClearMultiDamage ();
    traceline (src,(src + (dir * 2048)),0,self);
    puff_org = (trace_endpos - (dir * 4));
    while ( (shotcount > 0) ) {
        direction = ((dir + ((crandom () * spread_x) * v_right)) + ((crandom () * spread_y) * v_up));
        traceline (src,(src + (direction * 2048)),0,self);
        if ( (trace_fraction != 1) ) {
            if ( (self.current != 32768) ) {
                TraceAttack (4,direction);
            } else {
                if (!(classtype & 2)) {
                    TraceAttack (5,direction);
                } else {
                    TraceAttack (8,direction);
                }
            }
        }
        shotcount = (shotcount - 1);
        if ( (self.current == WEAP_ASSAULT_CANNON) ) {
            puff_org = (trace_endpos + direction);
            Multi_Finish ();
        }
    }
    ApplyMultiDamage ();
    if ( (self.current != 32768)) {
        Multi_Finish ();
    }
}

float SetAttribute (float cur_val, float new_val) {
    if (modetype & 2) return(cur_val);
    return(new_val);
}

void W_FireShotgun () {
    vector dir;
    sound (self,CHAN_WEAPON,"weapons/guncock.wav",1,1);
    KickPlayer (-2,self);
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 1);
        self.currentammo = self.ammo_shells;
        if (allow_stamina)
            self.stamina = self.stamina - 70;
    }
    dir = aim (self,100000);
    deathmsg = 1;
    EjectShell ();
    FireBullets (6,dir,'0.040 0.040 0');
}

void W_FireSuperShotgun () {
    vector dir;
    if ( (self.currentammo == 1) ) {
        W_FireShotgun ();
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/shotgn2.wav",1,1);
    KickPlayer (-4,self);
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 2);
        self.currentammo = self.ammo_shells;
        if (allow_stamina)
            self.stamina = self.stamina - 100;
    }
    dir = aim (self,100000);
    deathmsg = 2;
    EjectShell ();
    FireBullets (14,dir,'0.140 0.080 0');
}

void FireSniperBullet (vector direction, float damage, vector spread) {
    vector src;
    vector dir;
    makevectors (self.v_angle);
    src = (self.origin + (v_forward * 10));
    src_z = (self.absmin_z + (self.size_z * 0.700));
    ClearMultiDamage ();
    dir = ((direction + ((crandom () * spread_x) * v_right)) + ((crandom () * spread_y) * v_up));
    traceline (src,(src + (dir * 4096)),0,self);
    if ( (trace_fraction != 1) ) {
        TraceAttack (damage,direction);
    }
    puff_org = (trace_endpos + direction);
    Multi_Finish ();
    ApplyMultiDamage ();
}

void W_FireSniperRifle () {
    vector dir;
    vector src;
    float dam_mult;
    float zdif;
    float use_this;
    float x;
    vector f;
    vector g;
    vector h;
    float heattime;
    sound (self,CHAN_WEAPON,"weapons/sniper.wav",1,1);
    KickPlayer (-2,self);
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 1);
        self.currentammo = self.ammo_shells;
        if (allow_stamina)
            self.stamina = self.stamina - 270;
    }
    makevectors (self.v_angle);
    src = (self.origin + (v_forward * 10));
    src_z = (self.absmin_z + (self.size_z * 0.700));
    use_this = 0;
    traceline (src,(src + (dir * 8092)),0,self);
    if ( (trace_fraction != 1) ) {
        if ( (trace_ent != world) ) {
            if ( (trace_ent.classname == "player") ) {
                use_this = 1;
            }
        }
    }
    KickPlayer (-4,self);
    if ( !use_this ) {
        dir = aim (self,10000);
        traceline (src,(src + (dir * 3072)),0,self);
    }
    heattime = time - self.heat;
    self.heat = (heattime * (72 * 3)) + 50;
    if (self.heat > 401) self.heat = 401;
    deathmsg = 18;
    dam_mult = 0.800;
    if ( trace_ent ) {
        if ( (trace_ent.classname == "player") ) {
            f = (trace_endpos - src);
            g_x = trace_endpos_x;
            g_y = trace_endpos_y;
            g_z = 0;
            h_x = trace_ent.origin_x;
            h_y = trace_ent.origin_y;
            h_z = 0;
            x = vlen ((g - h));
            f = ((normalize (f) * x) + trace_endpos);
            zdif = (f_z - trace_ent.origin_z);
            deathmsg = 18;
            trace_ent.head_shot_vector = '0 0 0';
            if ( (zdif < 0) ) {
                dam_mult = 0.400;
                trace_ent.leg_damage = (trace_ent.leg_damage + 1);
                TeamFortress_SetSpeed (trace_ent);
                deathmsg = 28;
                TF_T_Damage (trace_ent,self,self,(self.heat * dam_mult),2,1);
                if ( (trace_ent.health > 0) ) {
                    sprint (trace_ent,PRINT_LOW,"Leg injury!\n");
                    sprint (self,PRINT_MEDIUM,"Leg shot - that'll slow him down!\n");
                }
                return ;
            } else {
                if ( (zdif > 20) ) {
                    dam_mult = 1.200;
                    stuffcmd (trace_ent,"bf\n");
                    trace_ent.head_shot_vector = (trace_ent.origin - self.origin);
                    deathmsg = 29;
                    TF_T_Damage (trace_ent,self,self,(self.heat * dam_mult),2,1);
                    if ( (trace_ent.health > 0) ) {
                        sprint (trace_ent,PRINT_LOW,"Head injury!\n");
                        sprint (self,PRINT_MEDIUM,"Head shot - that's gotta hurt!\n");
                    }
                    return ;
                } else {
                    deathmsg = 18;
                }
            }
        }
    }

    ClearMultiDamage ();
    if ( (trace_fraction != 1) ) {
        TraceAttack ((self.heat * dam_mult),dir);
    }
    ApplyMultiDamage ();
}

void W_FireAutoRifle () {
    vector dir;
    sound (self,CHAN_WEAPON,"weapons/autorifle.wav",1,1);
    KickPlayer (-1,self);
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 1);
        self.currentammo = self.ammo_shells;
        if (allow_stamina)
            self.stamina = self.stamina - 30;
    }
    makevectors (self.v_angle);
    dir = v_forward;
    deathmsg = 19;
    FireSniperBullet (dir,8, '0.04 0.04 0');
}

void () s_plasma1 = [ 0, s_plasma2 ] {};

void () s_plasma2 = [ 1, s_plasma3 ] {};

void () s_plasma3 = [ 2, s_plasma4 ] {};

void () s_plasma4 = [ 3, s_plasma1 ] {};

void Plasma_stream_touch () {
    if ( ((other.takedamage == 2) && (other.health > 0)) ) {
        TF_T_Damage (other,self,self.owner,20,2,8);
        if (cb_prematch ) return ;

    } else {
        T_RadiusDamage (self,self.owner,27,other);
        self.origin = (self.origin - (8 * normalize (self.velocity)));
    }
    deathmsg = 18;
    sound (self,0,"weapons/laserhit.wav",1,1);
    dremove(self);
}
#ifdef CSQC

float SendPlasma (entity toplayer) {
    WriteByte(MSG_ENTITY, CLASS_PLASMA);
    WriteCoord(MSG_ENTITY, self.origin_x);
    WriteCoord(MSG_ENTITY, self.origin_y);
    WriteCoord(MSG_ENTITY, self.origin_z);
    WriteAngle(MSG_ENTITY, self.angles_x);
    WriteAngle(MSG_ENTITY, self.angles_y);
    //WriteByte(MSG_ENTITY, ));
    return 1;
}
#endif

void W_FirePlasma () {
    float rn;
    entity plasma;
    if ( (self.waterlevel > 2) ) {
        makevectors (self.v_angle);
        //NewBubbles (2,(self.origin + (v_forward * 64)));
        rn = random ();
        if ( (rn < 0.500) ) {
            sound (self,CHAN_WEAPON,"misc/water1.wav",1,1);
        } else {
            sound (self,CHAN_WEAPON,"misc/water2.wav",1,1);
        }
        return ;
    }
    if (!modetype & 2) {
        self.ammo_cells = (self.ammo_cells - 1);
        self.currentammo = self.ammo_cells;
    }
    sound (self,0,"weapons/hyperb1.wav",1,1);
    plasma = spawn ();
    plasma.owner = self;
    plasma.movetype = MOVETYPE_FLYMISSILE;
    plasma.solid = SOLID_BBOX;
    plasma.volume = 2.500;
    //plasma.effects = (plasma.effects | 64);
    plasma.classname = "plasma";
    makevectors (self.v_angle);
    plasma.velocity = aim (self,10000);
    plasma.velocity = (plasma.velocity * 1000);
    plasma.angles = vectoangles (plasma.velocity);
    plasma.touch = Plasma_stream_touch;
    setmodel (plasma,"progs/s_plasma.spr");
    plasma.think = s_plasma1;
    plasma.nextthink = (time + 0.050);
    //setmodel (plasma,"progs/laser.mdl");
    setsize (plasma,'0 0 0','0 0 0');
    setorigin (plasma,((self.origin + (v_forward * 16)) + '0 0 16'));
#ifdef CSQC
    plasma.SendEntity = SendPlasma;
    //newmis.starttime = time;
    plasma.Version+=1;
#endif
}

void W_FireAssaultCannon () {
    vector dir;
    KickPlayer (-4,self);
    if (!modetype & 2) {
        self.ammo_shells = (self.ammo_shells - 1);
        self.currentammo = self.ammo_shells;
        if (allow_stamina)
            self.stamina = self.stamina - 50;
    }
    dir = aim (self,100000);
    deathmsg = 20;
    if (!(classtype & 2)) {
        if ( self.velocity == '0 0 0') {
            FireBullets (4.500,dir,'0.050 0.050 0');
        } else {
            FireBullets (4,dir,'0.100 0.100 0');
        }
    } else {
        FireBullets (5, dir, '0.1 0.1 0');
    }
    EjectShell ();
}

void () s_explode1 = [ 0, s_explode2 ] {
}

void () s_explode2 = [ 1, s_explode3 ] {};

void () s_explode3 = [ 2, s_explode4 ] {};

void () s_explode4 = [ 3, s_explode5 ] {};

void () s_explode5 = [ 4, s_explode6 ] {};

void () s_explode6 = [ 5, SUB_Remove ] {};

void MissileRadius () {
    float damg;
    if ( (self.owner.classname == "building_sentrygun") ) {
        damg = 150;
    } else {
        if ((self.playerclass == 11)) {
            damg = 120;

        } else {
            damg = 92;
        }
    }
    deathmsg = self.weapon;
    T_RadiusDamage (self,self.owner,damg,other);
    self.origin = (self.origin - (8 * normalize (self.velocity)));
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    dremove (self);
}

void T_MissileTouch () {
    float damg;

    if ( self.voided ) {
        return ;
    }

    self.voided = 1;
    if ( (pointcontents (self.origin) == -6) ) {
        dremove (self);
        return ;
    }
    if ((self.playerclass == 11)) {
        damg = (100 + (random () * 20));
    } else {
        damg = (92 + (random () * 20));
    }
    deathmsg = self.weapon;
    if ( other.health ) {
        TF_T_Damage (other,self,self.owner,damg,2,0);
    }
    MissileRadius();
}

void RealisticMove () {
    if (self.attack_finished < time) {
        if (self.weapon == 6) {
            MissileRadius();
        } else {
            SUB_Remove();
        }
        return;
    }
    if (vlen(self.velocity) < vlen(self.movedir)) {
        self.velocity_x = self.velocity_x + (self.movedir_x / 20);
        self.velocity_y = self.velocity_y + (self.movedir_y / 20);
        self.velocity_z = self.velocity_z + (self.movedir_z / 20);
    }
    self.nextthink = time + 0.01;
}
#ifdef CSQC

float SendRocket (entity toplayer) {
    WriteByte(MSG_ENTITY, CLASS_ROCKET);
    WriteCoord(MSG_ENTITY, self.origin_x);
    WriteCoord(MSG_ENTITY, self.origin_y);
    WriteCoord(MSG_ENTITY, self.origin_z);
    WriteAngle(MSG_ENTITY, self.angles_x);
    WriteAngle(MSG_ENTITY, self.angles_y);
    //WriteByte(MSG_ENTITY, ));
    return 1;
}
#endif

void W_FireRocket () {
    vector pvel;
    if (!modetype & 2) {
        self.ammo_rockets = (self.ammo_rockets - 1);
        self.currentammo = self.ammo_rockets;
        if (allow_stamina)
            self.stamina = self.stamina - 300;
    }
    sound (self,CHAN_WEAPON,"weapons/sgun1.wav",1,1);
    KickPlayer (-2,self);
    newmis = spawn ();
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    makevectors (self.v_angle);
    newmis.velocity = v_forward;
    if ( (self.playerclass == 11 )) {
        newmis.movedir = (newmis.velocity * 1000);
    } else {
        newmis.movedir = (newmis.velocity * 900);
    }
    newmis.angles = vectoangles (newmis.movedir);
    if (realistic & 1) {

        pvel_x = (self.velocity_x / 2) + (newmis.movedir_x / 3);
        pvel_y = (self.velocity_y / 2) + (newmis.movedir_y / 3);
        pvel_z = (self.velocity_z / 2) + (newmis.movedir_z / 3);
        newmis.velocity =  pvel;
        //pvel = (self.origin + '0 0 16');
        //traceline (pvel,(pvel + (v_forward * 700)),1,self);
        //newmis.dest = trace_endpos;
        newmis.think = RealisticMove;
        newmis.nextthink = time + 0.01;
        newmis.attack_finished = (time + 6);
    } else {
        newmis.velocity = newmis.movedir;
        newmis.nextthink = (time + 6);
        newmis.think = MissileRadius;
    }
    newmis.classname = "rocket";
    newmis.touch = T_MissileTouch;

    newmis.voided = 0;

    newmis.weapon = 6;
    setmodel (newmis,"progs/missile.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,((self.origin + (v_forward * 8)) + '0 0 16'));
#ifdef CSQC
    newmis.SendEntity = SendRocket;
    //newmis.starttime = time;
    newmis.Version+=1;
#endif
}

void LightningHit (entity from, float damage) {
    WriteByte (4,23);
    WriteByte (4,13);
    WriteCoord (4,trace_endpos_x);
    WriteCoord (4,trace_endpos_y);
    WriteCoord (4,trace_endpos_z);
    multicast (trace_endpos,2);
    deathmsg = 7;
    TF_T_Damage (trace_ent,from,from,damage,2,8);
}

void LightningDamage (vector p1, vector p2, entity from, float damage) {
    entity e1;
    entity e2;
    vector f;
    f = (p2 - p1);
    normalize (f);
    f_x = (0 - f_y);
    f_y = f_x;
    f_z = 0;
    f = (f * 16);
    e2 = world;
    e1 = world;
    traceline (p1,p2,0,self);
    if ( trace_ent.takedamage ) {
        LightningHit (from,damage);
        if ( (self.classname == "player") ) {
            if ( (other.classname == "player") ) {
                trace_ent.velocity_z = (trace_ent.velocity_z + 400);
            }
        }
    }
    e1 = trace_ent;
    traceline ((p1 + f),(p2 + f),0,self);
    if ( ((trace_ent != e1) && trace_ent.takedamage) ) {
        LightningHit (from,damage);
    }
    e2 = trace_ent;
    traceline ((p1 - f),(p2 - f),0,self);
    if ( (((trace_ent != e1) && (trace_ent != e2)) && trace_ent.takedamage) ) {
        LightningHit (from,damage);
    }
}

void W_FireLightning () {
    vector org;
    float cells;
    if ( (self.ammo_cells < 1) ) {
        self.last = self.current;
        self.current = W_BestWeapon ();
        W_SetCurrentAmmo ();
        W_PrintWeaponMessage ();
        return ;
    }
    if ( (self.waterlevel > 1) ) {
        cells = self.ammo_cells;
        self.ammo_cells = 0;
        W_SetCurrentAmmo ();
        deathmsg = 7;
        T_RadiusDamage (self,self,(35 * cells),world);
        return ;
    }
    if ( (self.t_width < time) ) {
        sound (self,CHAN_WEAPON,"weapons/lhit.wav",1,1);
        self.t_width = (time + 0.600);
    }
    KickPlayer (-2,self);
    if (!modetype & 2) {
        self.ammo_cells = (self.ammo_cells - 1);
        self.currentammo = self.ammo_cells;
        if (allow_stamina)
            self.stamina = self.stamina - 40;
    }
    org = (self.origin + '0 0 16');
    traceline (org,(org + (v_forward * 600)),1,self);
    WriteByte (4,23);
    WriteByte (4,6);
    WriteEntity (4,self);
    WriteCoord (4,org_x);
    WriteCoord (4,org_y);
    WriteCoord (4,org_z);
    WriteCoord (4,trace_endpos_x);
    WriteCoord (4,trace_endpos_y);
    WriteCoord (4,trace_endpos_z);
    multicast (org,1);
    LightningDamage (self.origin,(trace_endpos + (v_forward * 4)),self,30);
}

void ExplodeOldPipebomb (entity player) {
    entity old;
    float index;
    if ( (player != world) ) {
        index = player.pteam.num_pipebombs;
        index = (index - (store_obs.max_pipebombs / store_obs.cnt));
    } else {
        index = (store_obs.num_pipebombs - store_obs.max_pipebombs);
    }
    old = find (world,classname,"pipebomb");
    while ( (index > 0) ) {
        if ( (old == world) ) {
            store_obs.num_pipebombs = 0;
            pteam1.num_pipebombs = 0;
            pteam2.num_pipebombs = 0;
            pteam3.num_pipebombs = 0;
            pteam4.num_pipebombs = 0;
            return ;
        }
        if ( (old.owner == player) || (player == world) ) {
            old.nextthink = (time + 0.500);
            index = (index - 1);
        }
        old = find (old,classname,"pipebomb");
    }
}

void GrenadeExplode () {
    entity te;

    if ( self.voided ) {
        return ;
    }

    self.voided = 1;
    if ( (self.classname == "pipebomb") ) {
        store_obs.num_pipebombs = (store_obs.num_pipebombs - 1);
        self.owner.pteam.num_pipebombs = self.owner.pteam.num_pipebombs - 1;
        if ( !(self.flags & 512) ) {
            self.weapon = 40;
        }
    }
    if ( (self.owner.has_disconnected != 1) ) {
        deathmsg = self.weapon;
        T_RadiusDamage (self,self.owner,120,world);
    }
    if ( (self.no_active_nail_grens != 0) ) {
        self.no_active_nail_grens = 0;
        self.owner.no_active_nail_grens = (self.owner.no_active_nail_grens - 1);
        te = find (world,classname,"grenade");
        while ( te ) {
            if ( ((te.owner == self.owner) && (te.no_active_nail_grens > 0)) ) {
                te.no_active_nail_grens = (te.no_active_nail_grens - 1);
            }
            te = find (te,classname,"grenade");
        }
    }
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    dremove (self);
}

void PipebombTouch () {
    if ( (other.classname != "worldspawn") ) {
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void GrenadeTouch () {
    if ( (other == self.owner) ) {
        return ;
    }
    if ( (other.takedamage == 2) ) {
        GrenadeExplode ();
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void InitGrenade (entity te) {
    vector pvel;
    if (!modetype & 2) {
        self.ammo_rockets = (self.ammo_rockets - 1);
        self.currentammo = self.ammo_rockets;
        if (allow_stamina)
            self.stamina = self.stamina - 180;
    }
    sound (self,CHAN_WEAPON,"weapons/grenade.wav",1,1);
    KickPlayer (-2,self);

    te.voided = 0;
    te.owner = self;
    te.movetype = MOVETYPE_BOUNCE;
    te.solid = SOLID_BBOX;
    makevectors (self.v_angle);
    if ( self.v_angle_x ) {
        te.movedir = ((((v_forward * 600) + (v_up * 200)) + ((crandom () * v_right) * 10)) + ((crandom () * v_up) * 10));
    } else {
        te.movedir = aim (self,10000);
        te.movedir = (te.movedir * 600);
        te.movedir_z = 200;
    }
    te.avelocity = '300 300 300';
    te.angles = vectoangles (te.movedir);
    if (realistic & 1) {
        pvel_x = (self.velocity_x / 2);
        pvel_y = (self.velocity_y / 2);
        pvel_z = (self.velocity_z / 2);
        te.velocity =  pvel + te.movedir;
    } else {
        te.velocity =  te.movedir;
    }
    te.think = GrenadeExplode;
    setmodel (te,"progs/grenade2.mdl");
    setsize (te,'0 0 0','0 0 0');
    setorigin (te,self.origin);
}
#ifdef CSQC

float SendGrenade (entity toplayer) {
    WriteByte(MSG_ENTITY, CLASS_GRENADE);
    WriteByte(MSG_ENTITY, self.skin);
    WriteCoord(MSG_ENTITY, self.origin_x);
    WriteCoord(MSG_ENTITY, self.origin_y);
    WriteCoord(MSG_ENTITY, self.origin_z);
    WriteCoord(MSG_ENTITY, self.velocity_x);
    WriteCoord(MSG_ENTITY, self.velocity_y);
    WriteCoord(MSG_ENTITY, self.velocity_z);
    WriteAngle(MSG_ENTITY, self.angles_x);
    WriteAngle(MSG_ENTITY, self.angles_y);
    return 1;
}
#endif

void W_FireGrenade () {
    newmis = spawn ();
    InitGrenade(newmis);
    newmis.weapon = 5;
    newmis.classname = "grenade";
    newmis.skin = 1;
    newmis.touch = GrenadeTouch;
    newmis.nextthink = (time + 2.500);
#ifdef CSQC
    newmis.SendEntity = SendGrenade;
    newmis.starttime = time;
    newmis.Version+=1;
#endif
}

void W_FirePipebomb () {
    newmis = spawn ();
    InitGrenade(newmis);
    if ( (self.pteam) ) {
        self.pteam.num_pipebombs = self.pteam.num_pipebombs + 1;
        if ( (self.pteam.num_pipebombs > (store_obs.max_pipebombs / store_obs.cnt)) ) {
            ExplodeOldPipebomb (self);
        }
    } else {
        store_obs.num_pipebombs = (store_obs.num_pipebombs + 1);
        if ( (store_obs.num_pipebombs > store_obs.max_pipebombs ) ) {
            ExplodeOldPipebomb (world);
        }
    }
    newmis.classname = "pipebomb";
    newmis.touch = PipebombTouch;
    newmis.skin = 2;
    newmis.nextthink = (time + 120);
    newmis.weapon = 11;
    newmis.pteam = self.pteam;
#ifdef CSQC
    newmis.SendEntity = SendGrenade;
    newmis.starttime = time;
    newmis.Version+=1;
#endif
}

#ifdef CSQC
float SendNail (entity toplayer) {
    vector v;
    v = self.origin + self.velocity*(time-self.starttime);
    WriteByte(MSG_ENTITY, CLASS_NAIL);
    WriteCoord(MSG_ENTITY, v_x);
    WriteCoord(MSG_ENTITY, v_y);
    WriteCoord(MSG_ENTITY, v_z);
    WriteAngle(MSG_ENTITY, self.angles_x);
    WriteAngle(MSG_ENTITY, self.angles_y);
    //WriteByte(MSG_ENTITY, );
    return 1;
}
#endif

void spike_touch ();

void superspike_touch ();

void launch_spike (vector org, vector dir) {
    vector pvel;
    newmis = spawn ();

    newmis.voided = 0;
    newmis.owner = self;
    newmis.movetype = MOVETYPE_FLYMISSILE;
    newmis.solid = SOLID_BBOX;
    newmis.angles = vectoangles (dir);
    newmis.touch = spike_touch;
    newmis.weapon = 3;
    newmis.classname = "spike";
    newmis.movedir = (dir * 1000);
    if (realistic & 1) {
        pvel_x = (self.velocity_x / 2) + (newmis.movedir_x / 3);
        pvel_y = (self.velocity_y / 2) + (newmis.movedir_y / 3);
        pvel_z = (self.velocity_z / 2) + (newmis.movedir_z / 3);
        newmis.velocity =  pvel;
        newmis.attack_finished = (time + 3);
        newmis.think = RealisticMove;
        newmis.nextthink = time + 0.01;
    } else {
        newmis.velocity = newmis.movedir;
        newmis.think = SUB_Remove;
        newmis.nextthink = (time + 3);
    }
    setmodel (newmis,"progs/spike.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,org);
#ifdef CSQC
    newmis.SendEntity = SendNail;
    newmis.starttime = time;
    newmis.Version+=1;
#endif
}

void W_FireSuperSpikes () {
    vector dir;
    sound (self,CHAN_WEAPON,"weapons/spike2.wav",1,1);
    if (!modetype & 2) {
        self.ammo_nails = (self.ammo_nails - 2);
        self.currentammo = self.ammo_nails;
        if (allow_stamina)
            self.stamina = self.stamina - 30;
    }
    dir = aim (self,1000);
    launch_spike ((self.origin + '0 0 16'),dir);
    newmis.touch = superspike_touch;
    newmis.weapon = 4;
    setmodel (newmis,"progs/s_spike.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    KickPlayer (-2,self);
}

void W_FireSpikes (float ox) {
    vector dir;
    makevectors (self.v_angle);
    if ( ((self.ammo_nails >= 2) && (self.current == WEAP_SUPER_NAILGUN)) ) {
        W_FireSuperSpikes ();
        return ;
    }
    if ( (self.ammo_nails < 1) ) {
        self.last = self.current;
        self.current = W_BestWeapon ();
        W_SetCurrentAmmo ();
        W_PrintWeaponMessage ();
        return ;
    }
    sound (self,CHAN_WEAPON,"weapons/rocket1i.wav",1,1);
    if (!modetype & 2) {
        if (allow_stamina)
            self.stamina = self.stamina - 20;
        //   if ( (self.ammo_nails == 1) )
        //   {
        self.ammo_nails = (self.ammo_nails - 1);
        //   }
        //   else
        //   {
        //      self.ammo_nails = (self.ammo_nails - 2);
        //   }
        self.currentammo = self.ammo_nails;
    }
    dir = aim (self,1000);
    if (light_ents) {
        deathmsg = 3;
        FireSniperBullet (dir, 4, '0 0 0');
    } else {
        launch_spike (((self.origin + '0 0 16') + (v_right * ox)),dir);
    }
    KickPlayer (-2,self);
}
//.float hit_z;

void spike_touch () {
    if ( self.voided ) {
        return ;
    }

    self.voided = 1;
    if ( (other.solid == 1) ) {
        return ;
    }
    if ( (pointcontents (self.origin) == -6) ) {
        dremove (self);
        return ;
    }
    if ( other.takedamage ) {
		spawn_touchblood (9);
        deathmsg = self.weapon;
        if ( (self.owner.classname == "grenade") ) {
            TF_T_Damage (other,self,self.owner.owner,9,2,2);
        } else {
            TF_T_Damage (other,self,self.owner,18,2,2);
        }
    } else {
        WriteByte (4,23);
        WriteByte (4,0);
        //WriteByte (4,7);
        //WriteByte (4,8);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
    }
    dremove (self);
}

void superspike_touch () {
    float ndmg;

    if ( self.voided ) {
        return ;
    }

    self.voided = 1;
    if ( (other == self.owner) ) {
        return ;
    }
    if ( (other.solid == 1) ) {
        return ;
    }
    if ( (pointcontents (self.origin) == -6) ) {
        dremove (self);
        return ;
    }
    if ( other.takedamage ) {
		spawn_touchblood (18);
        deathmsg = self.weapon;
        if ( (deathmsg == 9) ) {
            ndmg = 30;
        } else {
            ndmg = 18;
        }
        if ( (self.owner.classname == "grenade") ) {
            TF_T_Damage (other,self,self.owner.owner,ndmg,2,2);
        } else {
            TF_T_Damage (other,self,self.owner,ndmg,2,2);
        }
    } else {
        WriteByte (4,23);
        if ( (self.owner.classname == "grenade") ) {
            WriteByte (4,8);
        } else {
            WriteByte (4,1);
        }
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
    }
    dremove (self);
}

void set_ca_none () {
    self.currentammo = 0;
    self.weaponmodel = "";
}

void set_ca_hook () {
    self.currentammo = 0;
    self.weaponmodel = "progs/v_grap.mdl";
}

void set_ca_medi () {
    self.currentammo = self.ammo_medikit;
    self.weaponmodel = "progs/v_medi.mdl";
}

void set_ca_span () {
    self.currentammo = self.ammo_cells;
    self.weaponmodel = "progs/v_span.mdl";
}

void set_ca_axe () {
    self.currentammo = 0;
    if ( (self.playerclass == 8) ) {
        self.weaponmodel = "progs/v_knife.mdl";
    } else {
        if (modetype & 4) {
            self.weaponmodel = "progs/v_knife.mdl";
        } else {
            self.weaponmodel = "progs/v_axe.mdl";
        }
    }
}

void set_ca_sr () {
    self.currentammo = self.ammo_shells;
    self.weaponmodel = "progs/v_srifle.mdl";
    self.items = (self.items | 256);
    self.weapon = 1;
}

void set_ca_ar () {
    self.currentammo = self.ammo_shells;
    self.items = (self.items | 256);
    self.weaponmodel = "progs/v_srifle.mdl";
    self.weapon = 2;
}

void set_ca_sg () {
    self.currentammo = self.ammo_shells;
    self.items = (self.items | 2048);
    if ( !(self.tfstate & 2) ) {
        self.weaponmodel = "progs/v_shot.mdl";
    }
    self.items = (self.items | 256);
    self.weapon = 1;
}

void set_ca_ssg () {
    self.currentammo = self.ammo_shells;
    if ( !(self.tfstate & 2) ) {
        self.weaponmodel = "progs/v_shot2.mdl";
        self.weaponframe = 0;
    }
    self.items = (self.items | 256);
    self.weapon = 2;
}

void set_ca_ng () {
    self.currentammo = self.ammo_nails;
    self.weaponmodel = "progs/v_nail.mdl";
    self.items = (self.items | 512);
    self.weapon = 4;
}

void set_ca_sng () {
    self.currentammo = self.ammo_nails;
    self.weaponmodel = "progs/v_nail2.mdl";
    self.items = (self.items | 512);
    self.weapon = 8;
}

void set_ca_gren () {
    self.currentammo = self.ammo_rockets;
    if ( !(self.tfstate & 2) ) {
        self.weaponmodel = "progs/v_rock.mdl";
    }
    self.items = (self.items | 1024);
}

void set_ca_gl () {
    set_ca_gren();
    self.weapon = 16;
}

void set_ca_pbl () {
    set_ca_gren();
    self.weapon = 32;
}

void set_ca_ft () {
    self.currentammo = self.ammo_cells;
    if (sep_models) {
        self.weaponmodel = "progs/v_flame.mdl";
    } else {
        self.weaponmodel = "progs/v_rock.mdl";
    }
    self.items = (self.items | 2048);
    self.weapon = 8;
}

void set_ca_rl () {
    self.currentammo = self.ammo_rockets;
    if ( !(self.tfstate & 2) ) {
        self.weaponmodel = "progs/v_rock2.mdl";
    }
    self.items = (self.items | 1024);
    self.weapon = 32;
}

void set_ca_ic () {
    self.currentammo = self.ammo_rockets;
    if (sep_models) {
        self.weaponmodel = "progs/v_ican.mdl";
    } else {
        self.weaponmodel = "progs/v_rock2.mdl";
    }
    self.items = (self.items | 1024);
    self.weapon = 32;
}

void set_ca_ac () {
    self.currentammo = self.ammo_shells;
    self.weaponmodel = "progs/v_asscan.mdl";
    self.items = (self.items | 256);
    self.weapon = 64;
}

void set_ca_lg () {
    self.currentammo = self.ammo_cells;
    self.weaponmodel = "progs/v_light.mdl";
    self.items = (self.items | 2048);
    self.weapon = 64;
}

void set_ca_pl () {
    self.currentammo = self.ammo_cells;
    self.items = (self.items | 2048);
    self.weaponmodel = "progs/v_plasma.mdl";
    self.weapon = 16;
}

void set_ca_tr () {
    self.currentammo = self.ammo_shells;
    if (sep_models) {
        self.weaponmodel = "progs/v_tranq.mdl";
    } else {
        self.weaponmodel = "progs/v_shot.mdl";
    }

    self.items = (self.items | 256);
    self.weapon = 1;
}

void set_ca_rg () {
    self.currentammo = self.ammo_nails;
    self.weaponmodel = "progs/v_rail.mdl";
    self.items = (self.items | 512);
    self.weapon = 1;
}

var void() weapnum_setammo[21] = {
    set_ca_none,
    set_ca_hook,
    set_ca_medi,
    set_ca_span,
    set_ca_axe,
    set_ca_sr,
    set_ca_ar,
    set_ca_sg,
    set_ca_ssg,
    set_ca_ng,
    set_ca_sng,
    set_ca_gl,
    set_ca_pbl,
    set_ca_ft,
    set_ca_rl,
    set_ca_ic,
    set_ca_ac,
    set_ca_lg,
    set_ca_pl,
    set_ca_tr,
    set_ca_rg
}

void W_SetCurrentAmmo () {
    float i, b;
    if ( ((self.health <= 0) || (self.current == 0)) ) {
        return ;
    }
    if ( ((self.current == WEAP_ASSAULT_CANNON) && (self.tfstate & 2048)) ) {
        return ;
    }
    player_run ();
    self.items = (self.items - (self.items & (((256 | 512) | 1024) | 2048)));
    self.weapon = 0;
	i = 0;
    for (b = 1; b < WEAP_LAST;  b *= 2) {
        i+=1;
        if (self.current == b) {
            break;
        }
    }
    self.th_melee = weapnum_setammo[i];
    self.th_melee();
    if (self.StatusBarSize)
        self.StatusRefreshTime = (time + 0.100);
    self.weaponframe = 0;
}

float W_BestWeapon () {
	float it;
	it = self.carried;
	if ( (((self.ammo_cells >= 1) && (it & WEAP_LIGHTNING)) && (self.waterlevel <= 1)) ) {
		return ( WEAP_LIGHTNING );
	} else if ( (((self.ammo_cells >= 7) && (self.ammo_shells >= 1)) && (it & WEAP_ASSAULT_CANNON)) ) {
		return ( WEAP_ASSAULT_CANNON );
	} else if ( ((self.ammo_cells >= 1) && (it & WEAP_FLAMETHROWER)) ) {
		return ( WEAP_FLAMETHROWER );
	} else if ( ((self.ammo_nails >= 2) && (it & WEAP_SUPER_NAILGUN)) ) {
		return ( WEAP_SUPER_NAILGUN );
	} else if ( ((self.ammo_shells >= 2) && (it & WEAP_SUPER_SHOTGUN)) ) {
		return ( WEAP_SUPER_SHOTGUN );
	} else if ( ((self.ammo_nails >= 1) && (it & WEAP_RAILGUN)) ) {
		return ( WEAP_RAILGUN );
	} else if ( ((self.ammo_nails >= 1) && (it & WEAP_NAILGUN)) ) {
		return ( WEAP_NAILGUN );
	} else if ( ((self.ammo_shells >= 1) && (it & WEAP_SHOTGUN)) ) {
		return ( WEAP_SHOTGUN );
	} else if ( ((self.ammo_shells >= 1) && (it & WEAP_TRANQ)) ) {
		return ( WEAP_TRANQ );
	} else if ( (it & WEAP_AXE) ) {
		return ( WEAP_AXE );
	} else if ( (it & WEAP_SPANNER) ) {
		return ( WEAP_SPANNER );
	} else if ( (it & WEAP_MEDIKIT) ) {
		return ( WEAP_MEDIKIT );
	} else {
		return ( 0 );
	}
}

float W_CheckNoAmmo () {
    if ( (self.current == WEAP_MEDIKIT) ) {
        return ( 1 );

    } else {
        if ( (((self.current == WEAP_AXE) || (self.current == WEAP_HOOK)) || (self.current == WEAP_SPANNER)) ) {
            return ( 1 );
        } else {
            if (self.current == WEAP_INCENDIARY) {

                if (self.currentammo >= ic_ammo) {
                    return ( 1 );
                }
            } else if ((self.current == WEAP_ASSAULT_CANNON) && (self.ammo_cells < 7)) {
                sprint (self,PRINT_HIGH,"Insufficient cells to power up the Assault Cannon.\n");
                return (0);
            } else {
                if ( (self.currentammo > 0) ) {
                    return ( 1 );
                }
            }
        }
    }
    sprint (self,PRINT_HIGH,"not enough ammo.\n");
    return ( 0 );

}

void player_axe1 ();

void player_axeb1 ();

void player_axec1 ();

void player_axed1 ();

void player_shot1 ();

void player_nail1 ();

void player_light1 ();

void player_rocket1 ();

void player_autorifle1 ();

void player_assaultcannon1 ();

void player_assaultcannonup1 ();

void player_assaultcannondown1 ();

void player_medikit1 ();

void player_medikitb1 ();

void player_medikitc1 ();

void player_medikitd1 ();

void player_chain1 ();

void player_chain2 ();

void player_chain3 ();

void player_chain4 ();

void player_chain5 ();

void attack_none () {
    player_run();
}

void attack_axe () {
    float r;
    Attack_Finished (0.500);
    sound (self,CHAN_WEAPON,"weapons/ax1.wav",1,1);
    r = random ();
    if ( (r < 0.250) ) {
        player_axe1 ();
    } else {
        if ( (r < 0.500) ) {
            player_axeb1 ();
        } else {
            if ( (r < 0.750) ) {
                player_axec1 ();
            } else {
                player_axed1 ();
            }
        }
    }
}

void attack_medi () {
    float r;
    sound (self,CHAN_WEAPON,"weapons/ax1.wav",1,1);
    r = random ();
    if ( (r < 0.250) ) {
        player_medikit1 ();
    } else {
        if ( (r < 0.500) ) {
            player_medikitb1 ();
        } else {
            if ( (r < 0.750) ) {
                player_medikitc1 ();
            } else {
                player_medikitd1 ();
            }
        }
    }
    Attack_Finished (0.500);
}

void attack_span () {
    Attack_Finished (0.500);
    sound (self,CHAN_WEAPON,"weapons/ax1.wav",1,1);
    player_axe1 ();
}

void attack_hook () {
    if ( !self.hook_out )
        player_chain1 ();
    Attack_Finished (0.100);
}

void attack_sg () {
    if ( (CheckForReload ()) ) return ;
    player_shot1 ();
    W_FireShotgun ();
    self.reload_shotgun = (self.reload_shotgun + 1);
    CheckForReload ();
    Attack_Finished (0.500);
}

void attack_ssg () {
    if ( (CheckForReload ()) )   return ;
    player_shot1 ();
    W_FireSuperShotgun ();
    self.reload_super_shotgun = (self.reload_super_shotgun + 2);
    CheckForReload ();
    Attack_Finished (0.700);
}

void attack_ng () {
    player_nail1 ();
}

void gren_end () {
    self.reload_grenade_launcher = (self.reload_grenade_launcher + 1);
    CheckForReload ();
    Attack_Finished (0.600);
}

void attack_gl () {
    if ( (CheckForReload ()) )  return ;
    player_rocket1 ();
    W_FireGrenade ();
    gren_end();
}

void attack_pbl () {
    if ( (CheckForReload ()) )  return ;
    player_rocket1 ();
    W_FirePipebomb ();
    gren_end();
}

void attack_rl () {
    if ( (CheckForReload ()) )  return ;
    player_rocket1 ();
    W_FireRocket ();
    self.reload_rocket_launcher = (self.reload_rocket_launcher + 1);
    if (self.StatusBarSize)
        self.StatusRefreshTime = (time + 0.100);
    CheckForReload ();
    Attack_Finished (0.800);
}

void attack_lg () {
    player_light1 ();
    Attack_Finished (1.100);
    sound (self,0,"weapons/lstart.wav",1,1);
}

void attack_sr () {
    if (self.flags & 512) {
        player_shot1 ();
        W_FireSniperRifle ();
        Attack_Finished (1.700);
    }
}

void attack_pl () {
    player_autorifle1 ();
    W_FirePlasma ();
    Attack_Finished (0.125);
}

void attack_ar () {
    player_autorifle1 ();
    W_FireAutoRifle ();
    Attack_Finished (0.100);
}

void attack_ac () {
    self.ammo_cells = (self.ammo_cells - 7);
    self.heat = 1;
    if (classtype & 2)
        self.tfstate = (self.tfstate | 65536);
    self.tfstate = (self.tfstate | 2048);
    TeamFortress_SetSpeed (self);
    player_assaultcannonup1 ();

}

void attack_ft () {
    player_shot1 ();
    W_FireFlame ();
    if ( (self.waterlevel > 2) ) {
        Attack_Finished (1);
    } else {
        Attack_Finished (0.150);
    }
}

void attack_ic () {
    player_rocket1 ();
    W_FireIncendiaryCannon ();
    if (classtype & 16) {
        Attack_Finished (1.200);
    } else {
        Attack_Finished (0.900);
    }
}

void attack_tr () {
    sound (self,CHAN_WEAPON,"weapons/dartgun.wav",1,1);
    player_shot1 ();
    W_FireTranq ();
    Attack_Finished (1.500);
}

void attack_rg () {
    sound (self,CHAN_WEAPON,"weapons/railgun.wav",1,1);
    player_shot1 ();
    if (railgun)
        W_FireRailgun ();
    else
        W_FireRail ();
    Attack_Finished (0.400);
}

var void() weapnum_attack[21] = {
    attack_none,
    attack_hook,
    attack_medi,
    attack_span,
    attack_axe,
    attack_sr,
    attack_ar,
    attack_sg,
    attack_ssg,
    attack_ng,
    attack_ng,
    attack_gl,
    attack_pbl,
    attack_ft,
    attack_rl,
    attack_ic,
    attack_ac,
    attack_lg,
    attack_pl,
    attack_tr,
    attack_rg
}

void W_Attack () {
    float b;
    float i;
    entity te;
    if ( !W_CheckNoAmmo () ) {
        self.current = W_BestWeapon ();
        W_SetCurrentAmmo ();
        W_PrintWeaponMessage ();
        return ;
    }
    if (allow_stamina) {
        if (self.stamina < 0) {
            return;
        }
    }
    if ( (self.has_disconnected == 1) ) {
        return ;
    }
    if ( (!self.playerclass) ) {
        return ;
    }

    if ( (self.tfstate & 2) ) {
        if (realistic & 2) {
            te = find (world,classname,"timer");
            while ( (te != world) ) {
                if (te.owner == self && te.weaponmode) {

                    if (te.voided) return;
                    te.think = Cancel_reload;
                    te.pausetime = te.nextthink;
                    te.nextthink = time + 0.01;

                    te.voided = 1;
                    return;
                } else {
                    te = find (te,classname,"timer");
                }
            }
        }
        return ;
    }
    if ( ((self.is_undercover || (self.undercover_team != 0)) || (self.undercover_skin != 0)) ) {
        Spy_RemoveDisguise (self);
    }
    makevectors (self.v_angle);
    self.show_hostile = (time + 1);
    for (b = 1; b < WEAP_LAST;  b *= 2) {
        i+=1;
        if (self.current == b) {
            break;
        }
    }
    self.th_missile = weapnum_attack[i];
    self.th_missile();
}

void W_PrintWeaponMessage () {
    if (self.current == WEAP_AXE && self.playerclass != CLASS_SPY) { // TODO: should we not have knife selected when spy?
		sprint (self,PRINT_MEDIUM,"Axe selected\n");
    } else if (self.current == WEAP_HOOK && allow_hook ) {
		sprint (self,PRINT_MEDIUM,"Grappling hook selected\n");
	} else if (self.current == WEAP_GRENADE_LAUNCHER) {
		sprint (self,PRINT_MEDIUM,"Normal grenade mode\n");
	} else if (self.current == WEAP_PIPEBOMB_LAUNCHER) {
		sprint (self,PRINT_MEDIUM,"Pipebomb mode\n");
	} else if (self.current == WEAP_SNIPER_RIFLE) {
		sprint (self,PRINT_MEDIUM,"Sniper rifle ready\n");
	} else if (self.current == WEAP_AUTO_RIFLE) {
		sprint (self,PRINT_MEDIUM,"Rifle on fully auto\n");
	} else if (self.current == WEAP_TRANQ) {
		sprint (self,PRINT_MEDIUM,"Tranquiliser gun selected\n");
	} else if (self.current == WEAP_MEDIKIT) {
		sprint (self,PRINT_MEDIUM,"Medikit/Bioweapon readied\n");
	} else if (self.current == WEAP_INCENDIARY) {
		sprint(self,PRINT_MEDIUM,"Incendiary Cannon\n");
	}
}

float imp_1 () {
    if (self.carried & WEAP_MEDIKIT) {
        return (WEAP_MEDIKIT);
    } else if (self.carried & WEAP_SPANNER) {
        return (WEAP_SPANNER);
    } else {
        return (WEAP_AXE);
    }
}

void W_ChangeWeapon () {
    float fl, imp;
    if ( (self.tfstate & 2) ) {
        return ;
    }
    fl = self.current;
    imp = self.impulse;
    if ( (imp == 1) ) {
        if (allow_hook) {
            if ((fl == WEAP_AXE) || (fl == WEAP_MEDIKIT) || (fl == WEAP_SPANNER)) {
                fl = WEAP_HOOK;
                if ( self.hook_out ) {
                    Reset_Grapple (self.hook);
                }
            } else {
                fl = imp_1();
            }
        } else {
            fl = imp_1();
        }
    } else {
        if ( (allow_hook && ((imp == 22) || (imp == 39))) ) {
            fl = WEAP_HOOK;
        } else {
            if ( (imp == 40) ) {
                fl = imp_1();
            } else {
                if ( (imp == 2) ) {
                    if ( (self.carried & WEAP_SNIPER_RIFLE) ) {
                        fl = WEAP_SNIPER_RIFLE;
                    } else {
                        if ( (self.carried & WEAP_SHOTGUN) ) {
                            fl = WEAP_SHOTGUN;
                        } else {
                            if ( (self.carried & WEAP_TRANQ) ) {
                                fl = WEAP_TRANQ;
                            } else {
                                fl = WEAP_RAILGUN;
                            }
                        }
                    }
                } else {
                    if ( (imp == 3) ) {
                        if ( (self.carried & WEAP_AUTO_RIFLE) ) {
                            fl = WEAP_AUTO_RIFLE;
                        } else {
                            fl = WEAP_SUPER_SHOTGUN;
                        }
                    } else {
                        if ( (imp == 4) ) {
                            fl = WEAP_NAILGUN;
                        } else {
                            if ( (imp == 5) ) {
                                if (self.carried & WEAP_SUPER_NAILGUN) {
                                    fl = WEAP_SUPER_NAILGUN;
                                } else {
                                    fl = WEAP_FLAMETHROWER;
                                }
                            } else {
                                if ( (imp == 6) ) {

                                    if ( (self.carried & WEAP_GRENADE_LAUNCHER) ) {
                                        fl = WEAP_GRENADE_LAUNCHER;
                                    } else {
                                        fl = WEAP_PLASMAGUN;
                                    }

                                } else {
                                    if ( (imp == 7) ) {
                                        if ( (self.carried & WEAP_INCENDIARY) ) {
                                            fl = WEAP_INCENDIARY;

                                        } else {
                                            if ( (self.carried & WEAP_ROCKET_LAUNCHER) ) {
                                                fl = WEAP_ROCKET_LAUNCHER;
                                            } else {
                                                //if ( (self.carried & WEAP_PIPEBOMB_LAUNCHER) ) {
                                                fl = WEAP_PIPEBOMB_LAUNCHER;
                                                //}
                                            }
                                        }
                                    } else {
                                        if ( (imp == 8) ) {
                                            if ( (self.carried & WEAP_LIGHTNING) ) {
                                                fl = WEAP_LIGHTNING;
                                            } else {
                                                fl = WEAP_ASSAULT_CANNON;
                                            }
                                        } else {
                                            if ( (imp == 176) ) {
                                                fl = WEAP_MEDIKIT;
                                            } else {
                                                if ( (imp == 12) ) {
                                                    fl = self.last;
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
    self.impulse = 0;
    if (!(self.carried & fl)) {
        sprint (self,PRINT_HIGH,"no weapon.\n");
        return ;
    }
    self.last = self.current;
    self.current = fl;
    W_SetCurrentAmmo ();
    W_PrintWeaponMessage ();
}

void SetWeapon (float weap) {
    self.last = self.current;
    self.current = weap;
    if ( (self.carried & self.current) ) {
        W_SetCurrentAmmo ();
        W_PrintWeaponMessage ();
    }
}

void PrevWeaponCmd () {
    float i;
    if ( ((self.weaponmodel == string_null) || (self.current == 0)) ) {
        return ;
    }
    if ( (self.tfstate & 2) ) {
        return ;
    }
    for (i = self.current; i > WEAP_HOOK;  i *= 0.5) {
        if (i != self.current) {
            if (self.carried & i) {
                SetWeapon(i);
                break;
            }
        }
    }

    if (i == WEAP_HOOK) {
        if (self.carried & WEAP_HOOK && self.current != WEAP_HOOK) {
            SetWeapon(WEAP_HOOK);
            return;
        }
        for (i = WEAP_LAST; i > WEAP_HOOK;  i *= 0.5) {
            if (i & self.carried ) {
                SetWeapon(i);
                break;
            }
        }
    }
}

void NextWeaponCmd () {
    float i;
    if ( ((self.weaponmodel == string_null) || (self.current == 0)) ) {
        return ;
    }
    if ( (self.tfstate & 2) ) {
        return ;
    }
    for (i = self.current; i < WEAP_LAST;  i *= 2) {
        if (i != self.current) {
            if (self.carried & i) {
                SetWeapon(i);
                break;
            }
        }
    }

    if (i == WEAP_LAST) {
        if (self.carried & WEAP_HOOK) {
            SetWeapon(WEAP_HOOK);
            return;
        }

        for (i = WEAP_HOOK; i < WEAP_LAST; i *= 2) {
            if (i & self.carried ) {
                SetWeapon(i);
                break;
            }
        }
    }
}
// everytime a impulse is pressed, this procedure is looped. If the time pressed is greated then 1 frame,
// it is loooped many times until impulse = 0.
// therefore after each procedure the addition of impulse = 0 and a return was added after each procedure
// to prevent excessive loops. Known to cause sticky grenades and un-useable impulses during loops.
// also procedures prematch and dead impulses was defined as a float to return to the weaponframe instead
// of just returning to impulse commands. Since commands is the last lot of impulses it was not needed to return directly.

float PreMatchImpulses ();

void CommandImpulses ();

float DeadImpulses ();

float CheckClanMode () {
    if (( modetype & 1) && (!cb_prematch)) {
        sprint (self, PRINT_HIGH, "Clan Battle in progress....\n");
        self.impulse = 0;
        return 1;
    }
    return 0;
}

void SuperDamageSound () {
    if ( (self.super_damage_finished > time) ) {
        if ( (self.super_sound < time) ) {
            self.super_sound = (time + 1);
            sound (self,4,"items/damage3.wav",1,1);
        }
    }
    return ;
}

void W_WeaponFrame () {
    vector tv;
    if ( !(self.tfstate & 2048) ) {
        if ( ((self.height > 29) && (self.height < self.oldheight)) ) {
            self.height = (self.height + 8);
            if ( (self.height > self.oldheight) ) {
                self.height = self.oldheight;
            }
            TF_zoom (self.height);
        }
    }
    if (round_active) {
        if ( (self.pteam.netname == "observe") ) {
            if (self.playerclass || self.deadflag) return;
            if (self.last_impulse) {
                if ( self.impulse ) {
                    if (( self.last_impulse == 71 )) {
                        StatusRes (self.impulse);
                        self.impulse = 0;
                        return;
                    }
                }
            }
            if (self.impulse) {
                if (DeadImpulses() ) return;
                CommandImpulses();
                self.impulse = 0;
            }
            return;
        }
    }
    if ( (self.current_menu > 0) ) {
        Player_Menu ();
        if ( (self.impulse > 0) && (self.impulse < 11) ) {
            if ((self.pteam.team == 0) && teamplay) {
                Menu_Team_Input (self.impulse);
            } else {
                if ( (!self.playerclass) ) {
                    if (round_active) return;
                    Menu_Class_Input (self.impulse);
                }
            }
            Menu_Input (self.impulse);
        }
    }
    if ((self.current == WEAP_ASSAULT_CANNON) || (self.current == WEAP_SPANNER)) {
        if ( (time < self.attack_finished) ) {
            return ;
        }
    }
    if ( ((self.impulse != 0) && (self.has_disconnected == 0)) ) {
        ImpulseCommands ();
    }
    if ( cease_fire ) {
        return ;
    }
    if (round_over) {
        return;
    }
    if ( (((self.is_building != 0) || (self.is_detpacking != 0)) || (self.is_feigning != 0)) ) {
        return ;
    }
    if (self.button0) {
        if ((self.current != WEAP_SNIPER_RIFLE) && (self.current != WEAP_ASSAULT_CANNON) && (self.current != WEAP_RAILGUN)) {
            if (self.tfstate & 2048) {
                self.tfstate = (self.tfstate - (self.tfstate & 2048));
                TeamFortress_SetSpeed (self);
                self.heat = 0;
                self.fire_held_down = 0;
            }
        } else if (self.current == WEAP_SNIPER_RIFLE) {
            if (time > (self.attack_finished - 0.200)) {
                if (self.height > 30) {
                    self.height = (self.height - 5);
                    TF_zoom (self.height);
                }
            }
        }
    }
    if ( (time < self.attack_finished) ) {
        return ;
    }
    if ((!self.button0) && (self.fire_held_down)) {
        self.fire_held_down = 0;
        if ( (self.tfstate & 2048) ) {
            if ( (self.current != WEAP_ASSAULT_CANNON) ) {
                W_Attack ();
            }
            self.tfstate = (self.tfstate - 2048);
            TeamFortress_SetSpeed (self);
            self.heat = 0;
        } else {
            if ((!self.is_frozen) && (self.tfstate & 65536)) {
                self.tfstate = self.tfstate - 65536;
                TeamFortress_SetSpeed (self);
                self.heat = 0;
            }
        }
        player_run ();
        return;
    }
    if ( (self.button0 && !self.fire_held_down) ) {
        if ( (self.current == WEAP_SNIPER_RIFLE) ) {
            tv = self.velocity;
            tv_z = 0;
            if ( (vlen (tv) <= 50) ) {
                SniperSight_Create ();
                //self.heat = 50;
                self.heat = time;
                self.oldheight =  stof(infokey(self,"fov"));
                if (!self.oldheight) self.oldheight = 100;
                self.height = self.oldheight;
                self.fire_held_down = 1;
                self.tfstate = (self.tfstate | 2048);
                TeamFortress_SetSpeed (self);
            }
        } else {
            if ( (self.current == WEAP_ASSAULT_CANNON) ) {
                if (self.flags & 512) {
                    SuperDamageSound ();
                    W_Attack ();
                }
            } else {
                if ( (self.current == WEAP_RAILGUN ) && (railgun) ) {
                    self.fire_held_down = 1;
                    self.heat = time;
                    self.tfstate = (self.tfstate | 2048);
                    TeamFortress_SetSpeed (self);

                } else {
                    SuperDamageSound ();
                    W_Attack ();
                }
            }
        }
    }
}

void RemoveGrenade () {
    entity te;
    if ( (self.no_active_napalm_grens > 0) ) {
        self.no_active_napalm_grens = 0;
        self.owner.no_active_napalm_grens = (self.owner.no_active_napalm_grens - 1);
        if ( (self.owner.no_active_napalm_grens < 0) ) {
            self.owner.no_active_napalm_grens = 0;
        }
        te = find (world,classname,"grentimer");
        while ( te ) {
            if ( ((te.owner == self.owner) && (te.no_active_napalm_grens > 0)) ) {
                te.no_active_napalm_grens = (te.no_active_napalm_grens - 1);
            }
            te = find (te,classname,"grentimer");
        }
        dremove (self.enemy);
        dremove (self);
    }
    if ( (self.no_active_gas_grens > 0) ) {
        self.no_active_gas_grens = 0;
        self.owner.no_active_gas_grens = (self.owner.no_active_gas_grens - 1);
        if ( (self.owner.no_active_gas_grens < 0) ) {
            self.owner.no_active_gas_grens = 0;
        }
        te = find (world,classname,"grentimer");
        while ( te ) {
            if ( ((te.owner == self.owner) && (te.no_active_gas_grens > 0)) ) {
                te.no_active_gas_grens = (te.no_active_gas_grens - 1);
            }
            te = find (te,classname,"grentimer");
        }
        dremove (self);
    }
}
