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
// r_misc.c

#include "quakedef.h"
#include "r_local.h"
#include "image.h"
#include <time.h>


/*
===============
R_CheckVariables
===============
*/
void R_CheckVariables (void)
{
	static qbool	oldbright = false;
	qbool			fullbright;

	fullbright = (r_fullbright.value && r_refdef2.allowCheats);
	if (fullbright != oldbright) {
		oldbright = r_fullbright.value;
		D_FlushCaches ();	// so all lighting changes
	}
}


/*
============
Show

Debugging use
============
*/
void Show (void)
{
	vrect_t	vr;

	vr.x = vr.y = 0;
	vr.width = vid.width;
	vr.height = vid.height;
	vr.pnext = NULL;
	VID_Update (&vr);
}

/*
====================
R_TimeRefresh_f

For program optimization
====================
*/
void R_TimeRefresh_f (void)
{
	int			i;
	float		start, stop, time;
	int			startangle;
	vrect_t		vr;

	if (cls.state != ca_active)
		return;

	startangle = r_refdef.viewangles[1];
	
	start = Sys_DoubleTime ();
	for (i=0 ; i<128 ; i++)
	{
		r_refdef.viewangles[1] = i/128.0*360.0;

		VID_LockBuffer ();

		R_RenderView ();

		VID_UnlockBuffer ();

		vr.x = r_refdef.vrect.x;
		vr.y = r_refdef.vrect.y;
		vr.width = r_refdef.vrect.width;
		vr.height = r_refdef.vrect.height;
		vr.pnext = NULL;
		VID_Update (&vr);
	}
	stop = Sys_DoubleTime ();
	time = stop-start;
	Com_Printf ("%f seconds (%f fps)\n", time, 128/time);
	
	r_refdef.viewangles[1] = startangle;
}

/*
================
R_LineGraph

Only called by R_DisplayTime
================
*/
void R_LineGraph (int x, int y, int h)
{
	int		i;
	byte	*dest;
	int		s;
	int		color;

// FIXME: should be disabled on no-buffer adapters, or should be in the driver
	
//	x += r_refdef.vrect.x;
//	y += r_refdef.vrect.y;
	
	dest = vid.buffer + vid.rowbytes*y + x;
	
	s = r_graphheight.value;

	if (h == 10000)
		color = 0x6f;	// yellow
	else if (h == 9999)
		color = 0x4f;	// red
	else if (h == 9998)
		color = 0xd0;	// blue
	else
		color = 0xff;	// pink

	if (h>s)
		h = s;
	
	for (i=0 ; i<h ; i++, dest -= vid.rowbytes*2)
	{
		dest[0] = color;
//		*(dest-vid.rowbytes) = 0x30;
	}
#if 0
	for ( ; i<s ; i++, dest -= vid.rowbytes*2)
	{
		dest[0] = 0x30;
		*(dest-vid.rowbytes) = 0x30;
	}
#endif
}

/*
==============
R_TimeGraph

Performance monitoring tool
==============
*/
#define	MAX_TIMINGS		100
extern float mouse_x, mouse_y;
int		graphval;
void R_TimeGraph (void)
{
	static	int		timex;
	int		a;
	float	r_time2;
	static byte	r_timings[MAX_TIMINGS];
	int		x;
	
	r_time2 = Sys_DoubleTime ();

	a = (r_time2-r_time1)/0.01;
//a = fabs(mouse_y * 0.05);
//a = (int)((r_refdef.vieworg[2] + 1024)/1)%(int)r_graphheight.value;
//a = (int)((pmove.velocity[2] + 500)/10);
//a = fabs(velocity[0])/20;
//a = ((int)fabs(origin[0])/8)%20;
//a = (cl.idealpitch + 30)/5;
//a = (int)(cl.simangles[YAW] * 64/360) & 63;
a = graphval;

	r_timings[timex] = a;
	a = timex;

	if (r_refdef.vrect.width <= MAX_TIMINGS)
		x = r_refdef.vrect.width-1;
	else
		x = r_refdef.vrect.width -
				(r_refdef.vrect.width - MAX_TIMINGS)/2;
	do
	{
		R_LineGraph (x, r_refdef.vrect.height-2, r_timings[a]);
		if (x==0)
			break;		// screen too small to hold entire thing
		x--;
		a--;
		if (a == -1)
			a = MAX_TIMINGS-1;
	} while (a != timex);

	timex = (timex+1)%MAX_TIMINGS;
}

