/*
	teamplay.c

	Teamplay enhancements

	Copyright (C) 2000-2001       Anton Gavrilov

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

#include "quakedef.h"
#include "version.h"
#include "pmove.h"

cvar_t	cl_parseSay = {"cl_parseSay", "0"};
cvar_t	cl_parseFunChars = {"cl_parseFunChars", "1"};
cvar_t	cl_triggers = {"cl_triggers", "0"};
cvar_t	tp_forceTriggers = {"tp_forceTriggers", "0"};
cvar_t	cl_nofake = {"cl_nofake", "0"};
cvar_t	cl_loadlocs = {"cl_loadlocs", "0"};
cvar_t	cl_mapname = {"mapname", "", CVAR_ROM};
cvar_t	cl_rocket2grenade = {"cl_r2g", "0"};

cvar_t	cl_teamskin = {"teamskin", ""};
cvar_t	cl_enemyskin = {"enemyskin", ""};

cvar_t	tp_name_axe = {"tp_name_axe", "axe"};
cvar_t	tp_name_sg = {"tp_name_sg", "sg"};
cvar_t	tp_name_ssg = {"tp_name_ssg", "ssg"};
cvar_t	tp_name_ng = {"tp_name_ng", "ng"};
cvar_t	tp_name_sng = {"tp_name_sng", "sng"};
cvar_t	tp_name_gl = {"tp_name_gl", "gl"};
cvar_t	tp_name_rl = {"tp_name_rl", "rl"};
cvar_t	tp_name_lg = {"tp_name_lg", "lg"};
cvar_t	tp_name_ra = {"tp_name_ra", "ra"};
cvar_t	tp_name_ya = {"tp_name_ya", "ya"};
cvar_t	tp_name_ga = {"tp_name_ga", "ga"};
cvar_t	tp_name_quad = {"tp_name_quad", "quad"};
cvar_t	tp_name_pent = {"tp_name_pent", "pent"};
cvar_t	tp_name_ring = {"tp_name_ring", "ring"};
cvar_t	tp_name_suit = {"tp_name_suit", "suit"};
cvar_t	tp_name_shells = {"tp_name_shells", "shells"};
cvar_t	tp_name_nails = {"tp_name_nails", "nails"};
cvar_t	tp_name_rockets = {"tp_name_rockets", "rockets"};
cvar_t	tp_name_cells = {"tp_name_cells", "cells"};
cvar_t	tp_name_mh = {"tp_name_mh", "mega"};
cvar_t	tp_name_health = {"tp_name_health", "health"};
cvar_t	tp_name_backpack = {"tp_name_backpack", "pack"};
cvar_t	tp_name_flag = {"tp_name_flag", "flag"};
cvar_t	tp_name_nothing = {"tp_name_nothing", "nothing"};
cvar_t	tp_name_someplace = {"tp_name_someplace", "someplace"};
cvar_t	tp_name_at = {"tp_name_at", "at"};

void TP_FindModelNumbers (void);
void TP_FindPoint (void);
char *TP_LocationName (vec3_t location);
extern int parsecountmod;


#define MAX_LOC_NAME 48

// this structure is cleared after entering a new map
typedef struct tvars_s {
	int		health;
	int		items;
	float	respawntrigger_time;
	float	deathtrigger_time;
	float	f_version_reply_time;
	char	lastdeathloc[MAX_LOC_NAME];
	char	tookname[32];
	char	tookloc[MAX_LOC_NAME];
	float	tooktime;
	int		pointframe;		// host_framecount for which pointitem&pointloc are valid
	char	pointname[32];
	char	pointloc[MAX_LOC_NAME];
} tvars_t;

tvars_t vars;

//===========================================================================
//								TRIGGERS
//===========================================================================

void TP_ExecTrigger (char *s)
{
	if (!cl_triggers.value || cls.demoplayback)
		return;

	if (Cmd_FindAlias(s))
	{
		char *astr, *p;
		qboolean quote = false;

		astr = Cmd_AliasString (s);
		for (p=astr ; *p ; p++)
		{
			if (*p == '"')
				quote = !quote;
			if (!quote && *p == ';')
			{
				// more than one command, add it to the command buffer
				Cbuf_AddText (astr);
				Cbuf_AddText ("\n");
				return;
			}
		}
		// a single line, so execute it right away
		Cmd_ExecuteString (astr);
		return;
	}
}


/*
==========================================================================
						        MACRO FUNCTIONS
==========================================================================
*/

#define MAX_MACRO_VALUE	256
static char	macro_buf[MAX_MACRO_VALUE] = "";

char *Macro_Quote_f (void)
{
	return "\"";
}

char *Macro_Health_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_HEALTH]);
	return macro_buf;
}

char *Macro_Armor_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_ARMOR]);
	return macro_buf;
}

char *Macro_Shells_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_SHELLS]);
	return macro_buf;
}

char *Macro_Nails_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_NAILS]);
	return macro_buf;
}

char *Macro_Rockets_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_ROCKETS]);
	return macro_buf;
}

char *Macro_Cells_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_CELLS]);
	return macro_buf;
}

char *Macro_Ammo_f (void)
{
	sprintf(macro_buf, "%i", cl.stats[STAT_AMMO]);
	return macro_buf;
}

char *Macro_Weapon_f (void)
{
	switch (cl.stats[STAT_ACTIVEWEAPON])
	{
	case IT_AXE: return "axe";
	case IT_SHOTGUN: return "sg";
	case IT_SUPER_SHOTGUN: return "ssg";
	case IT_NAILGUN: return "ng";
	case IT_SUPER_NAILGUN: return "sng";
	case IT_GRENADE_LAUNCHER: return "gl";
	case IT_ROCKET_LAUNCHER: return "rl";
	case IT_LIGHTNING: return "lg";
	default:
		return "";
	}
}

char *Macro_WeaponNum_f (void)
{
	switch (cl.stats[STAT_ACTIVEWEAPON])
	{
	case IT_AXE: return "1";
	case IT_SHOTGUN: return "2";
	case IT_SUPER_SHOTGUN: return "3";
	case IT_NAILGUN: return "4";
	case IT_SUPER_NAILGUN: return "5";
	case IT_GRENADE_LAUNCHER: return "6";
	case IT_ROCKET_LAUNCHER: return "7";
	case IT_LIGHTNING: return "8";
	default:
		return "0";
	}
}

int	_Macro_BestWeapon (void)
{
	int	best;

	best = 0;
	if (cl.stats[STAT_ITEMS] & IT_AXE)
		best = IT_AXE;
	if (cl.stats[STAT_ITEMS] & IT_SHOTGUN && cl.stats[STAT_SHELLS] >= 1)
		best = IT_SHOTGUN;
	if (cl.stats[STAT_ITEMS] & IT_SUPER_SHOTGUN && cl.stats[STAT_SHELLS] >= 2)
		best = IT_SUPER_SHOTGUN;
	if (cl.stats[STAT_ITEMS] & IT_NAILGUN && cl.stats[STAT_NAILS] >= 1)
		best = IT_NAILGUN;
	if (cl.stats[STAT_ITEMS] & IT_SUPER_NAILGUN && cl.stats[STAT_NAILS] >= 2)
		best = IT_SUPER_NAILGUN;
	if (cl.stats[STAT_ITEMS] & IT_GRENADE_LAUNCHER && cl.stats[STAT_ROCKETS] >= 1)
		best = IT_GRENADE_LAUNCHER;
	if (cl.stats[STAT_ITEMS] & IT_LIGHTNING && cl.stats[STAT_CELLS] >= 1)
		best = IT_LIGHTNING;
	if (cl.stats[STAT_ITEMS] & IT_ROCKET_LAUNCHER && cl.stats[STAT_ROCKETS] >= 1)
		best = IT_ROCKET_LAUNCHER;

	return best;
}

