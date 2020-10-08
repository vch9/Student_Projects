#include "pmtu.h"


void discover_pmtu(neighbours* n){
  int one = 1;
	int s, rc;
	s = socket(AF_INET6, SOCK_DGRAM, 0);
	if(s < 0){
    n->pmtu = 1232;
		return;
	}
	rc = setsockopt(s, IPPROTO_IPV6, IPV6_DONTFRAG, &one, sizeof(one));
	if(rc < 0){
    n->pmtu = 1232;
		return;
	}
	rc = setsockopt(s, IPPROTO_IPV6, IPV6_RECVPATHMTU, &one, sizeof(one));
	if(rc < 0){
    n->pmtu = 1232;
		return;
	}
	rc = setsockopt(s, IPPROTO_IPV6, IPV6_MTU_DISCOVER, &one, sizeof(one));
	if(rc < 0){
    n->pmtu = 1232;
		return;
	}

  struct sockaddr_in6 sin6;
  sin6.sin6_port = htons(n->port);
  sin6.sin6_family = AF_INET6;
  memcpy(&sin6.sin6_addr, n->addr, sizeof(n->addr));

  rc = connect(s, (struct sockaddr*)&sin6, sizeof(sin6));
	if(rc < 0){
    n->pmtu = 1232;
    return;
	}

  int pmtu = 64 * 1024 - 1;

	char pad[pmtu-40];
	memset(pad, 0, pmtu-40);
  pad[0] = 93;
  pad[1] = 2;
  uint16_t body_length = htons(pmtu-44);
  memcpy(pad+2, &body_length, 2);
  pad[4] = 1;
  pad[5] = pmtu-46;

	rc = send(s, pad, pmtu-40, 0);
  if(rc<0){
		if(errno==EMSGSIZE){
			struct ip6_mtuinfo mtuinfo;
			socklen_t infolen = sizeof(struct ip6_mtuinfo);
			rc = getsockopt(s, IPPROTO_IPV6, IPV6_PATHMTU, &mtuinfo, &infolen);
			if(rc >= 0) {
				/* On met a jour le PMTU */
				n->pmtu = mtuinfo.ip6m_mtu;
        return;
			}
		}
  }
  struct ip6_mtuinfo* info;
	struct msghdr msg;
	rc = recvmsg(s, &msg, 0);
	if(rc < 0){
	  n->pmtu = 1232;
    return;
	}
	struct cmsghdr* cmsg = CMSG_FIRSTHDR(&msg);
	while(cmsg != NULL) {
			if ((cmsg->cmsg_level == IPPROTO_IPV6) && (cmsg->cmsg_type == IPV6_PATHMTU)) {
				info = (struct ip6_mtuinfo*)CMSG_DATA(cmsg);
				break;
			}
			cmsg = CMSG_NXTHDR(&msg, cmsg);
	}
	if(info != NULL) {
		/* C'est une indication asynchrone */
		n->pmtu = info->ip6m_mtu;
	}
  else{
    n->pmtu = 1232;
  }
}
