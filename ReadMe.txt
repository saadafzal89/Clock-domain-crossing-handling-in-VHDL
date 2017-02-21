------------READ ME-------------

Team members:
Vyas Kovakkat 
Saad Afzal

*****Part-1*****

The incorrect code does not show non-zero average difference.
The following steps were done to synchronize the pulse signal across the two clock domains:

1. Added a 1-bit register entity in the source code folder.
2. Instantiated 3 register entities with 1 on source side and 2 on destination side.
3. Clock1 was used for register on source side and clock2 was used for registers on destination side.
4. Connected the output of source (i.e. 'pulse') to register-1.
5. Connected the output of register-1 to input of register-2 and output of register-2 to input of register-3.
6. Finally the output of register-3 was connected to the input of destination.
7. No combination logic was connected between the series connection of these three registers.


*****Part-2*****

The provided code shouldn't run on the board but it does with Average difference =0.0 in 9.2 seconds
The following steps were taken to synchronize the send_s and ack_s signal:

1. In the handshake.vhd file, source and destination sides send/receive 'send_s' and 'ack_s' signals respectively.
2. Extra state was added wherever and whenever these values were read. 
3. Adding extra state meant adding an extra register in the destination clock domain.
4. So states S_DELAY and S_DELAY1 were added on source whenever ack_s was being read, so this read was now done in next state.
5. Similarly, states S_DELAY and S_DELAY1 were added on destination whenever send_s was being read, so this read was now done in next state.
6. Hence, dual flop synchronizer was implemented by adding extra control states for synchronization of these signals.
7. The total time on board for execution increased from 9.2 to 11.2 seconds, adding latency due to this synchronization.


*****Part-3*****

Done as instructed by the professor in the lecture to achieve average difference of 0.0 on the zedboard.
This is much faster compared to handshake synchronizer taking 3.2 seconds for the same test case.