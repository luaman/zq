/*
Copyright (C) 1996-1997 Id Software, Inc.

This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  

See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

*/
// Spectator functions
// Added Aug11'97 by Zoid <zoid@idsoftware.com>
//
// These functions are called from the server if they exist.
// Note that Spectators only have one think since they movement code doesn't
// track them much.  Impulse commands work as usual, but don't call
// the regular ImpulseCommand handler in weapons.qc since Spectators don't
// have any weapons and things can explode.
//
//   --- Zoid.

//team
//shame about the fecking mess in the spectator code, ill structure the thing later (hopefully)
// /kK

void() ModStatus;
void() ModStatus2;
void() ModStatusVote;
void() PlayerStatus;
void() PlayerStatusN;
void() PlayerStatusS;
void() ShowVersion;
void() SMakeMOTD;
void() SShowCmds;
void() AdminImpBot;
void() ReqAdmin;
void() AdminForceStart;
void() AdminForceBreak;
void() AdminForcePause;
void() TogglePreWar;
void() ToggleMapLock;
void() ToggleMaster;
void() SelectMap;
void() ChangeDM;
void() ChangeTP;
void() TogglePowerups;
void() ToggleSpecTalk;
void(float t) TimeDown;
void(float t) TimeUp;
//void() ToggleQTimer;
void() ToggleQLag;
void() ToggleQEnemy;
void() ToggleQPoint;
void() ToggleRespawns;
void() ResetOptions;
void() ShowMaps;
void() PrintScores;
void() PlayerStats;
void() ChangeOvertime;
void() ChangeOvertimeUp;
void() SetOfficial;

void() TrackNext =
{
	local entity p;

	p = find(self.goalentity, classname, "player");
	while(p != world) {
		if(p != self && p.netname != "") {
			self.goalentity = p;
			return;
		}
		p = find(p, classname, "player");
	}
	p = find(world, classname, "player");
	while(p != world) {
		if(p != self && p.netname != "") {
			self.goalentity = p;
			return;
		}
		p = find(p, classname, "player");
	}
	if (p == world) {
		sprint(self, 2, "No target found ...\n");
		self.k_track = 2;
	}
};

void() TrackNext2 =
{
	local entity p;

	p = find(self.goalentity, classname, "info_intermission");
	if(p != world) {
		self.goalentity = p;
		return;
	}
	p = find(world, classname, "info_intermission");
	if(p != world) {
		self.goalentity = p;
		return;
	}
	sprint(self, 2, "No target found ...\n");
	self.k_track = 0;
};

void() ShowCamHelp =
{
	sprint(self, 2, "éíðõìóå ²µ next spawnpoint (floatcam)\néíðõìóå ²¶ change camera mode\néíðõìóå ²· zoom out (trackcam)\néíðõìóå ²¸ zoom in  (trackcam)\néíðõìóå ²¹ toggle statusbar (trackcam)\nuse [jump] to change target\n");
};
//team


