//Tonik:
entity (string name, string team, float topcolor, float bottomcolor) testbot = #83;

void() bot_map_load =
{
	// place your qc loaded waypoints here

	if (mapname == "dm1")
		map_dm1();
	else if (mapname == "dm2")
		map_dm2();
	else if (mapname == "dm3")
		map_dm3();
	else if (mapname == "dm4")
		map_dm4();
	else if (mapname == "dm5")
		map_dm5();
	else if (mapname == "dm6")
		map_dm6();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Variables and shtuff

bot.qc has become pretty much a header file
for all variable in the bot...

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

// ----- entity fields ---
.float	wallhug, keys, oldkeys, ishuman;
.float	b_frags, b_clientno, b_shirt, b_pants; 
.float	priority, ai_time, b_sound, missile_speed;
.float	portal_time, b_skill;
.float	b_aiflags, b_num, b_chattime;
.float	b_menu, b_menu_time, b_menu_value;
.float route_failed, dyn_flags, dyn_time;
.float dyn_plat;
.entity	temp_way, last_way;
.entity	target1, target2, target3, target4;
.entity	_next, _last;
.entity	current_way;
.vector	b_angle, b_dest, mouse_emu, obs_dir;
.vector	b_dir;
.float forwardmove, sidemove, upmove;
.vector dyn_dest;

// --------defines-----
float SVC_UPDATENAME	= 13;
float SVC_UPDATEFRAGS	= 14;
float SVC_UPDATECOLORS	= 17;

// used for the physics & movement AI
float KEY_MOVEUP 		= 1;
float KEY_MOVEDOWN 	= 2;
float KEY_MOVELEFT 	= 4;
float KEY_MOVERIGHT 	= 8;
float KEY_MOVEFORWARD	= 16;
float KEY_MOVEBACK	= 32;
float KEY_LOOKUP		= 64;
float KEY_LOOKDOWN	= 128;
float KEY_LOOKLEFT	= 256;
float KEY_LOOKRIGHT	= 512;

// these are aiflags for waypoints
// some overlap to the bot
float AI_TELELINK_1	= 1; // link type
float AI_TELELINK_2	= 2; // link type
float AI_TELELINK_3	= 4; // link type
float AI_TELELINK_4	= 8; // link type
float AI_DOORFLAG		= 16; // read ahead
float AI_PRECISION	= 32; // read ahead + point
float AI_SURFACE		= 64; // point 
float AI_BLIND		= 128; // read ahead + point
float AI_JUMP		= 256; // point + ignore
float AI_DIRECTIONAL	= 512; // read ahead + ignore
float AI_PLAT_BOTTOM	= 1024; // read ahead 
float AI_RIDE_TRAIN	= 2048; // read ahead 
float AI_SUPER_JUMP	= 4096; // point + ignore + route test
float AI_SNIPER		= 8192; // point type 
float AI_AMBUSH		= 16384; // point type
float AI_DOOR_NO_OPEN	= 32768; // read ahead
float AI_DIFFICULT	= 65536; // route test
float AI_TRACE_TEST	= 131072; // route test

// these are flags for bots/players (dynamic/editor flags)
float AI_OBSTRUCTED	= 1;
float AI_HOLD_SELECT	= 2;
float AI_ROUTE_FAILED	= 2;
float AI_WAIT		= 4;
float AI_DANGER		= 8;

// addition masks
float AI_POINT_TYPES 	= 29152;
float AI_READAHEAD_TYPES	= 36528;
float AI_IGNORE_TYPES	= 4864;

float WM_UNINIT		= 0;
float WM_DYNAMIC		= 1;
float WM_LOADING		= 2;
float WM_LOADED		= 3;
// editor modes aren't available in QW, but we retain support of them
// since the editor is still built into the AI in places
float WM_EDITOR		= 4;
float WM_EDITOR_DYNAMIC	= 5;
float WM_EDITOR_DYNLINK	= 6;

float OPT_NOCHAT	= 2;

// -------globals-----
float		max_clients;
float		bot_count, b_options;
float		waypoint_mode, dump_mode; 
float		waypoints, direct_route;
float		sv_gravity;
entity		fixer;
entity		route_table;
entity		b_temp1, b_temp2, b_temp3;
entity 		player_head, phys_head, way_head;
float		busy_waypoints;

// -------Prototypes------

// rankings
float(float clientno)		ClientBitFlag;
void(float whatbot, float whatskill) BotConnect;
void(entity bot)			BotDisconnect;

// waypointing
void()				DynamicWaypoint;
entity(vector org)		make_waypoint;
void()				ClearAllWays;
void()				FixWaypoints;
float()				begin_route;
void(entity this, float direct)			bot_get_path;
void()				WaypointThink;
entity(entity start)				FindWayPoint;

// physics & movement
float(entity e)			bot_can_rj;
void()				bot_jump;
void()				frik_bot_roam;
float(vector weird)		frik_walkmove;
void()				frik_movetogoal;
void()				frik_obstacles;
float(float flag)			frik_recognize_plat;
float(vector sdir)		frik_KeysForDir;
void(vector whichway, float danger) frik_obstructed;
void() 				CL_KeyMove;

// ai & misc
float(entity targ)		fov;
float(float y1, float y2)	angcomp;
float(entity targ1, entity targ2)		wisible;
float(entity targ)		sisible;
float(entity targ)		fisible;
vector(entity ent)		realorigin;
void(entity ent)			target_drop;
void(entity ent)			target_add;
void()				KickABot;
void(entity targ, float success) bot_lost;
string(entity ent, float r)		BotName;
string(entity ent)			PickARandomName;
float(float v)			frik_anglemod;
void() bot_chat;
void(float tpic) bot_start_topic;


// ----------Commands---------
void(entity e, float chan, string samp, float vol, float atten) frik_sound = #8;
vector(entity e, float sped)		frik_aim = #44;	

//----------------------------------------------------------------------------

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Function redclarations. These allow function 
designed to work for clients (sprint, so forth)
to mainly not complain when working with a bot

Although these shouldn't be needed anymore,
as the bots truly are clients now, if you don't
stop the SZ_ buffer from filling up by disabling
direct messages to the bots, it crashes quake :-(

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

vector(entity e, float sped) aim =
{
	e.missile_speed = sped;
	return frik_aim(e, sped);
};

void(entity e, float chan, string samp, float vol, float atten) sound = 
{
	frik_sound(e, chan, samp, vol, atten);
	if (samp == "items/inv3.wav")
		return;
	else if (e.classname == "player")
		e.b_sound = time + 1;
	else if (other.classname == "player")
		other.b_sound = time + 1;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Stuff mentioned up top
it just links the bot into the mod

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float(entity ent) GetClientNum;

void() ClientConnected =
{
	float isBot;

	isBot = FALSE;
	if (stof(infokey(self, "*bot")) != 0)
		isBot = TRUE;

	if (!isBot) {
		if (player_head)
			player_head._last = self;

		self._next = player_head;
		player_head = self;

		self.ishuman = TRUE;
		return;
	}

	bot_count = bot_count + 1;

	bot_start_topic(1);

	self.b_clientno = GetClientNum(self);
//	self.b_clientno = -1;

/*	// players can set skill all weird, so leave these checks in
	whatskill = rint(whatskill);
	if (whatskill > 3)
		whatskill = 3;
	else if (whatskill < 0)
		whatskill = 0;

	self.b_skill = whatskill;
*/

	// FIXME FIXME FIXME
	self.b_skill = 3;

	self.team = self.b_pants + 1;
}


void() ClientDisconnected =
{
	if (!self.ishuman) {
		BotDisconnect ();
		return;
	}

	if (player_head == self)
		player_head = self._next;
	if (self._next)
		self._next._last = self._last;
	if (self._last)
		self._last._next = self._next;
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotPreFrame & BotPostFrame, used to make the
bot easier to install

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
float () BotPreFrame =
{
//wtf?

//	if (self.b_clientno == -1)
//		return TRUE;


if (self.ishuman)
return;

	if (self.b_frags != self.frags)
	{
		if (self.b_frags > self.frags)
		{
			if (pointcontents(self.origin) == CONTENT_LAVA)
				bot_start_topic(10);
			else
				bot_start_topic(9);
		}
		else
			bot_start_topic(2);
		self.b_frags = self.frags;
	}

	DynamicWaypoint();
	return FALSE;
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Bot Chat code

The rest of this code is in bot_rank.qc

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/
void(entity client, float level, string s, string s2) sprint2 = #24;
void(float level, string s, string s2) bprint2	= #23;

void(string h) BotSay = // simulate talking by composing a 'chat' message
{
	bprint2 (PRINT_CHAT, self.netname, h);
};
void() BotSayInit =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 1);
	WriteString(MSG_ALL, self.netname);
};
void(string h) BotSay2 =
{
	WriteByte(MSG_ALL, 8);
	WriteByte(MSG_ALL, 3);
	WriteByte(MSG_ALL, 2);
	WriteString(MSG_ALL, h);
};
void(string h) BotSayTeam = 
{
	// FBX QW doesn't support teamplay...yet
};
/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotInit

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/


void() BotInit =
{
	max_clients = 32;	//Tonik

	bot_map_load();
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Rankings 'utilities'. Written by Alan Kivlin,
this code just fools clients by sending precisely
the same network messages as when a real player
signs on to the server.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

float(float clientno) ClientBitFlag =
{
	local float bitflag;
	bitflag = 1;
	while(clientno > 0)
	{
		bitflag = bitflag * 2;
		clientno = clientno - 1;
	}
	return bitflag;
};

void(entity e1, entity e2, float flag) DeveloperLightning = {};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

BotConnect and related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/				
entity(float num) GetClientEntity =
{
	local entity upsy;
	upsy = world;
	num = num + 1;
	while (num > 0)
	{
		num = num - 1;
		upsy = nextent(upsy);
	}
	return upsy;
};

float(entity ent) GetClientNum =
{
	entity upsy;
	float	num;

	upsy = world;
	num = 0;
	while (ent != upsy)
	{
		num = num + 1;
		upsy = nextent(upsy);
	}

	return num;
};

void(float whatbot, float whatskill) BotConnect =
{
	entity bot;
	entity temp;

	temp = spawn();
	if (whatbot)
		temp.netname = BotName(temp, whatbot);
	else
		temp.netname = PickARandomName(temp);

	bot = testbot(temp.netname, "", temp.b_shirt, temp.b_pants);

	remove (temp);

	if (!bot)
	{
		bprint (PRINT_HIGH, "Unable to connect a bot, server is full.\n");
		return;
	}

	bot.ishuman = 0;

};

void(entity bot) BotDisconnect =
{
	bot_count = bot_count - 1;
};


void BotAI ();	// Tonik

void BotPreThink (entity self)
{
	frik_obstacles();
	CL_KeyMove();
	BotAI ();
}

void() BotFrame =
{
	local string h;
	
	h = infokey(world, "bot_options");
	b_options = stof(h);
	
	// for the sake of speed
	sv_gravity = cvar("sv_gravity");
};

/*
-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=

Client commands. Allow the player to perform bot
related functions.

-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=-=
*/

void Cmd_AddBot (string skill_s)
{
	float skill;

	if (skill_s != "")
		skill = stof(skill_s);
	else
		skill = 1;

	BotConnect (0, skill);
}

void Cmd_RemoveBot ()
{
	KickABot ();
}