/*
==============
R_NetGraph
==============
*/
void R_NetGraph (void)
{
	extern cvar_t	r_netgraph;
	int		a, x, y, y2, w, i;
	int		lost;
	char	st[80];

	if (vid.width - 16 <= NET_TIMINGS)
		w = vid.width - 16;
	else
		w = NET_TIMINGS;

	x =	0;
	y = vid.height - sb_lines - 24 - (int)r_graphheight.value*2 - 2;

	if (r_netgraph.value != 2 && r_netgraph.value != 3)
		Draw_TextBox (x, y, (w+7)/8, ((int)r_graphheight.value*2+7)/8 + 1);

	y2 = y + 8;
	y = vid.height - sb_lines - 8 - 2;

	x = 8;
	lost = CL_CalcNet();
	for (a=NET_TIMINGS-w ; a<w ; a++)
	{
		i = (cls.netchan.outgoing_sequence-a) & NET_TIMINGSMASK;
		R_LineGraph (x+w-1-a, y, packet_latency[i]);
	}

	if (r_netgraph.value != 3) {
		sprintf(st, "%3i%% packet loss", lost);
		R_DrawString (8, y2, st);
	}
}

/*
==============
R_ZGraph
==============
*/
void R_ZGraph (void)
{
	int		a, x, w, i;
	static	int	height[256];

	if (r_refdef.vrect.width <= 256)
		w = r_refdef.vrect.width;
	else
		w = 256;

	height[r_framecount&255] = ((int)r_origin[2]) & 31;

	x = 0;
	for (a=0 ; a<w ; a++)
	{
		i = (r_framecount-a) & 255;
		R_LineGraph (x+w-1-a, r_refdef.vrect.height-2, height[i]);
	}
}

/*
=============
R_PrintTimes
=============
*/
void R_PrintTimes (void)
{
	float	r_time2;
	float		ms;

	r_time2 = Sys_DoubleTime ();

	ms = 1000* (r_time2 - r_time1);
	
	Com_Printf ("%5.1f ms %3i/%3i/%3i poly %3i surf\n",
				ms, c_faceclip, r_polycount, r_drawnpolycount, c_surf);
	c_surf = 0;
}


/*
=============
R_PrintDSpeeds
=============
*/
void R_PrintDSpeeds (void)
{
	float	ms, dp_time, r_time2, rw_time, db_time, se_time, de_time, dv_time;

	r_time2 = Sys_DoubleTime ();

	dp_time = (dp_time2 - dp_time1) * 1000;
	rw_time = (rw_time2 - rw_time1) * 1000;
	db_time = (db_time2 - db_time1) * 1000;
	se_time = (se_time2 - se_time1) * 1000;
	de_time = (de_time2 - de_time1) * 1000;
	dv_time = (dv_time2 - dv_time1) * 1000;
	ms = (r_time2 - r_time1) * 1000;

	Com_Printf ("%3i %4.1fp %3iw %4.1fb %3is %4.1fe %4.1fv\n",
				(int)ms, dp_time, (int)rw_time, db_time, (int)se_time, de_time,
				dv_time);
}


/*
=============
R_PrintAliasStats
=============
*/
void R_PrintAliasStats (void)
{
	Com_Printf ("%3i polygon model drawn\n", r_amodels_drawn);
}


void WarpPalette (void)
{
	int		i,j;
	byte	newpalette[768];
	int		basecolor[3];
	
	basecolor[0] = 130;
	basecolor[1] = 80;
	basecolor[2] = 50;

// pull the colors halfway to bright brown
	for (i=0 ; i<256 ; i++)
	{
		for (j=0 ; j<3 ; j++)
		{
			newpalette[i*3+j] = (host_basepal[i*3+j] + basecolor[j])/2;
		}
	}
	
	VID_ShiftPalette (newpalette);
}


/*
===================
R_TransformFrustum
===================
*/
void R_TransformFrustum (void)
{
	int		i;
	vec3_t	v, v2;
	
	for (i=0 ; i<4 ; i++)
	{
		v[0] = screenedge[i].normal[2];
		v[1] = -screenedge[i].normal[0];
		v[2] = screenedge[i].normal[1];

		v2[0] = v[1]*vright[0] + v[2]*vup[0] + v[0]*vpn[0];
		v2[1] = v[1]*vright[1] + v[2]*vup[1] + v[0]*vpn[1];
		v2[2] = v[1]*vright[2] + v[2]*vup[2] + v[0]*vpn[2];

		VectorCopy (v2, view_clipplanes[i].normal);

		view_clipplanes[i].dist = DotProduct (modelorg, v2);
	}
}


