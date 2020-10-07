# VLSI Vivado RTC using I2C

1. Design assumptions
The task of the group was to design a testbench / simulation of a system with a real-time clock as a slave, which is to communicate with the master via the I2C bus. The complementary group was to handle the RTC with the I2C interface.


2. Arrangements with the complementary group of the design process
My first task was to agree what the module itself should look like. We found that the best solution is to create two separate components that will be combined into one module. The simulation of this module would allow us to present everything on one graph. It was supposed to show the passage of time and communication using the bus.
 
You can see below how it looks like

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/schematic.png?raw=true)

3. The I2C bus
I figured we would start by communicating with our real-time clock. The complementary group created a working module and our task was to check if the module actually works correctly. At the beginning, I created the architecture and listed the most necessary signals so that we could present a working module. The next step was to create a map port with reference to the RTC.

The next step was to create a process that counts the clock cycles.

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/portmap.png?raw=true)

The next process was the sim process, which was to check the correctness of the addressing, enable port, check read and write. The code is shown in the figure below.

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/simprocess.png?raw=true)

The final step was to present the simulation plot and graphically check that the component is working properly. At the very bottom of the simulation graph, we have added a waveform that shows the state of our magistaral.

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/graph.png?raw=true)

4. RTC MCP7940 clock
After presenting the operation of the I2C bus, the next step was to simulate the operation of the RTC clock. We had a problem connecting both components to one module, so we created a separate simulation for the MCP7940 clock. The SCL line was changed from inout to in, and its job was to replace the CLK (responsible for timing). The SDA line has been split into two separate lines named SDA_in and SDA_out. This was due to problems with the presentation of the line operation in the simulation. The last problem that has already been solved was the counter process, which worked properly separately, but as a separate process in the whole simulation, it caused errors (the counter did not add the seconds, minutes and hours values). Below is a simulation graph that finally shows the working component.

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/graph2.png?raw=true)

In the simulation you can see that the whole system is working properly and the entire operation is possible with two lines. It shows sending bits on the SDA_in line, which is responsible for setting the SetHr state, which then sets the hour, which we also send on the SDA_in line. Another state presented in the simulation is GetHr, which sends us the current time on the SDA_out line and allows us to read it. Bit_index counts down sequentially sent bits, which are then interpreted by the state set on the line. CLK_count has been lowered to 3 (clock increments) for simulation to show the timing is correct. Depending on the clock speed of the processor, it is properly set to its speed. The save and load line shows us how to save and read the system.

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/simcode.png?raw=true)


The code presented above presents sequentially sent bits after the SDA_in line. They are sent serially, therefore scl_period is set as two clock ticks.

5. Check what happens when the chip gets the wrong address
The last recommendation was to check what happens when we enter the wrong address after the SDA_in line in our RTC chip to see what the chip does. 

![alt text](https://github.com/gryzmol98/Vivado-VHDL-RTC-using-I2C-Master-Slave/blob/main/images/badadress.png?raw=true)

We can see that our circuit in the simulation goes from IDLE to Check_adress all the time until it got a correctly formatted dataframe, then our circuit goes to the Get_Hr state, as it should be interpreted. Wrong address causes continuous transition from CHECK_ADRESS to IDLE.

6. Conclusions
The design process was very time consuming. Each time a problem was solved, another one appeared. Finally, the system has been completed and shows the correct operation of the RTC. The element that could not be solved was the combination of both components, i.e. the I2C bus and the MCP7940 (master-slave).
