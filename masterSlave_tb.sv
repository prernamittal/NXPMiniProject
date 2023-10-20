///////////////////////////////Transaction Class///////////////////////////
class transaction;
  rand bit [7:0] in_master_data, in_slave_data;
  rand bit [7:0] out_master_data, out_slave_data;
  bit mosi;
  bit miso;
  bit start;
 rand bit new_data;
  // Task to display the transaction details
function void display (string name);
$display("..."); 
$display(". -");
$display("%s", name);
$display("Transaction:data_new=%h,in_master_data =%h, in_slave_data =%h, out_master_data =%h, out_slave_data =%h, mosi=%b, miso=%b",new_data,in_master_data, in_slave_data, out_master_data, out_slave_data,  mosi, miso);
endfunction

///////////////////////////////Generator Class///////////////////////////
class generator: 
rand transaction trans; 
mailbox gen2driv;
event ended;
int repeat_count; 
function new(mailbox gen2driv);
this gen2driv=gen2driv; 
endfunction 
task main();
repeat (repeat_count) 
begin
trans= new();
if(!trans. randomize()) 
$fatal ("Gen:: Transaction Failed"); 
trans.display("[Generator]"); 
gen2driv.put(trans);
end
->ended; 
endtask
endclass

///////////////////////////////Driver Class///////////////////////////
class driver;
virtual intf vif; mailbox gen2driv
int no_of_transaction;
function new(virtual intf vif, mailbox gen2driv);
this.vif=vif;
this.gen2driv=gen2driv;
end function

//reset Task 
task reset:
wait (vif.reset);
 $display("Driver: Reset Started");
vif.start<=0;
vif.miso<=0;
vif.mosi<=0;
vif.new_data<=0;
vif.in_master_data<=8’b0;
vif.in_slave_data<=8’b0;
wait (vif.reset);
$display("Driver: reset Ended");
 endtask

task main;
forever begin
transaction trans; 
gen2driv.get(trans);
@(posedge vif.clk); 
vif.start<=start;
vif.new_data<= trans.new_data; 
vif.miso<=trans. miso;
vif.mosi<= trans. mosi;
vif.in_master_data<=trans. in_master_data;
vif.in_slave_data<=trans. in_slave_data;

@(posedge vif.clk)
trans.display("Driver");
no_of_transaction++; 
endtask
end
endclass

///////////////////////////////Interface///////////////////////////
interface intf(input logic clk, reset);

logic valid; 
logic miso; 
logic mosi;
logic in_master_data;
logic in_slave_data; 
endinterface

///////////////////////////////Monitor Class///////////////////////////
class monitor;
virtual intf vif; mailbox mon2scb;
function new(virtual intf vif, mailbox mon2scb);
this.vif= vif;
this.mon2scb= mon2scb; 
endfunction
 task main();
forever begin 
transaction trans;

trans=new();

@(posedge vif.clk ); 
wait (vif start); 
trans.new_data<= vif.new_data; 
trans.miso<=vif. miso;
trans.mosi<= vif. mosi;
trans.in_master_data<=vif. in_master_data;
trans.in_slave_data<=vif. in_slave_data;

@(posedge vif.clk); 

trans.out_slave_data<=vif. out_slave_data;
trans.out_master_data<=vif. out_master_data;
@(posedge vif.clk);

mon2scb.put(trans);
trans.display( Monitor");
end

endtask 
endclass

///////////////////////////////Scoreboard Class///////////////////////////
class scoreboard;

mailbox mon2scb; 
int no_of_transaction; 
function new(mailbox mon2scb); 
this.mon2scb=mon2scb; 
endfunction 

task main;
 transaction trans; 
forever begin 
mon2scb.get(trans);
 if ((trans.in_master_data==trans.out_slave_data) &&
(trans.in_slave_data==trans.out_master_data))
$display("Result matched");

else 
$error("Wrong Result”};
no_of_transaction++; 
trans.display("Scoreboard");
end 
endtask 
endclass

///////////////////////////////Environment Class///////////////////////////
`include "transaction.sv"
`include "generator.sv"
`include "driver.sv"
`include "monitor.sv"
 `include" scoreboard.sv"

class environment;
generator gen; 
driver driv; 
monitor mon;
scoreboard scb;
mailbox gen2driv;
mailbox mon2scb;
virtual intf vif;

function new(virtual intf vif);
 this.vif= vif;
gen2driv=new(); 
mon2scb=new();

gen= new(gen2driv); 
driv= new (vif, gen2driv); 
mon= new(vif, mon2scb); 
scb= new (mon2scb); 
endfunction

task pre_test();
driv.reset();
endtask

task test();
 fork 
gen.main();
driv.main();
mon.main();
scb.main();

join_any 
endtask

task post test();

wait (gen.ended. triggered);
wait (gen.repeat count driv.no_of_transaction); 
wait (gen.repeat_count == scb.no_of_transaction);
endtask

task run();

pre_test(); test();
post_test();
$finish; endtask
endclass


///////////////////////////////TEST///////////////////////////
`include "environment.sv 
program test(intf i intf);

//declaring environment instance environment env

initial begin

//creating environment 
Env=new(i_intf);

//setting the repeat count of generator as 4. means to generate 4 packets 
Env.gen.repeat_count=2
//calling run of env, it interns calls generator and driver main tasks 
env.run();

end

///////////////////////////////Top Module///////////////////////////
module top_test;
bit clk; bit reset;
always #5 clk=-clk;

initial begin 
reset = 1;
#12 reset=0;
end

intf i_intf(clk, reset);
test t1(i_intf);

spi_tb DUT(.clk(i_intf.clk), reset(i_intf.reset),.start(i_intf.start),. in_slave_data(i_intf.in_slave_data),.in_master_data(i_inf. in_master_data),. out_slave_data(i_intf.out_slave_data),.out_master_data(i_inf. out_master_data),.miso(i_intf.miso),. miso(i_intf.miso),.new_data(i_inf.new_data)
);

initial begin

$dumpfile("dump.vcd"); 
$dumpvars; end

endmodule

