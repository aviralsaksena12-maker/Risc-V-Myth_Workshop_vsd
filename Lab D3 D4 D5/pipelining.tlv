\m5_TLV_version 1d: tl-x.org
\m5
   
   
\SV
   
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   // Connect SV inputs to TLV pipesignals.
   $reset = *reset;
   
   |calc
      @1
         $a2[31:0] = $a * $a;
         $b2[31:0] = $b * $b;
         
      @2
         $cc_sq[31:0] = $a2 + $b2;
      @3
         $cc[31:0] = sqrt($
      
   // Assert these to end simulation (before the cycle limit).
   *passed = *cyc_cnt > 40;
   *failed = 1'b0;
\SV
   endmodule

