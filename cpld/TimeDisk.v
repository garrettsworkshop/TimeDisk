module TimeDisk(C7M, PHI1, nRES, nIRQ,
				   A, RAH, RA11, RAL, nWE, D, RD, nINH,
				   nDEVSEL, nIOSEL, nIOSTRB,
				   nRAMROMCS, RAMROMCSgb, RAMCS, nROMCS);
	/* Select Signals */
	`define BankSELA  (A[3:0]==4'hF)
	`define IRQSELA   (A[3:0]==4'hE)
	`define SigSEL3A  (A[3:0]==4'h7)
	`define SigSEL2A  (A[3:0]==4'h6)
	`define SigSEL1A  (A[3:0]==4'h5)
	`define SigSEL0A  (A[3:0]==4'h4)
	`define SigSELA   (A[3:2]==2'b01)
	`define RAMSELA   (A[3:0]==4'h3)
	`define AddrHSELA (A[3:0]==4'h2)
	`define AddrMSELA (A[3:0]==4'h1)
	`define AddrLSELA (A[3:0]==4'h0)
	
	/* Clock, Reset */
	input C7M, PHI1; // Clock inputs
	input nRES; // Reset
	input nINH; // Apple II bus "inhibit" pin
	
	/* Main state counter S[2:0] */
	reg [1:0] PHI0rf;
	reg [2:0] S = 0;
	always @(negedge C7M) PHI0rf[1:0] <= { PHI0rf[0], !PHI1 };
	always @(posedge C7M) begin
		S[2:0] <= (PHI0rf[1] && !PHI0rf[0] && PHI1) ? 3'h1 :
			S==0 ? 3'h0 :
			S==7 ? 3'h7 : S+3'h1;
	end
	
	/* Reset synchronization */
	reg nRESr0 = 0, nRESr = 0;
	always @(negedge C7M) nRESr0 <= nRES;
	always @(negedge C7M) if (S==1) nRESr <= nRESr0;

	/* Mode jumper loading */
	reg ModeLoaded = 0, Mode = 0;
	always @(posedge C7M) begin
		if (S==2) begin
			if (nRESr) ModeLoaded <= 1;
			if (!ModeLoaded) Mode <= RA11;
		end
	end

	/* Long cycle detect */
	reg LongCycle; always @(negedge C7M) LongCycle <= S==7 && !PHI1;

	/* Timer command sequence */
	/*reg [2:0] CS;
	always @(posedge C7M) begin
		if (!nRESr) CS <= 0;
		else if (S==5 && !nDEVSEL && `SigSELA) case (CS)
			0: CS <= D[7:0]==8'hFF ? 1 : 0;
			1: CS <= D[7:0]==8'h00 ? 2 : 0;
			2: CS <= D[7:0]==8'h55 ? 3 : 0;
			3: CS <= D[7:0]==8'hAA ? 4 : 0;
			4: CS <= D[7:0]==8'hC1 ? 5 : 0;
			5: CS <= D[7:0]==8'hAD ? 6 : 0;
			6: CS <= 7;
			7: CS <= 0;
		endcase
	end*/

	/* Timer enable command */
	/*reg TimerRegENCmd;
	always @(posedge C7M) begin
		if (!nRESr) TimerRegENCmd <= 0;
		else if (S==5 && SigSEL) begin
			TimerRegENCmd <= CS==6 && D[7:0]==8'h01;
		end
	end
	reg TimerRegEN;
	always @(posedge C7M) begin
		if (!nRESr) TimerRegEN <= 0;
		else if (S==5 && SigSEL && TimerRegENCmd) begin
			TimerRegEN <= D[0];
		end
	end*/

	/* Timer control register */
	/*reg NTSCnPAL, IRQEN;
	always @(posedge C7M) begin
		if (!nRESr) begin
			NTSCnPAL <= 0;
			IRQEN <= 0;
		end else if (S==5 && TimerRegEN && IRQWR) begin
			NTSCnPAL <= D[2];
			IRQEN <= D[1];
		end
	end*/
	
	/* Timer reset */
	/*reg TimerReset;
	always @(posedge C7M) begin
		if (S==5) begin
			TimerReset <= TimerRegEN && IRQWR && D[0];
		end
	end*/

	/* Timer */
	/*reg [8:0] Timer;
	wire Timer0; LCELL Timer0_MC (.in(Timer==0), .out(Timer0));
	always @(posedge PHI1) begin
		if (TimerReset) Timer <= 0;
		else if (LongCycle) begin
			if (NTSCnPAL ? Timer==261 : Timer==311) Timer <= 0;
			else Timer[8:0] <= Timer[8:0]+9'h1;
		end
	end*/

	/* IRQ generation */
	output nIRQ = 1'bZ;
	/*reg IRQ = 0;
	output nIRQ = IRQ ? 1'b0 : 1'bZ;
	always @(posedge C7M) begin
		if (!IRQEN) IRQ <= 0;
		else if (S==5 && IRQRD) IRQ <= 0;
		else if (S==7 && Timer0) IRQ <= 1;
	end*/

	/* RA[2:0] multiplexing */
	reg RA2_RA0, RA1_CLK;
	always @(posedge C7M) begin
		case (S)
			1: begin
				RA1_CLK <= 0;
				RA2_RA0 <= Addr[0];
			end 2: begin
				RA1_CLK <= 1;
				RA2_RA0 <= Addr[0];
			end 3: begin
				RA1_CLK <= Addr[1];
				RA2_RA0 <= Addr[2];
			end
		endcase
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
	output [10:1] RAL;
	assign RAL[10:3] = Addr[10:3]; // RA[10:3] only used for RAM
	assign RAL[2:1] = {RA2_RA0, RA1_CLK}; //RA[2:1] uesd to set RA0
	
	/* More select Signals */
	wire BankWR = (`BankSELA && !nWE && !nDEVSEL && REGEN);
	wire IRQRD; LCELL IRQRD_MC (.in(!nDEVSEL && `IRQSELA &&  nWE), .out(IRQRD));
	wire IRQWR; LCELL IRQWR_MC (.in(!nDEVSEL && `IRQSELA && !nWE), .out(IRQWR));
	wire SigSEL = !nDEVSEL && `SigSELA;
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
	wire [7:0] Dout = 
		nDEVSEL ? RD[7:0] :
		`SigSEL3A ? 8'h10 : // Hex 10 (meaning firmware 1.0)
		`SigSEL2A ? 8'h42 : // ASCII "B" (meaning rev. B)
		`SigSEL1A ? 8'h06 : // Hex 06 (meaning "4206")
		`SigSEL0A ? 8'h47 : // ASCII "G" (meaning "GW")
		`RAMSELA ? RD[7:0] :
		`AddrHSELA ? { 4'hF, Addr[19:16] } : 
		`AddrMSELA ? Addr[15:8] : 
		`AddrLSELA ? Addr[7:0] : 8'h00;
	inout [7:0] D = DOE ? Dout : 8'bZ;

	/* State-based data bus and ROM CS gating */
	reg CSDBEN = 0; // ROM CS and data bus driver gating
	always @(posedge C7M) begin
		// Only select ROM and drive Apple II data bus after S4 to avoid bus fight.
		// Thus we wait 1.5 7M cycles (210 ns) into PHI0 before driving.
		// Same for driving the ROM/SRAM data bus (RD).
		CSDBEN <= (S==4 || S==5 || S==6 || S==7);
	end

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
	wire RESIO; LCELL RESIO_MC (.in((!nIOSTRB && A[10:0]==11'h7FF) || !nRESr), .out(RESIO));
	always @(posedge C7M, posedge RESIO) begin
		if (RESIO) IOROMEN <= 0;
		else if (S==5 && !nIOSEL) IOROMEN <= 1;
	end

	/* DEVSEL register enable */
	reg REGEN = 0; // Register enable
	always @(posedge C7M, negedge nRESr) begin
		if (!nRESr) REGEN <= 0;
		else if (S==5 && !nIOSEL) REGEN <= 1;
	end

	/* Increment Control */
	reg IncAddrL, IncAddrM, IncAddrH;
	always @(posedge C7M, negedge nRESr) begin
		if (!nRESr) begin
			Addr <= 0;
			Bank <= 0;
			IncAddrL <= 0;
			IncAddrM <= 0;
			IncAddrH <= 0;
		end else begin
			// Increment address register
			if (S==1 && IncAddrL) begin
				IncAddrL <= 0;
				Addr[7:0] <= Addr[7:0]+8'h1;
				IncAddrM <= Addr[7:0] == 8'hFF;
			end else if (S==2 && IncAddrM) begin
				IncAddrM <= 0;
				Addr[15:8] <= Addr[15:8]+8'h1;
				IncAddrH <= Addr[15:8] == 8'hFF;
			end else if (S==3 && IncAddrH) begin
				IncAddrH <= 0;
				Addr[19:16] <= Addr[19:16]+4'h1;
			end else if (S==5) begin // Set register at end of S5 if accessed.
				if (BankWR) Bank[7:0] <= D[7:0];
				
				IncAddrL <= RAMSEL_BUF;
				IncAddrM <= AddrLWR && Addr[7] && ~D[7];
				IncAddrH <= AddrMWR && Addr[15] && ~D[7];
				
				if (AddrHWR) Addr[19:16] <= D[3:0]; // Addr hi
				if (AddrMWR) Addr[15:8] <= D[7:0]; // Addr mid
				if (AddrLWR) Addr[7:0] <= D[7:0]; // Addr lo
			end
		end
	end
endmodule
