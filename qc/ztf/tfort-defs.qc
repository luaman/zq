/*
	tfort-defs.qc

	qwtf global definitions

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

// FIXME: this whole file could do with cleaning up and organising

.float lefty;       // qwtf hook
.float maxspeed;    // qwtf
.entity oldenemy;   // qwtf
.float search_time; // qwtf
.void() th_melee;   // qwtf
.void() th_missile; // qwtf
vector vector_null; // qwtf
.float		cnt2;			// qwtf misc flag

//
// sentry
//
.float waitmin;
.float waitmax;

//
// TF unknown
//
.float volume;
.float oldheight;
.entity movetarget;
.float distance;

//===========================================================================


//
// builtin functions
//

float(float f) sqrt = #62; // qwtf

void(string str) tokanize = #84; // tokanize text
float() argc = #85;              // returns number of tokens
string(float num) argv = #86;    // returns token for the given number
float (string str) str2byte = #91;
float (string str) str2short = #92;
/* void (string str) freestr = #94; */
string (string str) readcmd = #96;                               // executes command on server, but result is returned by this function instead of writing to the console
string(string str, string substr) strstr = #98;                  // searches for substring in str, returns pointer to it or "" if not found
void(string logname, float console, string text) log = #100; // prints text to file 'logname', if console is non-zero, prints to the server console as well
void(entity cl, string text) redirectcmd = #101;                 // executes string on the console and redirects output to client (eg redirect(self, "status"))
void() calltimeofday = #102;                                     // force server to call mod function timeofday
float (string s) findmap = #104;
float(entity client, float level, float range, float start, float style, float footer) listmaps = #105;
string(float id) findmapname = #106;
float (string str) strlen = #114;
string (string str1, string str2) strcat = #115;
string (string str, float start, float len) substr = #116;
string (string str , float size) newstr = #118;

#ifdef CSQC
.float(entity to) SendEntity;
.float Version;

float	MSG_ENTITY		= 5;
#endif

void AttemptToActivate (entity Goal, entity AP, entity ActivatingGoal);
//added for optimization
entity store_obs;
entity pteam1;
entity pteam2;
entity pteam3;
entity pteam4;
//FTE
.float alpha;
//link lists
entity player_head;
entity spec_head;
.entity nextp;
.entity nexts;
.entity chain2;
.float sbar_type;
.float playerclass;
//.float cheat_check;
.float FlashTime;
.float nextpc;
.float last_impulse;
.float armorclass;
.float tf_items;
.float tf_items_flags;
.float no_grenades_1;
.float no_grenades_2;
.float tp_grenades_1;
.float tp_grenades_2;
.float get_aliases;
.float get_admin_aliases;
.float is_removed;
.float is_undercover;
.float is_building;
.float is_detpacking;
.float is_feigning;
.float is_unabletospy;
.float is_frozen;
//.float is_concussed;
.float has_disconnected;
.float tfstate;
.entity linked_list;
.entity observer_list;
.float maxammo_shells;
.float maxammo_nails;
.float maxammo_cells;
.float maxammo_rockets;
.float items_allowed;
.float armor_allowed;
.float maxarmor;
.float motd;
.float current_menu;
.float menu_count;
.float menu_displaytime;

float toggleflags;

float respawn_delay_time;
//float number_of_teams;
//float num_teams;
.entity pteam;  //added ent and .variables to reduce old variables see below
.float maxplayers;
.float max_pipebombs;
.float num_pipebombs;
.float max_ammoboxes;
.float num_ammoboxes;
//float illegalclasses;
//float civilianteams;
.float team_no;
// *** old variables gg shitcode
//float illegalclasses1;
//float illegalclasses2;
//float illegalclasses3;
//float illegalclasses4;
//float team1col;
//float team2col;
//float team3col;
//float team4col;
//float team1score;
//float team2score;
//float team3score;
//float team4score;
//float team1maxplayers;
//float team2maxplayers;
//float team3maxplayers;
//float team4maxplayers;
//float num_world_pipebombs;
//float num_team_pipebombs_1;
//float num_team_pipebombs_2;
//float num_team_pipebombs_3;
//float num_team_pipebombs_4;
//float num_max_pipebombs;
//float num_world_flares;
//float num_team_flares_1;
//float num_team_flares_2;
//float num_team_flares_3;
//float num_team_flares_4;
//float num_max_flares;
//float num_world_ammoboxes;
//float num_team_ammoboxes_1;
//float num_team_ammoboxes_2;
//float num_team_ammoboxes_3;
//float num_team_ammoboxes_4;
//float num_max_ammoboxes;
.float infection_team_no;

float ctfmap;

float coop;

