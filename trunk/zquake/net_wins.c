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
// net_wins.c

#include "quakedef.h"
#include "winquake.h"

netadr_t	net_local_adr;

netadr_t	net_from;
sizebuf_t	net_message;
int			net_clientsocket;
int			net_serversocket;

#define	MAX_UDP_PACKET	(MAX_MSGLEN*2)	// one more than msg + header
byte		net_message_buffer[MAX_UDP_PACKET];

WSADATA		winsockdata;

// Tonik -->
#define	 PORT_LOOPBACK 65535
int			loop_c2s_messageLength;
char		loop_c2s_message[MAX_UDP_PACKET];
int			loop_s2c_messageLength;
char		loop_s2c_message[MAX_UDP_PACKET];
// <-- Tonik

//=============================================================================

void NetadrToSockadr (netadr_t *a, struct sockaddr_in *s)
{
	memset (s, 0, sizeof(*s));
	s->sin_family = AF_INET;

	*(int *)&s->sin_addr = *(int *)&a->ip;
	s->sin_port = a->port;
}

void SockadrToNetadr (struct sockaddr_in *s, netadr_t *a)
{
	*(int *)&a->ip = *(int *)&s->sin_addr;
	a->port = s->sin_port;
}

qboolean	NET_CompareBaseAdr (netadr_t a, netadr_t b)
{
	if (a.ip[0] == b.ip[0] && a.ip[1] == b.ip[1] && a.ip[2] == b.ip[2] && a.ip[3] == b.ip[3])
		return true;
	return false;
}

qboolean	NET_CompareAdr (netadr_t a, netadr_t b)
{
	if (a.ip[0] == b.ip[0] && a.ip[1] == b.ip[1] && a.ip[2] == b.ip[2] && a.ip[3] == b.ip[3] && a.port == b.port)
		return true;
	return false;
}

char	*NET_AdrToString (netadr_t a)
{
	static	char	s[64];

#ifdef QW_BOTH
	if (*(int *)&a == 0 && a.port == PORT_LOOPBACK)
		return "loopback";
#endif

	sprintf (s, "%i.%i.%i.%i:%i", a.ip[0], a.ip[1], a.ip[2], a.ip[3], ntohs(a.port));

	return s;
}

char	*NET_BaseAdrToString (netadr_t a)
{
	static	char	s[64];
	
	sprintf (s, "%i.%i.%i.%i", a.ip[0], a.ip[1], a.ip[2], a.ip[3]);

	return s;
}

/*
=============
NET_StringToAdr

idnewt
idnewt:28000
192.246.40.70
192.246.40.70:28000
=============
*/
qboolean	NET_StringToAdr (char *s, netadr_t *a)
{
	struct hostent	*h;
	struct sockaddr_in sadr;
	char	*colon;
	char	copy[128];

// Tonik -->	
#ifdef QW_BOTH
	if (!strcmp(s, "local"))
	{
		memset(a, 0, sizeof(*a));
		a->port = PORT_LOOPBACK;
		return true;
	}
#endif
// <-- Tonik
	
	memset (&sadr, 0, sizeof(sadr));
	sadr.sin_family = AF_INET;
	
	sadr.sin_port = 0;

	strcpy (copy, s);
	// strip off a trailing :port if present
	for (colon = copy ; *colon ; colon++)
		if (*colon == ':')
		{
			*colon = 0;
			sadr.sin_port = htons((short)atoi(colon+1));	
		}
	
	if (copy[0] >= '0' && copy[0] <= '9')
	{
		*(int *)&sadr.sin_addr = inet_addr(copy);
	}
	else
	{
		if ((h = gethostbyname(copy)) == 0)
			return 0;
		*(int *)&sadr.sin_addr = *(int *)h->h_addr_list[0];
	}
	
	SockadrToNetadr (&sadr, a);

	return true;
}

