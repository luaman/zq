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
// sv_nchan.c - user reliable data stream writes

#include "server.h"

static byte backbuf_data[MAX_MSGLEN];
static sizebuf_t backbuf;
static client_t *backbuf_dest;
static qbool backbuf_write_started = false;


void ClientReliableWrite_Begin0 (client_t *cl)
{
	assert (!backbuf_write_started);
	backbuf_write_started = true;
	backbuf_dest = cl;
	SZ_Init (&backbuf, backbuf_data, sizeof(backbuf_data));
}

void ClientReliableWrite_Begin (client_t *cl, int c)
{
	ClientReliableWrite_Begin0 (cl);
	MSG_WriteByte (&backbuf, c);
}

void ClientReliableWrite_End (void)
{
	assert (backbuf_write_started);
	backbuf_write_started = false;

	SV_AddToReliable (backbuf_dest, backbuf.data, backbuf.cursize);
}

void ClientReliableWrite_Angle (float f)
{
	assert (backbuf_write_started);
	MSG_WriteAngle (&backbuf, f);
}

void ClientReliableWrite_Angle16 (float f)
{
	assert (backbuf_write_started);
	MSG_WriteAngle16 (&backbuf, f);
}

void ClientReliableWrite_Byte (int c)
{
	assert (backbuf_write_started);
	MSG_WriteByte (&backbuf, c);
}

void ClientReliableWrite_Char (int c)
{
	assert (backbuf_write_started);
	MSG_WriteChar (&backbuf, c);
}

void ClientReliableWrite_Float (float f)
{
	assert (backbuf_write_started);
	MSG_WriteFloat (&backbuf, f);
}

void ClientReliableWrite_Coord (float f)
{
	assert (backbuf_write_started);
	MSG_WriteCoord (&backbuf, f);
}

void ClientReliableWrite_Long (int c)
{
	assert (backbuf_write_started);
	MSG_WriteLong (&backbuf, c);
}

void ClientReliableWrite_Short (int c)
{
	assert (backbuf_write_started);
	MSG_WriteShort (&backbuf, c);
}

void ClientReliableWrite_String (char *s)
{
	assert (backbuf_write_started);
	MSG_WriteString(&backbuf, s);
}

void ClientReliableWrite_SZ (void *data, int len)
{
	assert (backbuf_write_started);
	SZ_Write (&backbuf, data, len);
}



static void SV_AddToBackbuf (client_t *cl, const byte *data, int size)
{
	backbuf_block_t *block;

	assert (size >= 0);
	if (!size)
		return;

	// allocate new block
	block = Q_malloc (sizeof(backbuf_block_t)-4 + size);

	// fill it in
	block->size = size;
	block->next = NULL;
	memcpy (block->data, data, size);

	// link it in
	if (cl->backbuf_head) {
		assert (cl->backbuf_tail != NULL);
		cl->backbuf_tail->next = block;
		cl->backbuf_tail = block;
	} else {
		assert (cl->backbuf_tail == NULL);
		cl->backbuf_head = cl->backbuf_tail = block;
	}

	// update total
	cl->backbuf_size += size;
}

void SV_AddToReliable (client_t *cl, const byte *data, int size)
{
	if (!cl->backbuf_size &&
		cl->netchan.message.cursize + size <= cl->netchan.message.maxsize)
	{
		// it will fit
		SZ_Write (&cl->netchan.message, data, size);
	}
	else
	{	// won't fit, add it to backbuf
		SV_AddToBackbuf (cl, data, size);
	}
}

// flush data from client's reliable buffers to netchan
void SV_FlushBackbuf (client_t *cl)
{
	backbuf_block_t *block;

	block = cl->backbuf_head;
	while (block) {
		if (block->size > (cl->netchan.message.maxsize - cl->netchan.message.cursize))
			break;

		// add to reliable
		SZ_Write (&cl->netchan.message, block->data, block->size);

		// update total
		cl->backbuf_size -= block->size;

		// free this block and grab next
		block = cl->backbuf_head->next;
		Q_free (cl->backbuf_head);
		cl->backbuf_head = block;
		if (!block) {
			assert (cl->backbuf_size == 0);
			cl->backbuf_tail = NULL;
		}
	}

}

void SV_ClearBackbuf (client_t *cl)
{
	backbuf_block_t *block;

	block = cl->backbuf_head;
	while (block) {
		// update total
		cl->backbuf_size -= block->size;

		// free this block and grab next
		block = cl->backbuf_head->next;
		Q_free (cl->backbuf_head);
		cl->backbuf_head = block;
		if (!block) {
			assert (cl->backbuf_size == 0);
			cl->backbuf_tail = NULL;
		}
	}
}

// clears both cl->netchan.message and backbuf
void SV_ClearReliable (client_t *cl)
{
	SZ_Clear (&cl->netchan.message);
	SV_ClearBackbuf (cl);
}
