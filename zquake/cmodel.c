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
// cmodel.c

//#include "common.h"
#include "quakedef.h"


/*
===============================================================================

HULL BOXES

===============================================================================
*/


static hull_t		box_hull;
static dclipnode_t	box_clipnodes[6];
static mplane_t		box_planes[6];

/*
** CM_InitBoxHull
**
** Set up the planes and clipnodes so that the six floats of a bounding box
** can just be stored out and get a proper hull_t structure.
*/
static void CM_InitBoxHull (void)
{
	int		i;
	int		side;

	box_hull.clipnodes = box_clipnodes;
	box_hull.planes = box_planes;
	box_hull.firstclipnode = 0;
	box_hull.lastclipnode = 5;

	for (i=0 ; i<6 ; i++)
	{
		box_clipnodes[i].planenum = i;
		
		side = i&1;
		
		box_clipnodes[i].children[side] = CONTENTS_EMPTY;
		if (i != 5)
			box_clipnodes[i].children[side^1] = i + 1;
		else
			box_clipnodes[i].children[side^1] = CONTENTS_SOLID;
		
		box_planes[i].type = i>>1;
		box_planes[i].normal[i>>1] = 1;
	}
	
}


/*
** CM_HullForBox
**
** To keep everything totally uniform, bounding boxes are turned into small
** BSP trees instead of being compared directly.
*/
hull_t *CM_HullForBox (vec3_t mins, vec3_t maxs)
{
	box_planes[0].dist = maxs[0];
	box_planes[1].dist = mins[0];
	box_planes[2].dist = maxs[1];
	box_planes[3].dist = mins[1];
	box_planes[4].dist = maxs[2];
	box_planes[5].dist = mins[2];

	return &box_hull;
}



int CM_HullPointContents (hull_t *hull, int num, vec3_t p)
{
	float		d;
	dclipnode_t	*node;
	mplane_t	*plane;

	while (num >= 0)
	{
		if (num < hull->firstclipnode || num > hull->lastclipnode)
			Sys_Error ("CM_HullPointContents: bad node number");
	
		node = hull->clipnodes + num;
		plane = hull->planes + node->planenum;
		
		if (plane->type < 3)
			d = p[plane->type] - plane->dist;
		else
			d = DotProduct (plane->normal, p) - plane->dist;
		if (d < 0)
			num = node->children[1];
		else
			num = node->children[0];
	}
	
	return num;
}


/*
===============================================================================

LINE TESTING IN HULLS

===============================================================================
*/

// 1/32 epsilon to keep floating point happy
#define	DIST_EPSILON	(0.03125)

static hull_t	trace_hull;
static trace_t	trace_trace;

