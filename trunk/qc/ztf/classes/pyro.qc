/*
    pyro.qc

    class functions/definitions

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

//void (vector org, entity shooter) NapalmGrenadeLaunch;
float RemoveFlameFromQueue (string id_flame);

entity FlameSpawn (string type, entity p_owner) {
    if ( (cb_prematch == 1) ) {
        return ( world );
    }
    if ( (type != "1") ) {
        return ( world );
    }
    num_world_flames = (num_world_flames + 1);
    while ( (num_world_flames > 16) ) {
        if ( !RemoveFlameFromQueue (type) ) {
            return ( world );
        }
    }
    newmis = spawn ();
    if ( (type == "1") ) {
        newmis.movetype = MOVETYPE_FLYMISSILE;
		newmis.solid = SOLID_BBOX;
        newmis.effects = 8;
        newmis.flame_id = "1";
        setmodel (newmis,"progs/flame2.mdl");
        setsize (newmis,'0 0 0','0 0 0');
	} else if ( (type == "2") ) {
		newmis.movetype = MOVETYPE_BOUNCE;
		newmis.solid = SOLID_BBOX;
		newmis.flame_id = "2";
		setmodel (newmis,"progs/flame2.mdl");
		newmis.frame = 1;
		setsize (newmis,'0 0 0','0 0 0');
	} else if ( (type == "3") ) {
		newmis.movetype = MOVETYPE_FLYMISSILE;
		newmis.solid = 2;
		newmis.flame_id = "3";
		setmodel (newmis,"progs/flame2.mdl");
		setsize (newmis,'0 0 0','0 0 0');
	} else if ( (type == "4") ) {
		newmis.movetype = 9;
		newmis.flame_id = "4";
		newmis.frame = 1;
		newmis.solid = 2;
		setmodel (newmis,"progs/flame2.mdl");
		setsize (newmis,'0 0 0','0 0 0');
	}
    newmis.owner = p_owner;
    return ( newmis );
}

void FlameDestroy (entity this) {
    num_world_flames = (num_world_flames - 1);
    dremove (this);
}

float RemoveFlameFromQueue (string id_flame) {
    entity tmp;
    if ( (num_world_flames < 20) ) {
        dprint ("ERROR in RemoveFlameFromQueue\n");
        return 0 ;
    }
    num_world_flames = (num_world_flames - 1);
    tmp = find (world,flame_id,"4");
    if ( !tmp ) {
        if ( (id_flame == "4") ) {
            return ( 0 );
        }
        tmp = find (world,flame_id,"3");
        if ( !tmp ) {
            if ( (id_flame == "3") ) {
                return ( 0 );
            }
            tmp = find (world,flame_id,"2");
            if ( !tmp ) {
                if ( (id_flame == "2") ) {
                    return ( 0 );
                }
                tmp = find (world,flame_id,"1");
                if ( !tmp ) {
                    dprint ("\n\nRemoveFlameFromQueue():BOOM!\n");
                    return ( 0 );
                }
            }
        }
    }
    dremove (tmp);
    return ( 1 );
}

void Remove () {
    FlameDestroy (self);
}

void NapalmGrenadeTouch () {
    sound (self,CHAN_WEAPON,"weapons/bounce.wav",1,1);
    if ( (self.velocity == '0 0 0') ) {
        self.avelocity = '0 0 0';
    }
}

void NapalmGrenadeNetThink () {
    entity head;
    entity te;
    if ( (self.heat == 0) ) {
        self.owner.no_active_napalm_grens = (self.owner.no_active_napalm_grens + 1);
        if ( (self.owner.no_active_napalm_grens > 1) ) {
            te = find (world,classname,"grentimer");
            while ( te ) {
                if ( ((te.owner == self.owner) && (te.no_active_napalm_grens == 1)) ) {
                    te.weapon = 15;
                    te.think = RemoveGrenade;
                    te.nextthink = (time + 0.100);
                }
                te = find (te,classname,"grentimer");
            }
        }
        self.no_active_napalm_grens = self.owner.no_active_napalm_grens;
    }
    self.nextthink = (time + 1);
    self.origin = self.enemy.origin;
    makevectors (self.v_angle);
    traceline (self.origin,self.origin,1,self);
    if ( (trace_inwater == 1) ) {
        sound (self,2,"misc/vapeur2.wav",1,1);
        RemoveGrenade ();
        return ;
    }
    head = findradius (self.origin,180);
    while ( head ) {
        head.chain2 = head.chain;
        if ( head.takedamage ) {
            deathmsg = 15;
            TF_T_Damage (head,self.enemy,self.owner,20,2,16);
            other = head;
            Napalm_touch ();
            if ( (other.classname == "player") ) {
                stuffcmd (other,"bf\nbf\n");
            }
        }
        head = head.chain2;
    }
    WriteByte (4,23);
    WriteByte (4,3);
    WriteCoord (4,self.origin_x);
    WriteCoord (4,self.origin_y);
    WriteCoord (4,self.origin_z);
    multicast (self.origin,1);
    self.heat = (self.heat + 1);
    if ( (self.heat > 7) ) {
        RemoveGrenade ();
    }
}

void NapalmGrenadeExplode () {
    entity te;
    entity head;
    if (anti_spam) {
        te = findradius (self.origin, anti_spam);
        while ( te ) {
            te.chain2 = te.chain;
            if ( (te.classname == "info_player_teamspawn") ) {
                spawn_tfog(self.origin);
                dremove (self);
                return;
            }
            te = te.chain2;
        }
    }
    sound (self,0,"weapons/flmgrexp.wav",1,1);
    traceline (self.origin,self.origin,1,self);
    if ( (trace_inwater == 1) ) {
        dremove (self);
        return ;
    }
    self.effects = (self.effects | 8);
    head = spawn ();
    head.think = NapalmGrenadeNetThink;
    head.classname = "grentimer";
    head.nextthink = (time + 0.100);
    head.heat = 0;
    head.origin = self.origin;
    head.owner = self.owner;
    head.pteam = self.owner.pteam;
    head.enemy = self;
}

#if 0
void NapalmGrenadeExplode2 () {
	float points;
	vector org;
	entity te;
	entity head;
	te = findradius (self.origin,500);
	while ( te ) {
		te.chain2 = te.chain;
		if ( (te.classname == "building_antispam") ) {
			spawn_tfog(self.origin);
			dremove (self);
			return;
		}
		te = te.chain2;
	}
	sound (self,0,"weapons/flmgrexp.wav",1,1);
	traceline (self.origin,self.origin,1,self);
	if ( (trace_inwater == 1) ) {
		sound (self,2,"misc/vapeur2.wav",1,1);
		dremove (self);
		return ;
	}
	self.effects = (self.effects | 8);
	// self.origin = self.enemy.origin;
	makevectors (self.v_angle);
	traceline (self.origin,self.origin,1,self);

	head = findradius (self.origin, 800);
	while ( head ) {
		head.chain2 = head.chain;
		if ( head.takedamage ) {
			points = (0.45 * vlen ((self.origin - head.origin)));
			points = (400 - points);
			if ( (head == self.owner) ) {
				points = (points * 0.800);
			}
			if ( (points > 0) ) {
				if ( CanDamage (head,self) ) {
					deathmsg = 15;
					TF_T_Damage (head,self.enemy,self.owner, points,2,16);
					other = head;
					Napalm_touch ();
					if ( (other.classname == "player") ) {
						stuffcmd (other,"bf\nbf\n");
					}
				}
			}
		}
		head = head.chain2;
	}
	WriteByte (4,23);
	WriteByte (4,3);
	WriteCoord (4,self.origin_x);
	WriteCoord (4,self.origin_y);
	WriteCoord (4,self.origin_z);
	multicast (self.origin,1);
	dremove (self);
}
#endif

void OnPlayerFlame_touch ();

void FlameFollow () {
    vector dir;
    vector vtemp;
    vector boundsize;
    float damage;
    vtemp = self.enemy.absmin;
    boundsize = self.enemy.size;
    self.solid = 0;
    self.movetype = 0;
    if ( (self.enemy.numflames == 0) ) {
        FlameDestroy (self);
        return ;
    }
    if ( (self.enemy.health < 1) ) {
        deathmsg = 15;
        T_RadiusDamage (self,self,10,self);
        self.enemy.numflames = 0;
        FlameDestroy (self);
        return ;
    }
    if ( ((self.enemy.armorclass & 16) && (self.enemy.armorvalue > 0)) ) {
        self.health = 0;
    }
    if ( (self.enemy.tfstate & 131072) ) {
        self.health = 45;
        self.enemy.tfstate = (self.enemy.tfstate - (self.enemy.tfstate & 131072));
    }
    if ( (self.health < 1) ) {
        if ( ((self.effects != 8) || (self.enemy.numflames <= 1)) ) {
            self.enemy.numflames = (self.enemy.numflames - 1);
            self.enemy.numflames = 0;
            FlameDestroy (self);
            return ;
        }
    }
    self.health = (self.health - 1);
    if ( (vlen (self.enemy.velocity) < 50) ) {
        dir_x = (((random () * boundsize_x) / 2) + (boundsize_x / 4));
        dir_y = (((random () * boundsize_y) / 2) + (boundsize_y / 4));
        dir_z = (((random () * boundsize_z) / 3) + (boundsize_z / 2));
        vtemp = (vtemp + dir);
        setorigin (self,vtemp);
        if ( (self.model != "progs/flame2.mdl") ) {
            self.model = "progs/flame2.mdl";
            setmodel (self,self.model);
        }
    } else {
        if ( (self.model == "progs/flame2.mdl") ) {
            self.model = string_null;
            setmodel (self,self.model);
        }
    }
    if ( (self.enemy.waterlevel > 1) ) {
        sound (self,2,"misc/vapeur2.wav",1,1);
        self.enemy.numflames = (self.enemy.numflames - 1);
        FlameDestroy (self);
        return ;
    }
    self.nextthink = (time + 0.100);
    if ( ((self.effects == 8) && (self.heat >= 3)) ) {
        damage = ((self.enemy.numflames * 0.300) * 3);
        if ( (damage < 1) ) {
            damage = 1;
        }
        self.heat = 1;
        deathmsg = 15;
        TF_T_Damage (self.enemy,self,self.owner,damage,2,16);
    } else {
        if ( (self.effects == 8) ) {
            self.heat = (self.heat + 1);
        }
    }
}

void OnPlayerFlame_touch () {
    entity flame;
    vector vtemp;
    if ( (((other != world) && (other.health > 0)) && (other != self.enemy)) ) {
        if ( (cb_prematch == 1) ) {
            return ;
        }
        if ( (other.numflames >= 4) ) {
            other.tfstate = (other.tfstate | 131072);
            return ;
        }
        if ( (other.classname == "player") ) {
            if ( (((teamplay & 16) && (other.pteam.team > 0)) && (other.pteam == self.owner.pteam)) ) {
                return ;
            }
            CenterPrint (other,"You are on fire!\n");
            stuffcmd (other,"bf\n");
        }
        if ( (other.numflames < 1) ) {
            flame = FlameSpawn ("1",other);
            sound (flame,2,"ambience/fire1.wav",1,1);
        } else {
            flame = FlameSpawn ("3",other);
            if ( (flame == world) ) {
                return ;
            }
        }
        flame.classname = "fire";
        flame.health = 45;
        other.numflames = (other.numflames + 1);
        flame.velocity = other.velocity;
        flame.enemy = other;
        flame.touch = OnPlayerFlame_touch;
        flame.owner = self.owner;
        vtemp = self.origin;
        setorigin (flame,vtemp);
        flame.nextthink = (time + 0.100);
        flame.think = FlameFollow;
    }
}

void QW_Flame_ResetTouch ();

void WorldFlame_touch () {
    entity flame;
    vector vtemp;
    deathmsg = 15;
    TF_T_Damage (other,self,self.enemy,10,2,16);
    self.touch = SUB_Null;
    if ( (self.heat > (time + 1)) ) {
        self.think = QW_Flame_ResetTouch;
        self.nextthink = (time + 1);
    }
    if ( (((other != world) && (other.solid != 1)) && (other.health > 0)) ) {
        if ( (cb_prematch == 1) ) {
            return ;
        }
        if ( (other.numflames >= 4) ) {
            other.tfstate = (other.tfstate | 131072);
            return ;
        }
        if ( (other.classname == "player") ) {
            if ( (((teamplay & 16) && (other.pteam.team > 0)) && (other.pteam == self.owner.pteam)) ) {
                return ;
            }
            CenterPrint (other,"You are on fire!\n");
            stuffcmd (other,"bf\n");
        }
        if ( (other.numflames < 1) ) {
            flame = FlameSpawn ("1",other);
            sound (flame,2,"ambience/fire1.wav",1,1);
        } else {
            flame = FlameSpawn ("3",other);
            if ( (flame == world) ) {
                return ;
            }
        }
        flame.classname = "fire";
        flame.health = 0;
        other.numflames = (other.numflames + 1);
        flame.velocity = other.velocity;
        flame.enemy = other;
        flame.touch = OnPlayerFlame_touch;
        flame.owner = self.owner;
        vtemp = (self.origin + '0 0 10');
        setorigin (flame,vtemp);
        flame.nextthink = (time + 0.150);
        flame.think = FlameFollow;
    }
}

void QW_Flame_ResetTouch () {
    self.touch = WorldFlame_touch;
    self.think = Remove;
    self.nextthink = self.heat;
}

void Flamer_stream_touch () {
    entity flame;
    vector vtemp;
    if ( (other.classname == "fire") ) {
        return ;
    }
    if ( (other != world) ) {
        if ( ((other.takedamage == 2) && (other.health > 0)) ) {
            deathmsg = 15;
            TF_T_Damage (other,self,self.owner,10,2,16);
            if (cb_prematch ) {
                return ;
            }
            if ( (other.numflames >= 4) ) {
                other.tfstate = (other.tfstate | 131072);
                return ;
            }
            if ( ((other.armorclass & 16) && (other.armorvalue > 0)) ) {
                return ;
            }
            if ( (other.classname == "player") ) {
                if ( (((teamplay & 16) && (other.pteam.team > 0)) && (other.pteam == self.owner.pteam)) ) {
                    return ;
                }
                CenterPrint (other,"You are on fire!\n");
                stuffcmd (other,"bf\n");
            }
            if ( (other.numflames < 1) ) {
                flame = FlameSpawn ("1",other);
                sound (flame,2,"ambience/fire1.wav",1,1);
            } else {
                flame = FlameSpawn ("3",other);
                if ( (flame == world) ) {
                    return ;
                }
            }
            flame.classname = "fire";
            flame.health = 45;
            other.numflames = (other.numflames + 1);
            flame.velocity = other.velocity;
            flame.enemy = other;
            flame.touch = OnPlayerFlame_touch;
            flame.owner = self.owner;
            vtemp = self.origin;
            setorigin (flame,vtemp);
            flame.nextthink = (time + 0.100);
            flame.think = FlameFollow;
        }
    } else {
        if ( ((random () < 0.300) || (pointcontents ((self.origin + '0 0 1')) != -1)) ) {
            self.velocity = '0 0 0';
            return ;

        }
        flame = FlameSpawn ("4",other);
        if ( (flame != world) ) {
            flame.touch = WorldFlame_touch;
            flame.classname = "fire";
            vtemp = (self.origin + '0 0 10');
            setorigin (flame,vtemp);
            flame.nextthink = (time + 8);
            flame.heat = flame.nextthink;
            flame.think = Remove;
            flame.enemy = self.owner;
        }
        if ((classtype & 16)) dremove (self);
    }
}

void Napalm_touch () {
    entity flame;
    vector vtemp;
    if ( (other.classname == "fire") ) {
        return ;
    }
    if ( (other != world) ) {
        if ( ((other.takedamage == 2) && (other.health > 0)) ) {
            deathmsg = 15;
            TF_T_Damage (other,self,self.owner,6,2,16);
            if (cb_prematch == 1 ) {
                return ;
            }
            if ( (other.numflames >= 4) ) {
                other.tfstate = (other.tfstate | 131072);
                return ;
            }
            if ( ((other.armorclass & 16) && (other.armorvalue > 0)) ) {
                return ;
            }
            if ( (other.classname == "player") ) {
                if ( (((teamplay & 16) && (other.pteam.team > 0)) && (other.pteam == self.owner.pteam)) ) {
                    return ;
                }
                CenterPrint (other,"You are on fire!\n");
                stuffcmd (other,"bf\n");
            }
            if ( (other.numflames < 1) ) {
                flame = FlameSpawn ("1",other);
                sound (flame,2,"ambience/fire1.wav",1,1);
            } else {
                flame = FlameSpawn ("3",other);
                if ( (flame == world) ) {
                    return ;
                }
            }
            flame.classname = "fire";
            flame.health = 45;
            other.numflames = (other.numflames + 1);
            flame.velocity = other.velocity;
            flame.enemy = other;
            flame.touch = OnPlayerFlame_touch;
            flame.owner = self.owner;
            vtemp = self.origin;
            setorigin (flame,vtemp);
            flame.nextthink = (time + 0.100);
            flame.think = FlameFollow;
        }
    } else {
        if ( (pointcontents ((self.origin + '0 0 1')) != -1) ) {
            FlameDestroy (self);
            return ;
        }
        flame = FlameSpawn ("4",other);
        if ( (flame != world) ) {
            flame.touch = WorldFlame_touch;
            flame.classname = "fire";
            vtemp = (self.origin + '0 0 10');
            setorigin (flame,vtemp);
            flame.nextthink = (time + 20);
            flame.heat = flame.nextthink;
            flame.think = Remove;
            flame.enemy = self.owner;
        }
        FlameDestroy (self);
    }
}

void NewBubbles (float num_bubbles, vector bub_origin) {
    entity bubble_spawner;
    bubble_spawner = spawn ();
    setorigin (bubble_spawner,bub_origin);
    bubble_spawner.movetype = 0;
    bubble_spawner.solid = 0;
    bubble_spawner.nextthink = (time + 0.100);
    if ( (self.classname == "player") ) {
        bubble_spawner.owner = self;
    } else {
        bubble_spawner.owner = self.enemy;
    }
    bubble_spawner.think = DeathBubblesSpawn;
    bubble_spawner.bubble_count = num_bubbles;
    return ;
}

void W_FireFlame () {
    entity flame;
    float rn;
    if ( (self.waterlevel > 2) ) {
        makevectors (self.v_angle);
        NewBubbles (2,(self.origin + (v_forward * 64)));
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
    sound (self,0,"weapons/flmfire2.wav",1,1);
    flame = spawn ();
    flame.owner = self;
    flame.movetype = 9;
    flame.solid = 2;
    flame.classname = "flamerflame";
    makevectors (self.v_angle);
    flame.velocity = aim (self,10000);
    flame.velocity = (flame.velocity * 700);
    flame.touch = Flamer_stream_touch;
    flame.think = s_explode1;
    flame.nextthink = (time + 0.150);
    setmodel (flame,"progs/s_explod.spr");
    setsize (flame,'0 0 0','0 0 0');
    setorigin (flame,((self.origin + (v_forward * 16)) + '0 0 16'));
}

void IncendiaryRadius () {
    float damg;
    damg = 52;
    self.volume = 1.23;
    //damg = 64;

    deathmsg = 15;
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

void T_IncendiaryTouch () {
    float damg;
    entity head;
    if ( (other == self.owner) ) {
        return ;
    }

    if  ( (pointcontents (self.origin) == -6) ) {
        remove (self);
        return ;
    }
    self.effects = (self.effects | 4);
    damg = (35 + (random () * 10));
    deathmsg = 15;
    if ( other.health ) {
        TF_T_Damage (other,self,self.owner,damg,2,0);
    }

    if (classtype & 16) {
        head = findradius (self.origin, 180);
        while (head) {
            if (head.takedamage) {
                traceline (self.origin, head.origin, 1, self);
                if ((trace_fraction == 1) || ((trace_fraction != 1) && (vlen (self.origin - head.origin) <= 64))) {
                    deathmsg = 15;
                    TF_T_Damage (head, self, self.owner, 10, 2, 16);
                    other = head;
                    Napalm_touch ();
                    if (other.classname == "player") {
                        stuffcmd (other, "bf\nbf\n");
                    }
                }
            }
            head = head.chain;
        }
        self.origin = self.origin - 8 * normalize (self.velocity);
        WriteByte (4,23);
        WriteByte (4,3);
        WriteCoord (4,self.origin_x);
        WriteCoord (4,self.origin_y);
        WriteCoord (4,self.origin_z);
        multicast (self.origin,1);
        dremove (self);
    } else {
        IncendiaryRadius();
    }
}

void W_FireIncendiaryCannon () {
    if ( (self.ammo_rockets < ic_ammo) ) {
        return ;
    }
    self.ammo_rockets = (self.ammo_rockets - ic_ammo);
    self.currentammo = self.ammo_rockets;
    newmis = spawn ();
    newmis.owner = self;
    sound (self,CHAN_WEAPON,"weapons/sgun1.wav",1,1);
    KickPlayer (-3,self);
    newmis.movetype = 9;
    newmis.solid = 2;
    newmis.classname = "rocket";
    makevectors (self.v_angle);
    newmis.velocity = aim (self,1000);
    if ((classtype & 16)) {
        newmis.velocity = (newmis.velocity * 600);
    } else {
        newmis.effects = (newmis.effects | 128);
        newmis.velocity = (newmis.velocity * 800);
    }
    newmis.angles = vectoangles (newmis.velocity);
    newmis.touch = T_IncendiaryTouch;
    newmis.nextthink = (time + 5);
    newmis.think = IncendiaryRadius;
    newmis.weapon = 33;
    setmodel (newmis,"progs/missile.mdl");
    setsize (newmis,'0 0 0','0 0 0');
    setorigin (newmis,((self.origin + (v_forward * 8)) + '0 0 16'));
}

void TeamFortress_IncendiaryCannon () {
    if ( !(self.carried & 16384) ) {
        return ;
    }
    if ( (self.ammo_rockets < ic_ammo) ) {
        sprint (self,PRINT_HIGH,"not enough ammo.\n");
        return ;
    }

    self.current = 16384;
    W_SetCurrentAmmo ();
}

void TeamFortress_FlameThrower () {
    if ( !(self.carried & 4096) ) {
        return ;
    }
    if ( (self.ammo_cells < 1) ) {
        sprint (self,PRINT_HIGH,"not enough ammo.\n");
        return ;
    }
    self.current = 4096;
    W_SetCurrentAmmo ();
}