char *Macro_BestWeapon_f (void)
{
	switch (_Macro_BestWeapon())
	{
	case IT_AXE: return "axe";
	case IT_SHOTGUN: return "sg";
	case IT_SUPER_SHOTGUN: return "ssg";
	case IT_NAILGUN: return "ng";
	case IT_SUPER_NAILGUN: return "sng";
	case IT_GRENADE_LAUNCHER: return "gl";
	case IT_ROCKET_LAUNCHER: return "rl";
	case IT_LIGHTNING: return "lg";
	default:
		return "";
	}
}

char *Macro_BestAmmo_f (void)
{
	switch (_Macro_BestWeapon())
	{
	case IT_SHOTGUN: case IT_SUPER_SHOTGUN: 
		sprintf(macro_buf, "%i", cl.stats[STAT_SHELLS]);
		return macro_buf;

	case IT_NAILGUN: case IT_SUPER_NAILGUN:
		sprintf(macro_buf, "%i", cl.stats[STAT_NAILS]);
		return macro_buf;

	case IT_GRENADE_LAUNCHER: case IT_ROCKET_LAUNCHER:
		sprintf(macro_buf, "%i", cl.stats[STAT_ROCKETS]);
		return macro_buf;

	case IT_LIGHTNING:
		sprintf(macro_buf, "%i", cl.stats[STAT_CELLS]);
		return macro_buf;

	default:
		return "0";
	}
}

// needed for %b parsing
char *Macro_BestWeaponAndAmmo_f (void)
{
	char buf[MAX_MACRO_VALUE];
	sprintf (buf, "%s:%s", Macro_BestWeapon_f(), Macro_BestAmmo_f());
	strcpy (macro_buf, buf);
	return macro_buf;
}

char *Macro_ArmorType_f (void)
{
	if (cl.stats[STAT_ITEMS] & IT_ARMOR1)
		return "g";
	else if (cl.stats[STAT_ITEMS] & IT_ARMOR2)
		return "y";
	else if (cl.stats[STAT_ITEMS] & IT_ARMOR3)
		return "r";
	else
		return "";	// no armor at all
}

char *Macro_Powerups_f (void)
{
	int effects;

	macro_buf[0] = 0;

	if (cl.stats[STAT_ITEMS] & IT_QUAD)
		strcpy(macro_buf, "quad");

	if (cl.stats[STAT_ITEMS] & IT_INVULNERABILITY) {
		if (macro_buf[0])
			strcat(macro_buf, "/");
		strcat(macro_buf, "pent");
	}

	if (cl.stats[STAT_ITEMS] & IT_INVISIBILITY) {
		if (macro_buf[0])
			strcat(macro_buf, "/");
		strcat(macro_buf, "ring");
	}

	effects = cl.frames[cl.parsecount&UPDATE_MASK].playerstate[cl.playernum].effects;
	if ( (effects & (EF_FLAG1|EF_FLAG2)) ||		// CTF
		(cl.teamfortress && cl.stats[STAT_ITEMS] & (IT_KEY1|IT_KEY2)) ) // TF
	{
		if (macro_buf[0])
			strcat(macro_buf, "/");
		strcat(macro_buf, "flag");
	}

	return macro_buf;
}

char *Macro_Location_f (void)
{
	return TP_LocationName (cl.frames[parsecountmod].playerstate[cl.playernum].origin);
}

char *Macro_LastDeath_f (void)
{
	if (vars.deathtrigger_time)
		return vars.lastdeathloc;
	else
		return tp_name_someplace.string;
}

char *Macro_Location2_f (void)
{
	if (vars.deathtrigger_time && realtime - vars.deathtrigger_time <= 5)
		return vars.lastdeathloc;
	return Macro_Location_f();
}

char *Macro_Time_f (void)
{
	time_t		t;
	struct tm	*ptm;

	time (&t);
	ptm = localtime (&t);
	strftime (macro_buf, sizeof(macro_buf)-1, "%H:%M", ptm);
	return macro_buf;
}

char *Macro_Date_f (void)
{
	time_t		t;
	struct tm	*ptm;

	time (&t);
	ptm = localtime (&t);
	strftime (macro_buf, sizeof(macro_buf)-1, "%d.%m.%y", ptm);
	return macro_buf;
}

// returns the last item picked up
char *Macro_Took_f (void)
{
	if (!vars.tooktime || realtime > vars.tooktime + 20)
		strncpy (macro_buf, tp_name_nothing.string, sizeof(macro_buf)-1);
	else
		strcpy (macro_buf, vars.tookname);
	return macro_buf;
}

// returns location of the last item picked up
char *Macro_TookLoc_f (void)
{
	if (!vars.tooktime || realtime > vars.tooktime + 20)
		strncpy (macro_buf, tp_name_someplace.string, sizeof(macro_buf)-1);
	else
		strcpy (macro_buf, vars.tookloc);
	return macro_buf;
}


// %i macro - last item picked up in "name at location" style
char *Macro_TookAtLoc_f (void)
{
	if (!vars.tooktime || realtime > vars.tooktime + 20)
		strncpy (macro_buf, tp_name_nothing.string, sizeof(macro_buf)-1);
	else {
		strncpy (macro_buf, va("%s %s %s", vars.tookname,
			tp_name_at.string, vars.tookloc), sizeof(macro_buf)-1);
	}
	return macro_buf;
}

// pointing calculations are CPU expensive, so the results are cached
// in vars.pointname & vars.pointloc
char *Macro_PointName_f (void)
{
	if (host_framecount != vars.pointframe)
		TP_FindPoint ();
	return vars.pointname;
}

char *Macro_PointLocation_f (void)
{
	if (host_framecount != vars.pointframe)
		TP_FindPoint ();
	if (vars.pointloc[0])
		return vars.pointloc;
	else
		return tp_name_someplace.string;
}

char *Macro_PointNameAtLocation_f (void)
{
	if (host_framecount != vars.pointframe)
		TP_FindPoint ();
	if (vars.pointloc[0])
		return va ("%s %s %s", vars.pointname, tp_name_at.string, vars.pointloc);
	else
		return vars.pointname;
}


typedef struct
{
	char	*name;
	char	*(*func) (void);
} macro_command_t;

// Note: longer macro names like "armortype" must be defined
// _before_ the shorter ones like "armor" to be parsed properly
macro_command_t macro_commands[] =
{
	{"qt", Macro_Quote_f},
	{"health", Macro_Health_f},
	{"armortype", Macro_ArmorType_f},
	{"armor", Macro_Armor_f},
	{"shells", Macro_Shells_f},
	{"nails", Macro_Nails_f},
	{"rockets", Macro_Rockets_f},
	{"cells", Macro_Cells_f},
	{"weaponnum", Macro_WeaponNum_f},
	{"weapon", Macro_Weapon_f},
	{"ammo", Macro_Ammo_f},
	{"bestweapon", Macro_BestWeapon_f},
	{"bestammo", Macro_BestAmmo_f},
	{"powerups", Macro_Powerups_f},
	{"location", Macro_Location_f},
	{"deathloc", Macro_LastDeath_f},
	{"time", Macro_Time_f},
	{"date", Macro_Date_f},
	{"tookatloc", Macro_TookAtLoc_f},
	{"tookloc", Macro_TookLoc_f},
	{"took", Macro_Took_f},
	{NULL, NULL}
};

#define MAX_MACRO_STRING 1024

/*
==============
TP_MacroString

returns NULL if no matching macro was found
==============
*/
int macro_length;	// length of macro name

char *TP_MacroString (char *s)
{
	static char	buf[MAX_MACRO_STRING];
	macro_command_t	*macro;

	macro = macro_commands;
	while (macro->name) {
		if (!Q_strncasecmp(s, macro->name, strlen(macro->name)))
		{
			macro_length = strlen(macro->name);
			return macro->func();
		}
		macro++;
	}

	macro_length = 0;
	return NULL;
}