#if !id386

/*
================
TransformVector
================
*/
void TransformVector (vec3_t in, vec3_t out)
{
	out[0] = DotProduct(in,vright);
	out[1] = DotProduct(in,vup);
	out[2] = DotProduct(in,vpn);		
}

#endif


/*
================
R_TransformPlane
================
*/
void R_TransformPlane (mplane_t *p, float *normal, float *dist)
{
	float	d;
	
	d = DotProduct (r_origin, p->normal);
	*dist = p->dist - d;
// TODO: when we have rotating entities, this will need to use the view matrix
	TransformVector (p->normal, normal);
}


/*
===============
R_SetUpFrustumIndexes
===============
*/
void R_SetUpFrustumIndexes (void)
{
	int		i, j, *pindex;

	pindex = r_frustum_indexes;

	for (i=0 ; i<4 ; i++)
	{
		for (j=0 ; j<3 ; j++)
		{
			if (view_clipplanes[i].normal[j] < 0)
			{
				pindex[j] = j;
				pindex[j+3] = j+3;
			}
			else
			{
				pindex[j] = j+3;
				pindex[j+3] = j;
			}
		}

	// FIXME: do just once at start
		pfrustum_indexes[i] = pindex;
		pindex += 6;
	}
}


/*
===============
R_SetupFrame
===============
*/
void R_SetupFrame (void)
{
	int				edgecount;
	vrect_t			vrect;
	float			w, h;

	if (r_numsurfs.value)
	{
		if ((surface_p - surfaces) > r_maxsurfsseen)
			r_maxsurfsseen = surface_p - surfaces;

		Com_Printf ("Used %d of %d surfs; %d max\n", surface_p - surfaces,
				surf_max - surfaces, r_maxsurfsseen);
	}

	if (r_numedges.value)
	{
		edgecount = edge_p - r_edges;

		if (edgecount > r_maxedgesseen)
			r_maxedgesseen = edgecount;

		Com_Printf ("Used %d of %d edges; %d max\n", edgecount,
				r_numallocatededges, r_maxedgesseen);
	}

	r_refdef.ambientlight = r_refdef2.allowCheats ? min((int)r_ambient.value, 0) : 0;

	R_CheckVariables ();
	
	R_AnimateLight ();

	r_framecount++;

// build the transformation matrix for the given view angles
	VectorCopy (r_refdef.vieworg, modelorg);
	VectorCopy (r_refdef.vieworg, r_origin);

	AngleVectors (r_refdef.viewangles, vpn, vright, vup);

// current viewleaf
	r_oldviewleaf = r_viewleaf;
	r_viewleaf = Mod_PointInLeaf (r_origin, cl.worldmodel);

	r_dowarpold = r_dowarp;
	r_dowarp = r_waterwarp.value && (r_viewleaf->contents <= CONTENTS_WATER);

	if ((r_dowarp != r_dowarpold) || r_viewchanged)
	{
		if (r_dowarp)
		{
			if ((vid.width <= vid.maxwarpwidth) &&
				(vid.height <= vid.maxwarpheight))
			{
				vrect.x = 0;
				vrect.y = 0;
				vrect.width = vid.width;
				vrect.height = vid.height;

				R_ViewChanged (&vrect, sb_lines, vid.aspect);
			}
			else
			{
				w = vid.width;
				h = vid.height;

				if (w > vid.maxwarpwidth)
				{
					h *= (float)vid.maxwarpwidth / w;
					w = vid.maxwarpwidth;
				}

				if (h > vid.maxwarpheight)
				{
					h = vid.maxwarpheight;
					w *= (float)vid.maxwarpheight / h;
				}

				vrect.x = 0;
				vrect.y = 0;
				vrect.width = (int)w;
				vrect.height = (int)h;

				R_ViewChanged (&vrect,
							   (int)((float)sb_lines * (h/(float)vid.height)),
							   vid.aspect * (h / w) *
								 ((float)vid.width / (float)vid.height));
			}
		}
		else
		{
			vrect.x = 0;
			vrect.y = 0;
			vrect.width = vid.width;
			vrect.height = vid.height;

			R_ViewChanged (&vrect, sb_lines, vid.aspect);
		}

		r_viewchanged = false;
	}

// start off with just the four screen edge clip planes
	R_TransformFrustum ();

// save base values
	VectorCopy (vpn, base_vpn);
	VectorCopy (vright, base_vright);
	VectorCopy (vup, base_vup);
	VectorCopy (modelorg, base_modelorg);

	R_SetSkyFrame ();

	R_SetUpFrustumIndexes ();

	r_cache_thrash = false;

// clear frame counts
	c_faceclip = 0;
	d_spanpixcount = 0;
	r_polycount = 0;
	r_drawnpolycount = 0;
	r_wholepolycount = 0;
	r_amodels_drawn = 0;
	r_outofsurfaces = 0;
	r_outofedges = 0;

	D_SetupFrame ();
}

