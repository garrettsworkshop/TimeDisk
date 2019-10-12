module TimeMachine(C7M, PHI1in, nRES,
				   A, RA, nWE, D, RD,
				   nDEVSEL, nIOSEL, nIOSTRB, nINH,
				   nRAMROMCS, RAMROMCSgb, RAMCS, nROMCS);

	/* Clock, Reset */
	input C7M, PHI1in; // Clock inputs
	input nRES; // Reset

	/* PHI1 Delay */
	wire [8:0] PHI1b;
	wire PHI1;
	LCELL PHI1b0_MC (.in(PHI1in), .out(PHI1b[0]));
	LCELL PHI1b1_MC (.in(PHI1b[0]), .out(PHI1b[1]));
	LCELL PHI1b2_MC (.in(PHI1b[1]), .out(PHI1b[2]));
	LCELL PHI1b3_MC (.in(PHI1b[2]), .out(PHI1b[3]));
	LCELL PHI1b4_MC (.in(PHI1b[3]), .out(PHI1b[4]));
	LCELL PHI1b5_MC (.in(PHI1b[4]), .out(PHI1b[5]));
	LCELL PHI1b6_MC (.in(PHI1b[5]), .out(PHI1b[6]));
	LCELL PHI1b7_MC (.in(PHI1b[6]), .out(PHI1b[7]));
	LCELL PHI1b8_MC (.in(PHI1b[7]), .out(PHI1b[8]));
	LCELL PHI1b9_MC (.in(PHI1b[8] & PHI1in), .out(PHI1));

	/* Address Bus, etc. */
	input nDEVSEL, nIOSEL, nIOSTRB; // Card select signals
	input [15:0] A; // 6502 address bus
	input nWE; // 6502 R/W
	output [19:0] RA; // ROM and RAM dual-function address pins
	assign RA[19] = Addr[19];
	assign RA[18:11] = (~nIOSTRB & FullIOEN) ? Bank+1 :
		(~nIOSTRB & ~FullIOEN) ? {7'b0000001, Bank[0]} : 
		(nIOSEL & nIOSTRB) ? Addr[18:11] : 8'h00;
	assign RA[10:0] = Addr[10:0];

	/* Select Signals */
	wire BankSELA = A[3:0]==4'hF;
	wire SetSELA = A[3:0]==4'hE;
	wire RAMSELA = A[3:0]==4'h3;
	wire AddrHSELA = A[3:0]==4'h2;
	wire AddrMSELA = A[3:0]==4'h1;
	wire AddrLSELA = A[3:0]==4'h0;
	LCELL BankWR_MC (.in(BankSELA & ~nWE & ~nDEVSEL & REGEN), .out(BankWR)); wire BankWR;
	wire SetWR = SetSELA & ~nWE & ~nDEVSEL & REGEN;
	LCELL RAMSEL_MC (.in(RAMSELA & ~nDEVSEL & REGEN), .out(RAMSEL)); wire RAMSEL;
	LCELL AddrHWR_MC (.in(AddrHSELA & ~nWE & ~nDEVSEL & REGEN), .out(AddrHWR)); wire AddrHWR;
	LCELL AddrMWR_MC (.in(AddrMSELA & ~nWE & ~nDEVSEL & REGEN), .out(AddrMWR)); wire AddrMWR;
	LCELL AddrLWR_MC (.in(AddrLSELA & ~nWE & ~nDEVSEL & REGEN), .out(AddrLWR)); wire AddrLWR;

	/* Data Bus Routing */
	// SRAM/ROM data bus
	wire RDOE = CSDBEN & ~nWE;
	inout [7:0] RD = RDOE ? D[7:0] : 8'bZ;
	// Apple II data bus
	wire DOE = CSDBEN & nWE &
		((~nDEVSEL & REGEN & ~RAMSEL) | (~nDEVSEL & REGEN & RAMSEL & RAMROMCSgb) | (~nIOSEL & RAMROMCSgb) | (~nIOSTRB & IOROMEN & RAMROMCSgb));
	wire [7:0] Dout = (nDEVSEL | RAMSELA) ? RD[7:0] :
		AddrHSELA ? {4'hF, Addr[19:16]} : 
		AddrMSELA ? Addr[15:8] : 
		AddrLSELA ? Addr[7:0] : 8'h00;
	inout [7:0] D = DOE ? Dout : 8'bZ;
	
	/* Inhibit output */
	wire AROMSEL;
	LCELL AROMSEL_MC (.in(/*(A[15:12]==4'hD | A[15:12]==4'hE | A[15:12]==4'hF) & nWE & ~MODE*/0), .out(AROMSEL));
	output nINH = AROMSEL ? 1'b0 :  1'bZ;

	/* SRAM and ROM Control Signals */
	output nRAMROMCS = ~(RAMSEL | ~nIOSEL | (~nIOSTRB & IOROMEN));
	input RAMROMCSgb; // nRAMROMCS as gated by DS1215, then inverted
	output RAMCS = RAMSEL & CSDBEN;
	output nROMCS = ~(RAMROMCSgb & CSDBEN & (~nIOSEL | (~nIOSTRB & IOROMEN)));
	
  	/* 6502-accessible Registers */
	reg [7:0] Bank = 0; // Bank register for ROM access
	reg [19:0] Addr = 0; // Address register bits 19:0
	
	/* Increment Control */
	reg IncAddrL = 0, IncAddrM = 0, IncAddrH = 0;

	/* State Counters */
	reg PHI1reg = 1'b0; // Saved PHI1 at last rising clock edge
	reg PHI0seen = 1'b0; // Have we seen PHI0 since reset?
	reg [2:0] S = 3'h0; // State counter

	/* Misc. */
	reg REGEN = 0; // Register enable
	reg IOROMEN = 0; // IOSTRB ROM enable
	reg CSDBEN = 0; // ROM CS, data bus driver gating
	reg FullIOEN = 0;

	// Apple II Bus Compatibiltiy Rules:
	// Synchronize to PHI0 or PHI1. (PHI1 here)
	// PHI1's edge may be -20ns,+10ns relative to C7M.
	// Delay the rising edge of PHI1 to get enough hold time:
	// 		PHI1modified = PHI1 & PHI1delayed;
	// Only sample /DEVSEL, /IOSEL at these times:
	// 		2nd and 3rd rising edge of C7M in PHI0 (S4, S5)
	//		all 3 falling edges of C7M in PHI0 (S4, S5, S6)
	// Can sample /IOSTRB at same times as /IOSEL, plus:
	//		1st rising edge of C7M in PHI0 (S3)

	always @(posedge C7M, negedge nRES) begin
		if (~nRES) begin // Reset
			PHI1reg <= 0;
			PHI0seen <= 0;
			S <= 0;
			REGEN <= 0;
			IOROMEN <= 0;
			CSDBEN <= 0;
			Addr <= 0;
			Bank <= 0;
			FullIOEN <= 0;
			IncAddrL <= 0;
			IncAddrM <= 0;
			IncAddrH <= 0;
		end else begin
			// Synchronize state counter to S1 when just entering PHI1
			PHI1reg <= PHI1; // Save old PHI1
			if (~PHI1) PHI0seen <= 1; // PHI0seen set in PHI0
			S <= (PHI1 & ~PHI1reg & PHI0seen) ? 4'h1 : 
				S==0 ? 3'h0 :
				S==7 ? 3'h7 : S+1;

			// Disable IOSTRB ROM when accessing 0xCFFF.
			if (S==3 & ~nIOSTRB & A[10:0]==11'h7FF) IOROMEN <= 1'b0;

			// Registers enabled at end of S4 by any IOSEL access (Cn00-CnFF).
			if (S==4 & ~nIOSEL) REGEN <= 1;

			// Enable IOSTRB ROM when accessing CnXX in IOSEL ROM.
			if (S==4 & ~nIOSEL) IOROMEN <= 1'b1;

			// Only drive Apple II data bus after state 4 to avoid bus fight.
			// Thus we wait 1.5 7M cycles (210 ns) into PHI0 before driving.
			// Same for driving the ROM/SRAM data bus (RD).
			// Similarly, only select the ROM chip starting at the end of S4.
			// This provides address setup time for write operations and 
			// minimizes power consumption.
			CSDBEN <= S==4 | S==5 | S==6 | S==7;

			// Increment address register
			if (S==1 & IncAddrL) begin
				Addr[7:0] <= Addr[7:0]+1;
				IncAddrL <= 0;
				IncAddrM <= Addr[7:0] == 8'hFF;
			end
			if (S==2 & IncAddrM) begin
				Addr[15:8] <= Addr[15:8]+1;
				IncAddrM <= 0;
				IncAddrH <= Addr[15:8] == 8'hFF;
			end
			if (S==3 & IncAddrH) begin
				IncAddrH <= 0;
				Addr[19:16] <= Addr[19:16]+1;
			end
			
			// Set register at end of S5 if accessed.
			if (S==5) begin
				if (BankWR) Bank[7:0] <= D[7:0]; // Bank
				if (SetWR) FullIOEN <= D[7:0] == 8'hE5;
				
				IncAddrL <= RAMSEL;
				IncAddrM <= AddrLWR & Addr[7] & ~D[7];
				IncAddrH <= AddrMWR & Addr[15] & ~D[7];
				
				if (AddrHWR) Addr[19:16] <= D[3:0]; // Addr hi
				if (AddrMWR) Addr[15:8] <= D[7:0]; // Addr mid
				if (AddrLWR) Addr[7:0] <= D[7:0]; // Addr lo
			end
		end
	end
endmodule
