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
	always @(negedge C7M) PHI0rf[1:0] <= { PHI0rf[0], !PHI1 };
	always @(posedge C7M) begin
		if (PHI0rf[1] && !PHI0rf[0] && PHI1) S <= 1;
		else if (S==0) S <= 0;
		else if (S==7) S <= 7;
		else S <= S+1;
	end
	
	/* Reset input synchronization */
	reg nRESr0; always @(posedge C7M) nRESr0 <= nRES;
	reg nRESr;
	always @(posedge C7M) begin
		if (S==1) nRESr <= nRESr0;
		else nRESr <= !(!nRESr || !nRESr0); 
	end

	/* Mode and revision load */
	reg ModeLoaded;
	reg Mode; reg Rev;
	always @(posedge PHI1) begin
		ModeLoaded <= 1;
		if (!ModeLoaded) begin
			Mode <= RA11;
			Rev <= RAL[2];
		end
	end

	/* Timer enable */
	reg TimerUnlock = 0;
	reg US = 0;
	always @(posedge PHI1, negedge nRES) begin
		if (!nRES) begin
			TimerUnlock <= 0;
			US <= 0;
		end else if (!nDEVSEL || !nIOSEL) begin
			if (SigWR && US==0 && D[7:0]==8'hC1) begin
				US <= 1;
			end else if (SigWR && US==1 && D[7:0]==8'hAD) begin
				TimerUnlock <= 1;
				US <= 0;
			end else US <= 0;
		end
	end

	/* Timer control */
	reg TimerMode;
	reg IRQEN;
	always @(posedge PHI1, negedge nRES) begin
		if (!nRES) begin
			IRQEN <= 0;
			TimerMode <= 0;
		end else if (IRQWR) begin
			IRQEN <= D[7];
			TimerMode <= D[6];
		end
	end
	
	/* Timer */
	reg [14:0] Timer;
	always @(posedge PHI1, negedge nRES) begin
		if (!nRES) Timer <= 0;
		else if (Timer==0) begin
			case (TimerMode)
				0: Timer <= 17029; // NTSC frame
				1: Timer <= 20279; // PAL frame
			endcase
		end else if (IRQWR && D[5]) Timer <= {D[4:0], 10'h0000};
		else Timer <= Timer-1;
	end
		
	/* IRQ generation */
	reg IRQRDr = 0;
	always @(posedge C7M) if (S==6) IRQRDr <= IRQRD;
	reg IRQ = 0;
	always @(posedge C7M, negedge nRES) begin
		if (!nRES) IRQ <= 0;
		else if (S==2) begin
			if (Timer==1 && IRQEN) IRQ <= 1;
			else if (IRQRDr) IRQ <= 0;
		end
	end

	/* IRQ multiplexing with RA[1:0] */
	reg RA0_IRQ, RA1_CLK;
	always @(negedge C7M) begin
		case (S)
			1: begin
				RA1_CLK <= 0;
				RA0_IRQ <= IRQ;
			end 2: begin
				RA1_CLK <= 1;
				RA0_IRQ <= IRQ;
			end default: begin
				RA1_CLK <= Addr[1];
				RA0_IRQ <= Addr[0];
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
	inout [10:0] RAL;
	assign RAL[10:3] = Addr[10:3]; // RA[10:3] only used for RAM
	assign RAL[2] = !ModeLoaded ? 1'bZ : Addr[2]; // RA[2] used for rev load
	assign RAL[1:0] = {RA1_CLK, RA0_IRQ}; //RA[1:0] uesd to set IRQ pin
	
	/* Select Signals */
	`define BankSELA  (A[3:0]==4'hF)
	`define IRQSELA   (A[3:0]==4'hE)
	`define SigSELA   (A[3:0]==4'h4)
	`define RAMSELA   (A[3:0]==4'h3)
	`define AddrHSELA (A[3:0]==4'h2)
	`define AddrMSELA (A[3:0]==4'h1)
	`define AddrLSELA (A[3:0]==4'h0)
	wire BankWR = (`BankSELA && !nWE && !nDEVSEL && REGEN);
	`define RAMSEL (`RAMSELA && !nDEVSEL && REGEN)
	wire IRQSEL =  `IRQSELA && !nWE && !nDEVSEL;
	wire IRQWR = IRQSEL && !nWE;
	wire IRQRD = IRQSEL &&  nWE;
	wire SigWR = `SigSELA && !nWE && !nDEVSEL;
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
		`BankSELA ? { Rev, 6'h00, Bank[0] } :
		`IRQSELA ? { IRQ, 7'b000000 } : 
		`SigSELA ? 8'h06 :
		`RAMSELA ? RD[7:0] :
		`AddrHSELA ? { 4'hF, Addr[19:16] } : 
		`AddrMSELA ? Addr[15:8] : 
		`AddrLSELA ? Addr[7:0] : 8'h00;
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
		else if (S==6 && !nIOSEL) IOROMEN <= 1;
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
		else if (S==6 && !nIOSEL) REGEN <= 1;
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
				Addr[7:0] <= Addr[7:0]+1;
				IncAddrM <= Addr[7:0] == 8'hFF;
			end else if (S==2 & IncAddrM) begin
				IncAddrM <= 0;
				Addr[15:8] <= Addr[15:8]+1;
				IncAddrH <= Addr[15:8] == 8'hFF;
			end else if (S==3 & IncAddrH) begin
				IncAddrH <= 0;
				Addr[19:16] <= Addr[19:16]+1;
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
