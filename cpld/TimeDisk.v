module TimeDisk(C7M, PHI1, nRES,
				   A, RAH, RA11, RAL, nWE, D, RD, nINH,
				   nDEVSEL, nIOSEL, nIOSTRB,
				   nRAMROMCS, RAMROMCSgb, RAMCS, nROMCS);

	/* Clock, Reset */
	input C7M, PHI1; // Clock inputs
	input nRES; // Reset
	input nINH; // Apple II bus "inhibit" pin
	
	/* Main state counter S[2:0] */
	reg [1:0] PHI0rf;
	reg [2:0] S = 0;
	always @(negedge C7M) begin
		PHI0rf[1:0] <= { PHI0rf[0], !PHI1 };
	end
	always @(posedge C7M) begin
		S[2:0] <= (PHI0rf[1] && !PHI0rf[0] && PHI1) ? 3'h1 :
			S==0 ? 3'h0 :
			S==7 ? 3'h7 : S+3'h1;
	end
	
	/* Reset synchronization */
	reg nRESr0;
	reg nRESr;
	always @(posedge C7M) begin
		nRESr0 <= nRES;
		if (S==1) nRESr <= nRESr0;
		else nRESr <= !(!nRESr || !nRESr0); 
	end
	
	/* Mode jumper loading */
	reg ModeLoaded = 0;
	reg Mode = 0;
	always @(posedge C7M) begin
		if (S==2) begin
			if (nRESr) ModeLoaded <= 1;
			if (!ModeLoaded) Mode <= RA11;
		end
	end
	
	/* Address Bus, etc. */
	input nDEVSEL, nIOSEL, nIOSTRB; // Card select signals
	input [15:0] A; // 6502 address bus
	input nWE; // 6502 R/W
	// ROM and RAM dual-function address pins
	output [19:12] RAH;
	assign RAH[19] = Addr[19];
	assign RAH[18:12] = 
		(!Mode && !nIOSEL)  ? { 6'b000000, 1'b0 } :
		(!Mode && !nIOSTRB) ? { 6'b000000, Bank[0] } :
		( Mode && !nIOSEL)  ? { 6'b000000, 1'b1 } :
		( Mode && !nIOSTRB) ? { Bank[7:2], Bank[1] } : Addr[18:12];
	inout RA11 = !ModeLoaded ? 1'bZ : 
		(!Mode && !nIOSEL)  ? 1'b0:
		(!Mode && !nIOSTRB) ? 1'b1 :
		( Mode && !nIOSEL)  ? 1'b0 :
		( Mode && !nIOSTRB) ? Bank[0] : Addr[11];
	output [10:0] RAL;
	assign RAL[10:0] = Addr[10:0]; // RA[10:0] only used for RAM
	
	/* Select Signals */
	`define BankSELA (A[3:0]==4'hF)
	`define ModeSELA (A[3:0]==4'hE)
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
		`AddrHSELA ? { 4'hF, Addr[19:16] } : 
		`AddrMSELA ? Addr[15:8] : 
		`AddrLSELA ? Addr[7:0] : 
		`ModeSELA ? { 7'h00, Mode } : 
		`BankSELA ?  Bank[7:0] : 8'h00;
	inout [7:0] D = DOE ? Dout : 8'bZ;

	/* SRAM and ROM Control Signals */
	input RAMROMCSgb; // nRAMROMCS as gated by DS1215, then inverted
	output nRAMROMCS; LCELL nRAMROMCS_MC (.in(!(`RAMSEL || !nIOSEL)), .out(nRAMROMCS));
	output RAMCS; LCELL RAMCS_MC (.in(`RAMSEL && CSDBEN), .out(RAMCS));
	output nROMCS; LCELL nROMCS_MC (.in(!(CSDBEN && ((!nIOSEL && RAMROMCSgb) || (!nIOSTRB && IOROMEN)))), .out(nROMCS));
	
  	/* 6502-accessible Registers */
	reg [7:0] Bank = 0; // Bank register for ROM access
	reg [19:0] Addr = 0; // Address register bits 19:0
	
	/* IOSTRB ROM enable */
	reg IOROMEN = 0; // IOSTRB ROM enable
	wire RESIO; LCELL RESIO_MC (.in(!nIOSTRB && A[10:0]==11'h7FF), .out(RESIO));
	always @(posedge C7M, posedge RESIO) begin
		if (RESIO) IOROMEN <= 0;
		else if (S==1 && !nRESr) IOROMEN <= 0;
		else if (S==5 && !nIOSEL) IOROMEN <= 1;
	end

	/* State-based data bus and ROM CS gating */
	reg CSDBEN = 0; // ROM CS and data bus driver gating
	always @(posedge C7M) begin
		// Only select ROM and drive Apple II data bus after S4 to avoid bus fight.
		// Thus we wait 1.5 7M cycles (210 ns) into PHI0 before driving.
		// Same for driving the ROM/SRAM data bus (RD).
		CSDBEN <= (S==4 || S==5 || S==6 || S==7);
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
				IncAddrL <= 0;
				Addr[7:0] <= Addr[7:0]+8'h1;
				IncAddrM <= Addr[7:0] == 8'hFF;
			end else if (S==2 & IncAddrM) begin
				IncAddrM <= 0;
				Addr[15:8] <= Addr[15:8]+8'h1;
				IncAddrH <= Addr[15:8] == 8'hFF;
			end else if (S==3 & IncAddrH) begin
				IncAddrH <= 0;
				Addr[19:16] <= Addr[19:16]+4'h1;
			end else if (S==6) begin // Set register in middle of S6 if accessed.
				if(BankWR) Bank[7:0] <= D[7:0];
				
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
