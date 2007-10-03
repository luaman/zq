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
// mathlib.h
#ifndef _MATHLIB_H_
#define _MATHLIB_H_

#define	PITCH	0		// up / down
#define	YAW		1		// left / right
#define	ROLL	2		// fall over

typedef float vec_t;
typedef vec_t vec3_t[3];
typedef vec_t vec4_t[4];
typedef vec_t vec5_t[5];

typedef	int	fixed4_t;
typedef	int	fixed8_t;
typedef	int	fixed16_t;

#ifndef M_PI
#define M_PI		3.14159265358979323846	// matches value in gcc v2 math.h
#endif

// !!! if this is changed, it must be changed in asm_i386.h too !!!
typedef struct mplane_s
{
	vec3_t	normal;
	float	dist;
	byte	type;			// for texture axis selection and fast side tests
	byte	signbits;		// signx + signy<<1 + signz<<1
	byte	pad[2];
} mplane_t;


EXTERNC extern vec3_t vec3_origin;

#define DEG2RAD( a ) ( ( (a) * M_PI ) / 180.0f )
#define RAD2DEG( a ) ( ( (a) * 180.0f ) / M_PI )

#define NANMASK (255<<23)
#define	IS_NAN(x) (((*(int *)&x)&NANMASK)==NANMASK)

#define Q_rint(x) ((x) > 0 ? (int)((x) + 0.5) : (int)((x) - 0.5))

#define DotProduct(x,y)			(x[0]*y[0]+x[1]*y[1]+x[2]*y[2])
#define VectorSubtract(a,b,c)	(c[0]=a[0]-b[0],c[1]=a[1]-b[1],c[2]=a[2]-b[2])
#define VectorAdd(a,b,c)		(c[0]=a[0]+b[0],c[1]=a[1]+b[1],c[2]=a[2]+b[2])
#define VectorCopy(a,b)			(b[0]=a[0],b[1]=a[1],b[2]=a[2])
#define VectorClear(a)			(a[0]=a[1]=a[2]=0)
#define VectorNegate(a,b)		(b[0]=-a[0],b[1]=-a[1],b[2]=-a[2])
#define VectorSet(v, x, y, z)	(v[0]=(x),v[1]=(y),v[2]=(z))

EXTERNC void VectorMA (const vec3_t veca, float scale, const vec3_t vecb, vec3_t vecc);

vec_t _DotProduct (const vec3_t v1, const vec3_t v2);
void _VectorSubtract (const vec3_t veca, const vec3_t vecb, vec3_t out);
void _VectorAdd (const vec3_t veca, const vec3_t vecb, vec3_t out);
void _VectorCopy (const vec3_t in, vec3_t out);

EXTERNC int VectorCompare (const vec3_t v1, const vec3_t v2);
EXTERNC vec_t VectorLength (const vec3_t v);
EXTERNC vec_t VectorLengthSquared (const vec3_t v);
EXTERNC void CrossProduct (const vec3_t v1, const vec3_t v2, vec3_t cross);
EXTERNC float VectorNormalize (vec3_t v);		// returns vector length
EXTERNC float VectorNormalize2 (const vec3_t v, vec3_t out);
EXTERNC void VectorScale (const vec3_t in, vec_t scale, vec3_t out);

#define LerpFloat(from, to, frac) ((from) + (frac)*((to) - (from)))
EXTERNC void LerpVector (const vec3_t from, const vec3_t to, float frac, vec3_t out);
EXTERNC void LerpAngles (const vec3_t from, const vec3_t to, float frac, vec3_t out);

int Q_log2(int val);

EXTERNC void R_ConcatRotations (const float in1[3][3], const float in2[3][3], float out[3][3]);
EXTERNC void R_ConcatTransforms (const float in1[3][4], const float in2[3][4], float out[3][4]);

EXTERNC void FloorDivMod (double numer, double denom, int *quotient,
		int *rem);

EXTERNC void vectoangles(const vec3_t vec, vec3_t ang);
EXTERNC void AngleVectors (const vec3_t angles, vec3_t forward, vec3_t right, vec3_t up);
EXTERNC void MakeNormalVectors (const vec3_t forward, vec3_t right, vec3_t up);
EXTERNC int BoxOnPlaneSide (vec3_t emins, vec3_t emaxs, struct mplane_s *plane);
float	anglemod(float a);

EXTERNC void PerpendicularVector( vec3_t dst, const vec3_t src );
EXTERNC void RotatePointAroundVector( vec3_t dst, const vec3_t dir, const vec3_t point, float degrees );


#define BOX_ON_PLANE_SIDE(emins, emaxs, p)	\
	(((p)->type < 3)?						\
	(										\
		((p)->dist <= (emins)[(p)->type])?	\
			1								\
		:									\
		(									\
			((p)->dist >= (emaxs)[(p)->type])?\
				2							\
			:								\
				3							\
		)									\
	)										\
	:										\
		BoxOnPlaneSide( (emins), (emaxs), (p)))

#endif /* _MATHLIB_H_ */

