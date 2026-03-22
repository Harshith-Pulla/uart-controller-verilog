// ============================================================
// UART Testbench
// Connects TX and RX together (loopback)
// Sends 0xA5 and checks if receiver gets the same byte
// ============================================================

`timescale 1ns / 1ps

module uart_tb;

    // clock and reset
    reg clk;
    reg rst;

    // TX signals
    reg        tx_start;
    reg  [7:0] tx_data;
    wire       tx_line;
    wire       tx_busy;
    wire       baud_tick;

    // RX signals
    wire [7:0] rx_data;
    wire       rx_valid;

    // --------------------------------------------------------
    // Instantiate baud generator
    // --------------------------------------------------------
    uart_baud_gen baud_gen (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick)
    );

    // --------------------------------------------------------
    // Instantiate transmitter
    // --------------------------------------------------------
    uart_tx tx_inst (
        .clk       (clk),
        .rst       (rst),
        .baud_tick (baud_tick),
        .tx_start  (tx_start),
        .tx_data   (tx_data),
        .tx        (tx_line),
        .tx_busy   (tx_busy)
    );

    // --------------------------------------------------------
    // Instantiate receiver — TX output feeds directly into RX
    // --------------------------------------------------------
    uart_rx rx_inst (
        .clk      (clk),
        .rst      (rst),
        .rx       (tx_line),  // loopback: TX wire goes into RX
        .rx_data  (rx_data),
        .rx_valid (rx_valid)
    );

    // --------------------------------------------------------
    // Clock generation: 100 MHz -> period = 10 ns
    // --------------------------------------------------------
    initial clk = 0;
    always #5 clk = ~clk;

    // --------------------------------------------------------
    // Stimulus
    // --------------------------------------------------------
    initial begin
        // initialize
        rst      = 1;
        tx_start = 0;
        tx_data  = 8'h00;

        // hold reset for 20 clock cycles
        repeat(20) @(posedge clk);
        rst = 0;

        // wait a few cycles after reset
        repeat(5) @(posedge clk);

        // send byte 0xA5 (10100101 in binary)
        tx_data  = 8'hA5;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0; // pulse for exactly one cycle

        // wait until receiver gets the data
        // at 9600 baud, one frame = 10 bits = ~1.04 ms = 104160 cycles
        wait(rx_valid == 1);
        @(posedge clk);

        // check result
        if (rx_data == 8'hA5)
            $display("PASS: Received 0x%h correctly", rx_data);
        else
            $display("FAIL: Expected 0xA5, got 0x%h", rx_data);

        // send a second byte to show multiple transmissions
        repeat(20) @(posedge clk);
        tx_data  = 8'h3C;
        tx_start = 1;
        @(posedge clk);
        tx_start = 0;

        wait(rx_valid == 1);
        @(posedge clk);

        if (rx_data == 8'h3C)
            $display("PASS: Received 0x%h correctly", rx_data);
        else
            $display("FAIL: Expected 0x3C, got 0x%h", rx_data);

        // finish simulation
        repeat(20) @(posedge clk);
        $finish;
    end

    // --------------------------------------------------------
    // Optional: dump waveforms for GTKWave or Vivado viewer
    // --------------------------------------------------------
    initial begin
        $dumpfile("uart_tb.vcd");
        $dumpvars(0, uart_tb);
    end

endmodule
