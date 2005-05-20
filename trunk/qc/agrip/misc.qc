/*  Copyright (C) 2004  Matthew T. Atkinson

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA

    See file, 'COPYING', for details.
*/

/* $AGRIP-START */
/* AGRIP Misc Functions */


// CONSTANTS

// for misc...
float SNAP_MISC_NORMYAW_OFFSET = 0;

// for nav...
float SNAP_NAV_STRUCT_WALL = 40;
float SNAP_NAV_STRUCT_SLOPE = 41; 
float SNAP_NAV_STRUCT_SLOPE_DOWN = 41.5;
float SNAP_NAV_STRUCT_DOOR = 42;

float SNAP_NAV_DIR_FWD = 1;
float SNAP_NAV_DIR_BCK = 2;
float SNAP_NAV_DIR_LFT = 4;
float SNAP_NAV_DIR_RGT = 8;
float SNAP_NAV_DIR_UP = 16;
float SNAP_NAV_DIR_DN = 32;

float SNAP_NAV_JMP_NRM = 1;
float SNAP_NAV_JMP_RUN = 2;


// PROTOTYPES

// OBJECT UTILITY FUNCTIONS
float   (vector targ_origin)                        snap_misc_ownervisible;
void    (string msg_string)                         snap_misc_m2o;

// PLAYER UTILITY FUNCTIONS
void    ()                                          snap_misc_weaponswitch;
void    ()                                          snap_misc_blockedtest;
void    (float direction)                           snap_misc_blockedtest_propchg;
void    (string msg_string)                         snap_misc_m2m;

// GENERIC UTILITY FUNCTIONS
float   (float init_yaw)                            snap_misc_normalyaw;
void    (vector point, string sprite, float ttl)    snap_misc_showpoint;
float   (vector jump_origin, vector move_dir)       snap_misc_jumptest;


// IMPLEMENTATIONS

// OBJECT UTILITY FUNCTIONS

float (vector targ_origin) snap_misc_ownervisible =
/*
    Purpose:
        This function is used by ESR and D5k to determine if the
        player that owns it can ``see'' an object.
        PLEASE NOTE that this INCLUDES a check for if the object is
        within the player's FOV (90 degrees).
    Takes:
        vector targ_origin  - the entity we're trying to assess for
                              visibility.
    Returns:
        float               - true or false
*/
{
    traceline(self.owner.origin, targ_origin, true, self);

    if( trace_fraction == 1 )
    {
        local float obj_orig_yaw, player_normal_yaw;
        local float min_fov_yaw, max_fov_yaw;
    
        // Get yaw of targ's origin relative to player...
        obj_orig_yaw = vectoyaw(targ_origin - self.owner.origin);
        obj_orig_yaw = snap_misc_normalyaw(obj_orig_yaw);
    
        // Get yaw of player...
        player_normal_yaw = snap_misc_normalyaw(self.owner.angles_y);
    
        // Work out the bounds that will be used to test if the object is within
        // the player's FOV...
        
        // For min...
        min_fov_yaw = player_normal_yaw - 45;
        /*if( min_fov_yaw > 360 )
            min_fov_yaw = min_fov_yaw - 360;
        else if(min_fov_yaw < 0 )
            min_fov_yaw = min_fov_yaw + 360;*/
    
        // For max...
        max_fov_yaw = player_normal_yaw + 45;
        /*if( max_fov_yaw > 360 )
            max_fov_yaw = max_fov_yaw - 360;
        else if(max_fov_yaw < 0 )
            max_fov_yaw = max_fov_yaw + 360;*/
        
        // Debug info
        /*dprint("fovtest1 :: owner yaw = ");dprint(ftos(player_normal_yaw));
        dprint("  obj_orig_yaw = ");dprint(ftos(obj_orig_yaw));dprint("\n");
        dprint("fovtest2 :: min yaw = ");dprint(ftos(min_fov_yaw));
        dprint("  max yaw = ");dprint(ftos(max_fov_yaw));dprint("\n");*/
    
        // Is it within our FOV?
        if( min_fov_yaw <= obj_orig_yaw && max_fov_yaw >= obj_orig_yaw )
        {
            return true;
        }
        else
        {
            // Could be that annoying 360 bug...
            obj_orig_yaw = obj_orig_yaw - 360;
            if( min_fov_yaw <= obj_orig_yaw && max_fov_yaw >= obj_orig_yaw )
                return true;
            else
                return false;
        }
    }
    else
    {
        return false;
    }
};

void (string msg_string) snap_misc_m2o =
/*
    Purpose:
        Print a message to the owner of self with high importance.
    Takes:
        * string message    - the message
    Returns:
        void
    Notes:
        Is used by all keypress events because they should happen in real time.
*/
{
    if( ! self.owner.agrip_aux.state )
        sprint(self.owner, PRINT_MEDIUM, "!", msg_string);
    else
        sprint(self.owner, PRINT_MEDIUM, msg_string);
};