// Returns true if we can't bind the address locally--in other words, 
// the IP is NOT one of our interfaces.
qboolean NET_IsClientLegal(netadr_t *adr)
{
#if 0
	struct sockaddr_in sadr;
	int newsocket;

	if (adr->ip[0] == 127)
		return false; // no local connections period

	NetadrToSockadr (adr, &sadr);

	if ((newsocket = socket (PF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
		Sys_Error ("NET_IsClientLegal: socket:", strerror(errno));

	sadr.sin_port = 0;

	if( bind (newsocket, (void *)&sadr, sizeof(sadr)) == -1) 
	{
		// It is not a local address
		close(newsocket);
		return true;
	}
	close(newsocket);
	return false;
#else
	return true;
#endif
}

//=============================================================================

qboolean NET_GetPacket (int net_socket)
{
	int 	ret;
	struct sockaddr_in	from;
	int		fromlen;

// Tonik -->
	if (net_socket == net_clientsocket && loop_s2c_messageLength > 0)
	{
		memcpy (net_message_buffer, loop_s2c_message, loop_s2c_messageLength);
		net_message.cursize = loop_s2c_messageLength;
		loop_s2c_messageLength = 0;
		memset (&from, 0, sizeof(from));
		from.sin_port = PORT_LOOPBACK;
		SockadrToNetadr (&from, &net_from);
		return net_message.cursize;
	}

	if (net_socket == net_serversocket && loop_c2s_messageLength > 0)
	{
//		Con_DPrintf ("NET_GetPacket: c2s\n");
		memcpy (net_message_buffer, loop_c2s_message, loop_c2s_messageLength);
		net_message.cursize = loop_c2s_messageLength;
		loop_c2s_messageLength = 0;
		memset (&from, 0, sizeof(from));
		from.sin_port = PORT_LOOPBACK;
		SockadrToNetadr (&from, &net_from);
		return net_message.cursize;
	}
// <-- Tonik

	fromlen = sizeof(from);
	ret = recvfrom (net_socket, (char *)net_message_buffer, sizeof(net_message_buffer), 0, (struct sockaddr *)&from, &fromlen);
	SockadrToNetadr (&from, &net_from);

	if (ret == -1)
	{
		int errno = WSAGetLastError();

		if (errno == WSAEWOULDBLOCK)
			return false;
		if (errno == WSAEMSGSIZE) {
			Con_Printf ("Warning:  Oversize packet from %s\n",
				NET_AdrToString (net_from));
			return false;
		}
		if (errno == 10054) {
			Con_DPrintf ("NET_GetPacket: Error 10054 from %s\n", NET_AdrToString (net_from));
			return false;
		}

		Sys_Error ("NET_GetPacket: %s", strerror(errno));
	}

	net_message.cursize = ret;
	if (ret == sizeof(net_message_buffer) )
	{
		Con_Printf ("Oversize packet from %s\n", NET_AdrToString (net_from));
		return false;
	}

	return ret;
}

//=============================================================================

void NET_SendPacket (int net_socket, int length, void *data, netadr_t to)
{
	int ret;
	struct sockaddr_in	addr;

// Tonik -->
	if (*(int *)&to.ip == 0 && to.port == 65535)	// Loopback
	{
		if (net_socket == net_clientsocket)
		{
//			if (loop_c2s_messageLength)
//				Con_Printf ("Warning: NET_SendPacket: loop_c2s: NET_SendPacket without NET_GetPacket\n");
			memcpy (loop_c2s_message, data, length);
			loop_c2s_messageLength = length;
			return;
		}
		else if (net_socket == net_serversocket)
		{
//			if (loop_s2c_messageLength)
//				Con_Printf ("Warning: NET_SendPacket: loop_s2c: NET_SendPacket without NET_GetPacket\n");
			memcpy (loop_s2c_message, data, length);
			loop_s2c_messageLength = length;
			return;
		}
		Sys_Error("NET_SendPacket: loopback: unknown socket");
		return;
	}
// <-- Tonik

	NetadrToSockadr (&to, &addr);

	ret = sendto (net_socket, data, length, 0, (struct sockaddr *)&addr, sizeof(addr) );
	if (ret == -1)
	{
		int err = WSAGetLastError();

// wouldblock is silent
        if (err == WSAEWOULDBLOCK)
	        return;

#ifndef SERVERONLY
		if (err == WSAEADDRNOTAVAIL)
			Con_DPrintf("NET_SendPacket Warning: %i\n", err);
		else
#endif
			Con_Printf ("NET_SendPacket ERROR: %i\n", errno);
	}
}

//=============================================================================

int UDP_OpenSocket (int port, qboolean crash)
{
	int newsocket;
	struct sockaddr_in address;
	unsigned long _true = true;
	int i;

	if ((newsocket = socket (PF_INET, SOCK_DGRAM, IPPROTO_UDP)) == -1)
		Sys_Error ("UDP_OpenSocket: socket:", strerror(errno));

	if (ioctlsocket (newsocket, FIONBIO, &_true) == -1)
		Sys_Error ("UDP_OpenSocket: ioctl FIONBIO:", strerror(errno));

	address.sin_family = AF_INET;
//ZOID -- check for interface binding option
	if ((i = COM_CheckParm("-ip")) != 0 && i < com_argc) {
		address.sin_addr.s_addr = inet_addr(com_argv[i+1]);
		Con_Printf("Binding to IP Interface Address of %s\n",
				inet_ntoa(address.sin_addr));
	} else
		address.sin_addr.s_addr = INADDR_ANY;

	if (port == PORT_ANY)
		address.sin_port = 0;
	else
		address.sin_port = htons((short)port);
	if( bind (newsocket, (void *)&address, sizeof(address)) == -1)
	{
#ifdef QW_BOTH
		if (!crash)
			return -1;
		else
#endif
		Sys_Error ("UDP_OpenSocket: bind: %s", strerror(errno));
	}

	return newsocket;
}

void NET_GetLocalAddress (int net_socket)	// FIXME
{
	char	buff[512];
	struct sockaddr_in	address;
	int		namelen;

	gethostname(buff, 512);
	buff[512-1] = 0;

	NET_StringToAdr (buff, &net_local_adr);

	namelen = sizeof(address);
	if (getsockname (net_socket, (struct sockaddr *)&address, &namelen) == -1)
		Sys_Error ("NET_Init: getsockname:", strerror(errno));
	net_local_adr.port = address.sin_port;

	Con_Printf("IP address %s\n", NET_AdrToString (net_local_adr) );
}

/*
====================
NET_Init
====================
*/
int __serverport;	// so we can open it later
void NET_Init (int clientport, int serverport)
{
	WORD	wVersionRequested; 
	int		r;

	wVersionRequested = MAKEWORD(1, 1); 

	r = WSAStartup (MAKEWORD(1, 1), &winsockdata);

	if (r)
		Sys_Error ("Winsock initialization failed.");

	//
	// open the single socket to be used for all communications
	//
//	net_socket = UDP_OpenSocket (port);
	if (clientport)
		net_clientsocket = UDP_OpenSocket (clientport, true);
#ifndef QW_BOTH
	if (serverport)
		net_serversocket = UDP_OpenSocket (serverport, false);
#else
	// An ugly hack to let you run zquake and qwsv or proxy without
	// changing ports via the command line	-- Tonik, 5 Aug 2000
	__serverport = serverport;
	net_serversocket = -1;
/*	if (net_serversocket == -1)
	{
		Con_Printf ("NET_Init: Could not open server socket\n");
	}	*/
#endif

	//
	// init the message buffer
	//
	net_message.maxsize = sizeof(net_message_buffer);
	net_message.data = net_message_buffer;

	//
	// determine my name & address
	//
	if (clientport)
		NET_GetLocalAddress (net_clientsocket);
	else if (serverport)
		NET_GetLocalAddress (net_serversocket);

	Con_Printf("UDP Initialized\n");
}

/*
====================
NET_Shutdown
====================
*/
void	NET_Shutdown (void)
{
	if (net_clientsocket)
		closesocket (net_clientsocket);
	if (net_serversocket)
		closesocket (net_serversocket);
	WSACleanup ();
}