float rj;
.float tracking;
.entity building;
.float building_wait;
.entity real_owner;
.float has_dispenser;
.float has_sentry;
//.float has_teleporter;
.float real_frags;
.float deaths;
.float respawn_time;
.float weaponmode;
.float carried;
.float num_weaps;
.float current;
.float last;
float ic_ammo;

float server_type;

float anti_spam;
.float ammo_medikit;
.float maxammo_medikit;
.float ammo_detpack;
.float maxammo_detpack;
.float reload_shotgun;
.float reload_super_shotgun;
.float reload_grenade_launcher;
.float reload_rocket_launcher;
.float heat;
//.float immune_to_check;
.float last_sound;
.float no_active_nail_grens;
.float no_active_napalm_grens;
.float no_active_gas_grens;
.float goal_no;
.float group_no;
.float goal_state;
.float owned_by;
.float goal_activation;
.float goal_effects;
.float goal_result;
.float goal_group;
.float else_goal;
.float if_goal_is_active;
.float if_goal_is_inactive;
.float if_goal_is_removed;
.float if_group_is_active;
.float if_group_is_inactive;
.float if_group_is_removed;
.float activate_goal_no;
.float inactivate_goal_no;
.float remove_goal_no;
.float restore_goal_no;
.float activate_group_no;
.float inactivate_group_no;
.float remove_group_no;
.float restore_group_no;
.vector goal_min;
.vector goal_max;
.float has_item_from_group;
.float hasnt_item_from_group;
.float remove_item_group;
.float return_item_no;
.float if_item_has_moved;
.float if_item_hasnt_moved;
.float remove_spawnpoint;
.float restore_spawnpoint;
.float remove_spawngroup;
.float restore_spawngroup;
.float display_item_status1;
.float display_item_status2;
.float display_item_status3;
.float display_item_status4;
.string team_str_home;
.string team_str_moved;
.string team_str_carried;
.string non_team_str_home;
.string non_team_str_moved;
.string non_team_str_carried;
.float ex_skill_min;
.float ex_skill_max;
.float increase_team1;
.float increase_team2;
.float increase_team3;
.float increase_team4;
.string broadcast;
.string team_broadcast;
.string non_team_broadcast;
.string owners_team_broadcast;
.string netname_broadcast;
.string netname_team_broadcast;
.string netname_non_team_broadcast;
.string netname_owners_team_broadcast;
.string team_drop;
.string non_team_drop;
.string netname_team_drop;
.string netname_non_team_drop;
string team_menu_string;
.float all_active;
.float item_list;

float item_list_bit;
.float delay_time;
.float dont_do_triggerwork;
.float g_a;
.float g_e;
.string t_s_h;
.string t_s_m;
.string t_s_c;
.string n_s_h;
.string n_s_m;
.string n_s_c;
.string b_b;
.string b_t;
.string b_n;
.string b_o;
.string n_b;
.string n_t;
.string n_n;
.string n_o;
.string d_t;
.string d_n;
.string d_n_t;
.string d_n_n;
.float h_i_g;
.float hn_i_g;
.float r_i_g;
.float a_s;
.float a_n;
.float a_r;
.float a_c;
.float rv_s_h;
.float rs_s_h;
.float rv_gr;
.float rs_gr;
.float rv_g;
.float rs_g;
.float has_abbreviated;

float num_world_flames;
.float numflames;
.string flame_id;
.float undercover_team;
.float undercover_skin;
.string undercover_name;
.float hook_out;
//float live_camera;
.float camdist;
.float campan;
//.vector camangle;
//.entity camera_list;

float already_chosen_map;
.entity hook;
.float on_hook;
.float fire_held_down;
.vector head_shot_vector;
.float leg_damage;
.float nailpos;
.float StatusRefreshTime;
.float StatusBarSize;
.float StatusBarRes;
//.float mapcount /* = 100 */;

float holdlimit;
//pm_speed

float gspeed;

float gspeedtype /* = 0 */;
.float gs_interval;

float airspeed;
float aspeedtype /* = 0 */;
.float a_speed;
.float a_gspeed;
.float g_count;

float freeze;

float allow_stamina ;
//float allow_ttrack ;

float allow_grenpack;
//float allow_crouch;

float sentry_speed ;

float sentry_delay ;

float sentry_fire;

float pipedelay;

float pmtime;
//float saferj;
.float dmg_inflicted;
.float dmg_recieved;
.float dmg_self;
.float dmg_team;
.float flag_touches;
.float flag_captures;
.float flag_fumbles;
.float stamina;
//.float CenterPrintTime;
.float ScannerOn;
//float clan_scores_dumped;

float cb_prematch;

float elect ;

float v_break  ;

