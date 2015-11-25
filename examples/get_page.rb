require "#{File.expand_path(__FILE__)}/../../tcp"

YOUR_MAC_ADDRESS = "08:00:27:88:0c:a6"
YOUR_IP_ADDRESS  = "10.0.2.15"
FAKE_MAC_ADDRESS = "52:54:00:12:35:03"
FAKE_IP_ADDRESS  = "10.0.2.3"

def arp_spoofing
  arppkt = PacketFu::ARPPacket.new(:flavor => "Linux")

  arppkt.eth_saddr = arppkt.arp_saddr_mac = YOUR_MAC_ADDRESS
  arppkt.eth_daddr = arppkt.arp_daddr_mac = FAKE_MAC_ADDRESS
  arppkt.arp_saddr_ip = YOUR_IP_ADDRESS
  arppkt.arp_daddr_ip = FAKE_IP_ADDRESS

  arppkt.arp_opcode    = 2

  arppkt.to_w
end

5.times { arp_spoofing; sleep(0.1) }

TARGET_IP   = "216.58.197.110"
TARGET_PORT = "80"

tcp = Teeceepee.new(TARGET_IP, TARGET_PORT, FAKE_IP_ADDRESS)
tcp.connect