// PLAYER UTILITY FUNCTIONS

void () snap_misc_weaponswitch =
/*
    Purpose:
        When the player's weapon is changed (by number keys or `/') this
        works out which weapon is now being used and makes a sound to tell
        the player which weapon they've got.
    Takes:
        void
    Returns:
        void
*/
{
    if( self.weapon == IT_AXE )
        snap_misc_m2m("Axe.\n");
    else if( self.weapon == IT_SHOTGUN )
        snap_misc_m2m("Shotgun.\n");
    else if( self.weapon == IT_SUPER_SHOTGUN )
        snap_misc_m2m("Double-Barrelled Shotgun.\n");
    else if (self.weapon == IT_NAILGUN )
        snap_misc_m2m("Nailgun.\n");
    else if (self.weapon == IT_SUPER_NAILGUN )
        snap_misc_m2m("Super Nailgun.\n");
    else if (self.weapon == IT_GRENADE_LAUNCHER )
        snap_misc_m2m("Grenade Launcher.\n");
    else if (self.weapon == IT_ROCKET_LAUNCHER )
        snap_misc_m2m("Rocket Launcher.\n");
    else if (self.weapon == IT_LIGHTNING )
        snap_misc_m2m("Lightning Gun.\n");
};

void () snap_misc_blockedtest =
/*
    Purpose:
        Called by PlayerPostThink() every tick.  Detect if the player has
        collided with, or is stuck on, anything in all six drections.
    Takes:
        void
    Returns:
        void - but it does set values in self.agrip_aux
    Notes:
      + When we detect that the player is stuck, we set the ``just hit this''
        agrip-aux bitfield property to include the direction we've just hit in.
      + We also set the ``sustained touch'' bitfiled to include the direction.
        The nav object un-sets the ``just hit'' when it has noticed and made a
        wall-hit sound for that direction.
      + The footsteps code is capable of detecting scraping against walls.
      + Please read the agrip-aux.qc code for more information.
      + Because the setting/unsetting of the properties only varies with the
        direction, it is in a separate function that is called by this one.
*/
{
    // Get our velocity vectors...
    makevectors(self.angles);

    // Tracebox and store the results in the bitfields.
    // BTW, Ada really loves bitfields _and_ makes them easy to use!

    // agrip_aux properties:
    //  * .ammo_shells  - ``just hit this''
    //  * .ammo_nails   - ``sustained touch''
    //  * .ammo_rockets - count of walls we're touching

    // Forward
    tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin + ( v_forward * 10 ) ), true, self);
    snap_misc_blockedtest_propchg(SNAP_NAV_DIR_FWD);

    // Backwards
    tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin - ( v_forward * 10 ) ), true, self);
    snap_misc_blockedtest_propchg(SNAP_NAV_DIR_BCK);

    // Left
    tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin - ( v_right * 10 ) ), true, self);
    snap_misc_blockedtest_propchg(SNAP_NAV_DIR_LFT);

    // Right
    tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin + ( v_right * 10 ) ), true, self);
    snap_misc_blockedtest_propchg(SNAP_NAV_DIR_RGT);

    // If we're in water...
    // AG_FIXME - clear the up/down flags if we're not in water.
    if( 0 )
    {
        // Up
        tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin + ( v_up * 10 ) ), true, self);
        snap_misc_blockedtest_propchg(SNAP_NAV_DIR_UP);
    
        // Down
        tracebox(self.origin, VEC_HULL_MIN, VEC_HULL_MAX, (self.origin - ( v_up * 10 ) ), true, self);
        snap_misc_blockedtest_propchg(SNAP_NAV_DIR_DN);
    }
};

void (float direction) snap_misc_blockedtest_propchg =
/*
    Purpose:
        This function is called by the one that tests if we are blocked in any
        direction and sets the properties of the agrip_aux object accordingly.
    Takes:
        * float direction   - the direction we're currently processing
    Returns:
        void - it sets the values in the agrip_aux object.
*/
{
    /*if( direction == SNAP_NAV_DIR_FWD )
    {
        dprint("tracebox fraction: ");
        dprint(ftos(trace_fraction));
        dprint("\n");
    }*/

    // If we're touching a wall in this direction...
    if( trace_fraction == 0 )
    {
        // If the nav object has noticed we've hit the wall, it will have
        // cleared the ``just hit this'' flag and left the ``sustained touch''
        // one set.  We shouldn't set the ``just hit this'' if the other one
        // is still set...
        if( ! (self.agrip_aux.ammo_nails & direction) )
        {
            // Set both the ``just hit this'' and ``sustained hit'' flags...
            self.agrip_aux.ammo_shells = self.agrip_aux.ammo_shells + direction;
            self.agrip_aux.ammo_nails = self.agrip_aux.ammo_nails + direction;

            // Add this wall we're touching to the counter...
            self.agrip_aux.ammo_rockets = self.agrip_aux.ammo_rockets + 1;
        }
    }
    else
    {
        // If either of the flags are set...
        if(     (self.agrip_aux.ammo_nails & direction)
            ||  (self.agrip_aux.ammo_shells & direction) )
        {
            // Clear both flags...
            self.agrip_aux.ammo_shells = self.agrip_aux.ammo_shells - ( self.agrip_aux.ammo_shells & direction );
            self.agrip_aux.ammo_nails = self.agrip_aux.ammo_nails - ( self.agrip_aux.ammo_nails & direction );

            // Decrement the wall-touch counter...
            self.agrip_aux.ammo_rockets = self.agrip_aux.ammo_rockets - 1;
        }
    }
};

