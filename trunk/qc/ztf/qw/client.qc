
void player_pain ();

void player_stand1 ();

void spawn_tfog (vector org);

void spawn_tdeath (vector org, entity death_owner);

float modelindex_eyes /* = 0 */;

float modelindex_player /* = 0 */;

float modelindex_null /* = 0 */;

void TeamFortress_PrintClassName (entity Viewer, float pc, float rpc);

void TeamFortress_RemoveTimers ();

void TeamFortress_SetupRespawn ();

float IsLegalClass (float pc);

void CeaseFire_think ();

void ShowFrags (entity print);

void StartRound ();

void StartTimer ();

void RemoveVotes ();

void TeamFortress_MOTD ();

void ConcussionGrenadeTimer ();

void Drop_detpack ();

void BioInfection_Decay ();

void TF_AddFrags (entity pl, float fr, float type);

void Engineer_RemoveBuildings (entity eng);

void TeamFortress_Alias (string halias, float himpulse1, float himpulse2);

void CheckAutoKick (entity p);

void TeamFortress_ExecClassScript (entity p);

void TeamFortress_ExecMapScript (entity p);

void PreMatch_Think ();

void SetTeam (entity p);

float ClassIsRestricted (float tno, float pc);

float CheckClassAvailable (float tno);

void Service_Grapple ();

void ParseTFDetect (entity AD);
entity Finditem (float ino);

void tfgoalitem_GiveToPlayer (entity Item, entity AP, entity Goal);

void CTF_FlagCheck ();

void CheckConnectRate () {
    float player_rate;
    float maxrate;
    float minrate;
    string tmp;
    // This is used to check a players rate.  If above allowed setting then it kicks em off.
    player_rate = stof(infokey(self, "rate"));
    maxrate = stof(infokey(world, "maxrate"));
    minrate = stof(infokey(world, "minrate"));
    if (maxrate  || minrate) {
        if ((player_rate > maxrate) && (maxrate!=0 )) {
            sprint (self, PRINT_HIGH, "\nYour Ú·ÙÂ setting is too high for this server.\n");
            tmp=ftos(maxrate);
            sprint (self, PRINT_HIGH, "Rate set to ");
            sprint (self, PRINT_CHAT, tmp, "\n");
            stuffcmd(self, "rate ");
            stuffcmd(self, tmp);
            stuffcmd(self, "\n");
        }
        if ((player_rate < minrate) && (minrate < maxrate)) {
            sprint (self, PRINT_HIGH, "\nYour Ú·ÙÂ setting is too low for this server.\n");
            tmp=ftos(minrate);
            sprint (self, PRINT_HIGH, "Rate set to ");
            sprint(self, PRINT_CHAT, tmp, "\n");
            stuffcmd(self, "rate ");
            stuffcmd(self, tmp);
            stuffcmd(self, "\n");
        }
    }
}

void SetChangeParms () {
    if ( (self.health <= 0) ) {
        SetNewParms ();
        return ;
    }
    self.items = (self.items - (self.items & (((((131072 | 262144) | 524288) | 1048576) | 2097152) | 4194304)));
    if ( (self.health > 100) ) {
        self.health = 100;
    }
    if ( (self.health < 50) ) {
        self.health = 50;
    }
    parm1 = self.items;
    parm2 = self.health;
    parm3 = self.armorvalue;
    if ( (self.ammo_shells < 25) ) {
        parm4 = 25;
    } else {
        parm4 = self.ammo_shells;
    }
    parm5 = self.ammo_nails;
    parm6 = self.ammo_rockets;
    parm7 = self.ammo_cells;
    parm8 = self.current;
    parm9 = (self.armortype * 100);
    parm10 = 0;
    parm11 = 0;
    parm12 = 0;
    parm13 = self.StatusBarRes;
    parm14 = self.StatusBarSize;
    parm15 = self.is_admin;
}

void SetNewParms () {
    parm1 = 0;
    parm2 = 100;
    parm3 = 0;
    parm4 = 25;
    parm5 = 0;
    parm6 = 0;
    parm7 = 0;
    parm8 = 1;
    parm9 = 0;
    parm10 = 0;
    parm11 = 0;
    parm12 = 0;
    parm13 = 0;
    parm14 = 0;
    parm15 = 0;
}

void Remove_Entity (string entname) {
      entity  e;
    e = find(world, classname, entname);
    while (e) {
        e.think = SUB_Remove;
        e.nextthink = time + 0.1;
        e = find(e, classname, entname);
    }
}

void Remove_All_Items () {
    Remove_Entity("item_artifact_super_damage");
    Remove_Entity("item_artifact_invulnerability");
    Remove_Entity("item_artifact_invisibility");
    Remove_Entity("item_artifact_envirosuit");
    Remove_Entity("item_shells");
    Remove_Entity("item_spikes");
    Remove_Entity("item_rockets");
    Remove_Entity("item_cells");
    Remove_Entity("item_weapon");
    Remove_Entity("item_armor1");
    Remove_Entity("item_armor2");
    Remove_Entity("item_armorInv");
    Remove_Entity("weapon_supershotgun");
    Remove_Entity("weapon_supernailgun");
    Remove_Entity("weapon_nailgun");
    Remove_Entity("weapon_rocketlauncher");
    Remove_Entity("weapon_grenadelauncher");
    Remove_Entity("weapon_lightning");
    Remove_Entity("item_health");
}

void DecodeLevelParms () {
    string st;
    entity ent;
    entity te;
    float fl;
    if ( serverflags ) {
        if ( (world.model == "maps/start.bsp") ) {
            SetNewParms ();
        }
    }
    self.items = parm1;
    self.health = parm2;
    self.armorvalue = parm3;
    self.ammo_shells = parm4;
    self.ammo_nails = parm5;
    self.ammo_rockets = parm6;
    self.ammo_cells = parm7;
    self.current = parm8;
    self.armortype = (parm9 * 0.010);
    if ( !(toggleflags & 256) ) {
        localcmd("serverinfo oztf 1.77a\n");
        Initialise_Teams();
        //toggleflags = (toggleflags | parm10);
        flagem_checked = 0;
        if ( (coop || !deathmatch) ) {
            toggleflags = (toggleflags | 1);
        }
        nextmap = mapname;
        ent = find (world,classname,"info_tfdetect");
        if ( (ent != world) ) {
            if ( (teamplay == 0) ) {
                cvar_set ("teamplay","1?OzTeamFortress");
            }
            te = find (world,classname,"info_player_teamspawn");
            while (te != world) {
                if ( (store_obs.cnt < te.team_no) ) {
                    store_obs.cnt = te.team_no;
                }
                te = find (te,classname,"info_player_teamspawn");
            }
            ParseTFDetect (ent);
            if ( ((store_obs.cnt <= 0) || (store_obs.cnt >= 5)) ) {
                store_obs.cnt = 4;
            }
        } else {
            ent = find (world,classname,"info_player_team1");
            if ( ((ent != world) || (ctfmap == 1)) ) {
                ctfmap = 1;
                if ( (teamplay == 0) ) {
                    cvar_set ("teamplay","11?OzTeamFortress");
                }
                ent = spawn ();
                ent.nextthink = (time + 30);
                ent.think = CTF_FlagCheck;
                store_obs.cnt = 2;
            } else {
                ent = find (world,classname,"func_bomb_target");
                if ( ent != world ) {
                    cvar_set ("teamplay","21?OzTeamFortress");
                    modetype = modetype | 4;
                    rounds = -1;
                    store_obs.cnt = 2;
                } else {
                    cvar_set ("teamplay","1?OzTeamFortress");
                    store_obs.cnt = 4;
                    store_obs.maxammo_shells = 15;
                    classtype = classtype | 64;
                    realdm = 1;
                }
            }
        }
        ent = find (world,classname,"info_soccer_goal");
        if ( ent != world ) {
            rounds = -1;
            store_obs.cnt = 2;
        }
        bprint (PRINT_HIGH,"Mapname: ");
        bprint (PRINT_HIGH,mapname);
        bprint (PRINT_HIGH,"\n");
        if ( store_obs.cnt == 2) {
            dremove(pteam3);
            dremove(pteam4);
        }
        autokick_kills = 0;
        autokick_time = 0;
        cease_fire = 0;
        toggleflags = (toggleflags | 128);
        toggleflags = (toggleflags - (toggleflags & 2));
        toggleflags = (toggleflags | 256);
        st = infokey (world,"temp1");
        fl = stof (st);
        if (fl) {
            toggleflags = (toggleflags | fl);
        }
        if ( (stof (infokey (world,"rj")) != 0) ) {
            rj = stof (infokey (world,"rj"));
        } else {
            rj = 1;
        }
        st = infokey (world,"arena");
        if ((st == "on")) {
            rounds = -1;
            //cvar_set ("deathmatch","4");
            cvar_set ("teamplay","1333?OzArena");
            realdm = 0;
            modetype = modetype | 8;
            Remove_All_Items ();
            // deathmatch = 4;
        }
        st = infokey (world, "tfstrike");
        if ((st == "on")) {
            modetype = modetype | 4;
            rounds = -1;
        }
        st = infokey (world, "duel");
        if ((st == "on")) {
            modetype = modetype | 32;
            rounds = -1;
        }
        st = infokey (world, "speedcap");
        if ((st == "on")) {
            modetype = modetype | 16;
            rounds = -1;
        }
        st = infokey (world, "rounds");
        if ((st == "on")) {
            rounds = -1;
        } else {
            if (stof(st) > 0 ) {
                rounds = stof(st) + 1;
            }
        }
        st = infokey (world,"practice");
        if ( (st == "on") ) {
            modetype = modetype  | 2;
        }
        st = infokey (world,"clan");
        if ( (st == "on") ) {
            modetype = modetype | 1;
        }
        st = infokey (world, "quadmode");
        if ((st == "on")) {
            cvar_set("timelimit", "10");
            modetype = 65; //clan + quad
            // modetype = modetype | 1;
        }
        if (modetype & 1) {
            localcmd("serverinfo status Standby\n");
            modetype = modetype | 1;
            if (modetype & 2) modetype = modetype - 2;
            cb_prematch = 1;
            st = infokey (world,"freeze");
            if ( (st == "on") ) {
                freeze = 1;
            } else {
                if (( mapname == "spaz4") || (mapname == "canalzon" )) {
                    localcmd("localinfo freeze on\n");
                    freeze = 1;
                }
            }
            pmtime = stof(infokey (world,"prematch"));
            if (pmtime) {
                StartTimer ();
            }
            if (!pmtime) {
                st = infokey (world,"cft");
                pmtime = stof (st);
                if (pmtime) {
                    cease_fire = 1;
                    bprint (PRINT_HIGH,"CEASE FIRE\n");
                    te = player_head;
                    while ( te ) {
                        centerprint (te,"CEASE FIRE\n");
                        te.tfstate = (te.tfstate | 65536);
                        TeamFortress_SetSpeed (te);
                        te = te.nextp;
                    }
                    te = spawn ();
                    te.classname = "ceasefire";
                    te.think = CeaseFire_think;
                    te.nextthink = (time + 5);
                    te.weapon = 1;
                    StartTimer ();
                }
            }
        } else {
            if (modetype & 1) modetype = modetype - 1;
            localcmd("serverinfo status Normal\n");
        }
        if (rounds) {
            if (modetype & 4) {
                st = infokey (world,"grenpacks");
                if ((st == "on")) localcmd("localinfo grenpacks off\n");
                allow_grenpack = 0;
            }
            st = infokey (world,"round_time");
            round_over = 1;
            te = spawn();
            te.owner = world;
            te.classname = "round";
            te.cnt = stof(st);
            if (!(modetype & 1)) {
                te.nextthink = (time + 1);
                te.think = StartRound;
            }
        }
        Calibrate_Level();
    }
    if ( parm11 ) {
        self.tfstate = parm11;
    }
    if ( (!self.playerclass ) ) {
        self.playerclass = parm12;
    }
    if ( parm13 ) {
        self.StatusBarRes = parm13;
    }
    if ( parm14 ) {
        self.StatusBarSize = parm14;
    }
    if ( parm15 ) {
        self.is_admin = parm15;
    }
}
entity FindIntermission () {
    entity spot;
    float cyc;
    spot = find (world,classname,"info_intermission");
    if ( spot ) {
        cyc = (random () * 1);
        return ( spot );
    }
    spot = find (world,classname,"info_player_start");
    if ( spot ) {
        return ( spot );
    }
    spot = find (world,classname,"info_player_deathmatch");
    if ( spot ) {
        cyc = (random () * 6);
        while ( (cyc > 1) ) {
            spot = find (spot,classname,"info_player_deathmatch");
            if ( !spot ) {
                spot = find (spot,classname,"info_player_deathmatch");
            }
            cyc = (cyc - 1);
        }
        return ( spot );
    }
    objerror ("FindIntermission: no spot");
    return ( world );
}
entity FindNextIntermission (entity start_point) {
    entity spot;
    if ( deathmatch ) {
        if ( ((start_point.classname == "info_intermission") || (start_point == world)) ) {
            spot = find (start_point,classname,"info_intermission");
            if ( spot ) {
                return ( spot );
            } else {
                start_point = world;
            }
        }
        if ( ((start_point.classname == "info_player_deathmatch") || (start_point == world)) ) {
            spot = find (start_point,classname,"info_player_deathmatch");
            if ( spot ) {
                return ( spot );
            }
        }
        spot = find (world,classname,"info_intermission");
        if ( spot ) {
            return ( spot );
        }
        spot = find (world,classname,"info_player_deathmatch");
        if ( spot ) {
            return ( spot );
        }
    } else {
        spot = find (world,classname,"info_player_start");
        if ( spot ) {
            return ( spot );
        }
    }
    return ( FindIntermission () );
}

