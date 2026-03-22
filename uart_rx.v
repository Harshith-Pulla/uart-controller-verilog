// ============================================================
// UART Receiver
// Format  : 8N1 (8 data bits, no parity, 1 stop bit)
// Sampling: Middle of each bit period to avoid edge noise
// Mid point = CLKS_PER_BIT / 2 = 5208 cycles
// ============================================================

module uart_rx (
    input  wire       clk,       // 100 MHz system clock
    input  wire       rst,       // synchronous reset, active high
    input  wire       rx,        // serial input line
    output reg  [7:0] rx_data,   // received byte
    output reg        rx_valid   // pulses high for 1 cycle when byte is ready
);

    parameter CLKS_PER_BIT = 10416;
    parameter HALF_BIT     = 5208; // sample at middle of bit

    // FSM states
    parameter IDLE  = 2'd0;
    parameter START = 2'd1;
    parameter DATA  = 2'd2;
    parameter STOP  = 2'd3;

    reg [1:0] state;
    reg [13:0] clk_cnt;   // counts clock cycles within each bit
    reg [2:0]  bit_cnt;   // counts received bits (0-7)
    reg [7:0]  shift_reg; // assembles incoming bits

    always @(posedge clk) begin
        if (rst) begin
            state     <= IDLE;
            clk_cnt   <= 0;
            bit_cnt   <= 0;
            shift_reg <= 0;
            rx_data   <= 0;
            rx_valid  <= 0;
        end
        else begin
            rx_valid <= 0; // default: not valid, pulse only when done

            case (state)

                IDLE: begin
                    clk_cnt <= 0;
                    bit_cnt <= 0;
                    // detect falling edge = start bit beginning
                    if (rx == 1'b0)
                        state <= START;
                end

                START: begin
                    // wait until we are at the MIDDLE of the start bit
                    // then confirm it is still low (not a glitch)
                    if (clk_cnt == HALF_BIT - 1) begin
                        if (rx == 1'b0) begin
                            clk_cnt <= 0;
                            state   <= DATA;
                        end
                        else begin
                            // it was a glitch, go back to idle
                            state <= IDLE;
                        end
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                DATA: begin
                    // wait one full bit period then sample
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        clk_cnt             <= 0;
                        shift_reg[bit_cnt]  <= rx; // sample the bit
                        if (bit_cnt == 3'd7) begin
                            bit_cnt <= 0;
                            state   <= STOP;
                        end
                        else begin
                            bit_cnt <= bit_cnt + 1;
                        end
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

                STOP: begin
                    // wait for stop bit period then output data
                    if (clk_cnt == CLKS_PER_BIT - 1) begin
                        rx_data  <= shift_reg;
                        rx_valid <= 1'b1; // data is ready
                        clk_cnt  <= 0;
                        state    <= IDLE;
                    end
                    else begin
                        clk_cnt <= clk_cnt + 1;
                    end
                end

            endcase
        end
    end

endmodule