/*
=============
TP_ParseChatString

Parses %a-like expressions
=============
*/
char *TP_ParseMacroString (char *s)
{
	static char	buf[MAX_MACRO_STRING];
	int		i = 0;
	char	*macro_string;

	if (!cl_parseSay.value)
		return s;

	while (*s && i < MAX_MACRO_STRING-1)
	{
		// check %[P], etc
		if (*s == '%' && s[1]=='[' && s[2] && s[3]==']')
		{
			static char mbuf[MAX_MACRO_VALUE];
			switch (s[2]) {
			case 'a':
				macro_string = Macro_ArmorType_f();
				if (!macro_string[0])
					macro_string = "a";
				if (cl.stats[STAT_ARMOR] < 30)
					sprintf (mbuf, "\x10%s:%i\x11", macro_string, cl.stats[STAT_ARMOR]);
				else
					sprintf (mbuf, "%s:%i", macro_string, cl.stats[STAT_ARMOR]);
				macro_string = mbuf;
				break;
				
			case 'h':
				if (cl.stats[STAT_HEALTH] >= 50)
					sprintf (macro_buf, "%i", cl.stats[STAT_HEALTH]);
				else
					sprintf (macro_buf, "\x10%i\x11", cl.stats[STAT_HEALTH]);
				macro_string = macro_buf;
				break;
				
			case 'P':
				macro_string = Macro_Powerups_f();
				if (macro_string[0])
					sprintf (mbuf, "\x10%s\x11", macro_string);
				else
					mbuf[0] = 0;
				macro_string = mbuf;
				break;
				
				// todo: %[w], %[b]
				
			default:
				buf[i++] = *s++;
				continue;
			}
			if (i + strlen(macro_string) >= MAX_MACRO_STRING-1)
				Sys_Error("TP_ParseMacroString: macro string length > MAX_MACRO_STRING)");
			strcpy (&buf[i], macro_string);
			i += strlen(macro_string);
			s += 4;	// skip %[<char>]
			continue;
		}
		
		// check %a, etc
		if (*s == '%')
		{
			switch (s[1])
			{
				case 'a': macro_string = Macro_Armor_f(); break;
				case 'A': macro_string = Macro_ArmorType_f(); break;
				case 'b': macro_string = Macro_BestWeaponAndAmmo_f(); break;
				case 'c': macro_string = Macro_Cells_f(); break;
				case 'd': macro_string = Macro_LastDeath_f(); break;
				case 'h': macro_string = Macro_Health_f(); break;
				case 'i': macro_string = Macro_TookAtLoc_f(); break;
				case 'l': macro_string = Macro_Location_f(); break;
				case 'L': macro_string = Macro_Location2_f(); break;
				case 'P':
				case 'p': macro_string = Macro_Powerups_f(); break;
				case 'r': macro_string = Macro_Rockets_f(); break;
				case 'w': macro_string = Macro_Weapon_f(); break;
				case 'W': macro_string = Macro_Ammo_f(); break;
				case 'x': macro_string = Macro_PointName_f(); break;
				case 'y': macro_string = Macro_PointLocation_f(); break;
				case 't': macro_string = Macro_PointNameAtLocation_f(); break;
				default: 
					buf[i++] = *s++;
					continue;
			}
			if (i + strlen(macro_string) >= MAX_MACRO_STRING-1)
				Sys_Error("TP_ParseMacroString: macro string length > MAX_MACRO_STRING)");
			strcpy (&buf[i], macro_string);
			i += strlen(macro_string);
			s += 2;	// skip % and letter
			continue;
		}

		buf[i++] = *s++;
	}
	buf[i] = 0;

	return buf;
}

/*
==============
TP_ParseFunChars

Doesn't check for overflows, so strlen(s) should be < MAX_MACRO_STRING
==============
*/
char *TP_ParseFunChars (char *s)
{
	static char	buf[MAX_MACRO_STRING];
	char	*out = buf;
	char	c;

	if (!cl_parseFunChars.value)
		return s;

	while (*s) {
		if (*s == '$' && s[1] == 'x') {
			int i;
			// check for $x10, $x8a, etc
			c = tolower(s[2]);
			if (c >= '0' && c <= '9')
				i = (c - '0') << 4;
			else if (c >= 'a' && c <= 'f')
				i = (c - 'a' + 10) << 4;
			else goto skip;
			c = tolower(s[3]);
			if (c >= '0' && c <= '9')
				i += (c - '0');
			else if (c >= 'a' && c <= 'f')
				i += (c - 'a' + 10);
			else goto skip;
			if (!i)
				i = ' ';
			*out++ = i;
			s += 4;
			continue;
		}
		if (*s == '$' && s[1]) {
			c = 0;
			switch (s[1]) {
				case '\\': c = 0x0D; break;
				case ':': c = 0x0A; break;
				case '[': c = 0x10; break;
				case ']': c = 0x11; break;
				case 'G': c = 0x86; break;
				case 'R': c = 0x87; break;
				case 'Y': c = 0x88; break;
				case 'B': c = 0x89; break;
				case '(': c = 0x80; break;
				case '=': c = 0x81; break;
				case ')': c = 0x82; break;
				case 'a': c = 0x83; break;
				case '<': c = 0x1d; break;
				case '-': c = 0x1e; break;
				case '>': c = 0x1f; break;
				case ',': c = 0x1c; break;
				case '.': c = 0x9c; break;
				case 'b': c = 0x8b; break;
				case 'c': c = 0x8d; break;
				case '$': c = '$'; break;
				case '^': c = '^'; break;
			}
			if (s[1] >= '0' && s[1] <= '9')
				c = s[1] - '0' + 0x12;
			if (c) {
				*out++ = c;
				s += 2;
				continue;
			}
		}
		if (*s == '^' && s[1] && s[1] != ' ') {
			*out++ = s[1] | 128;
			s += 2;
			continue;
		}
skip:			
		*out++ = *s++;
	}
	*out = 0;

	return buf;
}

/*
==============
TP_MacroList
==============
*/
void TP_MacroList_f (void)
{
	macro_command_t	*macro;
	int	i;

	for (macro=macro_commands,i=0 ; macro->name ; macro++,i++)
		Con_Printf ("%s\n", macro->name);

	Con_Printf ("------------\n%d macros\n", i);
}

/*
=============================================================================

							PROXY .LOC FILES

=============================================================================
*/

typedef struct locdata_s {
	vec3_t coord;
	char name[MAX_LOC_NAME];
} locdata_t;

#define MAX_LOC_ENTRIES 1024

locdata_t locdata[MAX_LOC_ENTRIES];	// FIXME: allocate dynamically?
int	loc_numentries;

#define SKIPBLANKS(ptr) while (*ptr == ' ' || *ptr == 9 || *ptr == 13) ptr++
#define SKIPTOEOL(ptr) while (*ptr != 10 && *ptr == 0) ptr++

void TP_LoadLocFile (char *path, qboolean quiet)
{
	char	*buf, *p;
	int		i, n, sign;
	int		line;
	int		nameindex;
	int		mark;
	char	locname[MAX_OSPATH];

	if (!*path)
		return;

	strcpy (locname, "locs/");
	if (strlen(path) + strlen(locname) + 2+4 > MAX_OSPATH)
	{
		Con_Printf ("TP_LoadLocFile: path name > MAX_OSPATH\n");
		return;
	}
	strcat (locname, path);
	if (!strstr(locname, "."))	
		strcat (locname, ".loc");	// Add default extension

	mark = Hunk_LowMark ();
	buf = (char *) COM_LoadHunkFile (locname);

	if (!buf)
	{
		if (!quiet)
			Con_Printf ("Could not load %s\n", locname);
		return;
	}

// Parse the whole file now

	loc_numentries = 0;

	p = buf;
	line = 1;

	while (1)
	{
		SKIPBLANKS(p);

		if (*p == 0)
			goto _endoffile;

		if (*p == 10 || (*p == '/' && p[1] == '/'))
		{
			p++;
			goto _endofline;
		}

		// parse three ints
		for (i = 0; i < 3; i++)
		{
			n = 0;
			sign = 1;
			while (1)
			{
				switch (*p++)
				{
				case ' ': case 9:
					goto _next;

				case '-':
					if (n)
					{
						Con_Printf ("Error in loc file on line #%i\n", line);
						SKIPTOEOL(p);		
						goto _endofline;
					}
					sign = -1;
					break;

				case '0': case '1': case '2': case '3': case '4':
				case '5': case '6': case '7': case '8': case '9':
					n = n*10 + (p[-1] - '0');
					break;

				default:	// including eol or eof
					Con_Printf ("Error in loc file on line #%i\n", line);
					SKIPTOEOL(p);		
					goto _endofline;
				}
			}
_next:
			n *= sign;
			locdata[loc_numentries].coord[i] = n / 8.0;

			SKIPBLANKS(p);
		}


		// parse location name

		nameindex = 0;
		while (1)
		{
			switch (*p)
			{
			case 13:
				p++;
				break;

			case 10: case 0:
				locdata[loc_numentries].name[nameindex] = 0;
				loc_numentries++;

				if (loc_numentries >= MAX_LOC_ENTRIES)
					goto _endoffile;

				// leave the 0 or 10 in buffer, so it is parsed properly
				goto _endofline;

			default:
				if (nameindex < MAX_LOC_NAME-1)
					locdata[loc_numentries].name[nameindex++] = *p;
				p++;
			}
		}
_endofline:
		line++;
	}
_endoffile:

	Hunk_FreeToLowMark (mark);

	if (quiet)
		Con_Printf ("Loaded %s\n", locname);
	else
		Con_Printf ("Loaded %s (%i locations)\n", locname, loc_numentries);
}

void TP_LoadLocFile_f (void)
{
	if (Cmd_Argc() != 2)
	{
		Con_Printf ("loadloc <filename> : load a loc file\n");
		return;
	}

	TP_LoadLocFile (Cmd_Argv(1), false);
}

char *TP_LocationName (vec3_t location)
{
	int		i, minnum;
	float	dist, mindist;
	vec3_t	vec;
	
	if (!loc_numentries || (cls.state != ca_active))
		return tp_name_someplace.string;

	minnum = 0;
	mindist = 9999999;

	for (i = 0; i < loc_numentries; i++) {
		VectorSubtract (location, locdata[i].coord, vec);
		dist = Length (vec);
		if (dist < mindist) {
			minnum = i;
			mindist = dist;
		}
	}

	return locdata[minnum].name;
}

/*
=============================================================================

							MESSAGE TRIGGERS

=============================================================================
*/

typedef struct msg_trigger_s {
	char	name[32];
	char	string[64];
	int		level;
	struct msg_trigger_s *next;
} msg_trigger_t;

static msg_trigger_t *msg_triggers;

msg_trigger_t *TP_FindTrigger (char *name)
{
	msg_trigger_t *t;

	for (t=msg_triggers; t; t=t->next)
		if (!strcmp(t->name, name))
			return t;

	return NULL;
}


void TP_MsgTrigger_f (void)
{
	int		c;
	char	*name;
	msg_trigger_t	*trig;

	c = Cmd_Argc();

	if (c > 5) {
		Con_Printf ("msg_trigger <trigger name> \"string\" [-l <level>]\n");
		return;
	}

	if (c == 1) {
		if (!msg_triggers)
			Con_Printf ("no triggers defined\n");
		else
		for (trig=msg_triggers; trig; trig=trig->next)
			Con_Printf ("%s : \"%s\"\n", trig->name, trig->string);
		return;
	}

	name = Cmd_Argv(1);
	if (strlen(name) > 31) {
		Con_Printf ("trigger name too long\n");
		return;
	}

	if (c == 2) {
		trig = TP_FindTrigger (name);
		if (trig)
			Con_Printf ("%s: \"%s\"\n", trig->name, trig->string);
		else
			Con_Printf ("trigger \"%s\" not found\n", name);
		return;
	}

	if (c >= 3) {
		if (strlen(Cmd_Argv(2)) > 63) {
			Con_Printf ("trigger string too long\n");
			return;
		}
		
		trig = TP_FindTrigger (name);

		if (!trig) {
			// allocate new trigger
			trig = Z_Malloc (sizeof(msg_trigger_t));
			trig->next = msg_triggers;
			msg_triggers = trig;
			strcpy (trig->name, name);
			trig->level = PRINT_HIGH;
		}

		strcpy (trig->string, Cmd_Argv(2));
		if (c == 5 && !Q_strcasecmp (Cmd_Argv(3), "-l")) {
			trig->level = Q_atoi (Cmd_Argv(4));
			if ((unsigned)trig->level > PRINT_CHAT)
				trig->level = PRINT_HIGH;
		}
	}
}

char *trigger_commands[] = {
	"play",
	"playvol",
	"stopsound",
	"set",
	"echo",
	"say",
	"say_team",
	"alias",
	"unalias",
	"msg_trigger",
	"inc",
	"bind",
	"unbind",
	"record",
	"easyrecord",
	"stop"
	"if"
};

#define NUM_TRIGGER_COMMANDS (sizeof(trigger_commands)/sizeof(trigger_commands[0]))

void TP_ExecuteTriggerString (char *text)
{
	static char	buf[1024];
	char	*arg0;
	int		i;
	cmd_function_t	*cmd;

	Cmd_ExpandString (text, buf);
	Cmd_TokenizeString (buf);
			
	if (!Cmd_Argc())
		return;		// no tokens

// check cvars
	if (Cvar_Command())
		return;

// check commands
	arg0 = Cmd_Argv(0);

	for (i=0; i < NUM_TRIGGER_COMMANDS ; i++)
		if (!Q_strcasecmp(arg0, trigger_commands[i]))
		{
			cmd = Cmd_FindCommand (arg0);
			if (cmd) {
				if (!cmd->function)
					Cmd_ForwardToServer ();
				else
					cmd->function ();
				return;
			}
		}

	if (cl_warncmd.value || developer.value)
		Con_Printf ("Invalid trigger command: \"%s\"\n", arg0);
}


void TP_ExecuteTriggerBuf (char *text)
{
	char	line[1024];
	int		i, quotes;

	while (*text)
	{
		quotes = 0;
		for (i=0 ; text[i] ; i++)
		{
			if (text[i] == '"')
				quotes++;
			if ( !(quotes&1) &&  text[i] == ';' )
				break;	// don't break if inside a quoted string
			if (text[i] == '\n')
				break;
		}
		memcpy (line, text, i);
		line[i] = 0;
		TP_ExecuteTriggerString (line);
		if (!text[i])
			break;
		text += i + 1;
	}
}

void TP_SearchForMsgTriggers (char *s, int level)
{
	msg_trigger_t	*t;
	char *string;

	if (cls.demoplayback)
		return;

	for (t=msg_triggers; t; t=t->next)
		if (t->level == level && t->string[0] && strstr(s, t->string))
		{
			if (level == PRINT_CHAT && (
				strstr (s, "f_version") || strstr (s, "f_system") ||
				strstr (s, "f_speed") || strstr (s, "f_modified")))
				continue; 	// don't let llamas fake proxy replies

			string = Cmd_AliasString (t->name);
			if (string)
				TP_ExecuteTriggerBuf (string);
			else
				Con_Printf ("trigger \"%s\" has no matching alias\n", t->name);
		}
}


void TP_CheckVersionRequest (char *s)
{
	char buf[11];
	int	i;

	if (cl.spectator)
		return;

	if (vars.f_version_reply_time
		&& realtime - vars.f_version_reply_time < 20)
		return;	// don't reply again if 20 seconds haven't passed

	while (1)
	{
		switch (*s++)
		{
		case 0:
		case '\n':
			return;
		case ':':
		case (char)':'|128:
			goto ok;
		}
	}
	return;

ok:
	for (i = 0; i < 11 && s[i]; i++)
		buf[i] = s[i] &~ 128;			// strip high bit

	if (!strncmp(buf, " f_version\n", 11) || !strncmp(buf, " z_version\n", 11))
	{
#ifdef RELEASE_VERSION
		Cbuf_AddText (va("say ZQuake version %s "
			QW_PLATFORM ":" QW_RENDERER "\n", Z_VERSION));
#else
		Cbuf_AddText (va("say ZQuake version %s (Build %04d) "
			QW_PLATFORM ":" QW_RENDERER "\n", Z_VERSION, build_number()));
#endif
		vars.f_version_reply_time = realtime;
	}
}


int	TP_CountPlayers ()
{
	int	i, count;

	count = 0;
	for (i = 0; i < MAX_CLIENTS ; i++) {
		if (cl.players[i].name[0] && !cl.players[i].spectator)
			count++;
	}

	return count;
}

char *TP_EnemyTeam ()
{
	int			i;
	char		myteam[MAX_INFO_STRING];
	static char	enemyteam[MAX_INFO_STRING];

	strcpy (myteam, Info_ValueForKey(cls.userinfo, "team"));

	for (i = 0; i < MAX_CLIENTS ; i++) {
		if (cl.players[i].name[0] && !cl.players[i].spectator)
		{
			strcpy (enemyteam, Info_ValueForKey(cl.players[i].userinfo, "team"));
			if (strcmp(myteam, enemyteam) != 0)
				return enemyteam;
		}
	}
	return "";
}

char *TP_PlayerName ()
{
	static char	myname[MAX_INFO_STRING];

	strcpy (myname, Info_ValueForKey(cl.players[cl.playernum].userinfo, "name"));
	return myname;
}

char *TP_PlayerTeam ()
{
	static char	myteam[MAX_INFO_STRING];

	strcpy (myteam, Info_ValueForKey(cl.players[cl.playernum].userinfo, "team"));
	return myteam;
}

char *TP_EnemyName ()
{
	int			i;
	char		*myname;
	static char	enemyname[MAX_INFO_STRING];

	myname = TP_PlayerName ();

	for (i = 0; i < MAX_CLIENTS ; i++) {
		if (cl.players[i].name[0] && !cl.players[i].spectator)
		{
			strcpy (enemyname, Info_ValueForKey(cl.players[i].userinfo, "name"));
			if (strcmp(enemyname, myname) != 0)
				return enemyname;
		}
	}
	return "";
}

char *TP_MapName ()
{
	return cl_mapname.string;
}

/*
=============================================================================
						TEAMCOLOR & ENEMYCOLOR
=============================================================================
*/

int		cl_teamtopcolor = -1;
int		cl_teambottomcolor;
int		cl_enemytopcolor = -1;
int		cl_enemybottomcolor;

void TP_TeamColor_f (void)
{
	int	top, bottom;
	int	i;

	if (Cmd_Argc() == 1)
	{
		if (cl_teamtopcolor < 0)
			Con_Printf ("\"teamcolor\" is \"off\"\n");
		else
			Con_Printf ("\"teamcolor\" is \"%i %i\"\n", 
				cl_teamtopcolor,
				cl_teambottomcolor);
		return;
	}

	if (!strcmp(Cmd_Argv(1), "off"))
	{
		cl_teamtopcolor = -1;
		for (i = 0; i < MAX_CLIENTS; i++)
			CL_NewTranslation(i);
		return;
	}

	if (Cmd_Argc() == 2)
		top = bottom = atoi(Cmd_Argv(1));
	else {
		top = atoi(Cmd_Argv(1));
		bottom = atoi(Cmd_Argv(2));
	}
	
	top &= 15;
	if (top > 13)
		top = 13;
	bottom &= 15;
	if (bottom > 13)
		bottom = 13;
	
//	if (top != cl_teamtopcolor || bottom != cl_teambottomcolor)
	{
		cl_teamtopcolor = top;
		cl_teambottomcolor = bottom;

		for (i = 0; i < MAX_CLIENTS; i++)
			CL_NewTranslation(i);
	}
}

void TP_EnemyColor_f (void)
{
	int	top, bottom;
	int	i;

	if (Cmd_Argc() == 1)
	{
		if (cl_enemytopcolor < 0)
			Con_Printf ("\"enemycolor\" is \"off\"\n");
		else
			Con_Printf ("\"enemycolor\" is \"%i %i\"\n", 
				cl_enemytopcolor,
				cl_enemybottomcolor);
		return;
	}

	if (!strcmp(Cmd_Argv(1), "off"))
	{
		cl_enemytopcolor = -1;
		for (i = 0; i < MAX_CLIENTS; i++)
			CL_NewTranslation(i);
		return;
	}

	if (Cmd_Argc() == 2)
		top = bottom = atoi(Cmd_Argv(1));
	else {
		top = atoi(Cmd_Argv(1));
		bottom = atoi(Cmd_Argv(2));
	}
	
	top &= 15;
	if (top > 13)
		top = 13;
	bottom &= 15;
	if (bottom > 13)
		bottom = 13;

//	if (top != cl_enemytopcolor || bottom != cl_enemybottomcolor)
	{
		cl_enemytopcolor = top;
		cl_enemybottomcolor = bottom;

		for (i = 0; i < MAX_CLIENTS; i++)
			CL_NewTranslation(i);
	}
}

//===================================================================

void TP_NewMap ()
{
	static char last_map[MAX_QPATH] = "";
	char mapname[MAX_QPATH];

	memset (&vars, 0, sizeof(vars));
	TP_FindModelNumbers ();

	COM_StripExtension (COM_SkipPath (cl.worldmodel->name), mapname);
	if (strcmp(mapname, last_map))
	{	// map name has changed
		loc_numentries = 0;	// clear loc file
		if (cl_loadlocs.value && !cls.demoplayback) {
			char locname[MAX_OSPATH];
			_snprintf (locname, MAX_OSPATH, "%s.loc", mapname);
			TP_LoadLocFile (locname, true);
		}
		strcpy (last_map, mapname);
		Cvar_SetROM (&cl_mapname, mapname);
	}

	TP_ExecTrigger ("f_newmap");
}

/*
======================
TP_CategorizeMessage

returns a combination of these values:
0 -- unknown (probably generated by the server)
1 -- normal
2 -- team message
4 -- spectator
Note that sometimes we can't be sure who really sent the message,
e.g. when there's a player "unnamed" in your team and "(unnamed)"
in the enemy team. The result will be 3 (1+2)

Never returns 2 if we are a spectator.
======================
*/
int TP_CategorizeMessage (char *s, int *offset)
{
	int		i, msglen, len;
	int		flags;
	player_info_t	*player;

	flags = 0;
	msglen = strlen(s);
	if (!msglen)
		return 0;

	*offset = 0;

	for (i=0, player=cl.players ; i < MAX_CLIENTS ; i++, player++)
	{
		len = strlen(player->name);
		if (!len)
			continue;
		// check messagemode1
		if (len+2 <= msglen && s[len] == ':' && s[len+1] == ' '	&&
			!strncmp(player->name, s, len))
		{
			if (player->spectator)
				flags |= 4;
			else
				flags |= 1;
			*offset = len + 2;
		}
		// check messagemode2
		else if (s[0] == '(' && !cl.spectator && len+4 <= msglen &&
			!strncmp(s+len+1, "): ", 3) &&
			!strncmp(player->name, s+1, len))
		{
			// no team messages in teamplay 0, except for our own
			if (i == cl.playernum || ( atoi(Info_ValueForKey(cl.serverinfo, "teamplay"))
				&& !strcmp(cl.players[cl.playernum].team, player->team)) )
				flags |= 2;
			*offset = len + 4;
		}
	}

	return flags;
}

