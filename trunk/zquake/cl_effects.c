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

#define ABSOLUTE_MIN_PARTICLES	512		// no fewer than this no matter what's
										// on the command line

int		ramp1[8] = {0x6f, 0x6d, 0x6b, 0x69, 0x67, 0x65, 0x63, 0x61};
int		ramp2[8] = {0x6f, 0x6e, 0x6d, 0x6c, 0x6b, 0x6a, 0x68, 0x66};
int		ramp3[8] = {0x6d, 0x6b, 6, 5, 4, 3};

cparticle_t	*active_particles, *free_particles;

cparticle_t	*cl_particles;
int			cl_numparticles;

/*
===============
CL_InitParticles
===============
*/
void CL_InitParticles (void)
{
	int		i;

	i = COM_CheckParm ("-particles");

	if (i)
	{
		cl_numparticles = (int)(Q_atoi(com_argv[i+1]));
		if (cl_numparticles < ABSOLUTE_MIN_PARTICLES)
			cl_numparticles = ABSOLUTE_MIN_PARTICLES;
	}
	else
	{
		cl_numparticles = MAX_PARTICLES;
	}

	cl_particles = (cparticle_t *)Hunk_AllocName (cl_numparticles * sizeof(cparticle_t), "particles");
}


/*
===============
CL_ClearParticles
===============
*/
void CL_ClearParticles (void)
{
	int		i;
	
	free_particles = &cl_particles[0];
	active_particles = NULL;

	for (i=0 ;i<cl_numparticles ; i++)
		cl_particles[i].next = &cl_particles[i+1];
	cl_particles[cl_numparticles-1].next = NULL;
}

static cparticle_t *new_particle (void)
{
	cparticle_t	*p;

	if (!free_particles)
		return NULL;

	p = free_particles;
	free_particles = p->next;
	p->next = active_particles;
	p->alpha = 1.0f;
	VectorClear (p->vel);
	active_particles = p;

	return p;
}

void CL_ReadPointFile_f (void)
{
	FILE	*f;
	vec3_t	org;
	int		r;
	int		c;
	cparticle_t	*p;
	char	name[MAX_OSPATH];
	extern cvar_t	cl_mapname;

	if (!com_serveractive)
		return;

	sprintf (name, "maps/%s.pts", cl_mapname.string);

	FS_FOpenFile (name, &f);
	if (!f)
	{
		Com_Printf ("couldn't open %s\n", name);
		return;
	}
	
	Com_Printf ("Reading %s...\n", name);
	c = 0;
	for ( ;; )
	{
		r = fscanf (f,"%f %f %f\n", &org[0], &org[1], &org[2]);
		if (r != 3)
			break;
		c++;
		
		if (!(p = new_particle()))
		{
			Com_Printf ("Not enough free particles\n");
			break;
		}

		p->die = 99999;
		p->color = (-c)&15;
		p->type = pt_static;
		VectorClear (p->vel);
		VectorCopy (org, p->org);
	}

	fclose (f);
	Com_Printf ("%i points read\n", c);
}
	
/*
===============
CL_ParticleExplosion
===============
*/
void CL_ParticleExplosion (vec3_t org)
{
	int			i, j;
	cparticle_t	*p;
	
	for (i=0 ; i<1024 ; i++)
	{
		if (!(p = new_particle()))
			return;

		p->die = cl.time + 5;
		p->color = ramp1[0];
		p->ramp = rand()&3;
		if (i & 1)
		{
			p->type = pt_explode;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((rand()%32)-16);
				p->vel[j] = (rand()%512)-256;
			}
		}
		else
		{
			p->type = pt_explode2;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((rand()%32)-16);
				p->vel[j] = (rand()%512)-256;
			}
		}
	}
}

/*
===============
CL_BlobExplosion
===============
*/
void CL_BlobExplosion (vec3_t org)
{
	int			i, j;
	cparticle_t	*p;
	
	for (i=0 ; i<1024 ; i++)
	{
		if (!(p = new_particle()))
			return;

		p->die = cl.time + 1 + (rand()&8)*0.05;

		if (i & 1)
		{
			p->type = pt_blob;
			p->color = 66 + rand()%6;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((rand()%32)-16);
				p->vel[j] = (rand()%512)-256;
			}
		}
		else
		{
			p->type = pt_blob2;
			p->color = 150 + rand()%6;
			for (j=0 ; j<3 ; j++)
			{
				p->org[j] = org[j] + ((rand()%32)-16);
				p->vel[j] = (rand()%512)-256;
			}
		}
	}
}

