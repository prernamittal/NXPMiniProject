# NXPMiniProject
Design and Verification of Single Master Single Slave SPI

## About SPI Communication

SPI is a common communication protocol used by many different devices. For example, SD card modules, RFID card reader modules, and 2.4 GHz wireless transmitter/receivers all use SPI to communicate with microcontrollers. <br><br>

One unique benefit of SPI is the fact that data can be transferred without interruption. Any number of bits can be sent or received in a continuous stream. With I2C and UART, data is sent in packets, limited to a specific number of bits. Start and stop conditions define the beginning and end of each packet, so the data is interrupted during transmission. Devices communicating via SPI are in a master-slave relationship. The master is the controlling device (usually a microcontroller), while the slave (usually a sensor, display, or memory chip) takes instruction from the master. The simplest configuration of SPI is a single master, single slave system, but one master can control more than one slave (more on this below). <br><br>

<b>MOSI (Master Output/Slave Input)</b> – Line for the master to send data to the slave.
<li>The master sends data to the slave bit by bit, in serial through the MOSI line. The slave receives the data sent from the master at the MOSI pin. Data sent from the master to the slave is usually sent with the most significant bit first.

<b>MISO (Master Input/Slave Output)</b> – Line for the slave to send data to the master.
<li>The slave can also send data back to the master through the MISO line in serial. The data sent from the slave back to the master is usually sent with the least significant bit first.

<b>SCLK (Clock)</b> – Line for the clock signal.
<li>SPI is a synchronous communication protocol. 
<li>The clock signal in SPI can be modified using the properties of clock polarity and clock phase. 
<li>Clock polarity can be set by the master to allow for bits to be output and sampled on either the rising or falling edge of the clock cycle. 
<li>Clock phase can be set for output and sampling to occur on either the first edge or second edge of the clock cycle, regardless of whether it is rising or falling.

<b>SS/CS (Slave Select/Chip Select)</b> – Line for the master to select which slave to send data to
<li>The master can choose which slave it wants to talk to by setting the slave’s CS/SS line to a low voltage level. In the idle, non-transmitting state, the slave select line is kept at a high voltage level. Multiple CS/SS pins may be available on the master, which allows for multiple slaves to be wired in parallel. If only one CS/SS pin is present, multiple slaves can be wired to the master by daisy-chaining.

## Steps of SPI Data Transmission
<ol>
<li>The master outputs the clock signal:
<li>The master switches the SS/CS pin to a low voltage state, which activates the slave:
<li>The master sends the data one bit at a time to the slave along the MOSI line. The slave reads the bits as they are received:
<li>If a response is needed, the slave returns data one bit at a time to the master along the MISO line. The master reads the bits as they are received.
</ol>

## Part-1: Verilog Based Verification of each IP block
<li> slave.v 
<li> master.v
  
## Part-2: SystemVerilog Based Testbench Verification
