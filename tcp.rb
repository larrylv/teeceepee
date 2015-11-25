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
      state = @conn.handle(PacketFu::Packet.parse pkt)
      return if state == Teeceepee::CLOSED_STATE
    end
  end
end

class Teeceepee
  attr_accessor :state, :dst_ip, :dst_port, :src_port, :server_ack_seq, :client_next_seq, :recv_buffer

  CLOSED_STATE      = "CLOSED".freeze
  SYN_SENT_STATE    = "SYN-SENT".freeze
  ESTABLISHED_STATE = "ESTABLISHED".freeze
  FIN_WAIT_1_STATE  = "FIN-WAIT-1".freeze
  LAST_ACK_STATE    = "LAST-ACK".freeze


  def initialize(url, fake_ip_address = nil)
    @hostname, @path = parse_uri(url)

    @src_port = Random.new.rand(12345..50000)
    @dst_ip   = Resolv.getaddress(@hostname)
    @dst_port = 80
    @config   = PacketFu::Utils.whoami?
    @state    = CLOSED_STATE

    @config = @config.merge(ip_saddr: fake_ip_address) if fake_ip_address

    @server_ack_seq = 0
    @client_next_seq = 0
    @recv_buffer = ""

    @listener = Listener.new(self, @config, @dst_ip)
    @listener_thread = Thread.new { @listener.listen }

    puts "Destination IP: #{@dst_ip}"
    # require 'pry'; binding.pry
  end

  def connect
    send_syn
    @state = SYN_SENT_STATE
  end

  def get_page
    payload = "GET #{@path} HTTP/1.0\r\nHost: #{@hostname}\r\n\r\n"
    while @state != ESTABLISHED_STATE # wait until handshake is done
      sleep(0.01)
    end

    send_ack([:psh], payload)
  end

  def recv(size)
    while @recv_buffer.size < size
      sleep(0.01)
      break if [CLOSED_STATE].include?(@state)
    end

    # should use mutex here
    @recv_buffer.slice!(0...size)
  end

  # Implementation might be not ugly using state machine
  def handle(pkt)
    # puts "Received packet, current state: #{@state}, buffer length: #{@recv_buffer.size}"
    # puts "tcp_flags: #{pkt.tcp_flags.inspect}"

    @client_next_seq = pkt.tcp_seq + 1
    @server_ack_seq  = pkt.tcp_ack

    if pkt.tcp_flags.rst == 1
      @state = CLOSED_STATE
    elsif pkt.tcp_flags.syn == 1
      if @state == SYN_SENT_STATE
        @state = ESTABLISHED_STATE
        send_ack
      end
    elsif pkt.tcp_flags.fin == 1
      if @state == ESTABLISHED_STATE
        @state = LAST_ACK_STATE
        send_ack([:fin])
      elsif @state == FIN_WAIT_1_STATE
        @state = CLOSED_STATE
        send_ack
      end
    elsif pkt.payload.length > 0
      @recv_buffer += pkt.payload
      send_ack
    elsif pkt.tcp_flags.ack == 1
      if @state == LAST_ACK_STATE
        @state = CLOSED_STATE
      end
    end

    @state
  end

  def close
    return if @state == CLOSED_STATE

    @state = "FIN-WAIT-1"
    send_ack([:fin])
  end

  private

  def send_syn
    synpkt               = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")

    synpkt.tcp_sport     = @src_port
    synpkt.ip_daddr      = @dst_ip
    synpkt.tcp_dst       = @dst_port
    synpkt.tcp_flags.syn = 1
    synpkt.recalc

    synpkt.to_w
  end

  def send_ack(flags = [], payload = "")
    ackpkt = PacketFu::TCPPacket.new(config: @config, flavor: "Linux")

    ackpkt.tcp_sport = @src_port
    ackpkt.ip_daddr  = @dst_ip
    ackpkt.tcp_dport = @dst_port
    ackpkt.tcp_ack   = @client_next_seq
    ackpkt.tcp_seq   = @server_ack_seq
    ackpkt.payload   = payload

    ackpkt.tcp_flags.ack = 1

    flags.each { |flag| ackpkt.tcp_flags.send("#{flag}=".to_sym, 1) }

    ackpkt.recalc

    ackpkt.to_w

    @server_ack_seq += payload.size
  end

  def parse_uri(url)
    uri = URI.parse(url)
    hostname, path = uri.hostname, uri.path
    path = "/" if path.empty?

    [hostname, path]
  end
end
