module CPU (clock);
  
  //Processor Instructions opcodes
  parameter LW    = 6'b100011,
            SW    = 6'b101011,
            BEQ   = 6'b000100,
            no-op = 32'b000000100000,
            ALUop = 6'b0;
  
  input clock;
  reg [31:0] PC, Regs[0:31], IMem [0:1023], DMem [0:1023]; //separate memories
  reg [31:0] IFIDIR, IDEXA, IDEXB, IDEXIR, EXMEMIR, EXMEMB, EXMEMALUout, MEMWBVal, MEMWBIR; //pipeline registers
  
  wire [4:0] IDEXrs, IDEXrt, EXMEMrd, MEMWBrd, MEMWBrt; //access register fields
  wire [5:0] EXMEMop, MEMWBop, IDEXop; //access opcodes
  wire [31:0] Ain, Bin; //ALU inputs
  
  //These assignments define fields from the pipeline register
  assign IDEXop = IDEXIR [31:26];
  assign IDEXrs = IDEXIR [25:21];
  assign IDEXrt = IDEXIR [15:11];
  assign EXMEMop = EXMEMIR [31:26];
  assign EXMEMrd = EXMEMIR [15:11];
  assign MEMWBop = MEMWBIR [31:26];
  assign MEMWBrt = MEMWBIR [25:20];
  assign MEMWBrd = MEMWBIR [20:16];
  
  //Inputs to the ALU come directly from ID/EX pipeline registers
  assign Ain = IDEXA;
  assign Bin = IDEXB;
  
  //Initialization of registers
  reg [5:0] i;
  initial begin
     PC =0;
     IFIDIR=no-op; IDEXIR=no-op; EXMEMIR=no-op; MEMWBIR=no-op;
    for (i=0; i<31; i++) Regs[i]=i; //initialize random value to the registers
  end
  
  always@(posedge clock) begin
    //Remember that all these actions happen every piepe stage and with non=blocking or parallel assignments
    
    //First instruction in pipeline is being fetched
    IFIDIR <= IMem[PC>>2];
    PC = PC+4;
    
    //Second instruction in pipeline is fetching register
    IDEXA <= Regs[IFIDIR[25:21]];
    IDEXB <= Regs[IFIDIR[20:16]];
    IDEXIR <= IFIDIR; // pass on IR register can happen anywhere
    
    //Third instruction is doing address calculation or ALU operation
    if ((IDEXop == LW)| (IDEXop == SW)) //address
      EXMEMALUout <= IDEXA + {{16{IDEXIR[15]}}, IDEXIR[15:0]};
    else if (IDEXop == ALUop)
      case (IDEXIR[5:0]) //various R-type instructions for the ALU
        32: EXMEMALUout <= Ain + Bin; //add
        31: EXMEMALUout <= Ain - Bin; //subtract
        default: //other R-type instructions
       endcase
        
      //pass IR and B registers
      EXMEMIR <= IDEXIR;
      EXMEMB <= IDEXB; 
    
    //Fourth is Mem Stage of pipeline
        if (EXMEMop == ALUop)
          MEMWBVal <= EXMEMALUout; //pass ALU results
        else if (EXMEMop == LW)
          MEMWBVal <= DMem[EXMEMALUout>>2];
        else if (EXMEMop == SW)
          DMem[EXMEMALUout>>2] <= EXMEMB;  //store
        
        MEMWBIR <= EXMEMIR; //pass IR
        
    //Fifth stage is thw Writeback Stage
        //update registers if ALU operation, and destination is not zero
        if ((MEMWBop == ALUop) & (MEMWBrd != 0))
          Regs[MEMWBrd] <= MEMWBVal; //ALU operation
        //update registers if Load, and destination is not zero
        else if ((EXMEMop == LW) & (MEMWBrt != 0))
          Regs[MEMWBrt] <= MEMWBVal;
     
 end
endmodule
        
