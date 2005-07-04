/*  Copyright (C) 2004, 2005  Matthew T. Atkinson

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
/* AGRIP Normal QuakeC Hook Functions */

// NOTES
//
// These are called from the main QuakeC code.  They're separated out like this
// so as to keep the footprint on the main code as small as possible.
// 
// The functions are named using the following convention:
//
//      agh_<qc-file-name>_<function-name>
//
// This allows us to know:
//
//      * The function is a hook.
//      * The main QC file that the function is in.
//      * An at-a-glance description of what the function does.
//


// PROTOTYPES

void() agh_world_precaches;
void() agh_world_padclients;
void() agh_client_startdevs;
void() agh_client_padclients_connect;
void() agh_client_padclients_disconnect;
void() agh_player_footsteps;
void() agh_player_dietidy;
void() agh_weapons_impulsecommands;


// IMPLEMENTATIONS

void() agh_world_precaches =
/*
    Purpose:
        Provide all of the precaches for an accessible game.
    Takes:
	void
    Returns:
	void
*/
{
    // Stuff to re-factor:
    precache_model("progs/s_light.spr");
    precache_sound("weapons/ric1.wav");
    precache_sound("player/land.wav");
    precache_sound("weapons/tink1.wav");

    // Welcome message
    precache_sound ("welcome.wav");

    // End of Level
    precache_sound ("endlevel.wav");

    // Drop Sounds
    precache_sound ("haz/drop-huge.wav");
    precache_sound ("haz/drop-big.wav");
    precache_sound ("haz/drop-small.wav");

    // EtherScan RADAR
    precache_sound ("esr/monster-higher.wav");
    precache_sound ("esr/monster-same.wav");
    precache_sound ("esr/monster-boc.wav");
    precache_sound ("esr/monster-lower.wav");
    precache_sound ("esr/enemy-higher.wav");
    precache_sound ("esr/enemy-same.wav");
    precache_sound ("esr/enemy-boc.wav");
    precache_sound ("esr/enemy-lower.wav");
    precache_sound ("esr/friend-higher.wav");
    precache_sound ("esr/friend-same.wav");
    precache_sound ("esr/friend-boc.wav");
    precache_sound ("esr/friend-lower.wav");
    precache_sound ("esr/haz.wav");

    // Navigation
    precache_sound ("nav/slope.wav");
    precache_sound ("nav/wall.wav");
    precache_sound ("nav/wall-scrape.wav");
    precache_sound ("nav/door.wav");
    precache_sound ("misc/menu3.wav");      // Need replacement wall-touch
    precache_sound ("nav/wind.wav");        // del?
    precache_sound ("ambience/windfly.wav");
    precache_sound ("misc/water2.wav");     // For the open space detection
    precache_sound ("nav/up.wav");
    precache_sound ("nav/down.wav");

    // Marker
    precache_sound ("nav/marker.wav");

    // Footsteps
    precache_sound ("footsteps/footstep_l.wav");
    precache_sound ("footsteps/footstep_r.wav");

    // D5K Entity Beeps
    precache_sound ("buttons/switch04.wav");        // Switch - AG_FIXME
    precache_sound ("doors/airdoor2.wav");          // Door - AG_FIXME
    precache_sound ("d5k/backpack.wav");
    precache_sound ("d5k/outside-fov.wav");

    // Toggles
    precache_sound ("toggles/on.wav");
    precache_sound ("toggles/off.wav");
    precache_sound ("toggles/mode.wav");

    // Ammo Out
    precache_sound ("ammo-out.wav");

    // Deny
    precache_sound ("deny.wav");
};

