\m5_TLV_version 1d: tl-x.org
\m5
\SV
   m5_makerchip_module
\TLV
   $reset = *reset;

   // 1. Inputs (using the provided small random values)
   $val1[31:0] = $rand1[3:0];
   $val2[31:0] = $rand2[3:0];
   
   // 2. Arithmetic Logic Unit (ALU) operations
   $sum[31:0]  = $val1 + $val2;
   $diff[31:0] = $val1 - $val2;
   $prod[31:0] = $val1 * $val2;
   $quot[31:0] = $val1 / $val2;

   // 3. The 4-to-1 MUX Logic
   // We use the ternary (? :) structure based on the $op signal
   $out[31:0] = ($sel[1:0] == 2'b00) ? $sum :
                ($sel[1:0] == 2'b01) ? $diff :
                ($sel[1:0] == 2'b10) ? $prod :
                                      $quot; // Default is 2'b11

   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule
