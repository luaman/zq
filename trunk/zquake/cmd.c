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
// cmd.c -- Quake script command processing module

#include "quakedef.h"

#ifndef SERVERONLY
void Cmd_ForwardToServer (void);
qboolean CL_CheckServerCommand (void);
#endif

cvar_t cl_warncmd = {"cl_warncmd", "0"};

cbuf_t	cbuf_main;
#ifndef SERVERONLY
cbuf_t	cbuf_svc;
#endif

cbuf_t	*cbuf_current = NULL;

//=============================================================================

/*
============
Cmd_Wait_f

Causes execution of the remainder of the command buffer to be delayed until
next frame.  This allows commands like:
bind g "impulse 5 ; +attack ; wait ; -attack ; impulse 2"
============
*/
void Cmd_Wait_f (void)
{
	if (cbuf_current)
		cbuf_current->wait = true;
}

/*
=============================================================================

						COMMAND BUFFER

=============================================================================
*/


void Cbuf_AddText (char *text) { Cbuf_AddTextEx (&cbuf_main, text); }
void Cbuf_InsertText (char *text) { Cbuf_InsertTextEx (&cbuf_main, text); }
void Cbuf_Execute () { Cbuf_ExecuteEx (&cbuf_main); }

/*
============
Cbuf_Init
============
*/
void Cbuf_Init (void)
{
	cbuf_main.text_start = cbuf_main.text_end = MAXCMDBUF / 2;
	cbuf_main.wait = false;
#ifndef SERVERONLY
	cbuf_svc.text_start = cbuf_svc.text_end = MAXCMDBUF / 2;
	cbuf_svc.wait = false;
#endif
}

/*
============
Cbuf_AddText

Adds command text at the end of the buffer
============
*/
void Cbuf_AddTextEx (cbuf_t *cbuf, char *text)
{
	int		len;
	int		new_start;
	int		new_bufsize;
	
	len = strlen (text);

	if (cbuf->text_end + len <= MAXCMDBUF)
	{
		memcpy (cbuf->text_buf + cbuf->text_end, text, len);
		cbuf->text_end += len;
		return;
	}

	new_bufsize = cbuf->text_end-cbuf->text_start+len;
	if (new_bufsize > MAXCMDBUF)
	{
		Con_Printf ("Cbuf_AddText: overflow\n");
		return;
	}

	// Calculate optimal position of text in buffer
	new_start = (MAXCMDBUF - new_bufsize) / 2;

	memcpy (cbuf->text_buf + new_start, cbuf->text_buf + cbuf->text_start, cbuf->text_end-cbuf->text_start);
	memcpy (cbuf->text_buf + new_start + cbuf->text_end-cbuf->text_start, text, len);
	cbuf->text_start = new_start;
	cbuf->text_end = cbuf->text_start + new_bufsize;
}


/*
============
Cbuf_InsertText

Adds command text immediately after the current command
Adds a \n to the text
============
*/
void Cbuf_InsertTextEx (cbuf_t *cbuf, char *text)
{
	int		len;
	int		new_start;
	int		new_bufsize;

	len = strlen(text);

	if (len < cbuf->text_start)
	{
		memcpy (cbuf->text_buf + (cbuf->text_start - len - 1), text, len);
		cbuf->text_buf[cbuf->text_start-1] = '\n';
		cbuf->text_start -= len + 1;
		return;
	}

	new_bufsize = cbuf->text_end - cbuf->text_start + len + 1;
	if (new_bufsize > MAXCMDBUF)
	{
		Con_Printf ("Cbuf_InsertText: overflow\n");
		return;
	}

	// Calculate optimal position of text in buffer
	new_start = (MAXCMDBUF - new_bufsize) / 2;

	memmove (cbuf->text_buf + (new_start + len + 1), cbuf->text_buf + cbuf->text_start, cbuf->text_end-cbuf->text_start);
	memcpy (cbuf->text_buf + new_start, text, len);
	cbuf->text_buf[new_start + len] = '\n';
	cbuf->text_start = new_start;
	cbuf->text_end = cbuf->text_start + new_bufsize;
}

/*
============
Cbuf_Execute
============
*/
void Cbuf_ExecuteEx (cbuf_t *cbuf)
{
	int		i;
	char	*text;
	char	line[1024];
	int		quotes;
	int		cursize;

	cbuf_current = cbuf;

	while (cbuf->text_end > cbuf->text_start)
	{
// find a \n or ; line break
		text = (char *)cbuf->text_buf + cbuf->text_start;

		cursize = cbuf->text_end - cbuf->text_start;
		quotes = 0;
		for (i=0 ; i<cursize ; i++)
		{
			if (text[i] == '"')
				quotes++;
			if ( !(quotes&1) &&  text[i] == ';')
				break;	// don't break if inside a quoted string
			if (text[i] == '\n')
				break;
		}

// don't execute lines without ending \n; this fixes problems with
// partially stuffed aliases not being executed properly
#ifndef SERVERONLY
		if (cbuf_current == &cbuf_svc && i == cursize)
			break;
#endif

		memcpy (line, text, i);
		line[i] = 0;
		if (i > 0 && line[i-1] == '\r')
			line[i-1] = 0;	// remove DOS ending CR
		
// delete the text from the command buffer and move remaining commands down
// this is necessary because commands (exec, alias) can insert data at the
// beginning of the text buffer

		if (i == cursize)
		{
			cbuf->text_start = cbuf->text_end = MAXCMDBUF/2;
		}
		else
		{
			i++;
			cbuf->text_start += i;
		}

// execute the command line
		Cmd_ExecuteString (line);
		
		if (cbuf->wait)
		{	// skip out while text still remains in buffer, leaving it
			// for next frame
			cbuf->wait = false;
			break;
		}
	}

	cbuf_current = NULL;
}

/*
==============================================================================

						SCRIPT COMMANDS

==============================================================================
*/

/*
===============
Cmd_StuffCmds_f

Adds command line parameters as script statements
Commands lead with a +, and continue until a - or another +
quake +prog jctest.qp +cmd amlev1
quake -nosound +cmd amlev1
===============
*/
void Cmd_StuffCmds_f (void)
{
	int		i, j;
	int		s;
	char	*text, *build, c;
		
// build the combined string to parse from
	s = 0;
	for (i=1 ; i<com_argc ; i++)
	{
		if (!com_argv[i])
			continue;		// NEXTSTEP nulls out -NXHost
		s += strlen (com_argv[i]) + 1;
	}
	if (!s)
		return;
		
	text = Z_Malloc (s+1);
	text[0] = 0;
	for (i=1 ; i<com_argc ; i++)
	{
		if (!com_argv[i])
			continue;		// NEXTSTEP nulls out -NXHost
		strcat (text,com_argv[i]);
		if (i != com_argc-1)
			strcat (text, " ");
	}
	
// pull out the commands
	build = Z_Malloc (s+1);
	build[0] = 0;
	
	for (i=0 ; i<s-1 ; i++)
	{
		if (text[i] == '+')
		{
			i++;

			for (j=i ; (text[j] != '+') && (text[j] != '-') && (text[j] != 0) ; j++)
				;

			c = text[j];
			text[j] = 0;
			
			strcat (build, text+i);
			strcat (build, "\n");
			text[j] = c;
			i = j-1;
		}
	}
	
	if (build[0])
		Cbuf_InsertText (build);
	
	Z_Free (text);
	Z_Free (build);
}


/*
===============
Cmd_Exec_f
===============
*/
void Cmd_Exec_f (void)
{
	char	*f;
	int		mark;

	if (Cmd_Argc () != 2)
	{
		Con_Printf ("exec <filename> : execute a script file\n");
		return;
	}

	// FIXME: is this safe freeing the hunk here???
	mark = Hunk_LowMark ();
	f = (char *)COM_LoadHunkFile (Cmd_Argv(1));
	if (!f)
	{
		Con_Printf ("couldn't exec %s\n",Cmd_Argv(1));
		return;
	}
	if (!Cvar_Command () && (cl_warncmd.value || developer.value))
		Con_Printf ("execing %s\n",Cmd_Argv(1));

#ifndef SERVERONLY
	if (cbuf_current == &cbuf_svc)
		Cbuf_AddText (f);
	else
#endif
		Cbuf_InsertText (f);
	Hunk_FreeToLowMark (mark);
}


/*
===============
Cmd_Echo_f

Just prints the rest of the line to the console
===============
*/
void Cmd_Echo_f (void)
{
	int		i;
	
	for (i=1 ; i<Cmd_Argc() ; i++)
		Con_Printf ("%s ",Cmd_Argv(i));
	Con_Printf ("\n");
}

/*
=============================================================================

								HASH

=============================================================================
*/

/*
==========
Key
==========
Returns hash key for a string
*/
static int Key (char *name)
{
	int	v;
	int c;

	v = 0;
	while ( (c = *name++) != 0 )
//		v += *name;
		v += c &~ 32;	// make it case insensitive

	return v % 32;
}

/*
=============================================================================

								ALIASES

=============================================================================
*/

static cmd_alias_t	*cmd_alias_hash[32];
static cmd_alias_t	*cmd_alias;

cmd_alias_t *Cmd_FindAlias (char *name)
{
	int			key;
	cmd_alias_t *alias;

	key = Key (name);
	for (alias = cmd_alias_hash[key] ; alias ; alias = alias->hash_next)
	{
		if (!Q_strcasecmp(name, alias->name))
			return alias;
	}
	return NULL;
}

char *Cmd_AliasString (char *name)
{
	int			key;
	cmd_alias_t *alias;

	key = Key (name);
	for (alias = cmd_alias_hash[key] ; alias ; alias = alias->hash_next)
	{
		if (!Q_strcasecmp(name, alias->name))
			return alias->value;
	}
	return NULL;
}


/*
===============
Cmd_Alias_f

Creates a new command that executes a command string (possibly ; seperated)
===============
*/

char *CopyString (char *in)
{
	char	*out;
	
	out = Z_Malloc (strlen(in)+1);
	strcpy (out, in);
	return out;
}

void Cmd_Alias_f (void)
{
	cmd_alias_t	*a;
	char		cmd[1024];
	int			i, c;
	int			key;
	char		*s;
//	cvar_t		*var;

	c = Cmd_Argc();
	if (c == 1)
	{
		Con_Printf ("Current alias commands:\n");
		for (a = cmd_alias ; a ; a=a->next)
			Con_Printf ("%s : %s\n\n", a->name, a->value);
		return;
	}

	s = Cmd_Argv(1);
	if (strlen(s) >= MAX_ALIAS_NAME)
	{
		Con_Printf ("Alias name is too long\n");
		return;
	}

#if 0
	if ( (var = Cvar_FindVar(s)) != NULL ) {
		if (var->flags & CVAR_USER_CREATED)
			Cvar_Delete (var->name);
		else {
//			Con_Printf ("%s is a variable\n");
			return;
		}
	}
#endif

	key = Key(s);

	// if the alias already exists, reuse it
	for (a = cmd_alias_hash[key] ; a ; a=a->hash_next)
	{
		if (!Q_strcasecmp(a->name, s))
		{
			Z_Free (a->value);
			break;
		}
	}

	if (!a)
	{
		a = Z_Malloc (sizeof(cmd_alias_t));
		a->next = cmd_alias;
		cmd_alias = a;
		a->hash_next = cmd_alias_hash[key];
		cmd_alias_hash[key] = a;
	}
	strcpy (a->name, s);

// copy the rest of the command line
	cmd[0] = 0;		// start out with a null string
	for (i=2 ; i<c ; i++)
	{
		if (i > 2)
			strcat (cmd, " ");
		strcat (cmd, Cmd_Argv(i));
	}
	
	a->value = CopyString (cmd);
}


qboolean Cmd_DeleteAlias (char *name)
{
	cmd_alias_t	*a, *prev;
	int			key;

	key = Key (name);

	prev = NULL;
	for (a = cmd_alias_hash[key] ; a ; a = a->hash_next)
	{
		if (!Q_strcasecmp(a->name, name))
		{
			// unlink from hash
			if (prev)
				prev->hash_next = a->hash_next;
			else
				cmd_alias_hash[key] = a->hash_next;
			break;
		}
		prev = a;
	}

	if (!a)
		return false;	// not found

	prev = NULL;
	for (a = cmd_alias ; a ; a = a->next)
	{
		if (!Q_strcasecmp(a->name, name))
		{
			// unlink from alias list
			if (prev)
				prev->next = a->next;
			else
				cmd_alias = a->next;

			// free
			Z_Free (a->value);
			Z_Free (a);			
			return true;
		}
		prev = a;
	}

	Sys_Error ("Cmd_DeleteAlias: alias list broken");
	return false;	// shut up compiler
}

void Cmd_UnAlias_f (void)
{
	char		*s;

	if (Cmd_Argc() != 2)
	{
		Con_Printf ("unalias <alias>: erase an existing alias\n");
		return;
	}

	s = Cmd_Argv(1);
	if (strlen(s) >= MAX_ALIAS_NAME)
	{
		Con_Printf ("Alias name is too long\n");
		return;
	}

	if (!Cmd_DeleteAlias(s))
		Con_Printf ("Unknown alias \"%s\"\n", s);
}

// remove all aliases
void Cmd_UnAliasAll_f (void)
{
	cmd_alias_t	*a, *next;
	int i;

	for (a=cmd_alias ; a ; a=next) {
		next = a->next;
		Z_Free (a->value);
		Z_Free (a);
	}
	cmd_alias = NULL;

	// clear hash
	for (i=0 ; i<32 ; i++) {
		cmd_alias_hash[i] = NULL;
	}
}


/*
=============================================================================

					COMMAND EXECUTION

=============================================================================
*/

#define	MAX_ARGS		80

static	int			cmd_argc;
static	char		*cmd_argv[MAX_ARGS];
static	char		*cmd_null_string = "";
static	char		*cmd_args = NULL;

static cmd_function_t	*cmd_hash_array[32];
static cmd_function_t	*cmd_functions;		// possible commands to execute

/*
============
Cmd_Argc
============
*/
int Cmd_Argc (void)
{
	return cmd_argc;
}

/*
============
Cmd_Argv
============
*/
char *Cmd_Argv (int arg)
{
	if ( arg >= cmd_argc )
		return cmd_null_string;
	return cmd_argv[arg];	
}

/*
============
Cmd_Args

Returns a single string containing argv(1) to argv(argc()-1)
============
*/
char *Cmd_Args (void)
{
	if (!cmd_args)
		return "";
	return cmd_args;
}


/*
============
Cmd_TokenizeString

Parses the given string into command line tokens.
============
*/
void Cmd_TokenizeString (char *text)
{
	int			idx;
	static char	argv_buf[1024];
	
	idx = 0;
		
	cmd_argc = 0;
	cmd_args = NULL;
	
	while (1)
	{
		// skip whitespace
		while (*text == ' ' || *text == '\t' || *text == '\r')
		{
			text++;
		}
		
		if (*text == '\n')
		{	// a newline seperates commands in the buffer
			text++;
			break;
		}

		if (!*text)
			return;
	
		if (cmd_argc == 1)
			 cmd_args = text;
			
		text = COM_Parse (text);
		if (!text)
			return;

		if (cmd_argc < MAX_ARGS)
		{
			cmd_argv[cmd_argc] = argv_buf + idx;
			strcpy (cmd_argv[cmd_argc], com_token);
			idx += strlen(com_token) + 1;
			cmd_argc++;
		}
	}
	
}


/*
============
Cmd_AddCommand
============
*/
void Cmd_AddCommand (char *cmd_name, xcommand_t function)
{
	cmd_function_t	*cmd;
	int	key;
	
	if (host_initialized)	// because hunk allocation would get stomped
		Sys_Error ("Cmd_AddCommand after host_initialized");
		
// fail if the command is a variable name
	if (Cvar_FindVar(cmd_name))
	{
		Con_Printf ("Cmd_AddCommand: %s already defined as a var\n", cmd_name);
		return;
	}
	
	key = Key (cmd_name);

// fail if the command already exists
	for (cmd=cmd_hash_array[key] ; cmd ; cmd=cmd->hash_next)
	{
		if (!Q_strcasecmp (cmd_name, cmd->name))
		{
			Con_Printf ("Cmd_AddCommand: %s already defined\n", cmd_name);
			return;
		}
	}

	cmd = Hunk_Alloc (sizeof(cmd_function_t));
	cmd->name = cmd_name;
	cmd->function = function;
	cmd->next = cmd_functions;
	cmd_functions = cmd;
	cmd->hash_next = cmd_hash_array[key];
	cmd_hash_array[key] = cmd;
}


/*
============
Cmd_Exists
============
*/
qboolean Cmd_Exists (char *cmd_name)
{
	int	key;
	cmd_function_t	*cmd;

	key = Key (cmd_name);
	for (cmd=cmd_hash_array[key] ; cmd ; cmd=cmd->hash_next)
	{
		if (!Q_strcasecmp (cmd_name, cmd->name))
			return true;
	}

	return false;
}


/*
============
Cmd_FindCommand
============
*/
cmd_function_t *Cmd_FindCommand (char *cmd_name)
{
	int	key;
	cmd_function_t	*cmd;

	key = Key (cmd_name);
	for (cmd=cmd_hash_array[key] ; cmd ; cmd=cmd->hash_next)
	{
		if (!Q_strcasecmp (cmd_name, cmd->name))
			return cmd;
	}

	return NULL;
}


/*
============
Cmd_CompleteCommand
============
*/
char *Cmd_CompleteCommand (char *partial)
{
	cmd_function_t	*cmd;
	int				len;
	cmd_alias_t		*alias;
	
	len = strlen(partial);
	
	if (!len)
		return NULL;

// check for exact match
	for (cmd=cmd_functions ; cmd ; cmd=cmd->next)
		if (!Q_strcasecmp (partial, cmd->name))
			return cmd->name;
	for (alias=cmd_alias ; alias ; alias=alias->next)
		if (!Q_strcasecmp (partial, alias->name))
			return alias->name;

// check for partial match
	for (cmd=cmd_functions ; cmd ; cmd=cmd->next)
		if (!Q_strncasecmp (partial, cmd->name, len))
			return cmd->name;
	for (alias=cmd_alias ; alias ; alias=alias->next)
		if (!Q_strncasecmp (partial, alias->name, len))
			return alias->name;

	return NULL;
}


void Cmd_CmdList_f (void)
{
	cmd_function_t	*cmd;
	int	i;

	for (cmd=cmd_functions, i=0 ; cmd ; cmd=cmd->next, i++)
		Con_Printf("%s\n", cmd->name);

	Con_Printf ("------------\n%d commands\n", i);
}


/*
===========
Cmd_Z_Cmd_f
===========
_z_cmd <command>
Just executes the rest of the string.
Can be used to do some zqwcl-specific action, e.g. "_z_cmd exec tonik_z.cfg"
*/
void Cmd_Z_Cmd_f (void)
{
	Cbuf_InsertText (Cmd_Args());
	Cbuf_InsertText ("\n");
}


/*
================
Cmd_ExpandString

Expands all $cvar expressions to cvar values
If not SERVERONLY, also expands $macro expressions
Note: dest must point to a 1024 byte buffer
================
*/
char *TP_MacroString (char *s);
void Cmd_ExpandString (char *data, char *dest)
{
	unsigned int	c;
	char	buf[255];
	int		i, len;
	cvar_t	*var, *bestvar;
	int		quotes = 0;
	char	*str;
	int		name_length;
#ifndef SERVERONLY
	extern int	macro_length;
#endif

	len = 0;

	while ( (c = *data) != 0)
	{
		if (c == '"')
			quotes++;

		if (c == '$' && !(quotes&1))
		{
			data++;

			// Copy the text after '$' to a temp buffer
			i = 0;
			buf[0] = 0;
			bestvar = NULL;
			while ((c = *data) > 32)
			{
				if (c == '$')
					break;
				data++;
				buf[i++] = c;
				buf[i] = 0;
				if ( (var = Cvar_FindVar(buf)) != NULL )
					bestvar = var;
			}

#ifndef SERVERONLY
			str = TP_MacroString (buf);
			name_length = macro_length;
			if (bestvar && (!str || (strlen(bestvar->name) > macro_length))) {
				str = bestvar->string;
				name_length = strlen(bestvar->name);
			}
#else
			if (bestvar) {
				str = bestvar->string;
				name_length = strlen(bestvar->name);
			} else
				str = NULL;
#endif

			if (str)
			{
				// check buffer size
				if (len + strlen(str) >= 1024-1)
					break;

				strcpy(&dest[len], str);
				len += strlen(str);
				i = name_length;
				while (buf[i])
					dest[len++] = buf[i++];
			}
			else
			{
				// no matching cvar or macro
				dest[len++] = '$';
				if (len + strlen(buf) >= 1024-1)
					break;
				strcpy (&dest[len], buf);
				len += strlen(buf);
			}
		}
		else
		{
			dest[len] = c;
			data++;
			len++;
			if (len >= 1024-1)
				break;
		}
	};

	dest[len] = 0;
}


/*
============
Cmd_ExecuteString

A complete command line has been parsed, so try to execute it
FIXME: lookupnoadd the token to speed search?
============
*/
void Cmd_ExecuteString (char *text)
{	
	cmd_function_t	*cmd;
	cmd_alias_t		*a;
	int				key;
	static char		buf[1024];

	Cmd_ExpandString (text, buf);
	Cmd_TokenizeString (buf);
			
// execute the command line
	if (!Cmd_Argc())
		return;		// no tokens

#ifndef SERVERONLY
	if (cbuf_current == &cbuf_svc) {
		if (CL_CheckServerCommand())
			return;
	}
#endif

	key = Key (cmd_argv[0]);

// check functions
	for (cmd=cmd_hash_array[key] ; cmd ; cmd=cmd->hash_next)
	{
		if (!Q_strcasecmp (cmd_argv[0], cmd->name))
		{
			if (cmd->function)
				cmd->function ();
#ifndef SERVERONLY
			else
				Cmd_ForwardToServer ();
#endif
			return;
		}
	}

// check cvars
	if (Cvar_Command())
		return;

// check alias
	for (a=cmd_alias_hash[key] ; a ; a=a->hash_next)
	{
		if (!Q_strcasecmp (cmd_argv[0], a->name))
		{
#ifndef SERVERONLY
			if (cbuf_current == &cbuf_svc) {
				Cbuf_AddText (a->value);
				Cbuf_AddText ("\n");
			}
			else
#endif
			{
				Cbuf_InsertText ("\n");
				Cbuf_InsertText (a->value);
			}
			return;
		}
	}

	if (cl_warncmd.value || developer.value)
		Con_Printf ("Unknown command \"%s\"\n", Cmd_Argv(0));
}


static qboolean is_numeric (char *c)
{	
	return (*c >= '0' && *c <= '9') ||
		((*c == '-' || *c == '+') && (c[1] == '.' || (c[1]>='0' && c[1]<='9'))) ||
		(*c == '.' && (c[1]>='0' && c[1]<='9'));
}
/*
================
Cmd_If_f
================
*/
void Cmd_If_f (void)
{
	int		i, c;
	char	*op;
	qboolean	result;
	char	buf[256];

	c = Cmd_Argc ();
	if (c < 5) {
		Con_Printf ("usage: if <expr1> <op> <expr2> <command> [else <command>]\n");
		return;
	}

	op = Cmd_Argv (2);
	if (!strcmp(op, "==") || !strcmp(op, "=") || !strcmp(op, "!=")
		|| !strcmp(op, "<>"))
	{
		if (is_numeric(Cmd_Argv(1)) && is_numeric(Cmd_Argv(3)))
			result = Q_atof(Cmd_Argv(1)) == Q_atof(Cmd_Argv(3));
		else
			result = !strcmp(Cmd_Argv(1), Cmd_Argv(3));

		if (op[0] != '=')
			result = !result;
	}
	else if (!strcmp(op, ">"))
		result = Q_atof(Cmd_Argv(1)) > Q_atof(Cmd_Argv(3));
	else if (!strcmp(op, "<"))
		result = Q_atof(Cmd_Argv(1)) < Q_atof(Cmd_Argv(3));
	else if (!strcmp(op, ">="))
		result = Q_atof(Cmd_Argv(1)) >= Q_atof(Cmd_Argv(3));
	else if (!strcmp(op, "<="))
		result = Q_atof(Cmd_Argv(1)) <= Q_atof(Cmd_Argv(3));
	else {
		Con_Printf ("unknown operator: %s\n", op);
		Con_Printf ("valid operators are ==, =, !=, <>, >, <, >=, <=\n");
		return;
	}

	buf[0] = '\0';
	if (result)
	{
		for (i=4; i < c ; i++) {
			if ((i == 4) && !Q_strcasecmp(Cmd_Argv(i), "then"))
				continue;
			if (!Q_strcasecmp(Cmd_Argv(i), "else"))
				break;
			if (buf[0])
				strcat (buf, " ");
			strcat (buf, Cmd_Argv(i));
		}
	}
	else
	{
		for (i=4; i < c ; i++) {
			if (!Q_strcasecmp(Cmd_Argv(i), "else"))
				break;
		}

		if (i == c)
			return;
		
		for (i++ ; i < c ; i++) {
			if (buf[0])
				strcat (buf, " ");
			strcat (buf, Cmd_Argv(i));
		}
	}

	Cbuf_InsertText (buf);
}


/*
================
Cmd_CheckParm

Returns the position (1 to argc-1) in the command's argument list
where the given parameter apears, or 0 if not present
================
*/
int Cmd_CheckParm (char *parm)
{
	int i;
	
	if (!parm)
		Sys_Error ("Cmd_CheckParm: NULL");

	for (i = 1; i < Cmd_Argc (); i++)
		if (! Q_strcasecmp (parm, Cmd_Argv (i)))
			return i;
			
	return 0;
}


/*
============
Cmd_Init
============
*/
void Cmd_Init (void)
{
//
// register our commands
//
	Cmd_AddCommand ("stuffcmds",Cmd_StuffCmds_f);
	Cmd_AddCommand ("exec",Cmd_Exec_f);
	Cmd_AddCommand ("echo",Cmd_Echo_f);
	Cmd_AddCommand ("alias",Cmd_Alias_f);
	Cmd_AddCommand ("wait", Cmd_Wait_f);
	Cmd_AddCommand ("cmdlist", Cmd_CmdList_f);
	Cmd_AddCommand ("unaliasall", Cmd_UnAliasAll_f);
	Cmd_AddCommand ("unalias", Cmd_UnAlias_f);
	Cmd_AddCommand ("if", Cmd_If_f);
	Cmd_AddCommand ("_z_cmd", Cmd_Z_Cmd_f);	// ZQuake
}
