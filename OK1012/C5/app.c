#include <sys/types.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <arpa/inet.h>
#include <linux/if_ether.h>
#include <linux/if_packet.h>
#include <net/if.h>
#include <unistd.h>
#include <sys/ioctl.h>
#include <stdio.h>
#include <string.h>
 
char buf[1024] = {0};
const char *ifname = "eth0";
 
int32_t raw_interface_idx_get(int32_t fd, const char *ifname)
{	
    struct ifreq ifreq;
	memset(&ifreq, 0, sizeof(ifreq));
	strncpy(ifreq.ifr_name, ifname, sizeof(ifreq.ifr_name) - 1);
	if (ioctl(fd, SIOCGIFINDEX, &ifreq) < 0)
    {
		return -1;
	}
 
    return ifreq.ifr_ifindex;
}
 
int main(int argc, char *argv[])
{
	int size;
	int ret;
	int fd;
    struct sockaddr_ll addr;
	fd = socket(PF_PACKET, SOCK_RAW, htons(ETH_P_ALL));
	printf("%d", fd);
	if (-1 == fd)
    {
		perror("socket");
		return -1;
	}
 
	ret = raw_interface_idx_get(fd, ifname);
	if (ret < 0)
	{
		printf("get ifname idx fail\n");
		goto out;
	}
 
	memset(&addr, 0, sizeof(addr));
	addr.sll_ifindex = ret;
	addr.sll_family = AF_PACKET;
	addr.sll_protocol = htons(ETH_P_ALL);
	ret = bind(fd, (struct sockaddr*)&addr, sizeof(addr));
	if (ret < 0)
	{
		perror("bind");
		goto out;
	}
 
	//ba:02:ea:1a:54:dd
	/*dst mac*/
	buf[0] = 0x00;
	buf[1] = 0x11;
	buf[2] = 0x22;
	buf[3] = 0x33;
	buf[4] = 0x44;
	buf[5] = 0x66;
	size = 6;
 
	/*src mac*/
	//   64:00:f1:11:22:33
	buf[6] = 0xba;
	buf[7] = 0x02;
	buf[8] = 0xea;
	buf[9] = 0x1a;
	buf[10] = 0x54;
	buf[11] = 0xdd;
	size += 6;
 
	/*vlan tpid 长度2bytes，Tag Protocol Identifier（标签协议标识符），表示帧类型。取值为0x8100时表示802.1Q Tag帧。如果不支持802.1Q的设备收到这样的帧，会将其丢弃。*/
	buf[size] = 0x81;
	size += 1;
	buf[size] = 0x00;
	size += 1;
 
	/*vlan tag*/
	buf[size] = 0x00;
	buf[size] |= 0xE0; //vlan pri = 2   前三个bit作为优先级值 1110 0000=7
	size += 1;
	buf[size] = 0x01; //vlan id = 1 
	size += 1;
 
	/*packet protocl*/
    buf[size] = 0x22;
	size += 1;
	buf[size] = 0xFF;
	size += 1;
 
	/*payload 有效载荷：数据传输中所欲传输的实际信息，称为实际数据或者数据体*/
    buf[size] = 'A';
	size += 1;
	for (int i = 0; i < 800; i++)
	{
		buf[size]='K';
		size+=1;

	}
 
	/*cycle send L2 packet*/
	while (1)
	{
		ret = send(fd, buf, size, 0);
		if (ret <= 0)
		{
			perror("send");
			break;
		}
 
		usleep(1);
	}
 
out:
	close(fd);
	return 0;
}
 