//===================================================================
// Pickup triggers
//

// symbolic names used in tp_took, tp_pickup, tp_point commands
char *pknames[] = {"quad", "pent", "ring", "suit", "ra", "ya",	"ga",
"mh", "health", "lg", "rl", "gl", "sng", "ng", "ssg", "pack",
"cells", "rockets", "nails", "shells", "flag"};

#define it_quad		(1<<0)
#define it_pent		(1<<1)
#define it_ring		(1<<2)
#define it_suit		(1<<3)
#define it_ra		(1<<4)
#define it_ya		(1<<5)
#define it_ga		(1<<6)
#define it_mh		(1<<7)
#define it_health	(1<<8)
#define it_lg		(1<<9)
#define it_rl		(1<<10)
#define it_gl		(1<<11)
#define it_sng		(1<<12)
#define it_ng		(1<<13)
#define it_ssg		(1<<14)
#define it_pack		(1<<15)
#define it_cells	(1<<16)
#define it_rockets	(1<<17)
#define it_nails	(1<<18)
#define it_shells	(1<<19)
#define it_flag		(1<<20)
#define NUM_ITEMFLAGS 21

#define it_powerups	(it_quad|it_pent|it_ring)
#define it_weapons	(it_lg|it_rl|it_gl|it_sng|it_ng|it_ssg)
#define it_armor	(it_ra|it_ya|it_ga)
#define it_ammo		(it_cells|it_rockets|it_nails|it_shells)

#define default_pkflags (it_powerups|it_suit|it_armor|it_weapons|it_mh| \
				it_rockets|it_pack|it_flag)

#define default_tookflags (it_powerups|it_ra|it_ya|it_lg|it_rl|it_mh|it_flag)

#define default_pointflags (it_powerups|it_suit|it_armor|it_mh| \
				it_lg|it_rl|it_gl|it_sng|it_rockets|it_pack|it_flag)

int pkflags = default_pkflags;
int tookflags = default_tookflags;
int pointflags = default_pointflags;


static void FlagCommand (int *flags, int defaultflags)
{
	int		i, j, c;
	char	*p;
	char	str[255] = "";
	qboolean	removeflag = false;
	int		flag;
	
	c = Cmd_Argc ();
	if (c == 1)
	{
		if (!*flags)
			strcpy (str, "nothing");
		for (i=0 ; i<NUM_ITEMFLAGS ; i++)
			if (*flags & (1<<i))
			{
				if (*str)
					strcat (str, " ");
				strcat (str, pknames[i]);
			}
		Con_Printf ("%s\n", str);
		return;
	}

	if (*Cmd_Argv(1) != '+' && *Cmd_Argv(1) != '-')
		*flags = 0;

	for (i=1 ; i<c ; i++)
	{
		p = Cmd_Argv (i);
		if (*p == '+') {
			removeflag = false;
			p++;
		} else if (*p == '-') {
			removeflag = true;
			p++;
		}

		flag = 0;
		for (j=0 ; j<NUM_ITEMFLAGS ; j++) {
			if (!Q_strncasecmp (p, pknames[j], 3)) {
				flag = 1<<j;
				break;
			}
		}

		if (!flag) {
			if (!Q_strcasecmp (p, "armor"))
				flag = it_ra|it_ya|it_ga;
			else if (!Q_strcasecmp (p, "weapons"))
				flag = it_lg|it_rl|it_gl|it_sng|it_ng|it_ssg;
			else if (!Q_strcasecmp (p, "powerups"))
				flag = it_quad|it_pent|it_ring;
			else if (!Q_strcasecmp (p, "ammo"))
				flag = it_cells|it_rockets|it_nails|it_shells;
			else if (!Q_strcasecmp (p, "default"))
				flag = defaultflags;
			else if (!Q_strcasecmp (p, "all"))
				flag = (1<<NUM_ITEMFLAGS)-1;
		}

		if (removeflag)
			*flags &= ~flag;
		else
			*flags |= flag;
	}
}

void TP_Took_f (void)
{
	FlagCommand (&tookflags, default_tookflags);
}

void TP_Pickup_f (void)
{
	FlagCommand (&pkflags, default_pkflags);
}

void TP_Point_f (void)
{
	FlagCommand (&pointflags, default_pointflags);
}


/*
// FIXME: maybe use sound indexes so we don't have to make strcmp's
// every time?

#define S_LOCK4		1	// weapons/lock4.wav
#define S_PKUP		2	// weapons/pkup.wav
#define S_HEALTH25	3	// items/health1.wav
#define S_HEALTH15	4	// items/r_item1.wav
#define S_MHEALTH	5	// items/r_item2.wav
#define S_DAMAGE	6	// items/damage.wav
#define S_EYES		7	// items/inv1.wav
#define S_PENT		8	// items/protect.wav
#define S_ARMOR		9	// items/armor1.wav

static char *tp_soundnames[] =
{
	"weapons/lock4.wav",
	"weapons/pkup.wav",
	"items/health1.wav",
	"items/r_item1.wav",
	"items/r_item2.wav",
	"items/damage.wav",
	"items/inv1.wav",
	"items/protect.wav"
	"items/armor1.wav"
};

#define TP_NUMSOUNDS (sizeof(tp_soundnames)/sizeof(tp_soundnames[0]))

int	sound_numbers[MAX_SOUNDS];

void TP_FindSoundNumbers (void)
{
	int		i, j;
	char	*s;
	for (i=0 ; i<MAX_SOUNDS ; i++)
	{
		s = &cl.sound_name[i];
		for (j=0 ; j<TP_NUMSOUNDS ; j++)
			...
	}
}
*/

typedef struct {
	int		itemflag;
	cvar_t	*cvar;
	char	*modelname;
	vec3_t	offset;		// offset of model graphics center
	float	radius;		// model graphics radius
	int		flags;		// TODO: "NOPICKUP" (disp), "TEAMENEMY" (flag, disp)
} item_t;

