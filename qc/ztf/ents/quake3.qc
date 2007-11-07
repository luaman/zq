#ifndef Q3_ENTS
#define Q3_ENTS

void ammo_bullets () { item_spikes();
                       };

void ammo_slugs () { item_cells();
                     };

void ammo_grenades () { item_rockets();
                        };

void() weapon_shotgun    = {weapon_supershotgun ();
                           };

void() weapon_railgun       = {
    if ( (CheckExistence () == 0) ) {
        dremove (self);
        return ;
    }
    precache_model ("progs/g_light.mdl");
    setmodel (self,"progs/g_light.mdl");
    self.weapon = 3;
    self.netname = "Railgun";
    self.touch = weapon_touch;
    setsize (self,'-16 -16 0','16 16 56');
    StartItem ();
};

void item_armor_body () {self.classname="item_armorInv";
                           item_armorInv();
                          };

void item_armor_combat () {self.classname="item_armor2";
                             item_armor2();
                            };

void item_quad () {self.classname="item_artifact_super_damage";
                     item_artifact_super_damage();
                    };

void item_health_small () {
    self.spawnflags = self.spawnflags & 1;
    item_health ();
};

void item_health_large () { item_health ();
                            };

void item_health_mega () {
    self.classname = "item_health";
    self.spawnflags = 2;
    item_health ();
};

void armor_shard_touch () {
    float value;
    if ( (other.health <= 0) ) {
        return ;
    }
    if ( (other.classname != "player") ) {
        return ;
    }
    if ( other.is_feigning ) {
        return ;
    }
    if ( ((other.tfstate & 65536) || (other.tfstate & 2048)) ) {
        return ;
    }
    if ( (cb_prematch == 1) ) {
        return ;
    }
    if (round_over) return;
    if (!other.armorvalue) return;
    value = other.armorvalue + 5;
    if ( (value > other.maxarmor) ) {
        value = other.maxarmor;
    }
    other.armorvalue = value;
    self.solid = 0;
    self.model = string_null;
    if (modetype & 8) TeamFortress_SetSpeed(other);
    if ( (deathmatch != 2) ) {
        self.nextthink = (time + 20);
    }
    if ( coop ) {
        self.nextthink = (time + 40);
    }
    self.think = SUB_regen;
    sound (other,3,"items/armor1.wav",1,1);
    stuffcmd (other,"bf\n");
    activator = other;
};

void item_armor_shard () {
    self.touch = armor_shard_touch;
    precache_model ("models/powerups/armor/shard.md3");
    setmodel (self,"models/powerups/armor/shard.md3");
    self.mdl = "models/powerups/armor/shard.md3";
    self.solid = 1;
    setsize (self,'-16 -16 -24','16 16 32');
    StartItem ();
}

void item_invis () {self.origin_z = self.origin_z + 16;
                      item_artifact_invisibility ();
                     };

void team_CTF_bluespawn () {self.origin_z = self.origin_z + 8;
                              info_player_team1();
                             };

void team_CTF_redspawn () {self.origin_z = self.origin_z + 8;
                             info_player_team2();
                            };

void team_CTF_blueflag () {item_flag_team1();
                            };

void team_CTF_redflag () {item_flag_team2();
                           };
//team_CTF_blueplayer

void misc_teleporter_dest () {info_teleport_destination();
                               };

void target_position () {};

void target_location () { dremove(self);
                          };

void target_speaker () {
    if (self.spawnflags & 1) {
        if (self.noise) {
            dremove(self);
            //precache_sound (self.noise);
            //ambientsound (self.origin,self.noise,0.700,3);
        }
    } else {
        trigger_push();
    }
};

void info_player_intermission () {info_intermission();
                                   };

void func_static () {
    InitTrigger ();
};

void misc_model () {
    if (self.model == "models/mapobjects/storch/storch2.md3") {
        light_torch_small_walltorch ();
    } else if (self.model == "models/mapobjects/gratelamp/gratelamp.md3") {
        light_flame_large_yellow ();
    } else {
        precache_model (self.model);
        InitTrigger ();
    }
};
//q3f + fe
.string allowteams;

void ConvertQ3Fent (string fullentdata) {
    float args;
    string key;
    string value;

    tokanize(fullentdata);
    args = argc() - 2;
    while (args>0) {
        key = (argv(args - 1));
        value = (argv(args));
        if (key == "carried_message") {
            self.message = value;
        } else if (key == "carried_all_message") {
            self.team_broadcast = value;
        } else if (key == "inactive_all_message") {
            self.noise4 = value;
        }
        // else if (key == "active_flaginfo")
        // {
        // }
        args = args - 2;
    }
};
float CheckQ3FcapPoint (string fullentdata) {
    float args;
    float active;
    string key;
    string value;

    tokanize(fullentdata);
    args = argc() - 2;
    while (args>0) {
        key = (argv(args - 1));
        value = (argv(args));
        if (key == "teamscore") {
            self.count = stof(value);
            self.frags = stof(value);
            active = 1;
        } else if (key == "holding") {
            if (value == "redflag") {
                self.team_no = 2;
                self.axhitme = 1;
            }
            if (value == "blueflag") {
                self.team_no = 1;
                self.axhitme = 2;
            }
            active = 1;
        } else if (key == "active_message") {
            self.message = value;
        }

        args = args - 2;
    }
    return (active);
};

void func_goalinfo () {
    string tmp;
    if (__fullspawndata != "") {
        dprint("MULTI MANAGER spawned!\n");
        tmp = __fullspawndata;
        ConvertQ3Fent(tmp);
    } else
        dprint("no server support for multi_manager\n");
    if (self.allowteams == "blue") {
        self.team_no = 1;
    } else if (self.allowteams == "red") {
        self.team_no = 2;
    }
    self.classname = "info_tfgoal";
    self.mdl = self.model;
    info_tfgoal();
};

void func_goalitem () {
    string tmp;
    if (__fullspawndata != "") {
        dprint("MULTI MANAGER spawned!\n");
        tmp = __fullspawndata;
        ConvertQ3Fent(tmp);
    } else
        dprint("no server support for multi_manager\n");
    if (self.allowteams == "blue") {
        self.team_no = 1;
    } else if (self.allowteams == "red") {
        self.team_no = 2;
    }
    self.classname = "item_tfgoal";
    self.mdl = self.model;
    item_tfgoal();
};

void fe_spawn () {
    if (self.allowteams == "blue") {
        self.team_no = 1;
        self.classname = "info_player_teamspawn";
    } else if (self.allowteams == "red") {
        self.team_no = 2;
        self.classname = "info_player_teamspawn";
    } else {
        self.classname = "info_player_spawn";
    }
};
#endif
