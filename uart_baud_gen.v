// ============================================================
// Baud Rate Generator
// System Clock : 100 MHz
// Baud Rate    : 9600
// Clocks/bit   : 100_000_000 / 9600 = 10416
// ============================================================

module uart_baud_gen (
    input  wire clk,        // 100 MHz system clock
    input  wire rst,        // synchronous reset, active high
    output reg  baud_tick   // 1-cycle pulse every bit period
);

    // 10416 - 1 because counter starts at 0
    parameter CLKS_PER_BIT = 10416;

    reg [13:0] counter; // 14 bits to hold up to 10416

    always @(posedge clk) begin
        if (rst) begin
            counter   <= 0;
            baud_tick <= 0;
        end
        else if (counter == CLKS_PER_BIT - 1) begin
            counter   <= 0;
            baud_tick <= 1; // pulse for exactly one clock cycle
        end
        else begin
            counter   <= counter + 1;
            baud_tick <= 0;
        end
    end

endmodule
