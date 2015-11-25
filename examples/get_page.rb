require "#{File.expand_path(__FILE__)}/../../tcp"

# use your own nameserver ip address
FAKE_IP_ADDRESS  = "10.0.2.3"

tcp = Teeceepee.new("http://www.groupon.com", FAKE_IP_ADDRESS)
tcp.connect
tcp.get_page

data = tcp.recv(10000)
tcp.close

puts data

