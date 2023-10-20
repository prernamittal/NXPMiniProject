module spi_master #(
    parameter CLK_DIV = 2   // Clock division factor
)(
    input clk,        // Clock input
    input rst,        // Reset input
    input miso,       // Master In Slave Out data line
    output mosi,      // Master Out Slave In data line
    output sck,       // Serial Clock line
    input start,      // Start signal
    input [7:0] data_in, // 8-bit input data
    output [7:0] data_out, // 8-bit output data
    output busy,      // Busy flag
    output new_data   // New data available flag
);

    // State definitions
    localparam STATE_SIZE = 2;
    localparam IDLE = 2'd0,
               WAIT_HALF = 2'd1,
               TRANSFER = 2'd2;

    // Internal registers
    reg [STATE_SIZE-1:0] state_d, state_q;
    reg [7:0] data_d, data_q;
    reg [CLK_DIV-1:0] sck_d, sck_q;
    reg mosi_d, mosi_q;
    reg [2:0] ctr_d, ctr_q;
    reg new_data_d, new_data_q;
    reg [7:0] data_out_d, data_out_q;

    // Output assignments
    assign mosi = mosi_d; //pragya changed from mosi_q to mosi_d
    assign sck = (~sck_q[CLK_DIV-1]) & (state_q == TRANSFER);
    assign busy = state_q != IDLE;
    assign data_out = data_out_q;
    assign new_data = new_data_q;

    // Combinational Logic Block
    always @(*) begin
        // Default assignments
        sck_d = sck_q;
        data_d = data_q;
        mosi_d = mosi_q;
        ctr_d = ctr_q;
        new_data_d = 1'b0;
        data_out_d = data_out_q;
        state_d = state_q;

        // State machine
        case (state_q)
            IDLE: begin
                sck_d = 4'b0;  // Reset clock counter
                ctr_d = 3'b0;  // Reset bit counter
                // If start signal is active
                if (start == 1'b1) begin
                    data_d = data_in; // Load input data
                    state_d = WAIT_HALF; // Move to next state
                end
            end

            WAIT_HALF: begin
                sck_d = sck_q + 1'b1;  // Increment clock counter
                // If half of the clock period has elapsed
                if (sck_q == {CLK_DIV-1{1'b1}}) begin
                    sck_d = 1'b0;  // Reset clock counter
                    state_d = TRANSFER; // Move to next state
                end
            end

            TRANSFER: begin
                sck_d = sck_q + 1'b1;  // Increment clock counter
                // If the clock counter is at zero (rising edge)
                if (sck_q == 4'b0000) begin
                    mosi_d = data_q[7];  // Set the most significant bit to mosi
                // If the clock is half full (falling edge)
                end else if (sck_q == {CLK_DIV-1{1'b1}}) begin
                    data_d = {data_q[6:0], miso};  // Shift and include miso bit
                // If clock counter is full (rising edge)
                end else if (sck_q == {CLK_DIV{1'b1}}) begin
                    ctr_d = ctr_q + 1'b1;  // Increment bit counter
                    // If we are on the last bit
                    if (ctr_q == 3'b111) begin
                        state_d = IDLE;  // Go back to idle state
                        data_out_d = data_q; // Set the output data register
                        new_data_d = 1'b1; // Indicate new data is available
                    end
                end
            end
        endcase
    end

    // Sequential Logic Block
    always @(posedge clk) begin
        if (rst) begin
            // On reset, initialize all registers
            ctr_q <= 3'b0;
            data_q <= 8'b0;
            sck_q <= 4'b0;
            mosi_q <= 1'b0;
            state_q <= IDLE;
            data_out_q <= 8'b0;
            new_data_q <= 1'b0;
        end else begin
            // Transfer intermediate values to state registers
            ctr_q <= ctr_d;
            data_q <= data_d;
            sck_q <= sck_d;
            mosi_q <= mosi_d;
            state_q <= state_d;
            data_out_q <= data_out_d;
            new_data_q <= new_data_d;
        end
    end
endmodule

module spi_slave(
    input clk,      // Clock input
    input rst,      // Reset input
    input ss,       // Slave Select
    input mosi,     // Master Out, Slave In
    output miso,    // Master In, Slave Out
    input sck,      // Serial Clock
    output done,    // Data transmission done flag
    input [7:0] din,  // 8-bit data input
    output [7:0] dout // 8-bit data output
);

// Declare registers for internal operations
reg mosi_d, mosi_q;
reg ss_d, ss_q;
reg sck_d, sck_q;
reg sck_old_d, sck_old_q;
  reg [7:0] data_d, data_q;
reg done_d, done_q;
reg [2:0] bit_ct_d, bit_ct_q; // Bit counter, 3 bits to count 0-7
reg [7:0] dout_d, dout_q;
reg miso_d, miso_q;

// Assigning register values to output
assign miso = miso_q;
assign done = done_q;
assign dout = dout_q;

// Combinational Logic Block
always @(*) begin
    // Default assignments for combinational variables
    ss_d      = ss;
    mosi_d    = mosi;
    miso_d    = miso_q;
    sck_d     = sck;
    sck_old_d = sck_q;
    data_d    = data_q;
    done_d    = 1'b0; // Ensure done flag is low by default
    bit_ct_d  = bit_ct_q;
    dout_d    = dout_q;

    // Check if slave is selected (ss is low when selected)
    if (ss_q) begin
        bit_ct_d = 3'b0;  // Reset bit counter
        data_d   = din;   // Load new data to be transmitted
        miso_d   = data_q[7]; // Assign most significant bit to miso
    end else begin
        // On Rising edge of Serial Clock (sck)
        if (!sck_old_q && sck_q) begin 
            data_d   = {data_q[6:0], mosi_q}; // Shift in mosi bit
            bit_ct_d = bit_ct_q + 1'b1;       // Increment bit count

            // If 8 bits have been processed
            if (bit_ct_q == 3'b111) begin
                dout_d = {data_q[6:0], mosi_q}; // Update dout with received byte
                done_d = 1'b1; // Set done flag high indicating byte reception is complete
                data_d = din;  // Load new data to be transmitted next
            end
        // On Falling edge of Serial Clock (sck)
        end else if (sck_old_q && !sck_q) begin 
            miso_d = data_q[7]; // Assign most significant bit to miso
        end
    end
end

// Sequential Logic Block
always @(posedge clk) begin
    // Check if reset is active
    if (rst) begin
        // Reset all sequential variables
        done_q  <= 1'b0;
        bit_ct_q <= 3'b0;
        dout_q  <= 8'b0;
        miso_q  <= 1'b1;
    end else begin
        // Transfer values from combinational (_d) to sequential (_q) variables
        done_q <= done_d;
        bit_ct_q <= bit_ct_d;
        dout_q <= dout_d;
        miso_q <= miso_d;
    end
    
    // Update old state registers with current state values
    sck_q <= sck_d;
    mosi_q <= mosi_d;
    ss_q <= ss_d;
    data_q <= data_d;
    sck_old_q <= sck_old_d;
end

endmodule