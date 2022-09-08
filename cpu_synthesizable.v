module CPU (clock);
  
  //Processor Instructions opcodes
  parameter LW    = 6'b100011,
            SW    = 6'b101011,
            BEQ   = 6'b000100,
            no-op = 32'b000000100000,
            ALUop = 6'b0;
  
endmodule
