// ============================================================
// UART Transmitter
// Format : 8N1 (8 data bits, no parity, 1 stop bit)
// Frame  : START(0) | D0 D1 D2 D3 D4 D5 D6 D7 | STOP(1)
// ============================================================

module uart_tx (
    input  wire       clk,       // 100 MHz system clock
    input  wire       rst,       // synchronous reset, active high
    input  wire       baud_tick, // 1-cycle pulse from baud generator
    input  wire       tx_start,  // pulse high for 1 cycle to send
    input  wire [7:0] tx_data,   // byte to transmit
    output reg        tx,        // serial output line
    output reg        tx_busy    // high while transmitting
);

    // FSM states
    parameter IDLE  = 2'd0;
    parameter START = 2'd1;
    parameter DATA  = 2'd2;
    parameter STOP  = 2'd3;

    reg [1:0] state;
    reg [7:0] shift_reg;  // holds the byte being shifted out
    reg [2:0] bit_cnt;    // counts 0 to 7 (8 data bits)

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            tx        <= 1'b1; // UART line idles HIGH
            tx_busy   <= 1'b0;
            shift_reg <= 8'd0;
            bit_cnt   <= 3'd0;
        end
        else begin
            case (state)

                IDLE: begin
                    tx      <= 1'b1; // keep line high
                    tx_busy <= 1'b0;
                    if (tx_start) begin
                        shift_reg <= tx_data;
                        tx_busy   <= 1'b1;
                        state     <= START;
                    end
                end

                START: begin
                    if (baud_tick) begin
                        tx      <= 1'b0; // pull line LOW = start bit
                        bit_cnt <= 3'd0;
                        state   <= DATA;
                    end
                end

                DATA: begin
                    if (baud_tick) begin
                        tx        <= shift_reg[0];      // LSB first
                        shift_reg <= shift_reg >> 1;    // shift right
                        if (bit_cnt == 3'd7)
                            state <= STOP;
                        else
                            bit_cnt <= bit_cnt + 1;
                    end
                end

                STOP: begin
                    if (baud_tick) begin
                        tx    <= 1'b1; // stop bit = HIGH
                        state <= IDLE;
                    end
                end

            endcase
        end
    end

endmodule
