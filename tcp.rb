require 'bundler'
require 'bundler/setup'

require 'packetfu'

class Teeceepee
  def initialize(ip, port)
    @ip     = ip
    @port   = port
    @config = PacketFu::Utils.whoami?
  end

  def syn
    synpkt               = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")
    synpkt.ip_daddr      = @ip.to_s
    synpkt.tcp_dst       = @port.to_i
    synpkt.tcp_src       = 41700 # hard coded for debugging w/ Wireshark
    synpkt.tcp_flags.syn = 1
    synpkt.recalc

    @cap = PacketFu::Capture.new(
      iface: @config[:iface],
      start: true,
      filter: "tcp and dst #{@config[:ip_saddr]} and tcp[13] == 18"
    )

    synpkt.to_w

    puts "SYN"
  end

  def ack
    @cap.stream.each do |pkt|
      synackpkt = PacketFu::Packet.parse(pkt)
      puts "SYNACK"

      ackpkt = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")
      ackpkt.ip_saddr = synackpkt.ip_daddr
      ackpkt.ip_daddr = synackpkt.ip_saddr
      ackpkt.eth_saddr = synackpkt.eth_daddr
      ackpkt.eth_daddr = synackpkt.eth_saddr
      ackpkt.tcp_sport = synackpkt.tcp_dport
      ackpkt.tcp_dport = synackpkt.tcp_sport
      ackpkt.tcp_flags.syn = 0
      ackpkt.tcp_flags.ack = 1
      ackpkt.tcp_ack = synackpkt.tcp_seq + 1
      ackpkt.tcp_seq = synackpkt.tcp_ack
      ackpkt.recalc

      ackpkt.to_w
      require 'pry'; binding.pry
      puts "ACK"
    end
  end
end

require 'pry'; binding.pry