void() agh_world_padclients =
/*
    Purpose:
        Spawn bots (if enabled) to fill out player spots until clients
        connect to the game.
    Takes:
	    void
    Returns:
	    void
    Notes:
        Works off the following serverinfo variables:
          + bots_padclients     - number of clients to pad
                                  bots_padclients % ag_numteams should == 0
          + ag_numteams         - number of teams to use
          + ag_team[1234]name   - names of teams
*/
{
    local float numteams;
    local float padclients;
    local float botsperteam;
    
    dprint("agh_world_padclients\n");

    if( infokey(world, "bots_padclients") == "0" )
        return;

    // How many bots to spawn?
    numteams = stof(infokey(world, "ag_numteams"));
    padclients = stof(infokey(world, "bots_padclients"));
    botsperteam = padclients / numteams;

    // Sanity checks...
    if( numteams < 0 || numteams > 4 )
    {
        error("Server misconfigured: ag_numteams isn't between 0 and 4!\n");
    }
    if( botsperteam * numteams != padclients )
    {
        error("Server misconfigured: bots_padclients doesn't divide into ag_numteams!\n");
    }

    // Spawn the little fraggers...
    dprint("need to spawn: ");
    dprint(ftos(botsperteam));
    dprint(" * ");
    dprint(ftos(numteams));
    dprint(" = ");
    dprint(ftos(padclients));
    dprint("\n");
}

void() agh_client_startdevs =
/*
    Purpose:
        Starts the appropriate helper devices when a client joins the server.
    Takes:
	    void
    Returns:
	    void
*/
{
    // Work out which devices are meant to be active...

    // Note that we have to reverse the value of the cvar as it is meant
    // to signify that the devices are on if it is 1 -- but we know that
    // as we've just connected they aren't.

    // AUX
    snap_aux_constructor();

    // Set message lock to un-prioritise the following message...
    self.agrip_aux.state = true;
   
    // Instead of blurting out lots for each dev...
    snap_misc_m2m("Starting devices...\n");
    soundtoclient(self, self, CHAN_AUTO, "toggles/on.wav", 1, ATTN_NORM);
    
    // Unset message lock...
    self.agrip_aux.state = false;

    // NAV
    if( infokey(self, "agv_t_nav") == "1" )
        snap_nav_constructor();

    // D5k
    if( infokey(self, "agv_t_d5k") == "1" )
        snap_d5k_constructor();

    // ESR
    if( infokey(self, "agv_t_esr") == "1" )
        snap_esr_constructor();

    // Compass Offset...
    SNAP_MISC_NORMYAW_OFFSET = self.angles_y;
    if( SNAP_MISC_NORMYAW_OFFSET == 270 )
        SNAP_MISC_NORMYAW_OFFSET = -90;

    // Terrible, terrible, ugly hack...
    // FIXME remove this when auth is out!
    if( stof(infokey(self, "fortytwo")) != 42 )
    {
        sprint(self, PRINT_HIGH, "Sorry, this is not a standard QuakeWorld server.\nYou need to use the AGRIP AudioQuake mod (version 0.3.0 beta 2 and later)\nto connect here.\n");
        dprint("KICKED SIGHTED PLAYER ``");
        dprint(self.netname);
        dprint("''!\n");
        stuffcmd(self, "wait;disconnect\n");
    }
};

void() agh_client_padclients_connect =
/*
    Purpose:
        Attempt to replace a connected bot with a connecting client
        if bot padding is on.
    Takes:
	    void
    Returns:
	    void
*/
{
    dprint("agh_client_padclieints_connect\n");
}

void() agh_client_padclients_disconnect =
/*
    Purpose:
        Attempt to replace a disconnected client with a bot
        if bot padding is on.
    Takes:
	    void
    Returns:
	    void
*/
{
    dprint("agh_client_padclieints_disconnect\n");
}