/*
===============
CL_RunParticleEffect
===============
*/
void CL_RunParticleEffect (vec3_t org, vec3_t dir, int color, int count)
{
	int			i, j;
	cparticle_t	*p;
	int			scale;

	if (count > 130)
		scale = 3;
	else if (count > 20)
		scale = 2;
	else
		scale = 1;

	for (i=0 ; i<count ; i++)
	{
		if (!(p = new_particle()))
			return;

		p->die = cl.time + 0.1*(rand()%5);
		p->color = (color&~7) + (rand()&7);
		p->type = pt_grav;
		for (j=0 ; j<3 ; j++)
		{
			p->org[j] = org[j] + scale*((rand()&15)-8);
			p->vel[j] = dir[j]*15;// + (rand()%300)-150;
		}
	}
}

/*
===============
CL_LavaSplash
===============
*/
void CL_LavaSplash (vec3_t org)
{
	int			i, j, k;
	cparticle_t	*p;
	float		vel;
	vec3_t		dir;

	for (i=-16 ; i<16 ; i++)
		for (j=-16 ; j<16 ; j++)
			for (k=0 ; k<1 ; k++)
			{
				if (!(p = new_particle()))
					return;
		
				p->die = cl.time + 2 + (rand()&31) * 0.02;
				p->color = 224 + (rand()&7);
				p->type = pt_grav;

				dir[0] = j*8 + (rand()&7);
				dir[1] = i*8 + (rand()&7);
				dir[2] = 256;
				
				p->org[0] = org[0] + dir[0];
				p->org[1] = org[1] + dir[1];
				p->org[2] = org[2] + (rand()&63);

				VectorNormalize (dir);
				vel = 50 + (rand()&63);
				VectorScale (dir, vel, p->vel);
			}
}

/*
===============
CL_TeleportSplash
===============
*/
void CL_TeleportSplash (vec3_t org)
{
	int			i, j, k;
	cparticle_t	*p;
	float		vel;
	vec3_t		dir;

	for (i=-16 ; i<16 ; i+=4)
		for (j=-16 ; j<16 ; j+=4)
			for (k=-24 ; k<32 ; k+=4)
			{
				if (!(p = new_particle()))
					return;
		
				p->die = cl.time + 0.2 + (rand()&7) * 0.02;
				p->color = 7 + (rand()&7);
				p->type = pt_grav;

				dir[0] = j*8;
				dir[1] = i*8;
				dir[2] = k*8;
				
				p->org[0] = org[0] + i + (rand()&3);
				p->org[1] = org[1] + j + (rand()&3);
				p->org[2] = org[2] + k + (rand()&3);
				
				VectorNormalize (dir);
				vel = 50 + (rand()&63);
				VectorScale (dir, vel, p->vel);
			}
}

