module TimeMachine(C7M, C7M_2, PHI1, nRES,
			 A, Addr19, RA, AddrL, nWE, D, RD,
			 nDEVSEL, nIOSEL, nIOSTRB,
			 nRAMROMCS, RAMROMCSgb, RAMCS, nROMCS);

	/* Clock, Reset, Mode */
	input C7M, C7M_2, PHI1; // Clock inputs
	input nRES; // Reset

	/* SRAM and ROM Control Signals */
	output nRAMROMCS = RAMSEL | ~nIOSEL | (~nIOSTRB & IOROMEN);
	input RAMROMCSgb; // RAMROMCS as gated by DS1215
	output RAMCS = RAMSEL & CSDBEN;
	output nROMCS = RAMROMCSgb & CSDBEN & (~nIOSEL | (~nIOSTRB & IOROMEN));

	/* Address Bus, etc. */
	input nDEVSEL, nIOSEL, nIOSTRB; // Card select signals
	input [15:0] A; // 6502 address bus
	input nWE; // 6502 R/W

	/* Data Bus Routing */
	// DRAM/ROM data bus
	wire RDOE = CSDBEN & (~nWE | ((nDEVSEL | nIOSEL | nIOSTRB) & ~RAMSEL));
	inout [7:0] RD = RDOE ? D[7:0] : 8'bZ;
	// Apple II data bus
	wire DOE = CSDBEN & nWE & nRES & (~nDEVSEL | ~nIOSEL | (~nIOSTRB & IOROMEN)); // must not OE when DS1315 is output
	inout [7:0] D = DOE ?
           AddrHSEL ? {4'hF, Addr19, AddrM[18:16]} : 
           AddrMSEL ? {AddrM[15:11], AddrL[10:8]} : 
           AddrLSEL ? AddrL[7:0] : 
           RD[7:0] : 8'bZ;

  	/* 6502-accessible Registers */
	reg [18:12] Bank = 7'h00; // Bank register for ROM access
	output reg Addr19; // Address register bit 19
	reg [18:11] AddrM; // Address register bits 18:11
	output [18:11] RA; // ROM and RAM dual-function address pins
	assign RA[18] = 1;//~nDEVSEL ? AddrM[12] : Bank[18];
	assign RA[17] = 1;//~nDEVSEL ? AddrM[13] : Bank[17];
	assign RA[16] = 1;//~nDEVSEL ? AddrM[12] : Bank[16];
	assign RA[15] = 1;//~nDEVSEL ? AddrM[12] : Bank[15];
	assign RA[14] = 1;//~nDEVSEL ? AddrM[12] : Bank[14];
	assign RA[13] = 1;//~nDEVSEL ? AddrM[11] : Bank[13];
	assign RA[12] = 1;//~nDEVSEL ? AddrM[12] : Bank[12];
	assign RA[11] = 1;//~nDEVSEL ? AddrM[11] : A[11];
	output reg [10:0] AddrL; // Address register bits 10:0

	/* State Counters */
	reg PHI1reg = 1'b0; // Saved PHI1 at last rising clock edge
	reg PHI0seen = 1'b0; // Have we seen PHI0 since reset?
	reg [3:0] S = 4'h0; // State counter

	/* Select Signals */
	wire BankSEL = A[3:0]==4'hF & ~nDEVSEL & REGEN; // Bank reg. at Cn0F
	wire RAMSEL = A[3:0]==4'h3 & ~nDEVSEL & REGEN; // RAM data reg. at Cn03
	reg RAMSELreg = 1'b0; // RAMSEL registered at end of S4
	wire AddrHSEL = A[3:0]==4'h2 & ~nDEVSEL & REGEN; // Addr. hi reg. at Cn02
	wire AddrMSEL = A[3:0]==4'h1 & ~nDEVSEL & REGEN; // Addr. mid reg. at Cn01
	wire AddrLSEL = A[3:0]==4'h0 & ~nDEVSEL & REGEN; // Addr. lo reg. at Cn00

	/* Misc. */
	reg REGEN = 0; // Register enable
	reg IOROMEN = 0; // IOSTRB ROM enable
	reg CSDBEN = 0; // ROM CS, data bus driver gating

	always @(posedge C7M, negedge nRES) begin
		if (~nRES) begin // Reset
			PHI1reg <= 1'b0;
			PHI0seen <= 1'b0;
			S <= 4'h0;
			RAMSELreg <= 1'b0;
			REGEN <= 1'b0;
			IOROMEN <= 1'b0;
			CSDBEN <= 1'b0;
			Addr19 <= 1'b0;
			AddrM <= 8'h00;
			AddrL <= 11'h000;
			Bank <= 7'h00;
		end else begin
			// Synchronize state counter to S1 when just entering PHI1
			PHI1reg <= PHI1;
			if (~PHI1) PHI0seen <= 1;
			S <= (PHI1 & ~PHI1reg & PHI0seen) ? 4'h1 : S==0 ? 4'h0 : S+1;

			// Register RAM "register" selected in S4.
			if (S==4) RAMSELreg <= RAMSEL;

			// Registers enabled in S3 by any IOSEL access (Cn00-CnFF).
			if (S==3) REGEN <= REGEN | ~nIOSEL;

			// Set/reset IOSTRB ROM enable in S3.
			// Enable IOSTRB ROM when accessing 0xCn00 in IOSEL ROM.
			// Disable IOSTRB ROM when accessing 0xCFFF.
			if (S==3) IOROMEN <= (A[11:0] == 12'hFFF & ~nIOSTRB) ? 1'b0 : 
								 (A[7:0] == 8'h00 & ~nIOSEL) ? 1'b1 : 
								 IOROMEN;

			// Only drive Apple II data bus after state 4 to avoid bus fight.
			// Thus we wait 1.5 7M cycles (210 ns) into PHI0 before driving.
			// Same for driving the ROM/DRAM data bus.
			// Similarly, only select the ROM chip starting at the end of S4.
			// This provides address setup time for write operations and 
			// minimizes power consumption.
			CSDBEN <= S==4 | S==5 | S==6 | S==7;

			// Increment address register after RAM access,
			// otherwise set register if accessed
			if (S==1 & RAMSELreg) begin
				AddrL <= AddrL+1;
				if (AddrL == 11'h7FF) AddrM <= AddrM+1;
				if (AddrM == 8'hFF) Addr19 <= ~Addr19;
			end else if (S==6 & AddrHSEL & ~nWE) begin
				Addr19 <= D[3]; // Set Addr19
				AddrM[18:16] <= D[2:0]; // Set Addr18:16
			end else if (S==6 & AddrMSEL & ~nWE) begin
				AddrM[15:11] <= D[7:3]; // Set Addr15:11
				AddrL[10:8] <= D[2:0]; // Set Addr10:8
			end else if (S==6 & AddrLSEL & ~nWE) AddrL[7:0] <= D[7:0]; // Set Addr7:0
			else if (S==6 & BankSEL & ~nWE) Bank[18:12] <= D[6:0]; // Set Bank6:0
		end
	end
endmodule
