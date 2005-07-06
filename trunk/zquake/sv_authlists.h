/*
Copyright (C) 2005  Matthew T. Atkinson

client authentication -- record management routines

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

#ifndef _SV_AUTHLISTS_H_
#define _SV_AUTHLISTS_H_

#include "q_shared.h"
#include "common.h"

// type that stores details for a client
typedef struct authclient_s
{
    char *name;
    char *hash;
    qbool valid;  // has master told us this is a valid token yet?
	struct authclient_s *prev;
	struct authclient_s *next;
} authclient_t;

// header for queues of above type
typedef struct authqh_s
{
    int maxlen;
    int curlen;
    authclient_t *start;
} authqh_t;


qbool SV_AuthListAdd(authqh_t *header);
    // adds an entry to a queue
    // reads name and hash from incomming packet

void SV_AuthListRemove(authqh_t *header, authclient_t *rm);
    // Removes a record from the list, frees associated memory
    // and decrements list length

qbool SV_AuthListMove(authqh_t *src, authqh_t *dest, authclient_t *authclient);
    // adds an entry to a queue
    // reads name and hash from incomming packet

qbool SV_AuthListValidate(authqh_t *header);
    // sets valid bit in an entry if the data is valid according to master
    // reads data on who to validate from incoming packet

authclient_t *SV_AuthListFind(authqh_t *header, char *name);
    // find a player in the queue
    // returns NULL if not found

void SV_AuthListPrint(authqh_t *header);
    // print whole of specified queue


#endif /* _SV_AUTHLISTS_H_ */

