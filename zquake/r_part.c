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

#include "quakedef.h"
#include "r_local.h"

vec3_t			r_pright, r_pup, r_ppn;

/*
===============
R_DrawParticles
===============
*/
void R_DrawParticles (void)
{
	int				i;
	particle_t		*p;

	D_StartParticles ();

	VectorScale (vright, xscaleshrink, r_pright);
	VectorScale (vup, yscaleshrink, r_pup);
	VectorCopy (vpn, r_ppn);
	
	for (i = 0, p = r_refdef2.particles; i < r_refdef2.numParticles; i++, p++)
	{
		D_DrawParticle (p);
	}

	D_EndParticles ();
}