void() agh_player_footsteps =
/*
    Purpose:
        Determines if and how to play footsteps.
    Takes:
	void
    Returns:
	void
*/
{
    // Play footsteps if the user has asked for it and they're not stuck...
    //
    // Please read snap_misc_blockedtest() for an explanation of the stuck
    // detection algorithm.
    //
    // If footsteps are disabled and we are stuck, a sound _is_ played so
    // that the player knows they're stuck.
    //
    // This also works out if the player is scraping along a wall.

    // Get out?
    // (It is faster to calculate the negative, as it uses ORs instead of ANDs.)
    if( ! (self.walkframe == 1 || self.walkframe == 4) )
        return;

    // Check we're not stuck...

    // Test if we are moving...
    if( self.origin != self.oldorigin )
    {
        // Are we scraping against a wall?
        // (This would show up as two walls; one front/back and one at the side.)
        if( self.agrip_aux.ammo_rockets > 1 )
        if( self.origin_z == self.oldorigin_z )
        {
            soundtoclient(self, self, CHAN_AUTO, "nav/wall-scrape.wav", 0.5, ATTN_NORM);

            // Go on to play a footstep too, as we _are_ moving, but make sure
            // we only play it at 1/2 the perceived ``speed''...
            if( self.walkframe != 1 )
                return;
            // Yes, we _should_ set self.oldorigin, but don't need to here
            // anyway -- phew!
        }

        // We're walking normally...
        // But we need to check that footsteps are turned on...
        if( infokey(self, "agv_t_footsteps") == "1" )
        {
            // Adjust speed according to if we're running or not...
            if( fabs(self.velocity_x + self.velocity_y) > 200 || self.walkframe == 1 )
            {
                // We may be in water...
                if( self.waterlevel > 1 )
                {
                    soundtoclient(self, self, CHAN_AUTO, "misc/outwater.wav", 0.5, ATTN_NORM);
                }
                else if( checkbottom(self) )
                {
                    // Generate the footstep sound a bit randomly...
                    local float r;
                    r = random(); 
                    if( r < 0.5 )
                        soundtoclient(self, self, CHAN_AUTO, "footsteps/footstep_l.wav", 0.5, ATTN_NORM);
                    else
                        soundtoclient(self, self, CHAN_AUTO, "footsteps/footstep_r.wav", 0.5, ATTN_NORM);
                }
            }
        }
    }
    // We aren't moving.
    // If we are stuck, or footsteps are OFF, we'll just continue making
    // the ``oomph'' sound...
    else //if( infokey(self, "agv_t_footsteps") == 0 )
    {
        // Need to make sure that we haven't just started moving
        // or we'll get spurious oomphs...
        if( self.agrip_aux.ammo_rockets > 0 )
        if( self.walkframe == 1 )
            soundtoclient(self, self, CHAN_AUTO, "player/land.wav", 0.5, ATTN_NORM);
    }

    // Store our origin...
    self.oldorigin = self.origin;
};

void() agh_player_dietidy =
/*
    Purpose:
        Kills all of the player's helper objects when they die.
    Takes:
	void
    Returns:
	void
*/
{
    // Set the message lock to un-prioritise the following messages...
    self.agrip_aux.state = true;

    // Disable NAV, ESR, D5k...
    snap_misc_m2m("Stopping devices...\n");
    soundtoclient(self, self, CHAN_AUTO, "toggles/off.wav", 1, ATTN_NORM);

    // NAV
    if( infokey(self, "agv_t_nav") == "1" )
    {
        remove(self.agrip_nav.aiment);
        remove(self.agrip_nav);
    }

    // D5k
    if( infokey(self, "agv_t_d5k") == "1" )
    {
        remove(self.agrip_d5k);
    }

    // ESR
    if( infokey(self, "agv_t_esr") == "1" )
    {
        remove(self.agrip_esr.aiment);
        remove(self.agrip_esr.enemy);
        remove(self.agrip_esr.goalentity);
        remove(self.agrip_esr);
    }

    // Remove all waypoints...
    if( self.agrip_aux.health > 0 )
        snap_misc_m2m("Removing markers...\n");
    // FIXME this is an NP-complete ugly hack!!!
    while( floor(self.agrip_aux.health) > 0 )
    {
        // debug info...
        /*dprint(self.netname);
        dprint(" call m_d with a-aux.h = ");
        dprint(ftos(self.agrip_aux.health));
        dprint("\n");*/
        // Call it *QUIETLY*...
        snap_marker_destructor(1);
    }

    // AUX
    remove(self.agrip_aux);
};

