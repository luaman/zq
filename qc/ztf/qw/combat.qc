
void Napalm_touch ();

void T_MissileTouch ();

void info_player_start ();

void ClientObituary (entity targ, entity attacker);

void DoResults (entity Goal, entity AP, float addb);

float Activated (entity Goal, entity AP);

float CanDamage (entity targ, entity inflictor)
{
    vector offset;
    traceline (inflictor.origin,targ.origin,0,self);
    if (trace_ent.classname == "func_glass") {
        return  (0);
    }
    if ( (targ.movetype == 7) ) {
        traceline (inflictor.origin,(0.500 * (targ.absmin + targ.absmax)),1,self);
        if ( (trace_fraction == 1) ) {
            return ( 1 );
        }
        if ( (trace_ent == targ) ) {
            return ( 1 );
        }
        return ( 0 );
    }
    traceline (inflictor.origin, targ.origin, 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_z = 0;
    offset_y = targ.maxs_y * 0.500000;
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.mins_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_y = targ.mins_y * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_z = targ.maxs_z * 0.500000;
    offset_y = targ.maxs_y * 0.500000;
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.mins_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_y = targ.mins_y * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_z = targ.mins_z * 0.500000;
    offset_y = targ.maxs_y * 0.500000;
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.mins_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_y = targ.mins_y * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    offset_x = targ.maxs_x * 0.500000;
    traceline (inflictor.origin, (targ.origin + offset), 1, self);
    if ((trace_fraction == 1)) {
        return (1);
    }
    return (0);
    return ( 0 );
}

void Killed (entity targ, entity attacker)
{
    entity oself;
    oself = self;
    self = targ;
    if ( (self.health < -99) ) {
        self.health = -99;
    }
    if ( ((self.movetype == 7) || (self.movetype == 0)) ) {
        self.th_die ();
        self = oself;
        return ;
    }
    self.enemy = attacker;
    if ( (self.flags & 32) ) {
        killed_monsters = (killed_monsters + 1);
        WriteByte (2,27);
    }
    ClientObituary (self,attacker);
    self.takedamage = 0;
    self.touch = SUB_Null;
    self.th_die ();
    self = oself;
}

void TF_T_Damage (entity targ, entity inflictor, entity attacker, float damage, float T_flags, float T_AttackType)
{
    vector dir;
    entity oldself;
    entity te;
    float save;
    float take;
    float no_damage;
    float moment;
    if ( (targ.takedamage == 0) ) {
        return ;
    }
    if ( (T_AttackType & 256) ) {
        targ.health = damage;
        return ;
    }
    if ( cease_fire ) {
        return ;
    }
    if (round_active) {
        round_pause = time;
    }
    no_damage = 0;
    if (targ.classname == "player") {
        if (!cb_prematch) {
            targ.dmg_recieved = targ.dmg_recieved + damage;
            if (targ.StatusBarSize)
                targ.StatusRefreshTime = (time + 0.100);
            if (attacker.classname == "player") {
                if (attacker == targ) {
                    attacker.dmg_self = attacker.dmg_self + damage;
                    if (attacker.StatusBarSize)
                        attacker.StatusRefreshTime = (time + 0.100);
                } else if (attacker.pteam.team == targ.pteam.team ) {
                    attacker.dmg_team = attacker.dmg_team + damage;
                    if (attacker.StatusBarSize)
                        attacker.StatusRefreshTime = (time + 0.100);
                } else {
                    attacker.dmg_inflicted = attacker.dmg_inflicted + damage;
                    if (attacker.StatusBarSize)
                        attacker.StatusRefreshTime = (time + 0.100);
                }
            }
        }
    }
    if ( (attacker.classname == "player") ) {
        damage = (damage * 0.900);
        if ( (attacker.super_damage_finished > time) ) {
            damage = (damage * 4);
        }
        if ( (targ.classname != "player") && (targ.killtarget != "building")) {
            if ( !Activated (targ,attacker) ) {
                if ( (targ.else_goal != 0) ) {
                    te = Findgoal (targ.else_goal);
                    if ( te ) {
                        AttemptToActivate (te,attacker,targ);
                    }
                }
                return ;
            }
        }
    }
    damage_attacker = attacker;
    if ( ((targ.armorclass != 0) && (T_AttackType != 0)) ) {
        if ( ((targ.armorclass & 1) && (T_AttackType & 1)) ) {
            damage = floor ((damage * 0.500));
        }
        if ( ((targ.armorclass & 2) && (T_AttackType & 2)) ) {
            damage = floor ((damage * 0.500));
        }
        if ( ((targ.armorclass & 4) && (T_AttackType & 4)) ) {
            damage = floor ((damage * 0.500));
        }
        if ( ((targ.armorclass & 8) && (T_AttackType & 8)) ) {
            damage = floor ((damage * 0.500));
        }
        if ( ((targ.armorclass & 16) && (T_AttackType & 16)) ) {
            damage = floor(damage * 0.500);
        }
    }
    if ( (T_flags & 1) ) {
        take = damage;
        save = 0;
    } else {
        save = ceil ((targ.armortype * damage));
        if (attacker.classname == "player") {
            if (targ.pteam.team > 0) {
                if (targ.pteam.team == attacker.pteam.team) {
                    if (targ != attacker) {
                        if (T_flags & 2) {
                            if ( (T_AttackType & 4) ) {
                                if ( (teamplay & 1024) ) {
                                    save = 0;
                                } else {
                                    if ( (teamplay & 512) ) {
                                        save = (save / 2);
                                    }
                                }
                            } else {
                                if ( (teamplay & 256) ) {
                                    save = 0;
                                } else {
                                    if ( (teamplay & 128) ) {
                                        save = (save / 2);
                                    }
                                }
                            }
                        }
                    } else {
                        if (teamplay & 64) {
                            no_damage = 1;
                            save = 0;
                        } else if (teamplay & 32) {
                            no_damage = 1;
                            save = (save / 2);
                        }
                    }
                }
            }
        }
        if ( (save >= targ.armorvalue) ) {
            save = targ.armorvalue;
            targ.armortype = 0;
            targ.armorclass = 0;
            targ.items = (targ.items - (targ.items & ((8192 | 16384) | 32768)));
        }
        targ.armorvalue = (targ.armorvalue - save);
        take = ceil ((damage - save));
    }
    if ((targ.flags & 8)) {
        targ.dmg_take = (targ.dmg_take + take);
        targ.dmg_save = (targ.dmg_save + save);
        targ.dmg_inflictor = inflictor;
    }
    if ( (((inflictor != world) && (targ.movetype == 3)) && !(targ.tfstate & 65536)) ) {
        if ( (deathmsg != 9) ) {
            //targ.immune_to_check = (time + (damage / 20));
            dir = (targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.500));
            dir = normalize (dir);
            if ( (targ.playerclass == 6) ) {
                moment = (damage / 4);
                if ( (damage <= 50) ) {
                    moment = 0;
                }
            } else if (inflictor.volume) {
                moment = damage * inflictor.volume;
            } else {
                moment = damage;
            }
            if ( (((moment < 60) && ((attacker.classname == "player") && (targ.classname == "player"))) && (attacker.netname != targ.netname)) ) {
                targ.velocity = (targ.velocity + ((dir * moment) * 11));
            } else {
                targ.velocity = (targ.velocity + ((dir * moment) * 8));
            }
            if ( (((rj > 1) && ((attacker.classname == "player") && (targ.classname == "player"))) && (attacker.netname == targ.netname)) ) {
                targ.velocity = (targ.velocity + ((dir * moment) * rj));
            }
        }
    }
    /*
       if ( (inflictor != world) && (targ.classname == "grenade") ) {
       dir = (targ.origin - ((inflictor.absmin + inflictor.absmax) * 0.500));
       dir = normalize (dir);
       if ( (((damage < 60) & ((attacker.classname == "player") & (attacker.netname != targ.netname))))) {
       targ.velocity = (targ.velocity + ((dir * damage) * 11));
       } else {
       targ.velocity = (targ.velocity + ((dir * damage) * 8));
       }
       }
     */
    if ( (targ.flags & 64) ) {
        return ;
    }
    if ( (targ.invincible_finished >= time) ) {
        if ( (self.invincible_sound < time) ) {
            sound (targ,3,"items/protect3.wav",1,1);
            self.invincible_sound = (time + 2);
        }
        return ;
    }
    if ( ((attacker.classname == "player") && ((targ.classname == "player") || (targ.killtarget == "building")) )) {
        if ( ((((targ.pteam.team > 0) && (targ.pteam.team == attacker.pteam.team )) && (targ != attacker)) && (T_flags & 2)) ) {
            if ( (T_AttackType & 4) ) {
                if ( (teamplay & 16) ) {
                    no_damage = 1;
                } else {
                    if ( (teamplay & 8) ) {
                        take = (take / 2);
                    }
                }
            } else {
                if ( (teamplay & 4) ) {
                    no_damage = 1;
                } else {
                    if ( (teamplay & 2) ) {
                        take = (take / 2);
                    }
                }
            }
        }
    }
    if ( (T_flags & 4) ) {
        if ( (targ == attacker) ) {
            return ;
        }
    }
    if ( (take < 1) ) {
        take = 1;
    }
    take = rint (take);
    if ( (no_damage == 0) ) {
        if ((modetype & 2) && (targ.classname == "player")) {
            targ.health = (1000 + take);
        } else {
            targ.health = (targ.health - take);
        }
    }
    if ( (no_damage == 1) ) {
        return ;
    }
    if ( (targ.armorvalue < 1) ) {
        targ.armorclass = 0;
        targ.armorvalue = 0;
    }
    if ( (targ.health <= 0) ) {
        if ( (((inflictor.classname == "detpack") && (inflictor.weaponmode == 1)) && (inflictor.enemy == targ)) ) {
            deathmsg = 16;
        }
        Killed (targ,attacker);
        return ;
    }
    oldself = self;
    self = targ;
    if ( self.th_pain ) {
        self.th_pain (attacker,take);
        if ( (skill >= 3) ) {
            self.pain_finished = (time + 5);
        }
    }
    self = oldself;
}

