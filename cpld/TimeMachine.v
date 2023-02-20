module TimeDisk(C7M, PHI1, nRES,
				   A, RA, nWE, D, RD, nINH,
				   nDEVSEL, nIOSEL, nIOSTRB,
				   nRAMROMCS, RAMROMCSgb, RAMCS, nROMCS);

	/* Clock, Reset */
	input C7M, PHI1; // Clock inputs
	input nRES; // Reset
	input nINH;
	
	/* Main state counter S[2:0] */
	reg [1:0] PHI0rf;
	reg [2:0] S = 0;
	always @(negedge C7M) begin
		PHI0rf[1:0] <= { PHI0rf[0], !PHI1 };
	end
	always @(posedge C7M) begin
		S[2:0] <= (PHI0rf[1] && !PHI0rf[0] && PHI1) ? 3'h1 :
			S==0 ? 3'h0 :
			S==7 ? 3'h7 : S+1;
	end
	
	/* Reset synchronization */
	reg nRESr0;
	reg nRESr;
	always @(posedge C7M) begin
		nRESr0 <= nRES;
		if (S==1) nRESr <= nRESr0;
		else nRESr <= !(!nRESr || nRESr0); 
	end
	
	/* Address Bus, etc. */
	input nDEVSEL, nIOSEL, nIOSTRB; // Card select signals
	input [15:0] A; // 6502 address bus
	input nWE; // 6502 R/W
	output [19:0] RA; // ROM and RAM dual-function address pins
	assign RA[19:0] = (!nIOSTRB || !nIOSEL) ? 
		{ Addr[19], 6'h00, Bank, A[11], Addr[10:0]} : 
		Addr[19:0];

	/* Select Signals */
	`define BankSELA (A[3:0]==4'hF)
	`define RAMSELA (A[3:0]==4'h3)
	`define AddrHSELA (A[3:0]==4'h2)
	`define AddrMSELA (A[3:0]==4'h1)
	`define AddrLSELA (A[3:0]==4'h0)
	wire BankWR = (`BankSELA && !nWE && !nDEVSEL && REGEN);
	`define RAMSEL (`RAMSELA && !nDEVSEL && REGEN)
	wire RAMSEL_BUF; LCELL RAMSEL_MC (.in(`RAMSEL), .out(RAMSEL_BUF));
	wire AddrHWR; LCELL AddrHWR_MC (.in(`AddrHSELA && !nWE && !nDEVSEL && REGEN), .out(AddrHWR));
	wire AddrMWR; LCELL AddrMWR_MC (.in(`AddrMSELA && !nWE && !nDEVSEL && REGEN), .out(AddrMWR));
	wire AddrLWR; LCELL AddrLWR_MC (.in(`AddrLSELA && !nWE && !nDEVSEL && REGEN), .out(AddrLWR));

	/* Data Bus Routing */
	// SRAM/ROM data Bus
	wire RDOE = CSDBEN && !nWE;
	inout [7:0] RD = RDOE ? D[7:0] : 8'bZ;
	// Apple II data bus
	wire DOE = CSDBEN && nWE &&
		((!nDEVSEL && (!RAMSEL_BUF || (RAMSEL_BUF && RAMROMCSgb))) ||
		 (!nIOSEL && RAMROMCSgb) || (!nIOSTRB && IOROMEN));
	wire [7:0] Dout = (nDEVSEL || `RAMSELA) ? RD[7:0] :
		`AddrHSELA ? Addr[23:16] : 
		`AddrMSELA ? Addr[15:8] : 
		`AddrLSELA ? Addr[7:0] : 
		`BankSELA ? {7'h00, Bank} : 8'h00;
	inout [7:0] D = DOE ? Dout : 8'bZ;

	/* SRAM and ROM Control Signals */
	input RAMROMCSgb; // nRAMROMCS as gated by DS1215, then inverted
	output nRAMROMCS; LCELL nRAMROMCS_MC (.in(!(`RAMSEL || !nIOSEL)), .out(nRAMROMCS));
	output RAMCS; LCELL RAMCS_MC (.in(`RAMSEL && CSDBEN), .out(RAMCS));
	output nROMCS; LCELL nROMCS_MC (.in(!(CSDBEN && ((!nIOSEL && RAMROMCSgb) || (!nIOSTRB && IOROMEN)))), .out(nROMCS));
	
  	/* 6502-accessible Registers */
	reg Bank = 0; // Bank register for ROM access
	reg [23:0] Addr = 0; // Address register bits 19:0
	
	/* IOSTRB ROM enable */
	reg IOROMEN = 0; // IOSTRB ROM enable
	wire RESIO; LCELL RESIO_MC (.in(!nIOSTRB && A[10:0]==11'h7FF), .out(RESIO));
	always @(posedge C7M) begin
		if (S==1 && !nRESr) IOROMEN <= 0;
		else if (S==5 && RESIO) IOROMEN <= 0;
		else if (S==5 && !nIOSEL) IOROMEN <= 1;
	end

	/* State-based data bus and ROM CS gating */
	reg CSDBEN = 0; // ROM CS and data bus driver gating
	always @(posedge C7M) begin
		// Only select ROM and drive Apple II data bus after S4 to avoid bus fight.
		// Thus we wait 1.5 7M cycles (210 ns) into PHI0 before driving.
		// Same for driving the ROM/SRAM data bus (RD).
		CSDBEN <= (S==4 || S==5 || S==6 || S==7) && (nIOSTRB || !RESIO);
	end

	/* DEVSEL register enable */
	reg REGEN = 0; // Register enable
	always @(posedge C7M) begin
		if (S==1 && !nRESr) REGEN <= 0;
		else if (S==5 && !nIOSEL) REGEN <= 1;
	end

	/* Increment Control */
	reg IncAddrL = 0, IncAddrM = 0, IncAddrH = 0;
	always @(negedge C7M) begin
		if (S==1 && !nRESr) begin
			Addr <= 0;
			Bank <= 0;
			IncAddrL <= 0;
			IncAddrM <= 0;
			IncAddrH <= 0;
		end else begin
			// Increment address register
			if (S==1 & IncAddrL) begin
				Addr[7:0] <= Addr[7:0]+1;
				IncAddrL <= 0;
				IncAddrM <= Addr[7:0] == 8'hFF;
			end else if (S==2 & IncAddrM) begin
				Addr[15:8] <= Addr[15:8]+1;
				IncAddrM <= 0;
				IncAddrH <= Addr[15:8] == 8'hFF;
			end else if (S==3 & IncAddrH) begin
				IncAddrH <= 0;
				Addr[23:16] <= Addr[23:16]+1;
			end else if (S==6) begin // Set register in middle of S6 if accessed.
				if (BankWR) Bank <= D[0]; // Bank
				
				IncAddrL <= RAMSEL_BUF;
				IncAddrM <= AddrLWR & Addr[7] & ~D[7];
				IncAddrH <= AddrMWR & Addr[15] & ~D[7];
				
				if (AddrHWR) Addr[19:16] <= D[3:0]; // Addr hi
				if (AddrMWR) Addr[15:8] <= D[7:0]; // Addr mid
				if (AddrLWR) Addr[7:0] <= D[7:0]; // Addr lo
			end
		end
	end
endmodule
