/*
	hip_misc.qc

	spawn functions for misc entities - ambient sounds etc

	Copyright (C) 2004  Anton 'Tonik' Gavrilov

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

//============================================================================

/*QUAKED ambient_humming
*/
void ambient_humming ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/humming.wav");
	ambientsound (self.origin, "ambient/humming.wav", self.volume, ATTN_STATIC);
	remove (self);
}


/*QUAKED ambient_rushing
*/
void ambient_rushing ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/rushing.wav");
	ambientsound (self.origin, "ambient/rushing.wav", self.volume, ATTN_STATIC);
	remove (self);
}

/*QUAKED ambient_fan_blowing
*/
void ambient_fan_blowing ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/fanblow.wav");
	ambientsound (self.origin, "ambient/fanblow.wav", self.volume, ATTN_STATIC);
	remove (self);
}

/*QUAKED ambient_running_water
*/
void ambient_running_water ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/runwater.wav");
	ambientsound (self.origin, "ambient/runwater.wav", self.volume, ATTN_STATIC);
	remove (self);
}

/*QUAKED ambient_waterfall
*/
void ambient_waterfall ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/waterfal.wav");
	ambientsound (self.origin, "ambient/waterfal.wav", self.volume, ATTN_STATIC);
	remove (self);
}

/*QUAKED ambient_riftpower
*/
void ambient_riftpower ()
{
	if (!self.volume)
		self.volume = 1;
	precache_sound ("ambient/riftpowr.wav");
	ambientsound (self.origin, "ambient/riftpowr.wav", self.volume, ATTN_STATIC);
	remove (self);
}

//============================================================================