void TF_MovePlayer () {
    entity place;
    place = FindNextIntermission (self.observer_list);
    self.observer_list = place;
    setorigin (self,(place.origin + '0 0 1'));
    self.angles = place.angles;
    self.fixangle = 1;
}

void GotoNextMap () {
    float nextlevel;
    string sl;
    string st;
    if ( (nextmap != mapname) ) {
        changelevel (nextmap);
        already_chosen_map = 1;
    }
    sl = infokey (world,mapname);
    if ( (sl != string_null) ) {
        nextmap = sl;
        already_chosen_map = 1;
        return ;
    }
    if ( !already_chosen_map ) {
        sl = infokey (world,"n");
        nextlevel = stof (sl);
        nextlevel = (nextlevel + 1);
        sl = ftos (nextlevel);
        localcmd ("localinfo n ");
        localcmd (sl);
        localcmd ("\n");
        st = infokey (world,"cd");
        if ( (st == string_null) ) {
            st = infokey (world,"cycledir");
        }
        if ( (st != string_null) ) {
            localcmd ("exec ");
            localcmd (st);
            localcmd ("/map");
        } else {
            localcmd ("exec qwmcycle/map");
        }
        localcmd (sl);
        localcmd (".cfg\n");
        already_chosen_map = 1;
    }
    if ( (infokey (world,"n") == "0") ) {
        already_chosen_map = 0;
    }
}

void ExitIntermission () {
    dprint ("Exiting intermission...\n");
    if ( deathmatch ) {
        dprint ("Exit Intermission in Deathmatch.\n");
        GotoNextMap ();
        return ;
    }
    intermission_exittime = (time + 1);
    intermission_running = (intermission_running + 1);
    dprint ("Exit Intermission.\n");
    GotoNextMap ();
}

void IntermissionThink () {
    float minp;
    float maxp;
    float currp;
    string sl;
    string st;
    if ( (time < intermission_exittime) ) {
        return ;
    }
    if (infokey(world, "serverdemo") != string_null) {
        localcmd("stop\n");
        st = infokey(world, "demo_auto_left");
        currp = stof(st);
        if (currp > 0) {
            currp = currp - 1;
            st = ftos(currp);
            localcmd("localinfo demo_auto_left ");
            localcmd(st);
            localcmd("\n");
        }
    }
    if ( ((!self.button0 && !self.button1) && !self.button2) ) {
        return ;
    }
    dprint ("Intermission think.\n");
    GotoNextMap ();
    sl = infokey (world,"nmap");
    if ( (sl != string_null) ) {
        st = infokey (world,"minp");
        minp = stof (st);
        st = infokey (world,"maxp");
        maxp = stof (st);
        currp = TeamFortress_GetNoPlayers ();
        dprint ("MAP CYCLING: Player Counting... ");
        if ( ((currp >= minp) && (currp <= maxp)) ) {
            dprint ("within range. Changing maps...\n");
            st = infokey (world,"cd");
            if ( (st == string_null) ) {
                st = infokey (world,"cycledir");
            }
            if ( (st != string_null) ) {
                localcmd ("exec ");
                localcmd (st);
                localcmd ("/");
            } else {
                localcmd ("exec qwmcycle/");
            }
            localcmd (sl);
            localcmd (".cfg\n");
        } else {
            dprint ("outside range. Next map.\n");
            already_chosen_map = 0;
        }
        localcmd ("localinfo minp \"\"\n");
        localcmd ("localinfo maxp \"\"\n");
        localcmd ("localinfo nmap \"\"\n");
    }
}

void execute_changelevel () {
    entity pos;
    dprint ("execute_changelevel()\n");
    intermission_running = 1;
    intermission_exittime = (time + 5);
    pos = FindIntermission ();
    WriteByte (2,32);
    WriteByte (2,3);
    WriteByte (2,30);
    WriteCoord (2,pos.origin_x);
    WriteCoord (2,pos.origin_y);
    WriteCoord (2,pos.origin_z);
    WriteAngle (2,pos.mangle_x);
    WriteAngle (2,pos.mangle_y);
    WriteAngle (2,pos.mangle_z);
    localcmd("serverinfo status Standby\n");
    other = player_head;
    while (other) {
        stuffcmd (other, "play endgame.wav\n");
        ShowFrags(other);
        stuffcmd (other, "on_matchend\n");
        other.takedamage = 0;
        other.solid = 0;
        other.movetype = 0;
        other.modelindex = 0;
        other = other.nextp;
    }
}

void trigger_changelevel () {
    dremove (self);
    return ;
}

void set_suicide_frame ();

void respawn () {
    if ( (self.has_disconnected == 1) ) {
        return ;
    }
    if ( cease_fire ) {
        return ;
    }
    CopyToBodyQue (self);
    setspawnparms (self);
    PutClientInServer ();
}

