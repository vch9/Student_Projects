#ifndef PROJECT_PMTU_H
#define PROJECT_PMTU_H
#include "struct.h"
#include "sys/socket.h"
#include <netinet/in.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

struct ip6_mtuinfo{
	struct sockaddr_in6 ip6m_addr;
	uint32_t ip6m_mtu;
};

void discover_pmtu(neighbours* n);

#endif //PROJECT_PMTU_H