void() agh_weapons_impulsecommands =
/*
    Purpose:
        Carries out the accessibility-related impulse commands...
    Takes:
	void
    Returns:
	void
*/
{
    // TUTOR BOT STUFF

    // Impulse  50  Adds a bot on our team
    //          51  Adds an enemy bot
    //          52  Sets and un-sets the call flag

    // Note:    Only if we are in teamplay mode will the bot's team be
    //          taken into consideration; otherwise it'll always be an
    //          opponent to us.

    if( self.impulse == 49 )
        KickABot();
    
    if( self.impulse == 50 )
        create_bot(1);
                   
    if( self.impulse == 51 )
        create_bot(2);
    
    if( self.impulse == 52 )
    {
        if( ! self.agrip_aux.ammo_cells )
        {
            self.agrip_aux.ammo_cells = true;
            snap_misc_m2m("Call for help\n");
        }
        else
        {
            self.agrip_aux.ammo_cells = false;
            snap_misc_m2m("Cancel call for help\n");
        }
     }

     
    // HELPER OBJECTS
	
    // Impulse  100 toggles nav
    //          101         nav/wall warnings
    //          102         nav/side wall warnings
    //          103         nav/wall hit warnings
    //          104         nav/z warnings
    //          105         nav/haz warnings
    //          106         nav/side haz warnings
    //          108         nav/corner warnings
    //	        110         d5k
    //	        120	        esr
    //	        121         esr/monster warnings
    //	        122         esr/enemy warnings
    //	        123         esr/friend warnings
    //	        130         footsteps
	
    // Navigation Helper -- ``nav''
    if( self.impulse == 100 )
    {
        if( infokey(self, "agv_t_nav") == "0" )
        {
            // Create a new object...
            snap_nav_constructor();
            stuffcmd(self, "setinfo agv_t_nav 1\n");
            snap_misc_m2m("NAV: Enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
        else
        {
            // Remove the object, as it exists now...
            remove(self.agrip_nav.aiment);
            remove(self.agrip_nav);
            stuffcmd(self, "setinfo agv_t_nav 0\n");
            snap_misc_m2m("NAV: Disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
    }

    // nav_wall_warnings
    if( self.impulse == 101 )
    {
        if( infokey(self, "agv_t_nav_wall_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_wall_warnings 0\n");
            snap_misc_m2m("NAV: Wall warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_wall_warnings 1\n");
            snap_misc_m2m("NAV: Wall warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_side_wall_warnings
    if( self.impulse == 102 )
    {
        if( infokey(self, "agv_t_nav_side_wall_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_side_wall_warnings 0\n");
            snap_misc_m2m("NAV: Side wall warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_side_wall_warnings 1\n");
            snap_misc_m2m("NAV: Side wall warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_wall_touch_warnings
    if( self.impulse == 103 )
    {
        if( infokey(self, "agv_t_nav_wall_touch_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_wall_touch_warnings 0\n");
            snap_misc_m2m("NAV: Wall touch warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_wall_touch_warnings 1\n");
            snap_misc_m2m("NAV: Wall touch warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_z_warnings
    if( self.impulse == 104 )
    {
        if( infokey(self, "agv_t_nav_z_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_z_warnings 0\n");
            snap_misc_m2m("NAV: Z warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_z_warnings 1\n");
            snap_misc_m2m("NAV: Z warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_haz_warnings
    if( self.impulse == 105 )
    {
        if( infokey(self, "agv_t_nav_haz_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_haz_warnings 0\n");
            snap_misc_m2m("NAV: Hazard warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_haz_warnings 1\n");
            snap_misc_m2m("NAV: Hazard warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_side_haz_warnings
    if( self.impulse == 106 )
    {
        if( infokey(self, "agv_t_nav_side_haz_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_side_haz_warnings 0\n");
            snap_misc_m2m("NAV: Side hazard warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_side_haz_warnings 1\n");
            snap_misc_m2m("NAV: Side hazard warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_space_warnings
    if( self.impulse == 107 )
    {
        if( infokey(self, "agv_t_nav_space_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_space_warnings 0\n");
            snap_misc_m2m("NAV: Open space warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_space_warnings 1\n");
            snap_misc_m2m("NAV: Open space warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // nav_corner_warnings
    if( self.impulse == 108 )
    {
        if( infokey(self, "agv_t_nav_corner_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_nav_corner_warnings 0\n");
            snap_misc_m2m("NAV: Corner warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_nav_corner_warnings 1\n");
            snap_misc_m2m("NAV: Corner warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }
    
    // Detector 5000 -- ``D5k''
    if( self.impulse == 110 )
    {
        if( infokey(self, "agv_t_d5k") == "0" )
        {
            // Create a new object...
            snap_d5k_constructor();
            stuffcmd(self, "setinfo agv_t_d5k 1\n");
            snap_misc_m2m("D5k: Enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
        else
        {
            // Remove the object, as it exists now...
            remove(self.agrip_d5k);
            stuffcmd(self, "setinfo agv_t_d5k 0\n");
            snap_misc_m2m("D5k: Disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
    }	

    // EtherScan RADAR -- ``ESR''
     
    // This has 3 modes: off, on (classic) and on (hazard)
    // It detects nothing / enemies / drops.
   
    if( self.impulse == 120 )
    {
        // Re-enabling the ESR...
        if( infokey(self, "agv_t_esr") == "0" )
        {
            stuffcmd(self, "setinfo agv_t_esr 1\n");
            snap_esr_constructor();
            soundtoclient(self, self, CHAN_AUTO, "toggles/on.wav", 1, ATTN_NORM);
            snap_misc_m2m("ESR: Set to mode 1.\n");
        }
        // Switching Modes...
        else if( infokey(self, "agv_t_esr") == "1" )
        {
            // If in mode 1, go to 2...
            stuffcmd(self, "setinfo agv_t_esr 2\n");

            // If we're in the middle of detecting a far-off enemy, the
            // player would have to wait a long time -- so we are going to
            // remove this wait...
            self.agrip_esr.nextthink = time + 0.01;
        }
        else if( infokey(self, "agv_t_esr") == "2" )
        {
            // The user wants to turn the ESR off...
            snap_misc_m2m("ESR: Disabled.\n");
            stuffcmd(self, "setinfo agv_t_esr 0\n");
        }
    }

    // ESR Monster Warnings...
    if( self.impulse == 121 )
    {
        if( infokey(self, "agv_t_esr_monster_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_esr_monster_warnings 0\n");
            snap_misc_m2m("ESR: Monster warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_esr_monster_warnings 1\n");
            snap_misc_m2m("ESR: Monster warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }
	
    // ESR Enemy Warnings...
    if( self.impulse == 122 )
    {
        if( infokey(self, "agv_t_esr_enemy_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_esr_enemy_warnings 0\n");
            snap_misc_m2m("ESR: Enemy warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_esr_enemy_warnings 1\n");
            snap_misc_m2m("ESR: Enemy warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }

    // ESR Friend Warnings...
    if( self.impulse == 123 )
    {
        if( infokey(self, "agv_t_esr_friend_warnings") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_esr_friend_warnings 0\n");
            snap_misc_m2m("ESR: Friend warnings disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_esr_friend_warnings 1\n");
            snap_misc_m2m("ESR: Friend warnings enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }
    
    // Footsteps...
    if( self.impulse == 130 )
    {
        if( infokey(self, "agv_t_footsteps") == "1" )
        {
            stuffcmd(self, "setinfo agv_t_footsteps 0\n");
            snap_misc_m2m("Footsteps disabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/off.wav", 1, ATTN_NORM);
        }
        else
        {
            stuffcmd(self, "setinfo agv_t_footsteps 1\n");
            snap_misc_m2m("Footsteps enabled.\n");
            soundtoclient(self, self, CHAN_VOICE, "toggles/on.wav", 1, ATTN_NORM);
        }
    }


    // IMMEDIATE USE ITEMS...
    
    // Impulse  140 activates   compass
    //          141             open space sweep
    //          150             drop describer
    //          160             jump describer
    //          170             adds a marker
    //          171             deletes last marker
     
    // Compass...
    if( self.impulse == 140 )
        snap_extnav_compass();

    // Spawn a sweep object...
    if( self.impulse == 141 )
    {
        local entity sweep;
        sweep = spawn();
        self.groundentity = sweep;
        sweep.owner = self;
        sweep.health = stof(infokey(self, "agv_nav_detrange"));
        sweep.think = snap_extnav_osd;
        sweep.nextthink = time;
        // it will remove itself when completed.
    }
            
    // Drop description...
    if( self.impulse == 150 )
    if( infokey(self, "agv_t_nav") == "1" )
    {
        // The NAV device will tell us what lies in the drop.
        // The property we examine is set every time it thinks.
        if( self.agrip_nav.weapon == CONTENT_EMPTY )
            snap_misc_m2m("Ground.\n");
        else if( self.agrip_nav.weapon == CONTENT_WATER )
            snap_misc_m2m("Water.\n");
        else if( self.agrip_nav.weapon == CONTENT_SLIME )
            snap_misc_m2m("Slime.\n");
        else if( self.agrip_nav.weapon == CONTENT_LAVA )
            snap_misc_m2m("Lava.\n");
        else
            soundtoclient(self, self, CHAN_AUTO, "deny.wav", 1, ATTN_NORM);
    }
   
    // Jump description...
    if( self.impulse == 160 )
    {
        // The NAV device will tell us if we can make the jump.
        // The property we examine is set every time it thinks.
        if( self.agrip_nav.takedamage == SNAP_NAV_JMP_RUN )
        {
            snap_misc_m2m("Running Jump.\n");
        }
        else if( self.agrip_nav.takedamage == SNAP_NAV_JMP_NRM )
        {
            snap_misc_m2m("Normal Jump.\n");
        }
        else
        {
            soundtoclient(self, self, CHAN_AUTO, "deny.wav", 1, ATTN_NORM);
        }
    }

    // Marker: Add
    if( self.impulse == 170 )
    {
        snap_marker_constructor();
    }

    // Marker: Delete last
    if( self.impulse == 171 )
    {
        snap_marker_destructor(0);
    }

    
   // STATUS INDICATORS...
    
   // Impulse   90	gives	Health and Armour levels
   //	        91		Ammo Overview
    
    if( self.impulse == 90 )
    {
        local string varval;
        varval = ftos(self.health);
        snap_misc_m2m(varval);
        sprint(self, 1, " health, ");
        varval = ftos(self.armorvalue);
        sprint(self, 1, varval);
        sprint(self, 1, " armour at factor ");
        varval = ftos(self.armortype);
        sprint(self, 1, varval);
        sprint(self, 1, ".\n");
    }

    if( self.impulse == 91 )
    {
        local string varval;
        varval = ftos(self.ammo_shells);
        snap_misc_m2m(varval);
        sprint(self, 1, " shells, ");
        varval = ftos(self.ammo_nails);
        sprint(self, 1, varval);
        sprint(self, 1, " nails, ");
        varval = ftos(self.ammo_rockets);
        sprint(self, 1, varval);
        sprint(self, 1, " rockets, ");
        varval = ftos(self.ammo_cells);
        sprint(self, 1, varval);
        sprint(self, 1, " cells.\n");
    }
};

/* $AGRIP-END */