/*
===========
SpectatorConnect

called when a spectator connects to a server
============
*/
void() SpectatorConnect =
{
	if(match_in_progress != 2 || stof(infokey(world, "k_ann"))) {	//team
		bprint (1, "Spectator ");
		bprint (1, self.netname);
		bprint (1, " entered the game\n");
	}
	self.goalentity = world; // used for impulse 25 below
	// Added this in for kick code.
	self.classname = "spectator";

//team
	SMakeMOTD();
	self.k_track = 0;
	self.ready = 0;		//used to check if admin stuffing has been performed
	self.k_666 = 40;		//zoom value default for trackcam
	self.suicide_time = 1;	//user for statusbar on/off checking
	self.k_domapstuff = 0;
	
	// Wait until you do stuffing

// added stuffing for numbers
	stuffcmd(self, "alias 1 \"impulse 1\"\nalias 2 \"impulse 2\"\nalias 3 \"impulse 3\"\nalias 4 \"impulse 4\"\nalias 5 \"impulse 5\"\nalias 6 \"impulse 6\"\nalias 7 \"impulse 7\"\nalias 8 \"impulse 8\"\nalias 9 \"impulse 9\"\n");
	stuffcmd(self, "alias 10 \"impulse 10\"\nalias 11 \"impulse 11\"\nalias 12 \"impulse 12\"\nalias 13 \"impulse 13\"\nalias 14 \"impulse 14\"\nalias 15 \"impulse 15\"\nalias 16 \"impulse 16\"\n");
// hope doesnt flood

	stuffcmd(self, "alias status \"impulse 22\"\n");
	stuffcmd(self, "alias cam \"impulse 23\"\n");
	stuffcmd(self, "alias join \"spectator 0; wait; wait; wait; reconnect\"\n");
	stuffcmd(self, "alias commands \"impulse 50\"\n");
	stuffcmd(self, "alias admin \"impulse 51\"\n");
	stuffcmd(self, "alias who \"impulse 56\"\n");
	stuffcmd(self, "alias about \"impulse 58\"\n");
	stuffcmd(self, "alias whoskin \"impulse 59\"\n");
	stuffcmd(self, "alias status2 \"impulse 64\"\n");
	stuffcmd(self, "alias scores \"impulse 74\"\n");
	stuffcmd(self, "alias whonot \"impulse 75\"\n");
	stuffcmd(self, "alias whovote \"impulse 77\"\n");
	stuffcmd(self, "alias stats \"impulse 87\"\n");
	stuffcmd(self, "alias elect \"impulse 92\"\n");

//team
	StuffMapAliases();
};

//team
void() SpectatorAdminGain =
{
	stuffcmd(self, "alias forcestart \"impulse 52\"\n");
	stuffcmd(self, "alias forcebreak \"impulse 53\"\n");
	stuffcmd(self, "alias lockmap \"impulse 54\"\n");


	stuffcmd(self, "alias prewar \"impulse 55\"\n");
	stuffcmd(self, "alias master \"impulse 57\"\n");
	stuffcmd(self, "alias dm \"impulse 60\"\n");
	stuffcmd(self, "alias tp \"impulse 61\"\n");
	stuffcmd(self, "alias powerups \"impulse 62\"\n");
	stuffcmd(self, "alias silence \"impulse 63\"\n");
	stuffcmd(self, "alias timeup \"impulse 65\"\n");
	stuffcmd(self, "alias timedown \"impulse 66\"\n");
	stuffcmd(self, "alias rpickup \"impulse 67\"\n");
	stuffcmd(self, "alias qlag \"impulse 68\"\n");
	stuffcmd(self, "alias qenemy \"impulse 69\"\n");
	stuffcmd(self, "alias spawn \"impulse 70\"\n");
	stuffcmd(self, "alias forcepause \"impulse 71\"\n");
	stuffcmd(self, "alias reset \"impulse 72\"\n");
	stuffcmd(self, "alias maps \"impulse 73\"\n");
	stuffcmd(self, "alias qpoint \"impulse 76\"\n");
// changed forcekick to kick
	stuffcmd(self, "alias kick \"impulse 83\"\n");
	stuffcmd(self, "alias overtime \"impulse 84\"\n");
	stuffcmd(self, "alias overtimeup \"impulse 85\"\n");
// added y/n
	stuffcmd(self, "alias y \"impulse 88\"\n");
	stuffcmd(self, "alias n \"impulse 89\"\n");
	stuffcmd(self, "alias deathmsg \"impulse 90\"\n");
	stuffcmd(self, "alias official \"impulse 91\"\n");

	self.ready = 1;
	
};
//team

/*
===========
SpectatorDisconnect

called when a spectator disconnects from a server
============
*/
void() SpectatorDisconnect =
{
	if(match_in_progress != 2 || stof(infokey(world, "k_ann"))) {	//team
		bprint (1, "Spectator ");
		bprint (1, self.netname);
		bprint (1, " left the game\n");
	}
	
	self.classname = string_null; // Cenobite, so we clear out any specs as they leave
	if(self.k_kicking) ExitKick(self);
};

