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


void(string item, string amount) Cmd_Give = {
	if (item == "2")
		self.items = self.items | IT_SHOTGUN;
	else if (item == "3")
		self.items = self.items | IT_SUPER_SHOTGUN;
	else if (item == "4")
		self.items = self.items | IT_NAILGUN;
	else if (item == "5")
		self.items = self.items | IT_SUPER_NAILGUN;
	else if (item == "6")
		self.items = self.items | IT_GRENADE_LAUNCHER;
	else if (item == "7")
		self.items = self.items | IT_ROCKET_LAUNCHER;
	else if (item == "8")
		self.items = self.items | IT_LIGHTNING;
	else if (item == "s" || item == "shells")
		self.ammo_shells = stof(amount);
	else if (item == "n" || item == "nails")
		self.ammo_nails = stof(amount);
	else if (item == "r" || item == "rockets")
		self.ammo_rockets = stof(amount);
	else if (item == "c" || item == "cells")
		self.ammo_cells = stof(amount);
	else if (item == "h" || item == "health")
		self.health = stof(amount);
	else {
		sprint (self, PRINT_HIGH, "no such item: ");
		sprint (self, PRINT_HIGH, item);
		sprint (self, PRINT_HIGH, "\n");
	}
};