void T_RadiusDamage (entity inflictor, entity attacker, float damage, entity ignore)
{
    float points;
    entity head;
    vector org;
    head = findradius (inflictor.origin,(damage + 40));
    while ( head ) {
        if ( (head != ignore) ) {
            if ( head.takedamage ) {
                org = (head.origin + ((head.mins + head.maxs) * 0.500));
                points = (0.500 * vlen ((inflictor.origin - org)));
                if ( (points < 0) ) {
                    points = 0;
                }
                points = (damage - points);
                if ( (head == attacker) ) {
                    points = (points * 0.750);
                }
                if ( (points > 0) ) {
                    if ( CanDamage (head,inflictor) ) {
                        if (inflictor.weapon == 33) {
                            TF_T_Damage (head,inflictor,attacker,points,2,4);
                            other = head;
                            Napalm_touch ();
                            if ( (other.classname == "player") ) {
                                stuffcmd (other,"bf\nbf\n");
                            }
                        } else {
                            TF_T_Damage (head,inflictor,attacker,points,2,4);
                        }
                    }
                }
            }
        }
        head = head.chain;
    }
}

void T_BeamDamage (entity attacker, float damage)
{
    float points;
    entity head;
    head = findradius (attacker.origin,(damage + 40));
    while ( head ) {
        if ( head.takedamage ) {
            points = (0.500 * vlen ((attacker.origin - head.origin)));
            points = (damage - points);
            if ( (head == attacker) ) {
                points = (points * 0.500);
            }
            if ( (points > 0) ) {
                if ( CanDamage (head,attacker) ) {
                    TF_T_Damage (head,attacker,attacker,points, 0, 0);
                }
            }
        }
        head = head.chain;
    }
}
