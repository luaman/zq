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

#include "pr_comp.h"			// defs shared with qcc
#include "progdefs.h"			// generated by program cdefs

typedef union eval_s
{
	string_t		string;
	float			_float;
	float			vector[3];
	func_t			function;
	int				_int;
	int				edict;
} eval_t;	


typedef struct link_s
{
	struct link_s	*prev, *next;
} link_t;

// (type *)STRUCT_FROM_LINK(link_t *link, type, member)
// ent = STRUCT_FROM_LINK(link,entity_t,order)
// FIXME: remove this mess!
#define	STRUCT_FROM_LINK(l,t,m) ((t *)((byte *)l - (int)&(((t *)0)->m)))
#define	EDICT_FROM_AREA(l) STRUCT_FROM_LINK(l,edict_t,area)


#define	MAX_ENT_LEAFS	16
typedef struct edict_s
{
	qbool		inuse;
	link_t		area;				// linked to a division node or leaf
	
	int			num_leafs;
	short		leafnums[MAX_ENT_LEAFS];	// for pvs checks, already -1

	entity_state_t	baseline;
	
	float		freetime;			// sv.time when the object was freed
	double		lastruntime;		// sv.time when SV_RunEntity was last
									// called for this edict
	entvars_t	v;					// C exported fields from progs
// other fields from progs come immediately after
} edict_t;

//============================================================================

extern	dprograms_t		*progs;
extern	dfunction_t		*pr_functions;
extern	char			*pr_strings;
extern	ddef_t			*pr_globaldefs;
extern	ddef_t			*pr_fielddefs;
extern	dstatement_t	*pr_statements;
extern	globalvars_t	*pr_global_struct;
extern	float			*pr_globals;			// same as pr_global_struct

extern	int				pr_edict_size;	// in bytes

//============================================================================
// z_ext_clientcommand progs extension

typedef struct {
	char		name[32];
	int			funcnum;
} pr_cmdfunction_t;

#define MAX_PR_CMDFUNCTIONS 1024
extern	pr_cmdfunction_t	pr_cmdfunctions[MAX_PR_CMDFUNCTIONS];
extern	int					pr_numcmdfunctions;

//============================================================================

void PR_Init (void);

void PR_ExecuteProgram (func_t fnum);
void PR_LoadProgs (void);

void PR_Profile_f (void);

edict_t *ED_Alloc (void);
void ED_Free (edict_t *ed);

char	*ED_NewString (char *string);
// returns a copy of the string allocated from the server's string heap

void ED_Print (edict_t *ed);
void ED_Write (FILE *f, edict_t *ed);
char *ED_ParseEdict (char *data, edict_t *ent);

void ED_WriteGlobals (FILE *f);
void ED_ParseGlobals (char *data);

void ED_LoadFromFile (char *data);

//define EDICT_NUM(n) ((edict_t *)((byte *)sv.edicts + (n)*pr_edict_size))
//define NUM_FOR_EDICT(e) (((byte *)(e) - (byte *)sv.edicts)/pr_edict_size)

edict_t *EDICT_NUM(int n);
int NUM_FOR_EDICT(edict_t *e);

#define	NEXT_EDICT(e) ((edict_t *)( (byte *)e + pr_edict_size))

#define	EDICT_TO_PROG(e) ((byte *)e - (byte *)sv.edicts)
#define PROG_TO_EDICT(e) ((edict_t *)((byte *)sv.edicts + e))

//============================================================================

#define	G_FLOAT(o) (pr_globals[o])
#define	G_INT(o) (*(int *)&pr_globals[o])
#define	G_EDICT(o) ((edict_t *)((byte *)sv.edicts+ *(int *)&pr_globals[o]))
#define G_EDICTNUM(o) NUM_FOR_EDICT(G_EDICT(o))
#define	G_VECTOR(o) (&pr_globals[o])
#define	G_STRING(o) (PR_GetString(*(string_t *)&pr_globals[o]))
#define	G_FUNCTION(o) (*(func_t *)&pr_globals[o])

#define	E_FLOAT(e,o) (((float*)&e->v)[o])
#define	E_INT(e,o) (*(int *)&((float*)&e->v)[o])
#define	E_VECTOR(e,o) (&((float*)&e->v)[o])
#define	E_STRING(e,o) (PR_GetString(*(string_t *)&((float*)&e->v)[o]))

extern	int		type_size[8];

typedef void (*builtin_t) (void);
extern builtin_t pr_builtins[], pr_extbuiltins[];
extern int pr_numbuiltins, pr_numextbuiltins;
#define ZQ_BUILTINS		0x5a00

extern int		pr_argc;

extern	qbool		pr_trace;
extern	dfunction_t	*pr_xfunction;
extern	int			pr_xstatement;


extern func_t SpectatorConnect, SpectatorDisconnect, SpectatorThink;
extern func_t BotConnect, BotDisconnect, BotPreThink, BotPostThink;

extern int	fofs_gravity, fofs_maxspeed;
extern int	fofs_forwardmove, fofs_sidemove, fofs_upmove;
extern int	fofs_vw_index, fofs_vw_frame;

#define EdictFieldFloat(ed, fieldoffset) ((eval_t *)((byte *)&(ed)->v + (fieldoffset)))->_float


void PR_RunError (char *error, ...);

void ED_PrintEdicts_f (void);
void ED_PrintNum (int ent);

//
// PR strings stuff
//
#define MAX_PRSTR 1024		// max static strings
#define MAX_DYN_PRSTR 1024	// max dynamic strings

extern char *pr_strtbl[MAX_PRSTR + MAX_DYN_PRSTR];
extern int num_prstr;

char *PR_GetString(int num);
int PR_SetString(char *s);
void PR_InitStrings (void);
void PR_FreeStrings (void);
