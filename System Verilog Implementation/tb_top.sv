`timescale 1ns / 1ps

module tb_top;

    // -------------------------------------------------------------------------
    // DUT Signals
    // -------------------------------------------------------------------------
    logic        clk;
    logic        reset;
    logic [31:0] cyc_cnt;
    wire         passed;
    wire         failed;

    // -------------------------------------------------------------------------
    // DUT Instantiation
    // -------------------------------------------------------------------------
    top dut (
        .clk     (clk),
        .reset   (reset),
        .cyc_cnt (cyc_cnt),
        .passed  (passed),
        .failed  (failed)
    );

    // -------------------------------------------------------------------------
    // Clock Generation (10 ns period = 100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // Cycle Counter
    // -------------------------------------------------------------------------
    always_ff @(posedge clk) begin
        if (reset)
            cyc_cnt <= 32'd0;
        else
            cyc_cnt <= cyc_cnt + 32'd1;
    end

    // -------------------------------------------------------------------------
    // Test Sequence
    // -------------------------------------------------------------------------
    initial begin
        // (Optional) VCD dump - Vivado XSim supports this too
        $dumpfile("tb_top.vcd");
        $dumpvars(0, tb_top);

        // Apply reset
        reset = 1'b1;
        @(posedge clk);
        @(posedge clk);
        reset = 1'b0;

        $display("=== Vivado Simulation Started ===");

        // Run until done or timeout
       fork : run_fork
            // -----------------------------------------------------------------
            // Branch 1: Timeout safety net
            // -----------------------------------------------------------------
            begin : timeout_block
                repeat(500) @(posedge clk);
                $display("[TIMEOUT] Simulation exceeded 500 cycles.");
                $display("  rf[10]  = %0d (expected 45)", dut.rf[10]);
                $display("  rf[17]  = %0d (expected 45)", dut.rf[17]);
                $display("  dmem[4] = %0d (expected 45)", dut.dmem[4]);
                $finish;
            end
        
            // -----------------------------------------------------------------
            // Branch 2: Live logger (prints every cycle)
            // -----------------------------------------------------------------
            begin : logger_block
                @(negedge reset);  // wait until reset drops
                $display("------------------------------------------------");
                $display(" Cycle |  PC  | rf[10] | rf[17] | dmem[4]");
                $display("------------------------------------------------");
                forever @(posedge clk) begin
                    $display("%5d  | %3d  | %6d | %6d | %7d",
                             cyc_cnt, dut.CPU_pc_a1, dut.rf[10], dut.rf[17], dut.dmem[4]);
                end
            end
        
            // -----------------------------------------------------------------
            // Branch 3: Detect pass and print final values
            // -----------------------------------------------------------------
            begin : monitor_block
                // 1. Wait for r10 to become 45
                wait(passed === 1'b1);
                $display("[INFO] rf[10] == 45 detected at cycle %0d", cyc_cnt);
        
                // 2. Wait just long enough for LW into r17 to finish
                while (dut.rf[17] !== 32'd45) @(posedge clk);
        
                // 3. Print final values in ALL cases so you can see them
                $display("[INFO] Final snapshot at cycle %0d:", cyc_cnt);
                $display("  rf[10]  = %0d", dut.rf[10]);
                $display("  rf[17]  = %0d", dut.rf[17]);
                $display("  dmem[4] = %0d", dut.dmem[4]);
        
                // 4. Pass/Fail verdict
                if (dut.rf[10] == 32'd45 && dut.rf[17] == 32'd45 && dut.dmem[4] == 32'd45)
                    $display("[PASS] All checks passed!");
                else
                    $display("[FAIL] One or more values are incorrect.");
        
                $finish;
            end
        join_any
        disable run_fork;
          end
endmodule
