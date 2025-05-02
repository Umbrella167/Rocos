import socket
import struct

# udp multicast receiver
class UDPReceiver:
    def __init__(self, multicast_group, port):
        self.multicast_group = multicast_group
        self.port = port
        self.sock = socket.socket(socket.AF_INET, socket.SOCK_DGRAM, socket.IPPROTO_UDP)
        self.sock.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
        self.sock.bind(('', port))
        group = socket.inet_aton(multicast_group)
        mreq = struct.pack("4sl", socket.inet_aton(multicast_group), socket.INADDR_ANY)
        self.sock.setsockopt(socket.IPPROTO_IP, socket.IP_ADD_MEMBERSHIP, mreq)

    def receive(self):
        while True:
            data, address = self.sock.recvfrom(10000)
            print(f"Received message: {data} from {address}")
            # Process the received data here
            # For example, you can decode it if it's a string
            # message = data.decode('utf-8')
            # print(f"Decoded message: {message}")

if __name__ == "__main__":
    multicast_group = '224.5.23.2'
    port = 10020
    receiver = UDPReceiver(multicast_group, port)
    print(f"Listening for messages on {multicast_group}:{port}")
    receiver.receive()