/*
================
SpectatorImpulseCommand

Called by SpectatorThink if the spectator entered an impulse
================
*/
void() SpectatorImpulseCommand =
{
//team

// Check to see if you kicking first so Camera code doesnt take over

	if(self.k_track == 1 && (self.goalentity.classname != "player" || self.goalentity.netname == ""))
        {
            self.k_track = 0; // oldman: corrected assigment
        }

	if(self.k_admin == 1 && self.impulse >= 1 && self.impulse <=9) 
	{
		if(self.k_domapstuff ==0 )
		{
			local entity stuffem;
			
			stuffem = spawn();
			stuffem.classname = "StuffCustomMaps";
			stuffem.owner = self;
			stuffem.cnt = -1;
			stuffem.think = StuffCustomMaps;
			stuffem.nextthink = time + 0.1;

			self.k_domapstuff=1;
		}
		
		AdminImpBot();

		if(self.k_admin == 2 && !self.ready) SpectatorAdminGain();
		self.impulse = 0;
	} else if(self.impulse == 26) {
		self.goalentity = world;
		self.k_track = self.k_track + 1;
		if(self.k_track == 3) self.k_track = 0;
		if(self.k_track == 1) {
			if(self.goalentity == world) {
				TrackNext();
			}
			if(self.k_track == 1) {
				sprint(self, 2, "--- Trackcam ---");
				if(!self.suicide_time) sprint(self, 2, " : showing ", self.goalentity.netname, "\n");
				else sprint(self, 2, "\n");
				self.deaths = time; 	//.deaths is used for spectators as a counter for centerprinted stuff
			}
		} else if(self.k_track == 0) sprint(self, 2, "--- Floatcam ---\n");
		if(self.k_track == 2) {
			if(self.goalentity == world) {
				TrackNext2();
			}
			if(self.k_track) {
				sprint(self, 2, "--- Intermissioncam ---\n");
				self.deaths = time;
			}
		}
	} else if(self.impulse == 27 && self.k_track == 1) {
		if(self.k_666 < 60) {
			self.k_666 = self.k_666 + 10;
		}
	} else if(self.impulse == 28 && self.k_track == 1) {
		if(self.k_666 > -10) {
			self.k_666 = self.k_666 - 10;
		}
	} else if(self.impulse == 29) {
		self.suicide_time = self.suicide_time + 1;
		if(self.suicide_time == 3) self.suicide_time = 0;
		if(!self.suicide_time) {
			msg_entity = self;
			WriteByte(1, 26);
			WriteString(1, "\n");
		}
	} else if(self.impulse == 25 && !self.k_track) {
//team
		// teleport the spectator to the next spawn point
		// note that if the spectator is tracking, this doesn't do
		// much



		self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		if (self.goalentity == world)
			self.goalentity = find(self.goalentity, classname, "info_player_deathmatch");
		if (self.goalentity != world) {
			setorigin(self, self.goalentity.origin);
			self.angles = self.goalentity.angles;
			self.fixangle = 1;           // turn this way immediately
		}
	}
//team
	else if(self.impulse == 22) ModStatus();
	else if(self.impulse == 64) ModStatus2();
	else if(self.impulse == 74) PrintScores();
	else if(self.impulse == 23) ShowCamHelp();
	else if(self.impulse == 50) SShowCmds();
	else if(self.impulse == 51) ReqAdmin();
	else if(self.impulse == 56) PlayerStatus();
	else if(self.impulse == 58) ShowVersion();
	else if(self.impulse == 59) PlayerStatusS();
	else if(self.impulse == 75) PlayerStatusN();
	else if(self.impulse == 77) ModStatusVote();
	else if(self.impulse == 87) PlayerStats();
	else if(self.impulse == 92) VoteAdmin();

	else if(self.k_admin == 2) {
		if(self.impulse == 52) AdminForceStart();
		else if(self.impulse == 53) AdminForceBreak();
		else if(self.impulse == 54) ToggleMapLock();
		else if(self.impulse == 55) TogglePreWar();
		else if(self.impulse == 57) ToggleMaster();
		else if(self.impulse == 60) ChangeDM();
		else if(self.impulse == 61) ChangeTP();
		else if(self.impulse == 62) TogglePowerups();
		else if(self.impulse == 63) ToggleSpecTalk();
		else if(self.impulse == 65) TimeUp(5);
		else if(self.impulse == 66) TimeDown(5);
		else if(self.impulse == 67) RandomPickup();
		else if(self.impulse == 68) ToggleQLag();
		else if(self.impulse == 69) ToggleQEnemy();
		else if(self.impulse == 70) ToggleRespawns();
		else if(self.impulse == 71) AdminForcePause();
		else if(self.impulse == 72) ResetOptions();
		else if(self.impulse == 73) ShowMaps();
		else if(self.impulse == 76) ToggleQPoint();
		else if(self.impulse == 83) AdminKick();
		else if(self.impulse == 84) ChangeOvertime();
		else if(self.impulse == 85) ChangeOvertimeUp();
		else if(self.impulse == 88) YesKick();
		else if(self.impulse == 89) DontKick();
		else if(self.impulse == 90) Deathmsg();
		else if(self.impulse == 91) SetOfficial();

		else if(self.impulse >= 100 && !match_in_progress) SelectMap();
	}
//team
	self.impulse = 0;
};