static qboolean RecursiveHullTrace (int num, float p1f, float p2f, vec3_t p1, vec3_t p2)
{
	dclipnode_t	*node;
	mplane_t	*plane;
	float		t1, t2;
	float		frac;
	int			i;
	vec3_t		mid;
	int			side;
	float		midf;

// check for empty
	if (num < 0)
	{
		if (num != CONTENTS_SOLID)
		{
			trace_trace.allsolid = false;
			if (num == CONTENTS_EMPTY)
				trace_trace.inopen = true;
			else
				trace_trace.inwater = true;
		}
		else
			trace_trace.startsolid = true;
		return true;		// empty
	}

	// FIXME, check at load time
	if (num < trace_hull.firstclipnode || num > trace_hull.lastclipnode)
		Sys_Error ("RecursiveHullTrace: bad node number");

//
// find the point distances
//
	node = trace_hull.clipnodes + num;
	plane = trace_hull.planes + node->planenum;

	if (plane->type < 3)
	{
		t1 = p1[plane->type] - plane->dist;
		t2 = p2[plane->type] - plane->dist;
	}
	else
	{
		t1 = DotProduct (plane->normal, p1) - plane->dist;
		t2 = DotProduct (plane->normal, p2) - plane->dist;
	}
	
#if 1
	if (t1 >= 0 && t2 >= 0)
		return RecursiveHullTrace (node->children[0], p1f, p2f, p1, p2);
	if (t1 < 0 && t2 < 0)
		return RecursiveHullTrace (node->children[1], p1f, p2f, p1, p2);
#else
	if ( (t1 >= DIST_EPSILON && t2 >= DIST_EPSILON) || (t2 > t1 && t1 >= 0) )
		return RecursiveHullTrace (node->children[0], p1f, p2f, p1, p2);
	if ( (t1 <= -DIST_EPSILON && t2 <= -DIST_EPSILON) || (t2 < t1 && t1 <= 0) )
		return RecursiveHullTrace (node->children[1], p1f, p2f, p1, p2);
#endif

// put the crosspoint DIST_EPSILON pixels on the near side
	if (t1 < 0)
		frac = (t1 + DIST_EPSILON)/(t1-t2);
	else
		frac = (t1 - DIST_EPSILON)/(t1-t2);
	if (frac < 0)
		frac = 0;
	if (frac > 1)
		frac = 1;
		
	midf = p1f + (p2f - p1f)*frac;
	for (i=0 ; i<3 ; i++)
		mid[i] = p1[i] + frac*(p2[i] - p1[i]);

	side = (t1 < 0);

// move up to the node
	if (!RecursiveHullTrace (node->children[side], p1f, midf, p1, mid))
		return false;

#ifdef PARANOID
	if (CM_HullPointContents (sv_hullmodel, mid, node->children[side])
	== CONTENTS_SOLID)
	{
		Com_Printf ("mid PointInHullSolid\n");
		return false;
	}
#endif
	
	if (CM_HullPointContents (&trace_hull, node->children[side^1], mid)
	!= CONTENTS_SOLID)
// go past the node
		return RecursiveHullTrace (node->children[side^1], midf, p2f, mid, p2);
	
	if (trace_trace.allsolid)
		return false;		// never got out of the solid area
		
//==================
// the other side of the node is solid, this is the impact point
//==================
	if (!side)
	{
		VectorCopy (plane->normal, trace_trace.plane.normal);
		trace_trace.plane.dist = plane->dist;
	}
	else
	{
		VectorNegate (plane->normal, trace_trace.plane.normal);
		trace_trace.plane.dist = -plane->dist;
	}

	while (CM_HullPointContents (&trace_hull, trace_hull.firstclipnode, mid)
	== CONTENTS_SOLID)
	{ // shouldn't really happen, but does occasionally
		frac -= 0.1;
		if (frac < 0)
		{
			trace_trace.fraction = midf;
			VectorCopy (mid, trace_trace.endpos);
			Com_DPrintf ("backup past 0\n");
			return false;
		}
		midf = p1f + (p2f - p1f)*frac;
		for (i=0 ; i<3 ; i++)
			mid[i] = p1[i] + frac*(p2[i] - p1[i]);
	}

	trace_trace.fraction = midf;
	VectorCopy (mid, trace_trace.endpos);

	return false;
}

// trace a line through the supplied clipping hull
// does not fill trace.ent
trace_t CM_HullTrace (hull_t *hull, vec3_t start, vec3_t end)
{
	// fill in a default trace
	memset (&trace_trace, 0, sizeof(trace_trace));
	trace_trace.fraction = 1;
	trace_trace.allsolid = true;
//	trace_trace.startsolid = true;		// this was (commented out) in pmovetst.c, why? -- Tonik
	VectorCopy (end, trace_trace.endpos);

	trace_hull = *hull;

	RecursiveHullTrace (trace_hull.firstclipnode, 0, 1, start, end);

	return trace_trace;
}

//===========================================================================


void CM_Init (void)
{
	CM_InitBoxHull ();
}

#if 0
static char			loadname[32];	// for hunk tags

static char			map_name[MAX_QPATH];
static unsigned int	map_checksum, map_checksum2;

static int			numcmodels;
static dmodel_t		map_cmodels[MAX_MAP_MODELS];

static mplane_t		*map_planes;
static int			numplanes;

static mnode_t		*map_nodes;
static int			numnodes;

static dclipnode_t	*map_clipnodes;
static int			numclipnodes;

static mleaf_t		*map_leafs;
static int			numleafs;

static byte			*map_visdata;
static byte			map_novis[MAX_MAP_LEAFS/8];

static char			*map_entitystring;

static byte			*cmod_base;		// for CM::Load* functions


/*void CM_Init (void)
{
	memset (map_novis, 0xff, sizeof(mod_novis));
}
*/

char *CM_EntityString (void)
{
	return map_entitystring;
}