float v_misc  ;
.float allowvote ;
.float electtime ;
.float tfkey;

float lights;
//float flag;

float sgtype;

float grenradius;

float conctype;

float classtype;

float grentype;

float modetype;
//temp floats, update later

float reload_sound;

float railgun;

float light_ents;

float sep_models;

float realdm;

float spec_msgs;

float powerups;
//float clanbattle;
//float practice;
//float tfstrike;
//float tfvsdm;
//float speedcap;
//float duel;
//float quadmode;

float realistic;

float bspversion;

float rounds;

float round_active;

float round_over;

float round_pause;
entity round_winner;
//float num_hostages;
//float team1frags;
//float team2frags;
//float team3frags;
//float team4frags;

float allow_hook;

float flagem_checked;

float cease_fire;
.float teamkills;

float autokick_time;

float autokick_kills;
//float autokick_concs;
.float vote;
.float bvote;
.float mvote;
.float is_admin;
.float admin_mode;
.entity admin_use;
.string ip;

float deathmsg;
string nextmap /* = "" */;

float intermission_running /* = 0 */;

float intermission_exittime /* = 0 */;
vector	VEC_HULL_MIN;
vector	VEC_HULL_MAX;
vector	VEC_HULL2_MIN;
vector	VEC_HULL2_MAX;
vector	VEC_HULL3_MIN;
vector	VEC_HULL3_MAX;
#ifdef CSQC

float SetPlayerStat30(float def) {
    return self.no_grenades_1;
}

float SetPlayerStat31(float def) {
    return self.no_grenades_2;
}
#endif

void KickPlayer (float psize, entity p) {
    msg_entity = p;
#if 0
	dprint(ftos(p.angles_x));
	dprint("\n");
	if (p.angles_x > 0) {
		p.angles_x = p.angles_x  + (psize * 2);
	} else {
		p.angles_x = p.angles_x * -1 + (psize * 2);
	}
	p.angles_z = p.angles_z;
	p.angles_y = p.angles_y;
	p.fixangle = 1;
	// FIXME fucks csqc angle
	if ( (psize > -3) ) {
		WriteByte (1,34);
	} else {
		WriteByte (1,35);
	}
#endif
}

const float WEAP_HOOK                = 1;
const float WEAP_MEDIKIT             = 2;
const float WEAP_SPANNER             = 4;
const float WEAP_AXE                 = 8;
const float WEAP_SNIPER_RIFLE        = 16;
const float WEAP_AUTO_RIFLE          = 32;
const float WEAP_SHOTGUN             = 64;
const float WEAP_SUPER_SHOTGUN       = 128;
const float WEAP_NAILGUN             = 256;
const float WEAP_SUPER_NAILGUN       = 512;
const float WEAP_GRENADE_LAUNCHER    = 1024;
const float WEAP_PIPEBOMB_LAUNCHER   = 2048;
const float WEAP_FLAMETHROWER        = 4096;
const float WEAP_ROCKET_LAUNCHER     = 8192;
const float WEAP_INCENDIARY          = 16384;
const float WEAP_ASSAULT_CANNON      = 32768;
const float WEAP_LIGHTNING           = 65536;
const float WEAP_PLASMAGUN           = 131072;
const float WEAP_TRANQ               = 262144;
const float WEAP_RAILGUN             = 524288;
const float WEAP_LAST                = 1048576;

const float CLASS_NONE               = 0;
const float CLASS_SCOUT              = 1;
const float CLASS_SNIPER             = 2;
const float CLASS_SOLDIER            = 3;
const float CLASS_DEMOMAN            = 4;
const float CLASS_MEDIC              = 5;
const float CLASS_HWGUY              = 6;
const float CLASS_PYRO               = 7;
const float CLASS_SPY                = 8;
const float CLASS_ENGINEER           = 9;
const float CLASS_RANDOM             = 10;
const float CLASS_CIVILIAN           = 11;
const float CLASS_SENTRY             = 13;

const float bled = 137;
const float gled = 134;
const float rled = 135;
const float yled = 136;

const float COLOR_BROWN = 176;
const float COLOR_GREEN = 18;
const float COLOR_WHITE = 48;

const float SBAR_200 = 11;
const float SBAR_240 = 16;
const float SBAR_300 = 22;
const float SBAR_350 = 27;
const float SBAR_384 = 33;
const float SBAR_400 = 35;
const float SBAR_480 = 45;
const float SBAR_600 = 60;
const float SBAR_768 = 80;

const float AMMO_SHELLS  = 1;
const float AMMO_NAILS   = 2;
const float AMMO_ROCKETS = 3;
const float AMMO_CELLS   = 4;
const float AMMO_GREN1   = 5;
const float AMMO_GREN2   = 6;
