/*
	commands.qc

	user commands

	Copyright (C) 1996-1997  Id Software, Inc.

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

// sp_commands.qc - single player specific player commands

void Cmd_Notarget ()
{
	if (self.flags & FL_NOTARGET)
	{
		sprint (self, PRINT_HIGH, "notarget OFF\n");
		self.flags = self.flags - FL_NOTARGET;
	}
	else
	{
		sprint (self, PRINT_HIGH, "notarget ON\n");
		self.flags = self.flags | FL_NOTARGET;
	}
}
