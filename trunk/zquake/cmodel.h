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


int CM_HullPointContents (hull_t *hull, int num, vec3_t p);
