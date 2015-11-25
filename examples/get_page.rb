require "#{File.expand_path(__FILE__)}/../../tcp"

# use your own nameserver ip address
FAKE_IP_ADDRESS  = "10.0.2.3"

tcp = Teeceepee.new("google.com", FAKE_IP_ADDRESS)
tcp.connect