void ClientKill () {
    entity te;
    if ( (self.has_disconnected == 1) ) {
        return ;
    }
    if ( (self.respawn_time > time) ) {
        return ;
    }
    if ( self.deadflag ) {
        return ;
    }
    if (round_over) {
        return;
    }
    if (modetype & 2) {
        self.respawn_time = (time + 1);
    } else {
        self.respawn_time = (time + 5);
    }
    if ( (self.playerclass ) ) {
        bprint (PRINT_MEDIUM,self.netname);
        bprint (PRINT_MEDIUM," suicides\n");
        if (!cb_prematch)
            TF_AddFrags (self,-1, 0);
        set_suicide_frame ();
        self.modelindex = modelindex_player;
        if ( (self.tfstate & 16) ) {
            te = find (world,classname,"timer");
            while ( te ) {
                if ( ((te.owner == self) && (te.think == BioInfection_Decay)) ) {
                    logfrag (te,self);
                    TF_AddFrags (te.enemy,1, 1);
                }
                te = find (te,classname,"timer");
            }
        } else {
            logfrag (self,self);
        }
    }
    self.weaponmodel = "";
    self.view_ofs = '0 0 -8';
    self.movetype = 0;
    TeamFortress_RemoveTimers ();
    TeamFortress_SetupRespawn ();
    self.health = -1;
    self.th_die ();
    self.deadflag = 3;
    self.takedamage = 0;
}
entity FindTeamSpawnPoint () {
    entity spot;
    entity at_spot;
    float spot_found;
    float attempts;
    //float cyc;
    string st;
    if (server_type) {
        st = strcat("ts", ftos(self.pteam.team));
    } else {
        if (self.pteam.team == 1) {
            st = "ts1";
        } else if (self.pteam.team == 2) {
            st = "ts2";
        } else if (self.pteam.team== 3) {
            st = "ts3";
        } else if (self.pteam.team == 4) {
            st = "ts4";
        }
    }
#if 0
	if ((modetype & 4) && (bspversion)) {
		spot = find (spot, classname, "info_player_start");
#endif
    spot = self.pteam.movetarget;
    attempts = 0;
    while ( 1 ) {
        attempts = (attempts + 1);
        spot = find (spot,team_str_home,st);
        if ( (spot == world) ) {
            spot = find (world,team_str_home,st);
        }
        if ( (spot == world) ) {
            return ( world );
        }
        attempts = (attempts + 1);
#if 0
           cyc = (random () * 6);
           while ( (cyc > 1) ) {
           spot = find (spot,team_str_home,st);
           if ( !spot )
           spot = find (spot,team_str_home,st);
           cyc = (cyc - 1);
           }
#endif
        at_spot = findradius (spot.origin,40);
        spot_found = 1;
        while ( (at_spot != world) ) {
            if ( ((at_spot.classname == "player") && (at_spot.deadflag == 0)) ) {
                spot_found = 0;
            }
            at_spot = at_spot.chain;
        }
        if ( !Activated (spot,self) ) {
            spot_found = 0;
        }
        if ( (spot_found || (attempts >= 30)) ) {
            self.pteam.movetarget = spot;
            return ( spot );
        }
    }
    return ( world );
}
entity SelectSpawnPoint () {
    entity spot;
    entity at_spot;
    float spot_found;
    float attempts;
    if ( (self.pteam.team != 0) ) {
        spot = FindTeamSpawnPoint ();
        if ( (spot != world) ) {
            return ( spot );
        }
    }
    if ( coop ) {
        lastspawn = find (lastspawn,classname,"info_player_coop");
        if ( (lastspawn == world) ) {
            lastspawn = find (world,classname,"info_player_coop");
        }
        if ( (lastspawn != world) ) {
            return ( lastspawn );
        }
    } else {
        if ( deathmatch ) {
            spot = find (lastspawn,classname,"info_player_deathmatch");
            if ( (spot == world) ) {
                spot = find (world,classname,"info_player_deathmatch");
            }
            attempts = 0;
            while ( ((spot != world) && (attempts < 100)) ) {
                attempts = (attempts + 1);
                at_spot = findradius (spot.origin,40);
                spot_found = 1;
                while ( at_spot ) {
                    if ( ((at_spot.classname == "player") && (at_spot.deadflag == 0)) ) {
                        spot_found = 0;
                    }
                    at_spot = at_spot.chain;
                }
                if ( (spot_found || (attempts >= 10)) ) {
                    lastspawn = spot;
                    return ( spot );
                }
                spot = find (spot,classname,"info_player_deathmatch");
                if ( (spot == world) ) {
                    spot = find (world,classname,"info_player_deathmatch");
                }
            }
        }
    }
    spot = find (world,classname,"info_player_start");
    if ( !spot ) {
        spot = find (world,classname,"info_intermission");
        if ( !spot ) {
            spot = find (world,classname,"info_player_teamspawn");
            if ( !spot ) {
                error ("PutClientInServer: no info_player_start on level\n");
            }
        }
    }
    return ( spot );
}

void PlayerDie ();

void TeamFortress_SetHealth ();

void TeamFortress_SetEquipment ();

void player_touch ();

void PutClientInServer () {
    float iszoom;
    entity spot;
    entity te;
    float oldclass;
    //self.immune_to_check = (time + 5);
    self.touch = player_touch;
    self.classname = "player";
    self.health = 100;
    self.solid = 3;
    self.movetype = 3;
    self.show_hostile = 0;
    self.max_health = 100;
    self.flags = 8;
    self.air_finished = (time + 12);
    self.dmg = 2;
    self.super_damage_finished = 0;
    self.radsuit_finished = 0;
    self.invisible_finished = 0;
    self.invincible_finished = 0;
    self.effects = 0;
    self.invincible_time = 0;
    self.reload_shotgun = 0;
    self.reload_super_shotgun = 0;
    self.reload_grenade_launcher = 0;
    self.reload_rocket_launcher = 0;
    self.on_hook = 0;
    self.hook_out = 0;
    self.fire_held_down = 0;
    self.gravity = 1;
    self.camdist = 0;
    DecodeLevelParms ();
    if (self.pteam.team) {
        if ( (!self.playerclass ) ) {
            if ( TeamFortress_TeamIsCivilian (self.pteam.team) ) {
                self.nextpc = 11;
            }
        }
    }
    iszoom = 0;
    if ( (self.tfstate & 4096) ) {
        iszoom = 1;
    }
    if (modetype & 32) {
        if (teamplay) {
            if (self.a_n == 1) {
                self.pteam = pteam1;
            } else if (self.a_n == 2) {
                self.pteam = pteam2;
            } else if (self.a_n > 2) {
                self.pteam = store_obs;
            }
        }
        if (self.a_n > 2) {
            self.playerclass = 0;
            if (self.a_n == 3) {
                sprint (self, PRINT_HIGH, "You are next in line\n");
            } else {
                sprint (self, PRINT_HIGH, "You are ", ftos(self.a_n), "th in the queue\n");
            }
        }
    }
    if (round_active) {
        //if (self.a_n != 2)
        self.playerclass = 0;
    } else {
        if ((self.nextpc != 0) ) {
            self.playerclass = self.nextpc;
            self.nextpc = 0;
            if ( (self.playerclass == 10) ) {
                self.tfstate = (self.tfstate | 8);
            } else {
                self.tfstate = (self.tfstate - (self.tfstate & 8));
                TeamFortress_ExecClassScript (self);
            }
        }
    }
    if ( (self.tfstate & 8) ) {
        if (round_active) {
            self.playerclass = 0;
        } else {
            if (CheckClassAvailable(self.pteam.team)) {
                oldclass = self.playerclass;
                self.playerclass = (1 + floor ((random () * (10 - 1))));
                while ((!IsLegalClass (self.playerclass) || (self.playerclass == oldclass) || (ClassIsRestricted (self.pteam.team,self.playerclass))  ) ) {
                    self.playerclass = (1 + floor ((random () * (10 - 1))));
                }
            } else {
                sprint (self,PRINT_HIGH,"All classes disabled, returning to Observer mode.\n");
                self.playerclass = 0;
            }
            self.tfstate = 8;
            TeamFortress_ExecClassScript (self);
        }
    } else {
        self.tfstate = 0;
    }
    if ( (iszoom == 1) ) {
        self.tfstate = (self.tfstate | 4096);
    }
    if ( (self.playerclass != 9) ) {
        Engineer_RemoveBuildings (self);
    }
    self.takedamage = 2;
    TeamFortress_PrintClassName (self,self.playerclass,(self.tfstate & 8));
    TeamFortress_SetEquipment ();
    TeamFortress_SetHealth ();
    TeamFortress_SetSpeed (self);
    TeamFortress_SetSkin (self);
    stuffcmd (self,"v_cshift 0 0 0 0\n");
    W_SetCurrentAmmo ();
    self.attack_finished = (time + 0.300);
    self.th_pain = player_pain;
    self.th_die = PlayerDie;
    self.deadflag = 0;
    self.pausetime = 0;
    spot = SelectSpawnPoint ();
    if ( (self.playerclass ) ) {
        spawn_tdeath (spot.origin,self);
    }
    self.observer_list = spot;
    //self.origin = (spot.origin + '0 0 1');
    if (spot.oldorigin) {
        setorigin(self, spot.oldorigin + '0 0 1');
    } else {
        setorigin(self, spot.origin + '0 0 1');
    }
    self.angles = spot.angles;
    self.fixangle = 1;
    if ( ((spot.classname == "info_player_teamspawn") && (!cb_prematch)) ) {
        if ( (spot.items != 0) ) {
            te = Finditem (spot.items);
            if ( te ) {
                tfgoalitem_GiveToPlayer (te,self,self);
            }
            if ( !(spot.goal_activation & 1) ) {
                spot.items = 0;
            }
        }
        if ( spot.message ) {
            CenterPrint (self,spot.message);
            if ( !(spot.goal_activation & 2) ) {
                spot.message = string_null;
            }
        }
        if ( (spot.activate_goal_no != 0) ) {
            te = Findgoal (spot.activate_goal_no);
            if ( te ) {
                AttemptToActivate (te,self,spot);
            }
        }
        if ( (spot.goal_effects == 1) ) {
            spot.classname = "deadpoint";
            spot.team_str_home = string_null;
            spot.nextthink = (time + 1);
            spot.think = SUB_Remove;
        }
    }
    setmodel (self,string_null);
    modelindex_null = self.modelindex;
    setmodel (self,"progs/eyes.mdl");
    modelindex_eyes = self.modelindex;
    setmodel (self,"progs/player.mdl");
    modelindex_player = self.modelindex;
    if ( (!self.playerclass ) ) {
        self.modelindex = modelindex_null;
        if (round_active) {
            self.current_menu = 0;
        }
        self.movetype = 8;
    }
    if (teamplay) {
        SetTeam(self);
    }
    setsize (self, VEC_HULL_MIN, VEC_HULL_MAX);
    self.view_ofs = '0 0 22';
    self.velocity = '0 0 0';
    player_stand1 ();
    if ( (deathmatch || coop) ) {
        makevectors (self.angles);
        if ( (self.playerclass) ) {
            spawn_tfog ((self.origin + (v_forward * 20)));
        }
    }
    if ( cease_fire ) {
        sprint (self,PRINT_HIGH,"\n\nCEASE FIRE MODE\n");
        self.tfstate = (self.tfstate | 65536);
        TeamFortress_SetSpeed (self);
    }
}

void PrintClientScore (entity c) {
    if ( ((c.frags > -10) && (c.frags < 0)) ) {
        bprint (PRINT_MEDIUM," ");
    } else {
        if ( (c.frags >= 0) ) {
            if ( (c.frags < 100) ) {
                bprint (PRINT_MEDIUM," ");
            }
            if ( (c.frags < 10) ) {
                bprint (PRINT_MEDIUM," ");
            }
        }
    }
    bprint (PRINT_MEDIUM,ftos (c.frags));
    bprint (PRINT_MEDIUM," ");
    bprint (PRINT_MEDIUM,c.netname);
    bprint (PRINT_MEDIUM,"\n");
}

void DumpScore () {
    entity e;
    entity sort;
    entity walk;
    if ( world.chain ) {
        error ("DumpScore: world.chain is set");
    }
    e = player_head;
    sort = world;
    while ( e ) {
        if ( !sort ) {
            sort = e;
            e.chain = world;
        } else {
            if ( (e.frags > sort.frags) ) {
                e.chain = sort;
                sort = e;
            } else {
                walk = sort;
                do {
                    if ( !walk.chain ) {
                        e.chain = world;
                        walk.chain = e;
                    } else {
                        if ( (walk.chain.frags < e.frags) ) {
                            e.chain = walk.chain;
                            walk.chain = e;
                        } else {
                            walk = walk.chain;
                        }
                    }
                } while ( (walk.chain != e) );
            }
        }
        e = e.nextp;
    }
    bprint (PRINT_MEDIUM,"\n");
    while ( sort ) {
        PrintClientScore (sort);
        sort = sort.chain;
    }
    bprint (PRINT_MEDIUM,"\n");
}

float already_cycled /* = 0 */;

void NextLevel () {
    entity o;
    if ( already_cycled ) {
        return ;
    }
    already_cycled = 1;
    o = spawn ();
    o.map = nextmap;
    o.think = execute_changelevel;
    o.nextthink = (time + 0.100);
}

void CheckRules () {
    if ( !(modetype & 1))  {
        if ( (timelimit && (time >= timelimit)) ) {
            NextLevel ();
        }
    }
    if ( (fraglimit && (self.frags >= fraglimit)) ) {
        NextLevel ();
    }
}

void PlayerDeathThink () {
    float fwd;
    if ( (self.flags & 512) ) {
        fwd = self.speed;
        fwd = (fwd - 20);
        if ( (fwd <= 0) ) {
            self.velocity = '0 0 0';
        } else {
            self.velocity = (fwd * normalize (self.velocity));
        }
    }
    if ( (self.deadflag == 2) ) {
        if ( ((self.button2 || self.button1) || self.button0) ) {
            return ;
        }
        self.deadflag = 3;
        return ;
    }
    if (round_over == 2) {
        self.button0 = 0;
        self.button1 = 0;
        self.button2 = 0;
        return ;
    }
    if (round_active && !modetype & 32) {
        if ( (self.respawn_time <= time) ) {
            self.button0 = 0;
            self.button1 = 0;
            self.button2 = 0;
            respawn ();
        }
        return ;
    }
    if ( ((!self.button2 && !self.button1) && !self.button0) ) {
        if ( self.respawn_time ) {
            if ( (self.respawn_time <= time) ) {
                self.button0 = 0;
                self.button1 = 0;
                self.button2 = 0;
            }
            return ;
        }
    } else {
        if ( (self.respawn_time <= time) ) {
            self.button0 = 0;
            self.button1 = 0;
            self.button2 = 0;
            respawn ();
        }
        return ;
    }
    if ( (self.impulse == 171) ) {
        if ( (self.respawn_time <= time) ) {
            self.button0 = 0;
            self.button1 = 0;
            self.button2 = 0;
            respawn ();
        }
        self.impulse = 0;
        return ;
    }
}

void PlayerJump () {
    entity te;
    float stumble;
    if ( (self.has_disconnected == 1) ) {
        return ;
    }
    if (allow_stamina) {
        if (self.stamina < 0) {
            return;
        }
    }
    if ( (self.flags & 2048) ) {
        return ;
    }
    if (self.tfstate & 65536) {
        return ;
    }
    if ( (!self.playerclass)) {
        if ((self.waterlevel >= 2)) {
            self.velocity_z = 350;
        } else {
            self.velocity_z = 200;
        }
        if (self.flags & 4096) {
            self.flags = self.flags - (self.flags & 4096);
        }
        self.button2 = 0;
        return ;
    }
    if ( (self.waterlevel >= 2) ) {
        if ( (self.watertype == -3) ) {
            self.velocity_z = 100;
        } else {
            if ( (self.watertype == -4) ) {
                self.velocity_z = 80;
            } else {
                self.velocity_z = 50;
            }
        }
        if ( (self.swim_flag < time) ) {
            self.swim_flag = (time + 1);
            if ( (random () < 0.500) ) {
                sound (self,4,"misc/water1.wav",1,1);
            } else {
                sound (self,4,"misc/water2.wav",1,1);
            }
        }
        if ((self.fire_held_down && (self.current == WEAP_ASSAULT_CANNON)) ) {
            self.tfstate = (self.tfstate - (self.tfstate & 2048));
            if (classtype & 2)
                self.tfstate = self.tfstate - (self.tfstate & 65536);
            TeamFortress_SetSpeed (self);
            self.weaponframe = 0;
            self.heat = 0;
            // self.count = 1;
            player_assaultcannondown1 ();
        }
        return ;
    }
    if ( !(self.flags & 512) ) {
        return ;
    }
    if ( !(self.flags & 4096) ) {
        return ;
    }
    if (allow_stamina) {
        if (self.stamina > 0) {
            self.stamina = self.stamina - 200;
        }
    }
    self.flags = (self.flags - (self.flags & 4096));
    self.button2 = 0;
    sound (self,4,"player/plyrjmp8.wav",1,1);
    if ((self.speed > 150) && (self.button0 && (self.current == WEAP_ASSAULT_CANNON)) ) {
        sprint (self,PRINT_MEDIUM,"You cannot fire the assault cannon without your feet on the ground...\n");
        self.tfstate = (self.tfstate - (self.tfstate & 2048));
        if (classtype & 2)
            self.tfstate = self.tfstate - (self.tfstate & 65536);
        TeamFortress_SetSpeed (self);
        self.weaponframe = 0;
        self.count = 1;
        self.heat = 0;
        player_assaultcannondown1 ();
    }
    if (!conctype) {
        if (self.invincible_finished) return;
        te = find (world, classname, "timer");
        while ((((te.owner != self) || (te.think != ConcussionGrenadeTimer)) && (te != world))) {
            te = find (te, classname, "timer");
        }
        if (((te != world) && (te != self))) {
            crandom ();
            stumble = (crandom () * (te.health / 100));
            if ((crandom () < 0)) {
                self.velocity_x = (self.velocity_y + stumble);
                self.velocity_y = (self.velocity_x + stumble);
            } else {
                self.velocity_x = ((-1 * self.velocity_y) + stumble);
                self.velocity_y = ((-1 * self.velocity_x) + stumble);
            }
        }
    }
    return;
}
.float dmgtime;

void WaterMove () {
    if ( (self.movetype == 8) ) {
        return ;
    }
    if ( (self.health < 0) ) {
        return ;
    }
    if ( (self.waterlevel != 3) ) {
        if ( (self.air_finished < time) ) {
            sound (self,2,"player/gasp2.wav",1,1);
        } else {
            if ( (self.air_finished < (time + 9)) ) {
                sound (self,2,"player/gasp1.wav",1,1);
            }
        }
        self.air_finished = (time + 12);
        self.dmg = 2;
    } else {
        if ( (self.air_finished < time) ) {
            if ( (self.pain_finished < time) ) {
                self.dmg = (self.dmg + 2);
                if ( (self.dmg > 15) ) {
                    self.dmg = 10;
                }
                TF_T_Damage (self,world,world,self.dmg,1,0);
                self.pain_finished = (time + 1);
            }
        }
    }
    if ( !self.waterlevel ) {
        if ( (self.flags & 16) ) {
            sound (self,4,"misc/outwater.wav",1,1);
            self.flags = (self.flags - 16);
        }
        return ;
    }
    if ( (self.watertype == -5) ) {
        if ( (self.dmgtime < time) ) {
            if ( (self.radsuit_finished > time) ) {
                self.dmgtime = (time + 1);
            } else {
                self.dmgtime = (time + 0.200);
            }
            TF_T_Damage (self,world,world,(10 * self.waterlevel),0,16);
        }
    } else {
        if ( (self.watertype == -4) ) {
            if ( ((self.dmgtime < time) && (self.radsuit_finished < time)) ) {
                self.dmgtime = (time + 1);
                TF_T_Damage (self,world,world,(4 * self.waterlevel), 0, 0);
            }
        }
    }
    if ( !(self.flags & 16) ) {
        if ( (self.watertype == -5) ) {
            sound (self,4,"player/inlava.wav",1,1);
        }
        if ( (self.watertype == -3) ) {
            sound (self,4,"player/inh2o.wav",1,1);
        }
        if ( (self.watertype == -4) ) {
            sound (self,4,"player/slimbrn2.wav",1,1);
        }
        self.flags = (self.flags + 16);
        self.dmgtime = 0;
    }
}

void CheckWaterJump () {
    vector start;
    vector end;
    makevectors (self.angles);
    start = self.origin;
    start_z = (start_z + 8);
    v_forward_z = 0;
    normalize (v_forward);
    end = (start + (v_forward * 24));
    traceline (start,end,1,self);
    if ( (trace_fraction < 1) ) {
        start_z = ((start_z + self.maxs_z) - 8);
        end = (start + (v_forward * 24));
        self.movedir = (trace_plane_normal * -50);
        traceline (start,end,1,self);
        if ( (trace_fraction == 1) ) {
            self.flags = (self.flags | 2048);
            self.velocity_z = 225;
            self.flags = (self.flags - (self.flags & 4096));
            self.teleport_time = (time + 2);
            return ;
        }
    }
}

void PlayerPreThink () {
    if ( (self.is_feigning && (self.waterlevel == 1)) ) {
        self.watertype = -3;
        self.waterlevel = 3;
    }
    if ( intermission_running ) {
        IntermissionThink ();
        return ;
    }
    CheckFps ();
    makevectors (self.v_angle);
    if ( (self.view_ofs == '0 0 0') ) {
        return ;
    }
    CheckRules ();
    if ( (self.deadflag >= 2) ) {
        self.movetype = 6;
        PlayerDeathThink ();
        return ;
    }
    if ( ((self.undercover_team || self.undercover_skin) || self.is_undercover) ) {
        if ( (self.effects & (8 | 4)) ) {
            sprint (self,PRINT_MEDIUM,"The glowing removes your disguise.\n");
            Spy_RemoveDisguise (self);
        }
        if ( (modetype & 4 && self.ammo_detpack) ) {
            sprint (self,PRINT_MEDIUM,"The bomb removes your disguise.\n");
            Spy_RemoveDisguise (self);
        }
    }
    if ( (self.deadflag == 1) ) {
        return ;
    }
    if ( !self.is_feigning ) {
#if 0
		if (self.crouch == 2) {
			pos = self.origin;
			traceline(pos, pos, 0, self, VEC_HULL_MIN, VEC_HULL_MAX);
			if (trace_allsolid)	//if player would be stuck
			{
				pos = self.origin+'0 0 18';	//can we move them up a little
				traceline(pos, pos, 0, self, VEC_HULL_MIN, VEC_HULL_MAX);
				if (!trace_allsolid)
				{
					self.origin = pos;
					self.crouch = 0;
					setsize(self, VEC_HULL_MIN, VEC_HULL_MAX);
					TeamFortress_SetSpeed (self);
				}
			}
		}
#endif
        if ( self.button2 ) {
            PlayerJump ();
        } else {
            self.flags = (self.flags | 4096);
        }
        if ( self.button1 ) {
            CheckUse ();
        }
    } else {
        if ( self.waterlevel ) {
            self.velocity_z = -100;
        }
    }
    if (allow_stamina) {
        if (self.stamina != 1000) {
            if (self.stamina < (1000 - 4)) {
                self.stamina = self.stamina + 4;
            } else {
                self.stamina = 1000;
            }
        }
    }
    if ( ((time < self.pausetime) || (cease_fire == 1)) ) {
        self.velocity = '0 0 0';
    }
    if ( (((time > self.attack_finished) && (self.currentammo == 0)) && (self.weapon > 16)) ) {
        self.weapon = W_BestWeapon ();
        W_SetCurrentAmmo ();
    }
    if ( self.on_hook ) {
        Service_Grapple ();
    }
}

void CheckPowerups () {
    float lighton;
    entity te;
    if ( (self.health <= 0) ) {
        return ;
    }
    if ( (!self.playerclass) ) {
        self.modelindex = modelindex_null;
    } else {
        if ( self.invisible_finished ) {
            if ( (self.tfstate & 64) ) {
                if ( (self.invisible_finished < (time + 10)) ) {
                    self.invisible_finished = (time + 666);
                }
            }
            if ( (self.invisible_sound < time) ) {
                sound (self,0,"items/inv3.wav",0.500,2);
                self.invisible_sound = (time + ((random () * 3) + 1));
            }
            if ( (self.invisible_finished < (time + 3)) ) {
                if ( (self.invisible_time == 1) ) {
                    sprint (self,PRINT_HIGH,"Ring of Shadows magic is fading\n");
                    stuffcmd (self,"bf\n");
                    sound (self,0,"items/inv2.wav",1,1);
                    self.invisible_time = (time + 1);
                }
                if ( (self.invisible_time < time) ) {
                    self.invisible_time = (time + 1);
                    stuffcmd (self,"bf\n");
                }
            }
            if ( (self.invisible_finished < time) ) {
                self.items = (self.items - 524288);
                self.invisible_finished = 0;
                self.invisible_time = 0;
            }
            self.frame = 0;
            self.modelindex = modelindex_eyes;
        } else {
            self.modelindex = modelindex_player;
        }
    }
    if ( self.invincible_finished ) {
        if ( (self.tfstate & 32) ) {
            if ( (self.invincible_finished < (time + 10)) ) {
                self.invincible_finished = (time + 666);
            }
        }
        if ( (self.invincible_finished < (time + 3)) ) {
            if ( (self.invincible_time == 1) ) {
                sprint (self,PRINT_HIGH,"Protection is almost burned out\n");
                stuffcmd (self,"bf\n");
                sound (self,0,"items/protect2.wav",1,1);
                self.invincible_time = (time + 1);
            }
            if ( (self.invincible_time < time) ) {
                self.invincible_time = (time + 1);
                stuffcmd (self,"bf\n");
            }
        }
        if ( (self.invincible_finished < time) ) {
            self.items = (self.items - 1048576);
            self.invincible_time = 0;
            self.invincible_finished = 0;
        }
        if ( (self.invincible_finished > time) ) {
            self.effects = (self.effects | 8);
            self.effects = (self.effects | 128);
        } else {
            lighton = 0;
            te = find (world,classname,"item_tfgoal");
            while ( te ) {
                if ( (te.owner == self) ) {
                    if ( (te.goal_activation & 1) ) {
                        lighton = 1;
                    }
                }
                te = find (te,classname,"item_tfgoal");
            }
            if ( !lighton ) {
                self.effects = (self.effects - (self.effects & 8));
                self.effects = (self.effects - (self.effects & 32));
                self.effects = (self.effects - (self.effects & 128));
            }
        }
    }
    if ( self.super_damage_finished ) {
        if ( (self.tfstate & 128) ) {
            if ( (self.super_damage_finished == (time + 10)) ) {
                self.super_damage_finished = (time + 666);
            }
        }
        if ( (self.super_damage_finished < (time + 3)) ) {
            if ( (self.super_time == 1) ) {
                sprint (self,PRINT_HIGH,"Quad Damage is wearing off\n");
                stuffcmd (self,"bf\n");
                sound (self,0,"items/damage2.wav",1,1);
                self.super_time = (time + 1);
            }
            if ( (self.super_time < time) ) {
                self.super_time = (time + 1);
                stuffcmd (self,"bf\n");
            }
        }
        if ( (self.super_damage_finished < time) ) {
            self.items = (self.items - 4194304);
            self.super_damage_finished = 0;
            self.super_time = 0;
        }
        if ( (self.super_damage_finished > time) ) {
            self.effects = (self.effects | 8);
            self.effects = (self.effects | 64);
        } else {
            lighton = 0;
            te = find (world,classname,"item_tfgoal");
            while ( te ) {
                if ( (te.owner == self) ) {
                    if ( (te.goal_activation & 1) ) {
                        lighton = 1;
                    }
                }
                te = find (te,classname,"item_tfgoal");
            }
            if ( !lighton ) {
                self.effects = (self.effects - (self.effects & 8));
                self.effects = (self.effects - (self.effects & 16));
                self.effects = (self.effects - (self.effects & 64));
            }
        }
    }
    if ( self.radsuit_finished ) {
        self.air_finished = (time + 12);
        if ( (self.tfstate & 256) ) {
            if ( (self.radsuit_finished == (time + 10)) ) {
                self.radsuit_finished = (time + 666);
            }
        }
        if ( (self.radsuit_finished < (time + 3)) ) {
            if ( (self.rad_time == 1) ) {
                sprint (self,PRINT_HIGH,"Air supply in Biosuit expiring\n");
                stuffcmd (self,"bf\n");
                sound (self,0,"items/suit2.wav",1,1);
                self.rad_time = (time + 1);
            }
            if ( (self.rad_time < time) ) {
                self.rad_time = (time + 1);
                stuffcmd (self,"bf\n");
            }
        }
        if ( (self.radsuit_finished < time) ) {
            self.items = (self.items - 2097152);
            self.rad_time = 0;
            self.radsuit_finished = 0;
        }
    }
}

void Admin_Alias (string alias) {
    stuffcmd (self,"alias ");
    stuffcmd (self,alias);
    stuffcmd (self," \"cmd ");
    stuffcmd (self,alias);
    stuffcmd (self,"\"\n");
}

void Admin_Aliases () {
    if (self.motd <= 130) {
        self.motd = (self.motd + 1);
    }
    if (self.motd == 90) {
        Admin_Alias ("countplayers");
        Admin_Alias ("deal");
        Admin_Alias ("kick");
        Admin_Alias ("next");
        Admin_Alias ("ceasefire");
        Admin_Alias ("listips");
        Admin_Alias ("timedown");
        Admin_Alias ("timeup");
        Admin_Alias ("pmdown");
    }
    if (self.motd == 96) {
        Admin_Alias ("pmup");
        Admin_Alias ("cfdown");
        Admin_Alias ("cfup");
        Admin_Alias ("otdown");
        Admin_Alias ("otup");
        Admin_Alias ("startmatch");
        Admin_Alias ("fragsdown");
        Admin_Alias ("fragsup");
        Admin_Alias ("tp");
    }
    if (self.motd == 112) {
        Admin_Alias ("clan");
        Admin_Alias ("restartmap");
        Admin_Alias ("gspeed");
        Admin_Alias ("silence");
        Admin_Alias ("freeze");
        Admin_Alias ("tfvsdm");
        Admin_Alias ("reset");
        Admin_Alias ("teamfrags");
        Admin_Alias ("fullts");
    }
    if (self.motd == 118) {
        Admin_Alias ("grapple");
        Admin_Alias ("clansetup");
        Admin_Alias ("fbskins");
        Admin_Alias ("highlander");
        Admin_Alias ("sgtype");
        Admin_Alias ("sgfire");
        Admin_Alias ("pipedelay");
        Admin_Alias ("soliddp");
        Admin_Alias ("flag_model");
    }
    if (self.motd == 124) {
        Admin_Alias ("flag_solid");
        Admin_Alias ("flag_drop");
        Admin_Alias ("frjump");
        Admin_Alias ("rounds");
        Admin_Alias ("duel");
        Admin_Alias ("speedcap");
        Admin_Alias ("practice");
        Admin_Alias ("tfstrike");
        stuffcmd(self, "on_admin\n");
        self.get_admin_aliases = 0;
    }
}

// FIXME: crashing mvdsv from here...
void PlayerPostThink () {
    float fdmg;
    if ( (self.motd <= 80) ) {
        TeamFortress_MOTD ();
    } else {
        if ( ((time > self.StatusRefreshTime) && (self.StatusBarSize != 0)) ) {
            RefreshStatusBar ();
        }
        if (self.is_admin) {
            if (self.get_admin_aliases) {
                if (self.motd <= 130) {
                    Admin_Aliases();
                }
            }
        }
    }

    if ( (self.view_ofs == '0 0 0') ) {
        return ;
    }

    if ( self.deadflag ) {
        if ( (self.impulse) && (!self.has_disconnected) ) {
            if (DeadImpulses() ) return;
            CommandImpulses();
            self.impulse = 0;
        }
        return ;
    }
    if ( (self.playerclass) ) {
        self.speed = vlen (self.velocity); // its current speed
        self.cnt = self.cnt + 1;
        self.a_speed = self.a_speed + self.speed;
        WaterMove ();
        if ((self.flags & 512)) {
            self.g_count = self.g_count + 1;
            self.a_gspeed = self.a_gspeed + self.speed;
            if (time > self.gs_interval)  CheckGspeed ();
            if ( ((self.jump_flag < -300) && (self.health > 0)) ) {
                if ( (self.watertype == -3) ) {
                    sound (self,4,"player/h2ojump.wav",1,1);
                } else {
                    if ( (self.jump_flag < -680) ) {
                        if ((infokey(world,"fallbunny") != "off") && !round_over) {
                            fdmg = 5;
                            fdmg = ((fdmg * (self.jump_flag / 400)) * -1);
                            if ( (self.playerclass == 1) ) {
                                fdmg = (fdmg / 2);
							} else if ( (self.playerclass == 6) ) {
								fdmg = (fdmg * 1.500);
                            }
                            fdmg = rint (fdmg);
                            TF_T_Damage (self,world,world,fdmg,1,0);
                            self.deathtype = "falling";
                        }
                        sound (self,2,"player/land2.wav",1,1);
                    } else {
                        sound (self,2,"player/land.wav",1,1);
                    }
                }
            }
        }
    } else {
        Check_Track();
    }
    self.jump_flag = self.velocity_z;
    CheckPowerups ();
    W_WeaponFrame ();
}

void Admin_Check (string cl_pwd) {
    string st;
    st = infokey (self,"ip");
    if (st == "0.0" || st == "127.0.1") {
        self.is_admin = 3;
        return;
    }
    st = infokey (world,"adminpwd");
    if (cl_pwd != string_null) {
        stuffcmd (self,"setinfo adminpwd \"");
        stuffcmd (self,"\"\n");
        if ( (st != string_null) &&  (cl_pwd == st)) {
            self.is_admin = 3;
            return;
        }
    }
    st = infokey (self,"*VIP");
    if (st != string_null) {
        self.is_admin = 1;
    }
}

#if 0
void () crash_catcher_think =
{
	float _l_8315;
	if (!self.owner)
	{
		remove (self);
		return;
	}
	if (!intermission_running)
	{
		fl = time - self.owner.lastthink;
		if ((fl > 0.800000))
		{

			void_self (self.owner, reset_fps);
		}
		if (self.style)
		{
			self.style = 0;
			self.nextthink = (time + 30);
			return;
		}
		if ((fl > 2))
		{
			if ((timing_action & 1))
			{
				bprint (PRINT_HIGH000, "á◊¡“Œ…Œ«∫ ", self.owner.netname, " is timing!");
				bprint (PRINT_CHAT000, "\n");
			}
			if (!self.owner.menu.lastthink)
			{
				if ((timing_action & 2))
				{
					self.owner.effects = (self.owner.effects | 8);
				}
				if ((timing_action & 16))
				{
					self.owner.menu.tp_back_weapon = self.owner.modelindex;
					self.owner.modelindex = modelindex_zombie;
				}
				if ((timing_action & 4))
				{
					self.owner.menu.loc_idx = 1;
				}
				if ((timing_action & 8))
				{
					if (!k_pause)
					{
						AdminForcePause (1);
					}
				}
			}
			self.style = 1;
			self.owner.menu.lastthink = 1;
		}
		self.nextthink = (time + 1);
	}
	else
	{
		remove (self);
	}
};

void () make_crash_catcher =
{
	entity te;
	if (!allow_timing)
	{
		return;
	}
	te = spawn ();
	te.classname = "crash_catcher";
	te.think = crash_catcher_think;
	te.owner = self;
	te.nextthink = time;
}

void () remove_crash_catcher =
{
	entity te;
	float fl;
	te = find (world, classname, "crash_catcher");
	while (((te != world) && (fl == 0)))
	{
		if ((te.owner == self))
		{
			fl = 1;
			dprint ("crash_catcher REMOVED\n");
			dremove (te);
		}
		else
		{
			te = find (te, classname, "crash_catcher");
		}
	}
}
#endif

void ClientConnect () {
    string st;
    //string st2;
    float res;
    bprint (PRINT_HIGH,self.netname);
    bprint (PRINT_HIGH," entered the game\n");
    //stuffcmd (self,"say -d\n");
    stuffcmd (self,"on_connect\n");
    self.tfstate = (self.tfstate | 4096);
    if ( (self.netname == string_null) ) {
        stuffcmd (self, "disconnect\n");
    }
    //make_crash_catcher ();
    //self.motd = 0;
    self.get_aliases = 1;
    self.nextp = player_head;
    player_head = self;
    self.fFrameReset = time + 15;
    st = infokey (self,"tfk");
    if ( st != string_null) {
        self.tfkey = stof(st);
    }
    st = infokey (self,"sbr");
    if ( (st == string_null) ) {
        st = infokey (self,"sbar_res");
    }
    res = stof(st);
    if ( (res == 768) ) {
        self.StatusBarRes = SBAR_768;
    } else {
        if ( (res == 600) ) {
            self.StatusBarRes = SBAR_600;
        } else {
            if ( (res == 480) ) {
                self.StatusBarRes = SBAR_480;
            } else {
                if ( (res == 400) ) {
                    self.StatusBarRes = SBAR_400;
                } else {
                    if ( (res == 384) ) {
                        self.StatusBarRes = SBAR_384;
                    } else {
                        if ( (res == 350) ) {
                            self.StatusBarRes = SBAR_350;
                        } else {
                            if ( (res == 300) ) {
                                self.StatusBarRes = SBAR_300;
                            } else {
                                if ( (res == 240) ) {
                                    self.StatusBarRes = SBAR_240;
                                } else {
                                    if ( (res == 200) ) {
                                        self.StatusBarRes = SBAR_200;
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    st = infokey (self,"sbs");
    if ( (st == string_null) ) {
        st = infokey (self,"sbar_size");
    }
    self.StatusBarSize = stof (st);
    if ( ((self.StatusBarSize > 10) || (self.StatusBarSize < 1)) ) {
        if (self.tfkey & 8) {
            self.StatusBarSize = 3;
        } else {
            self.StatusBarSize = 0;
        }
    }
    if (!server_type) {
        self.StatusBarSize = 0;
    }
    CheckConnectRate();
    TeamFortress_ExecMapScript (self);
    self.has_disconnected = 0;
    if ( (self.netname == string_null) ) {
        stuffcmd (self,"disconnect\n");
    }
    if ( intermission_running ) {
        GotoNextMap ();
    }
    st = infokey (self,"adminpwd");
    Admin_Check(st);
    if (self.is_admin) {
        self.get_admin_aliases = 1;
    }
    if ( (cb_prematch) ) {
        sprint (self,PRINT_HIGH,"CURRENTLY IN PREMATCH TIME\n");
    }
    //self.a_n = TeamFortress_GetNoPlayers() + 1;	queue
    stuffcmd (self,"cl_backspeed 999\n");
    stuffcmd (self,"cl_forwardspeed 999\n");
    stuffcmd (self,"cl_sidespeed 999\n");
}

void ClientDisconnect () {
    entity te;
    string st;
    float fr;
    fr = rint (self.frags);
    st = ftos (fr);
    if (TeamFortress_GetNoPlayers() == 1 && (!cb_prematch) && (modetype & 1)) GotoNextMap();
    bprint (PRINT_HIGH,self.netname," left the game with ",st," frags\n");
    sound (self,4,"player/tornoff2.wav",1,0);
    self.has_disconnected = 1;
    TeamFortress_RemoveTimers ();
    RemoveVotes();
    Engineer_RemoveBuildings (self);
    if (!modetype & 4) {
        te = find (world,classname,"detpack");
        while ( te ) {
            if ( (te.owner == self) ) {
                dremove (te);
                te = world;
            }
            te = find (te,classname,"detpack");
        }
        te = find (world,classname,"detpack_timer");
        while ( te ) {
            if ( (te.owner == self) ) {
                dremove (te);
                te = world;
            }
            te = find (te,classname,"detpack");
        }
    } else {
        if (self.is_detpacking) {
            self.ammo_detpack = 1;
        }
        Drop_detpack();
    }
    if (player_head == self)
        player_head = self.nextp;
    else {
        te = player_head;
        while (te) {
            if (te.nextp == self)
                te.nextp = self.nextp;
            te = te.nextp;
        }
    }
    set_suicide_frame ();
    self.netname = string_null;
    // self.team_no = 0;
    self.real_time = 0;
    self.flag_touches = 0;
    self.flag_captures = 0;
    self.flag_fumbles = 0;
    self.nailpos = 0;
    self.stamina = 0;
    self.pausetime = 0;
    self.enemy = world;
    self.no_active_gas_grens = 0;
    self.no_active_nail_grens = 0;
    self.no_active_napalm_grens = 0;
    self.deathtype = string_null;
    self.dmg_inflictor = world;
    self.observer_list = world;
    self.count = 0;
    self.last = 0;
    self.is_admin = 0;
    self.fAverageFrameTime = 0;
    self.fFrameCount = 0;
    self.fFrameReset = 0;
    self.fLowestFrameTime = 0;
    self.infection_team_no = 0;
    self.solid = 0;
    self.is_building = 0;
    self.is_detpacking = 0;
    self.is_undercover = 0;
    self.is_feigning = 0;
    self.is_unabletospy = 0;
    self.ammo_medikit = 0;
    self.maxammo_medikit = 0;
    self.ammo_detpack = 0;
    self.maxammo_detpack = 0;
    self.items_allowed = 0;
    self.armor_allowed = 0;
    self.maxarmor = 0;
    self.respawn_time = 0;
    self.heat = 0;
    self.ammo_rockets = 0;
    self.ammo_nails = 0;
    self.ammo_shells = 0;
    self.ammo_cells = 0;
    self.maxammo_rockets = 0;
    self.maxammo_nails = 0;
    self.maxammo_shells = 0;
    self.maxammo_cells = 0;
    self.no_grenades_1 = 0;
    self.no_grenades_2 = 0;
    self.tp_grenades_1 = 0;
    self.tp_grenades_2 = 0;
    self.tf_items = 0;
    self.ScannerOn = 0;
    self.armorclass = 0;
    self.armortype = 0;
    self.armorvalue = 0;
    self.current = 0;
    self.items = 0;
    self.carried = 0;
    self.touch = SUB_Null;
    self.classname = string_null;
    self.health = 0;
    self.movetype = 0;
    self.show_hostile = 0;
    self.max_health = 0;
    self.flags = 0;
    self.air_finished = 0;
    self.dmg = 0;
    self.super_damage_finished = 0;
    self.radsuit_finished = 0;
    self.invisible_finished = 0;
    self.invincible_finished = 0;
    self.effects = 0;
    self.invincible_time = 0;
    self.reload_shotgun = 0;
    self.reload_super_shotgun = 0;
    self.reload_grenade_launcher = 0;
    self.reload_rocket_launcher = 0;
    self.on_hook = 0;
    self.hook_out = 0;
    self.fire_held_down = 0;
    self.motd = 0;
    self.menu_count = 0;
    self.menu_displaytime = 0;
    self.current_menu = 0;
    self.tfstate = 0;
    //self.cheat_check = 0;
    self.maxspeed = 0;
    self.attack_finished = 0;
    self.gravity = 0;
    self.walkframe = 0;
    self.frame = 0;
    self.watertype = 0;
    self.colormap = 0;
    self.skin =  0;
    self.weapon = 0;
    self.weaponmodel = string_null;
    self.pain_finished = 0;
    self.playerclass = 0;
    self.has_dispenser = 0;
    self.has_sentry = 0;
    self.deaths = 0;
    self.real_frags = 0;
    self.teamkills = 0;
    self.heat = 0;
    //self.immune_to_check = 0;
    self.last_sound = 0;
    //self.observer_list  entity 101
    self.StatusRefreshTime = 0;
    self.StatusBarSize = 0;
    self.StatusBarRes = 0;
    self.currentammo = 0;
    self.takedamage = 0;
    self.dmg_inflicted = 0;
    self.dmg_recieved = 0;
    self.dmg_self = 0;
    self.dmg_team = 0;
    self.vote = 0;
    self.bvote = 0;
    //self.is_admin = 0;
    self.admin_mode = 0;
    self.velocity = '0 0 0';
    self.angles = '0 0 0';
    self.avelocity = '0 0 0';
    self.origin = '0 0 0';
    self.v_angle = '0 0 0';
    self.view_ofs = '0 0 0';
    self.absmin = '0 0 0';
    self.absmax = '0 0 0';
    self.noise = string_null;
    self.th_pain  = SUB_Null;
    self.th_die = SUB_Null;
    setsize (self,'0 0 0','0 0 0');
    self.nextthink = 0;
    self.think = SUB_Null;
}

void ClientObituary (entity targ, entity attacker) {
    float rnum;
    string deathstring;
    string deathstring2;
    rnum = random ();
    rnum = random ();
    if ( (cb_prematch) ) {
        return ;
    }
    if ( (targ.classname == "player") ) {
        if ( (attacker.classname == "teledeath") ) {
            bprint (PRINT_MEDIUM,targ.netname);
            bprint (PRINT_MEDIUM," was telefragged by ");
            bprint (PRINT_MEDIUM,attacker.owner.netname);
            bprint (PRINT_MEDIUM,"\n");
            if ( ((attacker.owner.pteam != targ.pteam) || (attacker.owner.pteam.team < 1)) ) {
                TF_AddFrags (attacker.owner,1 , 0);
            }
            return ;
        }
        if ( (attacker.classname == "teledeath2") ) {
            bprint (PRINT_MEDIUM,"Satan's power deflects ");
            bprint (PRINT_MEDIUM,targ.netname);
            bprint (PRINT_MEDIUM,"'s telefrag\n");
            TF_AddFrags (targ,-1, 0);
            logfrag (targ,targ);
            return ;
        }
        if ( (deathmsg == 37) ) {
            bprint (PRINT_MEDIUM,targ.netname);
            bprint (PRINT_MEDIUM," shoots his teammate one too many times.\n");
            return ;
        }
        if ( ((attacker.classname == "info_tfgoal") || (attacker.classname == "item_tfgoal")) ) {
            if ( (attacker.deathtype != "") ) {
                bprint (PRINT_MEDIUM,targ.netname);
                bprint (PRINT_MEDIUM,attacker.deathtype);
            }
            logfrag (targ,targ);
            return ;
        }
        if ( (attacker.classname == "player")) {
            if ( (targ == attacker) ) {
                TF_AddFrags (attacker,-1, 0);
                bprint (PRINT_MEDIUM,targ.netname);
                if ( (deathmsg == 8) ) {
					if ( (targ.playerclass == 2) ) {
						deathstring = " got splattered by his own grenade\n";
					} else if ( (targ.playerclass == 3) ) {
						deathstring = " sat on his own grenade\n";
					} else if ( (targ.playerclass == 4) ) {
						deathstring = " got to know his grenade too well\n";
					} else if ( (targ.playerclass == 5) ) {
						deathstring = " caught the end of his own grenade\n";
					} else if ( (targ.playerclass == 6) ) {
						deathstring = " got too close to his own grenade\n";
					} else if ( (targ.playerclass == 7) ) {
						deathstring = " let his own grenade get the best of him\n";
					} else if ( (targ.playerclass == 8) ) {
						deathstring = " tiptoed over his own grenade\n";
					} else if ( (targ.playerclass == 9) ) {
						deathstring = " stared at his grenade too long\n";
					} else {
						deathstring = " grenades himself\n";
					}
                } else {
                    if ( (deathmsg == 9) ) {
                        deathstring = " hammers himself\n";
					} else if ( (deathmsg == 10) ) {
						if ( (targ.playerclass == 4) ) {
							deathstring = " practiced his own Mirv dance\n";
						} else {
							if ( (targ.playerclass == 6) ) {
								deathstring = " allowed his Mirv to turn against him\n";
							} else {
								deathstring = " goes to pieces\n";
							}
						}
					} else if ( (deathmsg == 11) ) {
						deathstring = " ambushes himself with his own pipebombs\n";
					} else if ( (deathmsg == 40) ) {
						deathstring = " tried to juggle his own pipebombs\n";
					} else if ( (deathmsg == 24) ) {
						deathstring = " chokes on his own gas\n";
					} else if ( (deathmsg == 30) ) {
						deathstring = " explodes his ammo and body\n";
					} else if ( (deathmsg == 41) ) {
						deathstring = " stepped on too many of his own caltrops\n";
					} else if ( (deathmsg == 35) ) {
						deathstring = " is charred by his own flash grenade\n";
					} else if ( (deathmsg == 31) ) {
						deathstring = " detonates an ammo box too close to him\n";
					} else if ( (deathmsg == 12) ) {
						deathstring = " set the detpack and forgot to run\n";
					} else if ( (deathmsg == 13) ) {
						deathstring = " died impossibly!\n";
					} else if ( (deathmsg == 6) ) {
						deathstring = " becomes bored with life\n";
					} else if ( (deathmsg == 33) ) {
						deathstring = " chars himself with an incendiary rocket\n";
					} else if ( (deathmsg == 5) ) {
						deathstring = " tries to put the pin back in\n";
					} else if ( (deathmsg == 15) ) {
						deathstring = " torches himself\n";
					} else if ( ((deathmsg == 7) && (targ.waterlevel > 1)) ) {
						bprint (PRINT_MEDIUM," discharges into the water.\n");
						return ;
					} else if ( (deathmsg == 38) ) {
						deathstring = " gets too friendly with his sentrygun.\n";
					} else if ( (deathmsg == 39) ) {
						deathstring = " dispenses with himself.\n";
					} else if ( deathmsg == 18) {
						deathstring = " melted himself.\n";
					}
				}
                bprint (PRINT_MEDIUM,deathstring);
                return ;
            } else {
                if ( ((teamplay && (attacker.pteam == targ.pteam)) && (attacker.pteam.team > 0)) ) {
                    TF_AddFrags (attacker,-1, 0);
                    if ( (targ.undercover_team == 0) ) {
                        attacker.teamkills = (attacker.teamkills + 1);
                    }
                    deathstring2 = "\n";
                    if ( (rnum < 0.333) ) {
                        deathstring = " mows down teammate ";
                        deathstring2 = "\n";
					} else if ( (rnum < 0.666) ) {
						deathstring = " checks his glasses after killing ";
						deathstring2 = "\n";
					} else {
                            deathstring = " killed his supposed friend ";
                            deathstring2 = "\n";
                        }
                    if ( (deathmsg == 23) ) {
                        bprint (PRINT_MEDIUM,targ.netname);
                        bprint (PRINT_MEDIUM," didn't survive the operation by ");
                        bprint (PRINT_MEDIUM,attacker.netname);
                        bprint (PRINT_MEDIUM,"\n");
                        return ;
                    }
                    bprint (PRINT_MEDIUM,attacker.netname);
                    bprint (PRINT_MEDIUM,deathstring);
                    bprint (PRINT_MEDIUM,targ.netname);
                    bprint (PRINT_MEDIUM,deathstring2);
                    CheckAutoKick (attacker);
                    return ;
                } else {
                    TF_AddFrags (attacker,1, 1);
                    logfrag (attacker,targ);
                    if ( (deathmsg == 8) ) {
                        if ( (attacker.playerclass == 2) ) {
                            deathstring = " got up-close and personal with ";
                            deathstring2 = "'s grenade\n";
						} else if ( (attacker.playerclass == 3) ) {
							deathstring = " played catch with ";
							deathstring2 = "'s grenade\n";
						} else if ( (attacker.playerclass == 4) ) {
							deathstring = " received a pineapple enema from ";
							deathstring2 = "\n";
						} else if ( (attacker.playerclass == 5) ) {
							deathstring = " fetched ";
							deathstring2 = "'s pineapple\n";
						} else if ( (attacker.playerclass == 6) ) {
							deathstring = " caught too much shrapnel from ";
							deathstring2 = "'s grenade\n";
						} else if ( (attacker.playerclass == 7) ) {
							deathstring = " tried to pick up ";
							deathstring2 = "'s hot potato\n";
						} else if ( (attacker.playerclass == 8) ) {
							deathstring = " thought ";
							deathstring2 = " was tossing him a spare grenade\n";
						} else if ( (attacker.playerclass == 9) ) {
							deathstring = " stops to ponder the technical details of ";
							deathstring2 = "'s grenade\n";
						} else {
							deathstring = " surfs on a grenade from ";
							deathstring2 = "\n";
						}
                    } else {
                        if ( (deathmsg == 9) ) {
                            deathstring = " gets flayed by ";
                            deathstring2 = "'s nail grenade\n";
						} else if ( (deathmsg == 10) ) {
							if ( (attacker.playerclass == 4) ) {
								deathstring = " does a dance on ";
								deathstring2 = "'s Mirv grenade\n";
							} else {
								deathstring = " gets spammed by ";
								deathstring2 = "'s Mirv grenade\n";
							}
						} else if ( (deathmsg == 11) ) {
							deathstring = " is caught by ";
							deathstring2 = "'s pipebomb trap\n";
						} else if ( (deathmsg == 40) ) {
							deathstring = " fell victim to ";
							deathstring2 = "'s fireworks\n";
						} else if ( (deathmsg == 24) ) {
							deathstring = " gags on ";
							deathstring2 = "'s noxious gasses\n";
						} else if ( (deathmsg == 30) ) {
							deathstring = "'s ammo detonates him as ";
							deathstring2 = "'s EMP fries it\n";
						} else if ( (deathmsg == 41) ) {
							deathstring = " stepped on too many of ";
							deathstring2 = "'s caltrops\n";
						} else if ( (deathmsg == 35) ) {
							deathstring = " is charred by ";
							deathstring2 = "'s flash grenade\n";
						} else if ( (deathmsg == 31) ) {
							deathstring = " stands near some ammo as ";
							deathstring2 = "'s EMP nukes it\n";
						} else if ( (deathmsg == 12) ) {
							deathstring = " reaches orbit via ";
							deathstring2 = "'s detpack\n";
						} else if ( (deathmsg == 16) ) {
							deathstring = " cut the red wire of ";
							deathstring2 = "'s detpack\n";
						} else if ( (deathmsg == 13) ) {
							deathstring = " dies from ";
							deathstring2 = "'s mysterious tropical disease\n";
						} else if ( (deathmsg == 14) ) {
							deathstring = " escapes infection from ";
							deathstring2 = " by dying first\n";
						} else if ( (deathmsg == 5) ) {
							deathstring = " eats ";
							deathstring2 = "'s pineapple\n";
							if ( (targ.health < -40) ) {
								deathstring = " was gibbed by ";
								deathstring2 = "'s grenade\n";
							}
						} else if ( (deathmsg == 6) ) {
							deathstring = " rides ";
							deathstring2 = "'s rocket\n";
							if ( (targ.health < -40) ) {
								deathstring = " was gibbed by ";
								deathstring2 = "'s rocket\n";
							}
						} else if ( (deathmsg == 15) ) {
							if ( (rnum < 0.200) ) {
								deathstring = " is burnt up by ";
								deathstring2 = "'s flame\n";
							} else if ( (rnum < 0.400) ) {
								deathstring = " is fried by ";
								deathstring2 = "'s fire\n";
							} else if ( (rnum < 0.600) ) {
								deathstring = " feels ";
								deathstring2 = "'s fire of wrath\n";
							} else if ( (rnum < 0.800) ) {
								deathstring = " is reduced to ashes by ";
								deathstring2 = "\n";
							} else {
								deathstring = " is grilled by ";
								deathstring2 = "'s flame\n";
							}
						} else if ( (deathmsg == 17) ) {
							deathstring2 = "\n";
							if ( (attacker.playerclass == 8) ) {
								deathstring = " was knife-murdered by ";
							} else if ( (attacker.playerclass == 1) ) {
								deathstring = "'s mellon was split by ";
							} else if ( (attacker.playerclass == 2) ) {
								deathstring = " was put on the chop block by ";
							} else if ( (attacker.playerclass == 3) ) {
								deathstring = " was sliced and diced by ";
								deathstring2 = "'s blade\n";
							} else if ( (attacker.playerclass == 4) ) {
								deathstring = " is split from crotch to sternum by ";
								deathstring2 = "'s axe swing\n";
							} else if ( (attacker.playerclass == 6) ) {
								deathstring = " is split in two with a powerful axe blow from ";
							} else if ( (attacker.playerclass == 7) ) {
								deathstring = "'s death put another notch on ";
								deathstring2 = "'s axe\n";
							} else {
								deathstring = " was ax-murdered by ";
							}
						} else if ( (deathmsg == 32) ) {
							deathstring = " was spanner-murdered by ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 1) ) {
							if ( (attacker.playerclass == 1) ) {
								deathstring = " got too close to ";
								deathstring2 = "'s muzzleflash\n";
							} else if ( (attacker.playerclass == 3) ) {
								deathstring = " practices being ";
								deathstring2 = "'s clay pigeon\n";
							} else if ( (attacker.playerclass == 4) ) {
								deathstring = " was on the receiving end of ";
								deathstring2 = "'s shotgun barrel\n";
							} else if ( (attacker.playerclass == 5) ) {
								deathstring = " was fed a lead diet by ";
								deathstring2 = "\n";
							} else if ( (attacker.playerclass == 6) ) {
								deathstring = " got blasted by ";
								deathstring2 = "'s last resort\n";
							} else if ( (attacker.playerclass == 7) ) {
								deathstring = " got more than a powderburn from ";
								deathstring2 = "'s shotgun blast\n";
							} else {
								deathstring = " chewed on ";
								deathstring2 = "'s boomstick\n";
							}
						} else if ( (deathmsg == 2) ) {
							if ( (attacker.playerclass == 3) ) {
								deathstring = " was turned into swiss cheese by ";
								deathstring2 = "'s buckshot\n";
							} else if ( (attacker.playerclass == 5) ) {
								deathstring = " got a double-dose of ";
								deathstring2 = "'s buckshot\n";
							} else if ( (attacker.playerclass == 6) ) {
								deathstring = " unfortunately forgot ";
								deathstring2 = " carried a super-shotgun\n";
							} else if ( (attacker.playerclass == 8) ) {
								deathstring = " gets ventilated by ";
								deathstring2 = "'s super-shotgun blast\n";
							} else if ( (attacker.playerclass == 9) ) {
								deathstring = "'s body got chuck full of ";
								deathstring2 = "'s lead pellets\n";
							} else {
								deathstring = " ate 2 loads of ";
								deathstring2 = "'s buckshot\n";
							}
						} else if ( (deathmsg == 3) ) {
							if ( (attacker.playerclass == 1) ) {
								deathstring = " caught one too many nails from ";
								deathstring2 = "\n";
							} else if ( (attacker.playerclass == 2) ) {
								deathstring = " ran into ";
								deathstring2 = "'s nails\n";
							} else if ( (attacker.playerclass == 8) ) {
								deathstring = " was turned into ";
								deathstring2 = "'s pin-cushion\n";
							} else {
								deathstring = " was nailed by ";
								deathstring2 = "\n";
							}
						} else if ( (deathmsg == 4) ) {
							deathstring = " was punctured by ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 7) ) {
							deathstring = " accepts ";
							if ( (attacker.waterlevel > 1) ) {
								deathstring2 = "'s discharge\n";
							} else {
								deathstring2 = "'s shaft\n";
							}
						} else if ( (deathmsg == 21) ) {
							deathstring = " grappled with ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 18) ) {
							if (classtype & 1) {
								deathstring = " was melted by ";
								deathstring2 = "'s plasmagun\n";
							} else if ( (rnum <= 0.300) ) {
								deathstring = " takes a bullet in the chest from ";
								deathstring2 = "\n";
							} else {
								deathstring = " succumbs to sniperfire from ";
								deathstring2 = "\n";
							}
						} else if ( (deathmsg == 29) ) {
							if ( (rnum <= 0.500) ) {
								deathstring = " gets a third eye from ";
								deathstring2 = "\n";
							} else {
								deathstring = " gets his head blown off by ";
								deathstring2 = "\n";
							}
						} else if ( (deathmsg == 28) ) {
							if ( (rnum <= 0.500) ) {
								deathstring = " is made legless by ";
								deathstring2 = "\n";
							} else {
								deathstring = " gets his legs blown off by ";
								deathstring2 = "\n";
							}
						} else if ( (deathmsg == 19) ) {
							deathstring = " collects ";
							deathstring2 = "'s bullet spray.\n";
						} else if ( (deathmsg == 20) ) {
							deathstring = " gets sawn in half by ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 22) ) {
							deathstring = " gets knifed from behind by ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 25) ) {
							deathstring = " is put to sleep by ";
							deathstring2 = "\n";
						} else if ( (deathmsg == 26) ) {
							deathstring = " gets a hole in his heart from ";
							deathstring2 = "'s railgun\n";
						} else if ( (deathmsg == 33) ) {
							deathstring = " gets well done by ";
							deathstring2 = "'s incendiary rocket\n";
						} else if ( (deathmsg == 38) ) {
							deathstring = " gets destroyed by ";
							deathstring2 = "'s exploding sentrygun\n";
						} else if ( (deathmsg == 39) ) {
							deathstring = " didn't insert the correct change into ";
							deathstring2 = "'s dispenser.\n";
						}
                    }
                    if ( ((attacker.has_disconnected == 1) || (attacker.netname == string_null)) ) {
                        deathstring = " died.";
                        deathstring2 = "\n";
                    }
                    bprint (PRINT_MEDIUM,targ.netname);
                    bprint (PRINT_MEDIUM,deathstring);
                    bprint (PRINT_MEDIUM,attacker.netname);
                    bprint (PRINT_MEDIUM,deathstring2);
                }
            }
            return ;
        } else {
            if ( (attacker.classname == "building_sentrygun") ) {
                if ( (targ == attacker.real_owner) ) {
                    if ( (deathmsg == 34) ) {
                        deathstring = " intercepts his sentry gun's rocket\n";
					} else if ( (deathmsg == 27) ) {
						deathstring = " crossed his sentry gun's line of fire\n";
					} else if ( (deathmsg == 7) ) {
						deathstring = " crossed his sentry gun's shaft\n";
					}
                    bprint (PRINT_MEDIUM,targ.netname);
                    bprint (PRINT_MEDIUM,deathstring);
                } else {
                    if ( ((teamplay && (attacker.pteam == targ.pteam)) && (attacker.pteam.team > 0)) ) {
                        bprint (PRINT_MEDIUM,targ.netname);
                        bprint (PRINT_MEDIUM," obstructs his team's sentry gun\n");
                    } else {
                        TF_AddFrags (attacker.real_owner,1, 1);
                        logfrag (attacker.real_owner,targ);
                        if ( (deathmsg == 34) ) {
                            deathstring = " hates ";
                            deathstring2 = "'s sentry gun\n";
						} else if ( (deathmsg == 27) ) {
							deathstring = " is mown down by ";
							deathstring2 = "'s sentry gun\n";
						} else if ( (deathmsg == 7) ) {
							deathstring = " is electrocuted by ";
							deathstring2 = "'s sentry gun\n";
						}
                        bprint (PRINT_MEDIUM,targ.netname);
                        bprint (PRINT_MEDIUM,deathstring);
                        bprint (PRINT_MEDIUM,attacker.real_owner.netname);
                        bprint (PRINT_MEDIUM,deathstring2);
                    }
                }
            } else {
                logfrag (targ,targ);
                TF_AddFrags (targ,-1, 0);
                rnum = targ.watertype;
                bprint (PRINT_MEDIUM,targ.netname);
                if ( (rnum == -3) ) {
                    if ( (random () < 0.500) ) {
                        deathstring = " sleeps with the fishes\n";
                    } else {
                        deathstring = " sucks it down\n";
                    }
                } else {
                    if ( (rnum == -4) ) {
                        if ( (random () < 0.500) ) {
                            deathstring = " gulped a load of slime\n";
                        } else {
                            deathstring = " can't exist on slime alone\n";
                        }
                    } else {
                        if ( (rnum == -5) ) {
                            if ( (targ.health < -15) ) {
                                deathstring = " burst into flames\n";
							} else if ( (random () < 0.500) ) {
								deathstring = " turned into hot slag\n";
							} else {
								deathstring = " visits the Volcano God\n";
							}
                        } else {
                            if ( (attacker.classname == "explo_box") ) {
                                deathstring = " blew up\n";
							} else if ( ((attacker.solid == 4) && (attacker != world)) ) {
								deathstring = " was squished\n";
							} else if ( (targ.deathtype == "falling") ) {
								targ.deathtype = string_null;
								deathstring = " fell to his death\n";
							} else if ( ((attacker.classname == "trap_shooter") || (attacker.classname == "trap_spikeshooter")) ) {
								deathstring = " was spiked\n";
							} else if ( (attacker.classname == "fireball") ) {
								deathstring = " ate a lavaball\n";
							} else if ( (attacker.classname == "trigger_changelevel") ) {
								deathstring = " tried to leave\n";
							} else {
								deathstring = " died\n";
							}
						}
					}
                }
                bprint (PRINT_MEDIUM,deathstring);
            }
        }
    } else {
        if ( (targ.classname == "building_sentrygun") ) {
            if ( (attacker.classname == "teledeath") ) {
                bprint (PRINT_MEDIUM,targ.real_owner.netname);
                bprint (PRINT_MEDIUM,"'s sentrygun was telefragged by ");
                bprint (PRINT_MEDIUM,attacker.owner.netname);
                bprint (PRINT_MEDIUM,"\n");
                return ;
            }
            if ( (attacker.classname == "player") ) {
                if ( (attacker == targ.real_owner) ) {
                    bprint (PRINT_MEDIUM,targ.real_owner.netname);
                    bprint (PRINT_MEDIUM," destroys his sentrygun\n");
                    return ;
                }
                bprint (PRINT_MEDIUM,targ.real_owner.netname);
                bprint (PRINT_MEDIUM,"'s sentrygun was destroyed by ");
                bprint (PRINT_MEDIUM,attacker.netname);
                bprint (PRINT_MEDIUM,"\n");
                if ( ((attacker.pteam.team > 0) && (attacker.pteam == targ.real_owner.pteam)) ) {
                    TF_AddFrags (attacker,-1 , 0);
                    attacker.teamkills = (attacker.teamkills + 1);
                    CheckAutoKick (attacker);
                } else {
                    TF_AddFrags (attacker,1 , 1);
                }
                return ;
            }
        } else {
            if ( (targ.classname == "building_dispenser") ) {
                if ( ((attacker.pteam.team > 0) && (attacker.pteam == targ.real_owner.pteam)) ) {
                    TF_AddFrags (attacker,-1, 0);
                    attacker.teamkills = (attacker.teamkills + 1);
                    CheckAutoKick (attacker);
                }
            }
        }
    }
}