mleaf_t *CM_PointInLeaf (vec3_t p, model_t *model)
{
	mnode_t		*node;
	float		d;
	mplane_t	*plane;
	
	if (!model || !model->nodes)
		Host_Error ("CM_PointInLeaf: bad model");

	node = model->nodes;
	while (1)
	{
		if (node->contents < 0)
			return (mleaf_t *)node;
		plane = node->plane;
		d = DotProduct (p,plane->normal) - plane->dist;
		if (d > 0)
			node = node->children[0];
		else
			node = node->children[1];
	}
	
	return NULL;	// never reached
}


/*
===================
CM_DecompressVis
===================
*/
byte *CM_DecompressVis (byte *in, model_t *model)
{
	static byte	decompressed[MAX_MAP_LEAFS/8];
	int		c;
	byte	*out;
	int		row;

	row = (model->numleafs+7)>>3;	
	out = decompressed;

	if (!in)
	{	// no vis info, so make all visible
		while (row)
		{
			*out++ = 0xff;
			row--;
		}
		return decompressed;		
	}

	do
	{
		if (*in)
		{
			*out++ = *in++;
			continue;
		}
	
		c = in[1];
		in += 2;
		while (c)
		{
			*out++ = 0;
			c--;
		}
	} while (out - decompressed < row);
	
	return decompressed;
}

byte *CM_LeafPVS (mleaf_t *leaf, model_t *model)
{
	if (leaf == model->leafs)
		return map_novis;
	return CM_DecompressVis (leaf->compressed_vis, model);
}

/*
===============================================================================

					BRUSHMODEL LOADING

===============================================================================
*/

void CM_LoadVisibility (lump_t *l)
{
	if (!l->filelen)
	{
		map_visdata = NULL;
		return;
	}
	map_visdata = Hunk_AllocName ( l->filelen, loadname);	
	memcpy (map_visdata, cmod_base + l->fileofs, l->filelen);
}


void CM_LoadEntities (lump_t *l)
{
	if (!l->filelen)
	{
		map_entitystring = NULL;
		return;
	}
	map_entitystring = Hunk_AllocName ( l->filelen, loadname);	
	memcpy (map_entitystring, cmod_base + l->fileofs, l->filelen);
}


/*
=================
CM_LoadSubmodels
=================
*/
void CM_LoadSubmodels (lump_t *l)
{
	dmodel_t	*in;
	dmodel_t	*out;
	int			i, j, count;

	in = (void *)(cmod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("CM::LoadMap: funny lump size");
	count = l->filelen / sizeof(*in);

	if (count < 1)
		Host_Error ("Map with no models");
	if (count > MAX_MAP_MODELS)
		Host_Error ("Map has too many models");

	out = map_cmodels;
	numcmodels = count;

	for (i=0 ; i<count ; i++, in++, out++)
	{
		for (j=0 ; j<3 ; j++)
		{	// spread the mins / maxs by a pixel
			out->mins[j] = LittleFloat (in->mins[j]) - 1;
			out->maxs[j] = LittleFloat (in->maxs[j]) + 1;
			out->origin[j] = LittleFloat (in->origin[j]);
		}
		for (j=0 ; j<MAX_MAP_HULLS ; j++)
			out->headnode[j] = LittleLong (in->headnode[j]);
		out->visleafs = LittleLong (in->visleafs);
		out->firstface = LittleLong (in->firstface);
		out->numfaces = LittleLong (in->numfaces);
	}
}

/*
=================
CM_SetParent
=================
*/
void CM_SetParent (mnode_t *node, mnode_t *parent)
{
	node->parent = parent;
	if (node->contents < 0)
		return;
	CM_SetParent (node->children[0], node);
	CM_SetParent (node->children[1], node);
}

/*
=================
CM_LoadNodes
=================
*/
void CM_LoadNodes (lump_t *l)
{
	int			i, j, count, p;
	dnode_t		*in;
	mnode_t 	*out;

	in = (void *)(cmod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("CM::LoadMap: funny lump size");
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), loadname);	

	map_nodes = out;
	numnodes = count;

	for (i = 0; i < count; i++, in++, out++)
	{
		for (j=0 ; j<3 ; j++)
		{
			out->minmaxs[j] = LittleShort (in->mins[j]);
			out->minmaxs[3+j] = LittleShort (in->maxs[j]);
		}
	
		p = LittleLong(in->planenum);
		out->plane = map_planes + p;

		out->firstsurface = LittleShort (in->firstface);
		out->numsurfaces = LittleShort (in->numfaces);
		
		for (j=0 ; j<2 ; j++)
		{
			p = LittleShort (in->children[j]);
			if (p >= 0)
				out->children[j] = map_nodes + p;
			else
				out->children[j] = (mnode_t *)(map_leafs + (-1 - p));
		}
	}
	
	CM_SetParent (map_nodes, NULL);		// sets nodes and leafs
}