void R_32To8bit (unsigned int *in, int inwidth, int inheight, byte *out, int outwidth, int outheight)
{
	extern unsigned char d_15to8table[65536];

	assert(outwidth <= inwidth && outheight <= inheight);

	if (inwidth == outwidth && inheight == outheight) {
		int	i;
		for (i = inwidth*inheight; i; i--, in++)
			*out++ = d_15to8table[((*in & 0xf8)>>3) +	((*in & 0xf800)>>6) + ((*in & 0xf80000)>>9)];
	}
	else
	{	// scale down
		int i, j, pix;
		unsigned frac, fracstep;
		unsigned int *inrow;

		fracstep = (inwidth * 0x10000) / outwidth;
		for (i = 0; i < outheight; i++)
		{
			inrow = (int *)in + inwidth*(i*inheight/outheight);
			frac = fracstep >> 1;
			for (j = outwidth >> 2 ; j ; j--)
			{
				pix = inrow[frac >> 16]; frac += fracstep;
				out[0] = d_15to8table[((pix & 0xf8)>>3) + ((pix & 0xf800)>>6) + ((pix & 0xf80000)>>9)];
				pix = inrow[frac >> 16]; frac += fracstep;
				out[1] = d_15to8table[((pix & 0xf8)>>3) + ((pix & 0xf800)>>6) + ((pix & 0xf80000)>>9)];
				pix = inrow[frac >> 16]; frac += fracstep;
				out[2] = d_15to8table[((pix & 0xf8)>>3) + ((pix & 0xf800)>>6) + ((pix & 0xf80000)>>9)];
				pix = inrow[frac >> 16]; frac += fracstep;
				out[3] = d_15to8table[((pix & 0xf8)>>3) + ((pix & 0xf800)>>6) + ((pix & 0xf80000)>>9)];
				out += 4;
			}
			for (j = outwidth & 3 ; j ; j--)
			{
				pix = inrow[frac >> 16]; frac += fracstep;
				*out++ = d_15to8table[((pix & 0xf8)>>3) + ((pix & 0xf800)>>6) + ((pix & 0xf80000)>>9)];
			}
		}
	}
}


/* 
============================================================================== 
 
						SCREEN SHOTS 
 
============================================================================== 
*/ 


/* 
================== 
R_ScreenShot_f
================== 
*/  
void R_ScreenShot_f (void) 
{ 
	int			i; 
	char		pcxname[MAX_OSPATH]; 
	char		checkname[MAX_OSPATH];
	extern byte	current_pal[768];	// Tonik
	FILE		*f;
	byte		*pcxdata;
	int			pcxsize;

	if (Cmd_Argc() == 2) {
		strlcpy (pcxname, Cmd_Argv(1), sizeof(pcxname));
		COM_ForceExtension (pcxname, ".pcx");
	}
	else
	{
		// 
		// find a file name to save it to 
		// 
		strcpy(pcxname,"quake00.pcx");
		
		for (i=0 ; i<=99 ; i++) 
		{ 
			pcxname[5] = i/10 + '0'; 
			pcxname[6] = i%10 + '0'; 
			sprintf (checkname, "%s/%s", cls.gamedir, pcxname);
			f = fopen (checkname, "rb");
			if (!f)
				break;  // file doesn't exist
			fclose (f);
		} 
		if (i==100) 
		{
			Com_Printf ("R_ScreenShot_f: Couldn't create a PCX"); 
			return;
		}
	}
 
// 
// save the pcx file 
// 
	D_EnableBackBufferAccess ();

	WritePCX (vid.buffer, vid.width, vid.height, vid.rowbytes,
				  current_pal, &pcxdata, &pcxsize);

	D_DisableBackBufferAccess ();

	COM_WriteFile (va("%s/%s", cls.gamedirfile, pcxname), pcxdata, pcxsize);

	Com_Printf ("Wrote %s\n", pcxname);
} 

