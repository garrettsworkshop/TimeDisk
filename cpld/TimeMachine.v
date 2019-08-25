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
	// SRAM/ROM data bus
	wire RDOE = ~nWE | (nDEVSEL & nIOSEL & nIOSTRB);
	inout [7:0] RD = RDOE ? D[7:0] : 8'bZ;
	// Apple II data bus
	wire DOE = nRES & CSDBEN & nWE & RAMROMCSgb &
		((~nDEVSEL & REGEN) | ~nIOSEL | (~nIOSTRB & IOROMEN));
	wire [7:0] Dout = nDEVSEL ? RD[7:0] :
		AddrHSELA ? {4'hF, AddrH[19:16]} : 
		AddrMSELA ? {AddrH[15:11], AddrL[10:8]} : 
		AddrLSELA ? AddrL[7:0] : 8'h00; 
	inout [7:0] D = DOE ? Dout : 8'bZ;

  	/* 6502-accessible Registers */
	reg [18:12] Bank = 7'h00; // Bank register for ROM access
	output Addr19 = AddrH[19]; // Address register bit 19
	reg [19:11] AddrH; // Address register bits 19:11
	output [18:11] RA; // ROM and RAM dual-function address pins
	assign RA[18] = ~nDEVSEL ? AddrH[18] : Bank[18];
	assign RA[17] = ~nDEVSEL ? AddrH[17] : Bank[17];
	assign RA[16] = ~nDEVSEL ? AddrH[16] : Bank[16];
	assign RA[15] = ~nDEVSEL ? AddrH[15] : Bank[15];
	assign RA[14] = ~nDEVSEL ? AddrH[14] : Bank[14];
	assign RA[13] = ~nDEVSEL ? AddrH[13] : Bank[13];
	assign RA[12] = ~nDEVSEL ? AddrH[12] : Bank[12];
	assign RA[11] = ~nDEVSEL ? AddrH[11] : A[11];
	output reg [10:0] AddrL; // Address register bits 10:0

	/* Select Signals */
	wire BankSELA = A[3:0]==4'hF;
	wire BankSEL = ~nDEVSEL & BankSELA & REGEN; // ROM bank reg. at Cn0F
	wire RAMSELA = A[3:0]==4'h3;
	wire RAMSEL = ~nDEVSEL & RAMSELA & REGEN; // RAM data reg. at Cn03
	reg RAMSELreg;
	wire AddrHSELA = A[3:0]==4'h2;
	wire AddrHSEL = ~nDEVSEL & AddrHSELA & REGEN; // Addr. hi reg. at Cn02
	wire AddrMSELA = A[3:0]==4'h1;
	wire AddrMSEL = ~nDEVSEL & AddrMSELA & REGEN; // Addr. mid reg. at Cn01
	wire AddrLSELA = A[3:0]==4'h0;
	wire AddrLSEL = ~nDEVSEL & AddrLSELA & REGEN; // Addr. lo reg. at Cn00
	
	/* Misc. State */
	reg PHI1r1 = 0, PHI1r2 = 0; // PHI1 shift register (state)
	reg REGEN = 0; // Register enable
	reg IOROMEN = 0; // IOSTRB ROM enable
	wire CSDBEN = ~PHI1r2; // ROM CS, data bus driver gating
	
	always @(posedge C7M, negedge nRES) begin
		if (~nRES) begin
			PHI1r1 <= 0;
			PHI1r2 <= 0;
			RAMSELreg <= 0;
			REGEN <= 0;
			IOROMEN <= 0;
			Bank <= 7'h00;
			AddrH <= 9'h000;
			AddrL <= 11'h000;
		end else begin
			// Shift PHI1
			PHI1r1 <= PHI1;
			PHI1r2 <= PHI1r1;

			if (PHI1) begin // PHI1
				if (~PHI1r1) begin // 140 ns into PHI1
					// Increment address if RAM read from
					if (RAMSELreg) begin
						AddrL <= AddrL+1;
						if (AddrL == 11'h7FF) begin
							AddrH <= AddrH+1;
						end
					end
				end
			end else if (~PHI1) begin // PHI0
				if (~PHI1r1 & PHI1r2) begin // 210 ns into PHI0
					// Register the RAM select signal
					RAMSELreg <= RAMSEL;

					// Registers enabled by any IOSEL access (Cn00-FF).
					if (~nIOSEL) REGEN <= 1;

					// Disable IOSTRB ROM when accessing 0xCFFF in IOSTRB ROM.
					if (~nIOSTRB & A[11:0] == 12'hFFF) IOROMEN <= 0;
					// Enable IOSTRB ROM when accessing 0xCn00 in IOSEL ROM
					else if (~nIOSEL & A[7:0] == 8'h00) IOROMEN <= 1;
				end else if (~PHI1r1 & ~PHI1r2) begin // 350 ns into PHI0
					// Set register if selected for write
					if (AddrHSEL & ~nWE) begin
						AddrH[19:16] <= D[3:0]; // Set Addr19:16
					end else if (AddrMSEL & ~nWE) begin
						AddrH[15:11] <= D[7:3]; // Set Addr15:11
						AddrL[10:8] <= D[2:0]; // Set Addr10:8
					end else if (AddrLSEL & ~nWE) begin
						AddrL[7:0] <= D[7:0]; // Set Addr7:0
					end else if (BankSEL & ~nWE) begin
						Bank[18:12] <= D[6:0]; // Set Bank6:0
					end
				end
			end
		end
	end
endmodule
