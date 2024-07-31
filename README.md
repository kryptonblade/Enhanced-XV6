                                   OSN mini project-2 Report 

Specification-2 & 3

FCFS: 
In this specification, we schedule processes based on their creation times. The process that is created first gets to run first. For Implementing this I did changes in 3 files 

=>Makefile 
	Here I created a preprocessor macro. SCHEDULER_() 
=>proc.c 
	Here I implemented the main FCFS function where I iterate all runnable process and select the process with least creation time and run it by scheduling it to running.
=>trap.c 
	Here I skipped some code lines which are timer interrupts. Given that it should be Non preemptive.

for RR:
    average rtime:   ~21
    average wtime:  ~185

for FCFS:
    Average rtime:   ~21
    Average wtime:  ~148

specification-4
part B: 

1.
The implementation of data sequencing in my UDP-based code is different from traditional TCP in several ways:

Transport Protocol:
     Traditional TCP (Transmission Control Protocol) is a connection-oriented, reliable transport protocol, whereas my code uses UDP (User Datagram Protocol), which is connectionless and lacks the built-in reliability features of TCP.

Data Sequencing: 
    In traditional TCP, data sequencing is an integral part of the protocol itself. TCP assigns a sequence number to each byte of data sent and ensures that data is received and delivered in the correct order. In contrast, my UDP-based implementation assigns sequence numbers to chunks of data but does not guarantee in-order delivery. It relies on the application layer to handle sequencing and reordering of data if necessary.

Retransmissions: 
    TCP has a robust mechanism for retransmitting lost or unacknowledged packets. It uses a sliding window mechanism and cumulative acknowledgments to ensure reliable data delivery. The provided UDP code implements retransmissions manually, without a sliding window, by simply resending a chunk if it doesn't receive an acknowledgment within a specified timeout. This method is less efficient and lacks some of the sophisticated congestion control mechanisms present in TCP.

Acknowledgment Handling:
     TCP requires the receiver to send acknowledgments for received data, and the sender waits for these acknowledgments before sending more data. In the provided UDP code, acknowledgments are simulated randomly by skipping some of them (every third ACK). This approach is not representative of how TCP handles acknowledgments in a reliable and ordered manner.

Flow Control: 
    TCP has built-in flow control mechanisms to prevent overwhelming the receiver with data. It uses techniques like TCP window scaling to manage the rate of data transmission. The provided UDP code does not implement flow control, potentially leading to network congestion and inefficiency.



2.
To extend the UDP-based implementation to account for flow control, we can implement a basic form of flow control using a sliding window mechanism. This will help prevent overwhelming the receiver with data and improve efficiency. Here's how we can do it:

Sender Side:
    Maintain a sender window that defines the range of sequence numbers that can be sent without waiting for acknowledgments.
    Initialize the sender window with a size (e.g., window_size) that represents the maximum number of unacknowledged chunks allowed.
    Only send data chunks if their sequence numbers are within the sender window.
    Maintain a variable to keep track of the highest acknowledged sequence number (e.g., highest_acknowledged).

Receiver Side:
    Maintain a receiver window that defines the range of expected sequence numbers.
    Initialize the receiver window with a size that matches the sender's window size.
    Only accept and acknowledge chunks if their sequence numbers are within the receiver window.
    Maintain a variable to keep track of the highest sequence number received (e.g., highest_received).

Sender Side:
    After sending a chunk, start a timer for that chunk to track acknowledgment.
    When an acknowledgment is received, update highest_acknowledged and slide the sender window accordingly.
    Implement a timer mechanism to retransmit unacknowledged chunks if the timer expires.

Receiver Side:
    When receiving a chunk, check if it falls within the receiver window.
    If the chunk's sequence number is within the receiver window, process it and send an acknowledgment.
    Slide the receiver window to match the highest received sequence number.

By implementing this basic sliding window mechanism, we can achieve flow control in our UDP-based communication. This ensures that the sender does not overwhelm the receiver with too much data and provides a basic level of reliability. We can further optimize and enhance this mechanism as needed for your specific application requirements.