/*
=================
CM_LoadLeafs
=================
*/
void CM_LoadLeafs (lump_t *l)
{
	dleaf_t 	*in;
	mleaf_t 	*out;
	int			i, j, count, p;

	in = (dleaf_t *)(cmod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("CM::LoadMap: funny lump size");
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), loadname);	

	map_leafs = out;
	numleafs = count;

	for (i = 0; i < count; i++, in++, out++)
	{
		for (j=0 ; j<3 ; j++)
		{
			out->minmaxs[j] = LittleShort (in->mins[j]);
			out->minmaxs[3+j] = LittleShort (in->maxs[j]);
		}

		p = LittleLong(in->contents);
		out->contents = p;

		p = LittleLong(in->visofs);
		if (p == -1)
			out->compressed_vis = NULL;
		else
			out->compressed_vis = map_visdata + p;
		out->efrags = NULL;
		
		for (j=0 ; j<4 ; j++)
			out->ambient_sound_level[j] = in->ambient_level[j];
	}	
}

/*
=================
CM_LoadClipnodes
=================
*/
void CM_LoadClipnodes (lump_t *l)
{
	dclipnode_t *in, *out;
	int			i, count;
//	hull_t		*hull;

	in = (void *)(cmod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("CM::LoadMap: funny lump size");
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*sizeof(*out), loadname);	

	map_clipnodes = out;
	numclipnodes = count;

/*	hull = &loadmodel->hulls[1];
	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;
	hull->clip_mins[0] = -16;
	hull->clip_mins[1] = -16;
	hull->clip_mins[2] = -24;
	hull->clip_maxs[0] = 16;
	hull->clip_maxs[1] = 16;
	hull->clip_maxs[2] = 32;

	hull = &loadmodel->hulls[2];
	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;
	hull->clip_mins[0] = -32;
	hull->clip_mins[1] = -32;
	hull->clip_mins[2] = -24;
	hull->clip_maxs[0] = 32;
	hull->clip_maxs[1] = 32;
	hull->clip_maxs[2] = 64;
*/

	for (i=0 ; i<count ; i++, out++, in++)
	{
		out->planenum = LittleLong(in->planenum);
		out->children[0] = LittleShort(in->children[0]);
		out->children[1] = LittleShort(in->children[1]);
	}
}

/*
=================
CM_MakeHull0

Deplicate the drawing hull structure as a clipping hull
=================
*/
void CM_MakeHull0 (void)
{
#if 0 // FIXME
	mnode_t		*in, *child;
	dclipnode_t *out;
	int			i, j, count;
	hull_t		*hull;

	hull = &loadmodel->hulls[0];	
	
	in = loadmodel->nodes;
	count = loadmodel->numnodes;
	out = Hunk_AllocName ( count*sizeof(*out), loadname);	

	hull->clipnodes = out;
	hull->firstclipnode = 0;
	hull->lastclipnode = count-1;
	hull->planes = loadmodel->planes;

	for (i=0 ; i<count ; i++, out++, in++)
	{
		out->planenum = in->plane - loadmodel->planes;
		for (j=0 ; j<2 ; j++)
		{
			child = in->children[j];
			if (child->contents < 0)
				out->children[j] = child->contents;
			else
				out->children[j] = child - loadmodel->nodes;
		}
	}
#endif
}

/*
=================
CM_LoadPlanes
=================
*/
void CM_LoadPlanes (lump_t *l)
{
	int			i, j;
	mplane_t	*out;
	dplane_t 	*in;
	int			count;
	int			bits;
	
	in = (void *)(cmod_base + l->fileofs);
	if (l->filelen % sizeof(*in))
		Host_Error ("CM::LoadMap: funny lump size");
	count = l->filelen / sizeof(*in);
	out = Hunk_AllocName ( count*2*sizeof(*out), loadname);	
	
	map_planes = out;
	numplanes = count;

	for (i = 0; i < count; i++, in++, out++)
	{
		bits = 0;
		for (j=0 ; j<3 ; j++)
		{
			out->normal[j] = LittleFloat (in->normal[j]);
			if (out->normal[j] < 0)
				bits |= 1<<j;
		}

		out->dist = LittleFloat (in->dist);
		out->type = LittleLong (in->type);
		out->signbits = bits;
	}
}

