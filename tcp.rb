require 'bundler'
require 'bundler/setup'

require 'packetfu'

class Listener
  def initialize(conn, config, dst_ip)
    @conn = conn
    @cap = PacketFu::Capture.new(
      iface: config[:iface],
      start: true,
      filter: "tcp and dst #{config[:ip_saddr]} and src #{dst_ip}"
    )
  end

  def listen
    @cap.stream.each do |pkt|
      @conn.handle(PacketFu::Packet.parse pkt)
    end
  end
end

class Teeceepee
  attr_accessor :state

  CLOSED_STATE = "CLOSED".freeze
  SYN_SENT_STATE = "SYN-SENT".freeze

  def initialize(dst_ip, dst_port, fake_ip_address = nil)
    @dst_ip          = dst_ip
    @dst_port        = dst_port
    @config          = PacketFu::Utils.whoami?
    @state           = CLOSED_STATE
    @fake_ip_address = fake_ip_address

    @config = @config.merge(ip_saddr: fake_ip_address) if fake_ip_address

    @listener = Listener.new(self, @config, dst_ip)
    @listener_thread = Thread.new { @listener.listen }
  end

  def connect
    send_syn
    @state = SYN_SENT_STATE
  end

  def handle(pkt)
    send_ack(pkt)
  end

  private

  def send_syn
    synpkt               = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")

    synpkt.ip_daddr      = @dst_ip.to_s
    synpkt.tcp_dst       = @dst_port.to_i
    synpkt.tcp_flags.syn = 1
    synpkt.recalc

    synpkt.to_w

    puts "SYN"
  end

  def send_ack(pkt)
    ackpkt = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")

    ackpkt.ip_saddr = pkt.ip_daddr
    ackpkt.ip_daddr = pkt.ip_saddr
    ackpkt.eth_saddr = pkt.eth_daddr
    ackpkt.eth_daddr = pkt.eth_saddr
    ackpkt.tcp_sport = pkt.tcp_dport
    ackpkt.tcp_dport = pkt.tcp_sport
    ackpkt.tcp_flags.syn = 0
    ackpkt.tcp_flags.ack = 1
    ackpkt.tcp_ack = pkt.tcp_seq + 1
    ackpkt.tcp_seq = pkt.tcp_ack
    ackpkt.recalc

    ackpkt.to_w

    puts "ACK"
  end
end
