require "#{File.expand_path(__FILE__)}/../../tcp"

# use your own nameserver ip address
FAKE_IP_ADDRESS  = "10.0.2.3"

# IP of google.com
TARGET_IP   = "216.58.197.110"
TARGET_PORT = "80"

tcp = Teeceepee.new(TARGET_IP, TARGET_PORT, FAKE_IP_ADDRESS)
tcp.connect