/*
================
SpectatorThink

Called every frame after physics are run
================
*/
void() SpectatorThink =
{
//team
	local float f1, f2, f3;
	local entity p;
	local vector v1;

	self.effects = self.goalentity.effects;
//team

	// self.origin, etc contains spectator position, so you could
	// do some neat stuff here

	if(self.impulse)
		SpectatorImpulseCommand();

//team
	if(self.button2 && !self.jump_flag && self.k_track) {
		if(self.k_track == 1) {
			TrackNext();
			if(!self.suicide_time && self.k_track == 1) sprint(self, 2, "--- Tracking ", self.goalentity.netname, "\n");
		}
		else TrackNext2();
		self.jump_flag = 1;
	}
	if(!self.button2) self.jump_flag = 0;
	if(self.k_track == 1) {
		makevectors(self.goalentity.angles);
		//if someone should want to edit this code; - traceline takes the following parameters:
		//1: trace start position, 2: trace end position, 3: 1 = don't stop at entities : 0 = stop on first entity
		//4: take no notice of this entity (usually self)
		// /kemiKal
		if(self.k_666 != -10) {
			traceline(self.goalentity.origin, self.goalentity.origin - (v_forward * (self.k_666 - 4)), 1, self);
			if(trace_fraction < 1) trace_endpos = trace_endpos + (v_forward * 4);
			v1 = trace_endpos;
			traceline(v1, v1 + (v_up * 32), 1, self);
			if(trace_fraction == 1) {
				traceline(v1, v1 + (v_up * 0.4 * (self.k_666 + 10)), 1, self);
				if(trace_fraction < 1) trace_endpos = trace_endpos - (v_up * 4);
				setorigin(self, trace_endpos);
			} else setorigin(self, v1);
		} else {
			traceline(self.goalentity.origin, self.goalentity.origin + (v_forward * 14), 1, self);
			if(trace_fraction < 1) trace_endpos = trace_endpos - (v_forward * 4);
			setorigin(self, trace_endpos);
		}
		self.angles = self.v_angle = self.goalentity.v_angle;
		self.fixangle = 1;
		if(time > self.deaths && self.suicide_time && match_in_progress != 1)
		{
			msg_entity = self;

		WriteByte(1, 26);
			WriteShort(1, 2592);
			WriteShort(1, 2570);
			WriteShort(1, 2570);
			WriteShort(1, 2570);
			WriteShort(1, 2570);
			WriteShort(1, 2570);
			if(self.suicide_time == 2) {



			WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);

			WriteShort(1, 2570);
				WriteShort(1, 2570);

				WriteShort(1, 2570);
				WriteShort(1, 2570);
			}
			//"health xxx "
			WriteShort(1, 58856);
			WriteShort(1, 60641);
			WriteShort(1, 59636);
			WriteByte(1, 32);
			f1 = self.goalentity.health;
			if(f1 > 0 ) {
				f3 = floor(f1 / 100);
				f1 = f1 - (f3 * 100);
				if(f3) WriteByte(1, f3 + 48);
				else WriteByte(1, 32);
				f2 = floor(f1 / 10);
				f1 = f1 - (f2 * 10);
				if(f2 || f3) WriteByte(1, f2 + 48);
				else WriteByte(1, 32);
				WriteByte(1, f1 + 48);
				WriteByte(1, 32);
			} else {
			//"dead"
				WriteShort(1, 25956);
				WriteShort(1, 25697);
			}
			f1 = self.goalentity.armorvalue;
			if(f1 > 0) {
				WriteByte(1, 32);
				if(self.goalentity.items & 8192) {
					//" green armor "
					WriteByte(1, 32);
					WriteShort(1, 62183);
					WriteShort(1, 58853);
					WriteShort(1, 41198);
					WriteShort(1, 62177);
					WriteShort(1, 61421);
					WriteShort(1, 41202);
				} else if(self.goalentity.items & 16384) {
					//"yellow armor "
					WriteShort(1, 58873);
					WriteShort(1, 60652);
					WriteShort(1, 63471);
					WriteShort(1, 57760);
					WriteShort(1, 60914);
					WriteShort(1, 62191);
					WriteByte(1, 32);
				} else {
					//"   red armor "
					WriteByte(1, 32);
					WriteShort(1, 8224);
					WriteShort(1, 58866);
					WriteShort(1, 41188);
					WriteShort(1, 62177);
					WriteShort(1, 61421);
					WriteShort(1, 41202);
				}
				f3 = floor(f1 / 100);
				f1 = f1 - (f3 * 100);
				if(f3) WriteByte(1, f3 + 48);
				else WriteByte(1, 32);
				f2 = floor(f1 / 10);
				f1 = f1 - (f2 * 10);
				if(f2 || f3) WriteByte(1, f2 + 48);
				else WriteByte(1, 32);
				WriteByte(1, f1 + 48);
				WriteByte(1, 32);
			}
			WriteByte(1, 10);
			WriteString(1, self.goalentity.netname);
			self.deaths = time + 0.5;
		}
	} else if(self.k_track == 2) {
		makevectors(self.goalentity.angles);
		setorigin(self, self.goalentity.origin);
		self.angles = self.v_angle = self.goalentity.mangle;
		self.fixangle = 1;
		if(time > self.deaths && match_in_progress != 1)
		{
			p = find(world, classname, "timer");
			if(p != world) {
				msg_entity = self;
				WriteByte(1, 26);
				WriteShort(1, 2592);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				WriteShort(1, 2570);
				f1 = p.cnt;
				f2 = p.cnt2;
				if(f2 == 60) f2 = 0;
				else f1 = f1 - 1;
				f3 = floor(f1 / 10);
				f1 = f1 - (f3 * 10);
				WriteByte(1, f3 + 176);
				WriteByte(1, f1 + 176);
				WriteByte(1, 58);
				f3 = floor(f2 / 10);
				f2 = f2 - (f3 * 10);
				WriteByte(1, f3 + 176);
				WriteByte(1, f2 + 176);
				WriteByte(1, 0);
			}
			self.deaths = time + 0.5;
		}
	}
//team
};
