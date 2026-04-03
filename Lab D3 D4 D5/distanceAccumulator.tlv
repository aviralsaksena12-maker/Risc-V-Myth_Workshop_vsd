\m5_TLV_version 1d: tl-x.org
\m5
   
   
\SV
   `include "sqrt32.v"
   m5_makerchip_module   // (Expanded in Nav-TLV pane.)
\TLV
   // Connect SV inputs to TLV pipesignals.
    
   
   |calc
      @1
         $reset = *reset;
      ?$valid
         @1
            $aa_sq[31:0] = $aa * $aa;
            $bb_sq[31:0] = $bb * $bb;
            
         @2
            $cc_sq[31:0] = $aa_sq + $bb_sq;
         @3
            $cc[31:0] = sqrt($aa_sq + $bb_sq);
            
      @4
         $total_dist[63:0] = $reset ? 0 :
            $valid ? >>1$total_dist + $cc :
                                   $RETAIN;
      
   // Assert these to end simulation (before the cycle limit).
   *passed = *cyc_cnt > 16'd30;
   *failed = 1'b0;
\SV
   endmodule

