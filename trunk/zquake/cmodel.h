// cmodel.h

#include "bspfile.h"

// mplane->type
enum {
	SIDE_FRONT = 0,
	SIDE_BACK = 1,
	SIDE_ON = 2
};


// plane_t structure
// !!! if this is changed, it must be changed in asm_i386.h too !!!
typedef struct mplane_s
{
	vec3_t	normal;
	float	dist;
	byte	type;			// for texture axis selection and fast side tests
	byte	signbits;		// signx + signy<<1 + signz<<1
	byte	pad[2];
} mplane_t;

// !!! if this is changed, it must be changed in asm_i386.h too !!!
typedef struct
{
	dclipnode_t	*clipnodes;
	mplane_t	*planes;
	int			firstclipnode;
	int			lastclipnode;
	vec3_t		clip_mins;
	vec3_t		clip_maxs;
} hull_t;


typedef struct
{
	vec3_t	normal;
	float	dist;
} plane_t;

typedef struct
{
	qboolean	allsolid;		// if true, plane is not valid
	qboolean	startsolid;		// if true, the initial point was in a solid area
	qboolean	inopen, inwater;
	float		fraction;		// time completed, 1.0 = didn't hit anything
	vec3_t		endpos;			// final position
	plane_t		plane;			// surface normal at impact
	union {						// entity the surface is on
		int		entnum;			// for pmove
		struct edict_s *ent;	// for sv_world
	};
} trace_t;


typedef struct {
	vec3_t	mins, maxs;
	vec3_t	origin;
	hull_t	hulls[MAX_MAP_HULLS];
} cmodel_t;

typedef struct cleaf_s cleaf_t;

hull_t *CM_HullForBox (vec3_t mins, vec3_t maxs);
int CM_HullPointContents (hull_t *hull, int num, vec3_t p);
trace_t CM_HullTrace (hull_t *hull, vec3_t start, vec3_t end);
cleaf_t *CM_PointInLeaf (const vec3_t p);
int CM_Leafnum (const cleaf_t *leaf);
int	CM_LeafAmbientLevel (const cleaf_t *leaf, int ambient_channel);
byte *CM_LeafPVS (const cleaf_t *leaf);
byte *CM_LeafPHS (const cleaf_t *leaf);		// only for the server
byte *CM_FatPVS (vec3_t org);
int CM_FindTouchedLeafs (const vec3_t mins, const vec3_t maxs, int leafs[], int maxleafs, int headnode, int *topnode);
char *CM_EntityString (void);
int	CM_NumInlineModels (void);
cmodel_t *CM_InlineModel (char *name);
void CM_InvalidateMap (void);
cmodel_t *CM_LoadMap (char *name, qboolean clientload, unsigned *checksum, unsigned *checksum2);
void CM_Init (void);