/*
===============
CL_RocketTrail
===============
*/
void CL_RocketTrail (vec3_t start, vec3_t end, int type)
{
	vec3_t	vec;
	float	len;
	int			j;
	cparticle_t	*p;

	VectorSubtract (end, start, vec);
	len = VectorNormalize (vec);
	VectorScale (vec, 3, vec);
	while (len > 0)
	{
		len -= 3;

		if (!(p = new_particle()))
			return;
		
		VectorClear (p->vel);
		p->die = cl.time + 2;

		if (type == 4)
		{	// slight blood
			p->type = pt_slowgrav;
			p->color = 67 + (rand()&3);
			for (j=0 ; j<3 ; j++)
				p->org[j] = start[j] + ((rand()%6)-3);
			len -= 3;
		}
		else if (type == 2)
		{	// blood
			p->type = pt_slowgrav;
			p->color = 67 + (rand()&3);
			for (j=0 ; j<3 ; j++)
				p->org[j] = start[j] + ((rand()%6)-3);
		}
		else if (type == 6)
		{	// voor trail
			p->color = 9*16 + 8 + (rand()&3);
			p->type = pt_static;
			p->die = cl.time + 0.3;
			for (j=0 ; j<3 ; j++)
				p->org[j] = start[j] + ((rand()&15)-8);
		}
		else if (type == 1)
		{	// smoke
			p->ramp = (rand()&3) + 2;
			p->color = ramp3[(int)p->ramp];
			p->type = pt_fire;
			for (j=0 ; j<3 ; j++)
				p->org[j] = start[j] + ((rand()%6)-3);
		}
		else if (type == 0)
		{	// rocket trail
			p->ramp = (rand()&3);
			p->color = ramp3[(int)p->ramp];
			p->type = pt_fire;
			for (j=0 ; j<3 ; j++)
				p->org[j] = start[j] + ((rand()%6)-3);
		}
		else if (type == 3 || type == 5)
		{	// tracer
			static int tracercount;

			p->die = cl.time + 0.5;
			p->type = pt_static;
			if (type == 3)
				p->color = 52 + ((tracercount&4)<<1);
			else
				p->color = 230 + ((tracercount&4)<<1);
			
			tracercount++;

			VectorCopy (start, p->org);
			if (tracercount & 1)
			{
				p->vel[0] = 30*vec[1];
				p->vel[1] = 30*-vec[0];
			}
			else
			{
				p->vel[0] = 30*-vec[1];
				p->vel[1] = 30*vec[0];
			}
			
		}

		VectorAdd (start, vec, start);
	}
}

/*
===============
CL_LinkParticles
===============
*/
void CL_LinkParticles (void)
{
	cparticle_t		*p, *kill;
	float			grav;
	int				i;
	float			time1, time2, time3;
	float			dvel;
	float			frametime;

	for ( ;; )
	{
		kill = active_particles;
		if (kill && kill->die < cl.time)
		{
			active_particles = kill->next;
			kill->next = free_particles;
			free_particles = kill;
			continue;
		}
		break;
	}

	frametime = cls.frametime;
	time1 = frametime * 5;
	time2 = frametime * 10; // 15;
	time3 = frametime * 15;
	grav = frametime * 800 * 0.05;
	dvel = 4 * frametime;

	for (p=active_particles ; p ; p=p->next)
	{
		// blindly add all particles if paused
		if (cl.paused) 
		{
			V_AddParticle (p->org, p->color, p->alpha);
			continue;
		}

		for ( ;; )
		{
			kill = p->next;
			if (kill && kill->die < cl.time)
			{
				p->next = kill->next;
				kill->next = free_particles;
				free_particles = kill;
				continue;
			}
			break;
		}

		p->org[0] += p->vel[0] * frametime;
		p->org[1] += p->vel[1] * frametime;
		p->org[2] += p->vel[2] * frametime;

		switch (p->type)
		{
			case pt_static:
				break;

			case pt_fire:
				p->ramp += time1;
				if (p->ramp >= 6)
					p->die = -1;
				else
					p->color = ramp3[(int)p->ramp];
				p->alpha = (6-p->ramp)/6;
				p->vel[2] += grav;
				break;

			case pt_explode:
				p->ramp += time2;
				if (p->ramp >=8)
					p->die = -1;
				else
					p->color = ramp1[(int)p->ramp];
				for (i=0 ; i<3 ; i++)
					p->vel[i] += p->vel[i]*dvel;
				p->vel[2] -= grav;
				break;

			case pt_explode2:
				p->ramp += time3;
				if (p->ramp >=8)
					p->die = -1;
				else
					p->color = ramp2[(int)p->ramp];
				for (i=0 ; i<3 ; i++)
					p->vel[i] -= p->vel[i]*frametime;
				p->vel[2] -= grav;
				break;

			case pt_blob:
				for (i=0 ; i<3 ; i++)
					p->vel[i] += p->vel[i]*dvel;
				p->vel[2] -= grav;
				break;

			case pt_blob2:
				for (i=0 ; i<2 ; i++)
					p->vel[i] -= p->vel[i]*dvel;
				p->vel[2] -= grav;
				break;

			case pt_grav:
			case pt_slowgrav:
				p->vel[2] -= grav;
				break;
		}

		V_AddParticle (p->org, p->color, p->alpha);
	}
}