/*
Find closest color in the palette for named color
*/
int MipColor(int r, int g, int b)
{
	int i;
	float dist;
	int best;
	float bestdist;
	int r1, g1, b1;
	static int lr = -1, lg = -1, lb = -1;
	static int lastbest;

	if (r == lr && g == lg && b == lb)
		return lastbest;

	bestdist = 256*256*3;

	for (i = 0; i < 256; i++) {
		r1 = host_basepal[i*3] - r;
		g1 = host_basepal[i*3+1] - g;
		b1 = host_basepal[i*3+2] - b;
		dist = r1*r1 + g1*g1 + b1*b1;
		if (dist < bestdist) {
			bestdist = dist;
			best = i;
		}
	}
	lr = r; lg = g; lb = b;
	lastbest = best;
	return best;
}

// in r_draw.c
extern byte		*draw_chars;				// 8*8 graphic characters

void R_DrawCharToSnap (int num, byte *dest, int width)
{
	int		row, col;
	byte	*source;
	int		drawline;
	int		x;

	row = num>>4;
	col = num&15;
	source = draw_chars + (row<<10) + (col<<3);

	drawline = 8;

	while (drawline--)
	{
		for (x=0 ; x<8 ; x++)
			if (source[x])
				dest[x] = source[x];
			else
				dest[x] = 98;
		source += 128;
		dest += width;
	}

}

void R_DrawStringToSnap (const char *s, byte *buf, int x, int y, int width)
{
	byte *dest;
	const unsigned char *p;

	dest = buf + ((y * width) + x);

	p = (const unsigned char *)s;
	while (*p) {
		R_DrawCharToSnap(*p++, dest, width);
		dest += 8;
	}
}


/* 
================== 
R_RSShot

Memory pointed to by pcxdata is allocated using Hunk_TempAlloc
Never store this pointer for later use!

On failure (not enough memory), *pcxdata will be set to NULL
================== 
*/  
void R_RSShot (byte **pcxdata, int *pcxsize)
{ 
	int     x, y;
	unsigned char		*src, *dest;
	unsigned char		*newbuf;
	int w, h;
	int dx, dy, dex, dey, nx;
	int r, b, g;
	int count;
	float fracw, frach;
	char st[80];
	time_t now;
	extern cvar_t name;

// 
// save the pcx file 
// 
	D_EnableBackBufferAccess ();

	w = (vid.width < RSSHOT_WIDTH) ? vid.width : RSSHOT_WIDTH;
	h = (vid.height < RSSHOT_HEIGHT) ? vid.height : RSSHOT_HEIGHT;

	fracw = (float)vid.width / (float)w;
	frach = (float)vid.height / (float)h;

	newbuf = Q_malloc (w*h);

	for (y = 0; y < h; y++) {
		dest = newbuf + (w * y);

		for (x = 0; x < w; x++) {
			r = g = b = 0;

			dx = x * fracw;
			dex = (x + 1) * fracw;
			if (dex == dx) dex++; // at least one
			dy = y * frach;
			dey = (y + 1) * frach;
			if (dey == dy) dey++; // at least one

			count = 0;
			for (/* */; dy < dey; dy++) {
				src = vid.buffer + (vid.rowbytes * dy) + dx;
				for (nx = dx; nx < dex; nx++) {
					r += host_basepal[*src * 3];
					g += host_basepal[*src * 3+1];
					b += host_basepal[*src * 3+2];
					src++;
					count++;
				}
			}
			r /= count;
			g /= count;
			b /= count;
			*dest++ = MipColor(r, g, b);
		}
	}

	D_DisableBackBufferAccess ();

	time(&now);
	strcpy(st, ctime(&now));
	st[strlen(st) - 1] = 0;		// remove the trailing \n
	R_DrawStringToSnap (st, newbuf, w - strlen(st)*8, 0, w);

	strlcpy (st, cls.servername, sizeof(st));
	R_DrawStringToSnap (st, newbuf, w - strlen(st)*8, 10, w);

	strlcpy (st, name.string, sizeof(st));
	R_DrawStringToSnap (st, newbuf, w - strlen(st)*8, 20, w);

	WritePCX (newbuf, w, h, w, host_basepal, pcxdata, pcxsize);

	Q_free (newbuf);

	// return with pcxdata and pcxsize
} 

//=============================================================================