item_t	tp_items[] = {
	{	it_quad,	&tp_name_quad,	"progs/quaddama.mdl",
		{0, 0, 24},	25,
	},
	{	it_pent,	&tp_name_pent,	"progs/invulner.mdl",
		{0, 0, 22},	25,
	},
	{	it_ring,	&tp_name_ring,	"progs/invisibl.mdl",
		{0, 0, 16},	12,
	},
	{	it_suit,	&tp_name_suit,	"progs/suit.mdl",
		{0, 0, 24}, 20,
	},
	{	it_lg,		&tp_name_lg,	"progs/g_light.mdl",
		{0, 0, 30},	20,
	},
	{	it_rl,		&tp_name_rl,	"progs/g_rock2.mdl",
		{0, 0, 30},	20,
	},
	{	it_gl,		&tp_name_gl,	"progs/g_rock.mdl",
		{0, 0, 30},	20,
	},
	{	it_sng,		&tp_name_sng,	"progs/g_nail2.mdl",
		{0, 0, 30},	20,
	},
	{	it_ng,		&tp_name_ng,	"progs/g_nail.mdl",
		{0, 0, 30},	20,
	},
	{	it_ssg,		&tp_name_ssg,	"progs/g_shot.mdl",
		{0, 0, 30},	20,
	},
	{	it_cells,	&tp_name_cells,	"maps/b_batt0.bsp",
		{16, 16, 24},	18,
	},
	{	it_cells,	&tp_name_cells,	"maps/b_batt1.bsp",
		{16, 16, 24},	18,
	},
	{	it_rockets,	&tp_name_rockets,"maps/b_rock0.bsp",
		{8, 8, 20},	18,
	},
	{	it_rockets,	&tp_name_rockets,"maps/b_rock1.bsp",
		{16, 8, 20},	18,
	},
	{	it_nails,	&tp_name_nails,	"maps/b_nail0.bsp",
		{16, 16, 10},	18,
	},
	{	it_nails,	&tp_name_nails,	"maps/b_nail1.bsp",
		{16, 16, 10},	18,
	},
	{	it_shells,	&tp_name_shells,"maps/b_shell0.bsp",
		{16, 16, 10},	18,
	},
	{	it_shells,	&tp_name_shells,"maps/b_shell1.bsp",
		{16, 16, 10},	18,
	},
	{	it_health,	&tp_name_health,"maps/b_bh10.bsp",
		{16, 16, 8},	18,
	},
	{	it_health,	&tp_name_health,"maps/b_bh25.bsp",
		{16, 16, 8},	18,
	},
	{	it_mh,		&tp_name_mh,	"maps/b_bh100.bsp",
		{16, 16, 14},	20,
	},
	{	it_pack,	&tp_name_backpack, "progs/backpack.mdl",
		{0, 0, 18},	18,
	},
	{	it_flag,	&tp_name_flag,	"progs/tf_flag.mdl",
		{0, 0, 14},	25,
	},
	{	it_flag,	&tp_name_flag,	"progs/tf_stan.mdl",
		{0, 0, 45},	40,
	},
	{	it_ra|it_ya|it_ga, NULL,	"progs/armor.mdl",
		{0, 0, 24},	22,
	}

};

#define NUMITEMS (sizeof(tp_items) / sizeof(tp_items[0]))

item_t	*model2item[MAX_MODELS];

void TP_FindModelNumbers (void)
{
	int		i, j;
	char	*s;
	item_t	*item;

	for (i=0 ; i<MAX_MODELS ; i++) {
		model2item[i] = NULL;
		s = cl.model_name[i];
		if (!s)
			continue;
		for (j=0, item=tp_items ; j<NUMITEMS ; j++, item++)
			if (!strcmp(s, item->modelname))
				model2item[i] = item;
	}
}


// on success, result is non-zero
// on failure, result is zero
// for armors, returns skinnum+1 on success
static int FindNearestItem (int flags, item_t **pitem)
{
	frame_t		*frame;
	packet_entities_t	*pak;
	entity_state_t		*ent;
	int	i, bestidx, bestdist, bestskin;
	vec3_t	org, v;
	extern	int oldparsecountmod;

	VectorCopy (cl.frames[(cls.netchan.incoming_sequence)&UPDATE_MASK]
		.playerstate[cl.playernum].origin, org);

	// look in previous frame 
	frame = &cl.frames[oldparsecountmod&UPDATE_MASK];
	pak = &frame->packet_entities;
	bestdist = 100;
	bestidx = 0;
	*pitem = NULL;
	for (i=0,ent=pak->entities ; i<pak->num_entities ; i++,ent++)
	{
		int dist;
		item_t	*item;
		
		item = model2item[ent->modelindex];
		if (!item)
			continue;
		if ( ! (item->itemflag & flags) )
			continue;

		VectorSubtract (ent->origin, org, v);
		VectorAdd (v, item->offset, v);
		dist = Length (v);
		if (dist <= bestdist) {
			bestdist = dist;
			bestidx = ent->modelindex;
			bestskin = ent->skinnum;
			*pitem = item;
		}
	}

	if (bestidx && (*pitem)->itemflag == it_armor)
		return bestskin + 1;	// 1=green, 2=yellow, 3=red

	return bestidx;
}


static int CountTeammates ()
{
	int	i, count;
	player_info_t	*player;
	char	*myteam;

	if (tp_forceTriggers.value)
		return 1;

	if (!atoi(Info_ValueForKey(cl.serverinfo, "teamplay")))
		return 0;

	count = 0;
	myteam = cl.players[cl.playernum].team;
	for (i=0, player=cl.players; i < MAX_CLIENTS ; i++, player++) {
		if (player->name[0] && !player->spectator && (i != cl.playernum)
									&& !strcmp(player->team, myteam))
			count++;
	}

	return count;
}

static void ExecTookTrigger (char *s, int flag)
{
	if ( !((pkflags|tookflags) & flag) )
		return;

	vars.tooktime = realtime;
	strncpy (vars.tookname, s, sizeof(vars.tookname)-1);
	// FIXME: better use the item location, not the player's
	strncpy (vars.tookloc, TP_LocationName (cl.frames[parsecountmod]
			.playerstate[cl.playernum].origin), sizeof(vars.tookloc)-1);

	if (tookflags & flag) {
		if (CountTeammates())
			TP_ExecTrigger ("f_took");
	}
}

void TP_CheckPickupSound (char *s)
{
	if (cl.spectator)
		return;

	if (!strcmp(s, "items/damage.wav"))
		ExecTookTrigger (tp_name_quad.string, it_quad);
	else if (!strcmp(s, "items/protect.wav"))
		ExecTookTrigger (tp_name_pent.string, it_pent);
	else if (!strcmp(s, "items/inv1.wav"))
		ExecTookTrigger (tp_name_ring.string, it_ring);
	else if (!strcmp(s, "items/suit.wav"))
		ExecTookTrigger (tp_name_suit.string, it_suit);
	else if (!strcmp(s, "items/health1.wav") ||
			 !strcmp(s, "items/r_item1.wav"))
		ExecTookTrigger (tp_name_health.string, it_health);
	else if (!strcmp(s, "items/r_item2.wav"))
		ExecTookTrigger (tp_name_mh.string, it_mh);
	else
		goto more;
	return;

more:
	if (!cl.validsequence)
		return;

	// weapons
	if (!strcmp(s, "weapons/pkup.wav"))
	{
		int	deathmatch;
		item_t	*item;

		deathmatch = atoi(Info_ValueForKey(cl.serverinfo, "deathmatch"));
		if (deathmatch == 2 || deathmatch == 3)
			return;
		if (!FindNearestItem (it_weapons, &item))
			return;
		ExecTookTrigger (item->cvar->string, item->itemflag);
		return;
	}

	// armor
	if (!strcmp(s, "items/armor1.wav"))
	{
		item_t	*item;
		switch (FindNearestItem (it_armor, &item)) {
			case 1: ExecTookTrigger (tp_name_ga.string, it_ga); break;
			case 2: ExecTookTrigger (tp_name_ya.string, it_ya); break;
			case 3: ExecTookTrigger (tp_name_ra.string, it_ra); break;
		}
		return;
	}

	// backpack or ammo
	if (!strcmp (s, "weapons/lock4.wav"))
	{
		item_t	*item;
		if (!FindNearestItem (it_ammo|it_pack, &item))
			return;
		ExecTookTrigger (item->cvar->string, item->itemflag);
	}
}