void (string msg_string) snap_misc_m2m =
/*
    Purpose:
        Print a message to the player with high importance.
    Takes:
        * string message    - the message
    Returns:
        void
    Notes:
        Is used by all keypress events because they should happen in real time.
*/
{
    if( ! self.agrip_aux.state )
        sprint(self, PRINT_MEDIUM, "!", msg_string);
    else
        sprint(self, PRINT_MEDIUM, msg_string);
};


// GENERIC UTILITY FUNCTIONS

float (float init_yaw) snap_misc_normalyaw =
/*
    Purpose:
        This normalises the yaw sent in.
    Takes:
        * float init_yaw    - the Quake yaw.
    Returns:
        * float             - the normalised yaw.
    Notes:
        The global variable ``SNAP_MISC_NORMYAW_OFFSET'' set in the function
        ``PutClientInServer'' in client.qc is used as an offset.
        This is because the player could spawn at any angle in a map -- we need
        to make sure that ``North'' is always considered to be the way they are
        facing when they spawn.
*/
{
    local float normal_yaw;

    // Normalise the incoming yaw...
    // There are 3 common situations in Quake 1 maps:
    //  1. Offset is   0
    //  2. Offset is  90
    //  3. Offest is -90

    // Apply our offset...
    // 1, 2 & 3
    normal_yaw = init_yaw - SNAP_MISC_NORMYAW_OFFSET;

    // Correct out-of-range...
    if( normal_yaw <= 0 )
        normal_yaw = normal_yaw + 360;
    else if( normal_yaw > 360 )
        normal_yaw = normal_yaw - 360;

    // Flip-Reverse it, lol...
    normal_yaw = 360 - normal_yaw;
  
    // Some debug info...
    /*dprint("NORMALYAW():\n");
    dprint("init yaw: ");dprint(ftos(init_yaw));dprint("\n");
    dprint("norm yaw: ");dprint(ftos(normal_yaw));dprint("\n");
    dprint("\n");*/

    // Return the normalised yaw...
    return normal_yaw;
};

void (vector point, string sprite, float ttl) snap_misc_showpoint =
/*
    Purpose:
        _Where's_ the point?
    Takes:
        * vector    point   - Where the point is
        * string    sprite  - The model to use
        * float     ttl     - How long to show it for
    Returns:
        void
*/
{
    local entity temp_point_ent;
    temp_point_ent = spawn();
    setorigin(temp_point_ent, point);
    setmodel(temp_point_ent, sprite);
    remove(temp_point_ent);
};

float(vector jump_origin, vector move_dir) snap_misc_jumptest =
/*
    Purpose:
        We've found a drop -- can the player jump it?
        Routine adapted for bots too.
    Takes:
        vector jump_origin
        vector move_dir
    Returns:
        float (either SNAP_NAV_JMP_RUN or SNAP_NAV_JMP_NRM)
*/
{
    local float retval;
    local vector jumptestpoint;
    // Not strictly needed but keeps things readable!
    
    // To find out if the player can make a jump.  We need to:
    //  * Look in front of the drop horizontally.
    //  * See if there is a floor to land on within a reasonable distance.
    //  * See if there is space above to provide room for the jump.
    //  * Work out if a running jump is needed.

    // Where's the point we need to test?
    // For a running jump...
    jumptestpoint = jump_origin + move_dir * 240; 
    //snap_misc_showpoint(jumptestpoint, "progs/s_light.spr", 3);
    
    // Could we make a running jump?
    traceline(jumptestpoint, jumptestpoint - '0 0 100', true, self);
    //snap_misc_showpoint(trace_endpos, "progs/s_light.spr", 3);
    if( trace_fraction != 1 )
    {
        // We can make the running jump...
        retval = SNAP_NAV_JMP_RUN;
    }

    // Where's the point we need to test?
    // For a normal jump...
    jumptestpoint = jump_origin + move_dir * 110; 
    //snap_misc_showpoint(jumptestpoint, "progs/s_bubble.spr", 3);
    
    // Could we make a normal jump?
    traceline(jumptestpoint, jumptestpoint - '0 0 100', true, self);
    //snap_misc_showpoint(trace_endpos, "progs/s_bubble.spr", 3);
    if( trace_fraction != 1 )
    {
        // We can make the normal jump...
        retval = SNAP_NAV_JMP_NRM;
    }

    return retval;
};


/* $AGRIP-END */