/*
** hunk was reset by host, so the data is no longer valid
*/
void CM_InvalidateMap (void)
{
	map_name[0] = 0;
}

/*
** CM_LoadMap
*/
void CM_LoadMap (char *name, qboolean clientload, unsigned *checksum, unsigned *checksum2)
{
	int			i, j;
	dheader_t	*header;
	dmodel_t 	*bm;
	unsigned int *buf;

	if (map_name[0]) {
		assert(!strcmp(name, map_name));

		*checksum = map_checksum;
		*checksum = map_checksum2;
//		return &map_cmodels[0];		// still have the right version
		return;
	}

	// load the file
	buf = (unsigned int *)FS_LoadTempFile (name);
	if (!buf)
		Host_Error ("CM::LoadMap: %s not found", name);

	COM_FileBase (name, loadname);

	header = (dheader_t *)buf;

	i = LittleLong (header->version);
	if (i != BSPVERSION)
		Host_Error ("CM::LoadMap: %s has wrong version number (%i should be %i)", name, i, BSPVERSION);

	// swap all the lumps
	cmod_base = (byte *)header;

	for (i=0 ; i<sizeof(dheader_t)/4 ; i++)
		((int *)header)[i] = LittleLong ( ((int *)header)[i]);

	// checksum all of the map, except for entities
	map_checksum = map_checksum2 = 0;
	for (i = 0; i < HEADER_LUMPS; i++) {
		if (i == LUMP_ENTITIES)
			continue;
		map_checksum ^= LittleLong(Com_BlockChecksum(cmod_base + header->lumps[i].fileofs, 
			header->lumps[i].filelen));

		if (i == LUMP_VISIBILITY || i == LUMP_LEAFS || i == LUMP_NODES)
			continue;
		map_checksum2 ^= LittleLong(Com_BlockChecksum(cmod_base + header->lumps[i].fileofs, 
			header->lumps[i].filelen));
	}
	*checksum = map_checksum;
	*checksum2 = map_checksum2;

	// load into heap
	CM_LoadPlanes (&header->lumps[LUMP_PLANES]);
	CM_LoadVisibility (&header->lumps[LUMP_VISIBILITY]);
	CM_LoadLeafs (&header->lumps[LUMP_LEAFS]);
	CM_LoadNodes (&header->lumps[LUMP_NODES]);
	CM_LoadClipnodes (&header->lumps[LUMP_CLIPNODES]);
	CM_LoadEntities (&header->lumps[LUMP_ENTITIES]);
	CM_LoadSubmodels (&header->lumps[LUMP_MODELS]);

	CM_MakeHull0 ();

	Q_strncpyz (map_name, name, MAX_QPATH);

/*
//
// set up the submodels (FIXME: this is confusing)
//
	for (i=0 ; i<mod->numsubmodels ; i++)
	{
		bm = &mod->submodels[i];

		mod->hulls[0].firstclipnode = bm->headnode[0];
		for (j=1 ; j<MAX_MAP_HULLS ; j++)
		{
			mod->hulls[j].firstclipnode = bm->headnode[j];
			mod->hulls[j].lastclipnode = mod->numclipnodes-1;
		}
		
		mod->firstmodelsurface = bm->firstface;
		mod->nummodelsurfaces = bm->numfaces;
		
		VectorCopy (bm->maxs, mod->maxs);
		VectorCopy (bm->mins, mod->mins);
	
		mod->numleafs = bm->visleafs;

		if (i < mod->numsubmodels-1)
		{	// duplicate the basic information
			char	name[10];

			sprintf (name, "*%i", i+1);
			loadmodel = CM_FindName (name);
			*loadmodel = *mod;
			strcpy (loadmodel->name, name);
			mod = loadmodel;
		}
	}
*/
}

#if 0
dmodel_t* CM_InlineModel (char *name)
{
	int		num;

	if (!name || name[0] != '*')
		Host_Error ("CM_InlineModel: bad name");

	num = atoi (name+1);
	if (num < 1 || num >= numcmodels)
		Host_Error ("CM_InlineModel: bad number");

	return &map_cmodels[num];
}
#endif

#endif