void TP_FindPoint ()
{
	packet_entities_t	*pak;
	entity_state_t		*ent;
	int	i;
	vec3_t	forward, right, up;
	float	best;
	entity_state_t	*bestent;
	vec3_t	ang;
	vec3_t	vieworg, entorg;
	item_t	*item, *bestitem;

	ang[0] = cl.viewangles[0];
	ang[1] = cl.viewangles[1];
	ang[2] = 0;
	AngleVectors (ang, forward, right, up);
	VectorCopy (cl.simorg, vieworg);
	vieworg[2] += 22;	// adjust for view height

	best = -1;

	pak = &cl.frames[parsecountmod&UPDATE_MASK].packet_entities;
	for (i=0,ent=pak->entities ; i<pak->num_entities ; i++,ent++)
	{
		vec3_t	v, v2, v3;
		float dist, miss, rank;

		item = model2item[ent->modelindex];
		if (!item)
			continue;
		if (! (item->itemflag & pointflags) )
			continue;

		VectorAdd (ent->origin, item->offset, entorg);
		VectorSubtract (entorg, vieworg, v);

		dist = DotProduct (v, forward);
		if (dist < 10)
			continue;
		VectorScale (forward, dist, v2);
		VectorSubtract (v2, v, v3);
		miss = Length (v3);
		if (miss > 300)
			continue;
		if (miss > dist*1.7)
			continue;		// over 60 degrees off
		if (dist < 3000.0/8.0)
			rank = miss * (dist*8.0*0.0002f + 0.3f);
		else
			rank = miss;
		
		if (rank < best || best < 0) {
			// check if we can actually see the object
			vec3_t	end;
			pmtrace_t	trace;
			float	radius;

			radius = item->radius;
			if (ent->effects & (EF_BLUE|EF_RED|EF_DIMLIGHT|EF_BRIGHTLIGHT))
				radius = 200;

			if (dist <= radius)
				goto ok;

			// FIXME: is it ok to use PM_TraceLine here?
			// physent list might not have been built yet...

			VectorSubtract (vieworg, entorg, v);
			VectorNormalize (v);
			VectorMA (entorg, radius, v, end);
			trace = PM_TraceLine (vieworg, end);
			if (trace.fraction == 1)
				goto ok;

			VectorMA (entorg, radius, right, end);
			VectorSubtract (vieworg, end, v);
			VectorNormalize (v);
			VectorMA (end, radius, v, end);
			trace = PM_TraceLine (vieworg, end);
			if (trace.fraction == 1)
				goto ok;

			VectorMA (entorg, -radius, right, end);
			VectorSubtract (vieworg, end, v);
			VectorNormalize (v);
			VectorMA (end, radius, v, end);
			trace = PM_TraceLine (vieworg, end);
			if (trace.fraction == 1)
				goto ok;

			VectorMA (entorg, radius, up, end);
			VectorSubtract (vieworg, end, v);
			VectorNormalize (v);
			VectorMA (end, radius, v, end);
			trace = PM_TraceLine (vieworg, end);
			if (trace.fraction == 1)
				goto ok;

			// use half the radius, otherwise it's possible to see
			// through floor in some places
			VectorMA (entorg, -radius/2, up, end);
			VectorSubtract (vieworg, end, v);
			VectorNormalize (v);
			VectorMA (end, radius, v, end);
			trace = PM_TraceLine (vieworg, end);
			if (trace.fraction == 1)
				goto ok;

			continue;	// not visible
ok:
			best = rank;
			bestent = ent;
			bestitem = item;
		}
	}

	if (best >= 0) {
		char *p;
		if (!bestitem->cvar) {
			// armors are special
			switch (bestent->skinnum) {
				case 0: p = tp_name_ga.string; break;
				case 1: p = tp_name_ya.string; break;
				default: p = tp_name_ra.string;
			}
		} else
			p = bestitem->cvar->string;

		Q_strncpyz (vars.pointname, p, sizeof(vars.pointname));
		Q_strncpyz (vars.pointloc, TP_LocationName (bestent->origin), sizeof(vars.pointloc));
	}
	else {
		Q_strncpyz (vars.pointname, tp_name_nothing.string, sizeof(vars.pointname));
		vars.pointloc[0] = 0;
	}

	vars.pointframe = host_framecount;
}


#define	IT_WEAPONS (2|4|8|16|32|64)
void TP_StatChanged (int stat, int value)
{
	int		i;

	if (stat == STAT_HEALTH)
	{
		if (value > 0) {
			if (vars.health <= 0) {
				extern cshift_t	cshift_empty;
				vars.respawntrigger_time = realtime;
				if (cl.teamfortress)
					memset (&cshift_empty, 0, sizeof(cshift_empty));
				if (!cl.spectator && CountTeammates())
					TP_ExecTrigger ("f_respawn");
			}
			vars.health = value;
			return;
		}
		if (vars.health > 0) {		// We have just died
			vars.deathtrigger_time = realtime;
			strcpy (vars.lastdeathloc, Macro_Location_f());
			if (!cl.spectator && CountTeammates()) {
				if (cl.teamfortress && (cl.stats[STAT_ITEMS] & (IT_KEY1|IT_KEY2))
					&& Cmd_FindAlias("f_flagdeath"))
					TP_ExecTrigger ("f_flagdeath");
				else
					TP_ExecTrigger ("f_death");
			}
		}
		vars.health = value;
	}
	else if (stat == STAT_ITEMS)
	{
		i = value &~ vars.items;

		if (i & (IT_KEY1|IT_KEY2)) {
			if (cl.teamfortress && !cl.spectator)
				ExecTookTrigger (tp_name_flag.string, it_flag);
		}

		vars.items = value;
	}
}


void TP_Init ()
{
	Cvar_RegisterVariable (&cl_parseFunChars);
	Cvar_RegisterVariable (&cl_parseSay);
	Cvar_RegisterVariable (&cl_triggers);
	Cvar_RegisterVariable (&tp_forceTriggers);
	Cvar_RegisterVariable (&cl_nofake);
	Cvar_RegisterVariable (&cl_loadlocs);
	Cvar_RegisterVariable (&cl_rocket2grenade);
	Cvar_RegisterVariable (&cl_mapname);
	Cvar_RegisterVariable (&cl_teamskin);
	Cvar_RegisterVariable (&cl_enemyskin);
	Cvar_RegisterVariable (&tp_name_axe);
	Cvar_RegisterVariable (&tp_name_sg);
	Cvar_RegisterVariable (&tp_name_ssg);
	Cvar_RegisterVariable (&tp_name_ng);
	Cvar_RegisterVariable (&tp_name_sng);
	Cvar_RegisterVariable (&tp_name_gl);
	Cvar_RegisterVariable (&tp_name_rl);
	Cvar_RegisterVariable (&tp_name_lg);
	Cvar_RegisterVariable (&tp_name_ra);
	Cvar_RegisterVariable (&tp_name_ya);
	Cvar_RegisterVariable (&tp_name_ga);
	Cvar_RegisterVariable (&tp_name_quad);
	Cvar_RegisterVariable (&tp_name_pent);
	Cvar_RegisterVariable (&tp_name_ring);
	Cvar_RegisterVariable (&tp_name_suit);
	Cvar_RegisterVariable (&tp_name_shells);
	Cvar_RegisterVariable (&tp_name_nails);
	Cvar_RegisterVariable (&tp_name_rockets);
	Cvar_RegisterVariable (&tp_name_cells);
	Cvar_RegisterVariable (&tp_name_mh);
	Cvar_RegisterVariable (&tp_name_health);
	Cvar_RegisterVariable (&tp_name_backpack);
	Cvar_RegisterVariable (&tp_name_flag);
	Cvar_RegisterVariable (&tp_name_nothing);
	Cvar_RegisterVariable (&tp_name_someplace);
	Cvar_RegisterVariable (&tp_name_at);

	Cmd_AddCommand ("macrolist", TP_MacroList_f);
	Cmd_AddCommand ("loadloc", TP_LoadLocFile_f);
	Cmd_AddCommand ("msg_trigger", TP_MsgTrigger_f);
	Cmd_AddCommand ("teamcolor", TP_TeamColor_f);
	Cmd_AddCommand ("enemycolor", TP_EnemyColor_f);
	Cmd_AddCommand ("tp_took", TP_Took_f);
	Cmd_AddCommand ("tp_pickup", TP_Pickup_f);
	Cmd_AddCommand ("tp_point", TP_Point_f);
}
