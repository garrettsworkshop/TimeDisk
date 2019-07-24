EESchema Schematic File Version 4
LIBS:TimeMachine-cache
EELAYER 29 0
EELAYER END
$Descr USLetter 11000 8500
encoding utf-8
Sheet 2 2
Title "GR8RAM"
Date "2019-07-23"
Rev "0.1"
Comp "Garrett's Workshop"
Comment1 ""
Comment2 ""
Comment3 ""
Comment4 ""
$EndDescr
Wire Wire Line
	8850 2250 8850 2350
Wire Wire Line
	9450 1950 9450 2050
Wire Wire Line
	4650 1950 4650 2050
Wire Wire Line
	4050 2350 4050 2250
Text Notes 800  2050 2    50   ~ 0
Acc~CAS~
Wire Wire Line
	3150 1900 2550 1900
Wire Bus Line
	4300 950  4300 1600
Wire Bus Line
	4900 950  4900 1600
Text Notes 4300 1700 0    40   ~ 0
Allow CS, OE, WE
Text Notes 3700 1750 0    40   ~ 0
Latch addr. attr.\nSwitch ext. ROM
Text Notes 800  2350 2    50   ~ 0
~RAS~
Text Notes 800  1900 2    50   ~ 0
Ref~CAS~
Text Notes 1500 1100 0    40   ~ 0
S7
Text Notes 6600 850  0    104  ~ 0
Video Access
Text Notes 8600 850  0    100  ~ 0
6502 CPU Access
Wire Bus Line
	5500 950  5500 1600
Text Notes 5700 1100 0    40   ~ 0
S7
Wire Wire Line
	3450 1150 6150 1150
Wire Wire Line
	3450 1400 6150 1400
Wire Wire Line
	4650 1550 6150 1550
Wire Wire Line
	5800 1000 5800 1100
Wire Wire Line
	5500 1000 5800 1000
Wire Wire Line
	5500 1100 5500 1000
Wire Wire Line
	5200 1100 5500 1100
Wire Wire Line
	6400 1000 6400 1100
Wire Wire Line
	6100 1000 6400 1000
Wire Wire Line
	6100 1100 6100 1000
Wire Wire Line
	5800 1100 6100 1100
Wire Wire Line
	6150 1550 6150 1450
Wire Wire Line
	6150 1400 6150 1300
Wire Wire Line
	6150 1150 6150 1250
Wire Bus Line
	6100 850  6100 1700
Text Notes 6100 1700 0    40   ~ 0
Latch WR data
Text Notes 6300 1100 0    40   ~ 0
S8
Wire Wire Line
	10300 1100 10300 1000
Wire Wire Line
	10000 1100 10300 1100
Wire Wire Line
	10000 1000 10000 1100
Wire Wire Line
	9700 1000 10000 1000
Wire Wire Line
	9700 1100 9700 1000
Wire Wire Line
	9400 1100 9700 1100
Wire Wire Line
	9400 1000 9400 1100
Wire Wire Line
	9100 1000 9400 1000
Wire Wire Line
	9100 1100 9100 1000
Wire Wire Line
	8800 1100 9100 1100
Wire Wire Line
	8800 1000 8800 1100
Wire Wire Line
	8500 1000 8800 1000
Wire Wire Line
	8500 1100 8500 1000
Wire Wire Line
	8200 1100 8500 1100
Wire Wire Line
	8200 1000 8200 1100
Wire Wire Line
	7900 1000 8200 1000
Wire Wire Line
	7900 1100 7900 1000
Wire Wire Line
	7600 1100 7900 1100
Wire Wire Line
	7300 1100 7300 1000
Wire Wire Line
	7000 1100 7300 1100
Wire Wire Line
	7000 1000 7000 1100
Wire Wire Line
	6700 1000 7000 1000
Wire Wire Line
	6700 1100 6700 1000
Wire Wire Line
	6400 1100 6700 1100
Wire Wire Line
	7600 1000 7600 1100
Wire Wire Line
	10350 1550 9450 1550
Wire Wire Line
	8250 1450 9450 1450
Wire Wire Line
	7350 1550 8250 1550
Wire Wire Line
	8250 1450 8250 1550
Wire Wire Line
	10350 1550 10350 1450
Wire Wire Line
	9450 1450 9450 1550
Wire Wire Line
	7350 1450 7350 1550
Wire Wire Line
	7300 1000 7600 1000
Text Notes 6900 1100 0    40   ~ 0
S1
Text Notes 7500 1100 0    40   ~ 0
S2
Wire Wire Line
	10350 1400 10350 1300
Wire Wire Line
	8250 1400 10350 1400
Wire Wire Line
	8250 1300 8250 1400
Wire Wire Line
	10350 1150 10350 1250
Wire Wire Line
	8250 1150 10350 1150
Wire Wire Line
	8250 1250 8250 1150
Wire Bus Line
	8200 850  8200 1700
Wire Bus Line
	6700 950  6700 1600
Wire Bus Line
	7300 950  7300 1600
Wire Bus Line
	7900 950  7900 1600
Wire Bus Line
	8500 950  8500 1600
Wire Bus Line
	9100 950  9100 1600
Wire Bus Line
	9700 950  9700 1600
Wire Bus Line
	10300 850  10300 1700
Text Notes 8100 1100 0    40   ~ 0
S3
Text Notes 9100 1700 0    40   ~ 0
Allow CS, OE, WE
Text Notes 8700 1100 0    40   ~ 0
S4
Text Notes 9300 1100 0    40   ~ 0
S5
Text Notes 9900 1100 0    40   ~ 0
S6
Text Notes 8500 1750 0    40   ~ 0
Latch addr. attr.\nSwitch ext. ROM
Text Notes 6700 1750 0    40   ~ 0
Disallow CS, OE, WE\nIncrement addr. if attr.
Wire Wire Line
	6150 1250 8250 1250
Wire Wire Line
	6150 1300 8250 1300
Wire Wire Line
	6150 1450 7350 1450
Wire Bus Line
	1300 850  1300 1700
Wire Wire Line
	7350 1800 7350 1900
Wire Wire Line
	3150 1900 3150 1800
Wire Wire Line
	2550 1800 2550 1900
Wire Wire Line
	3450 2350 3450 2250
Wire Wire Line
	2850 2350 3450 2350
Wire Wire Line
	2850 2250 2850 2350
Text Notes 1900 1750 0    40   ~ 0
Disallow CS, OE, WE\nIncrement addr. if attr.
Text Notes 1300 1650 0    40   ~ 0
Latch WR data
Text Notes 5100 1100 0    40   ~ 0
S6
Text Notes 4500 1100 0    40   ~ 0
S5
Text Notes 3900 1100 0    40   ~ 0
S4
Text Notes 1800 850  0    104  ~ 0
Video Access
Text Notes 3300 1100 0    40   ~ 0
S3
Wire Bus Line
	3700 950  3700 1600
Wire Bus Line
	3100 950  3100 1600
Wire Bus Line
	2500 950  2500 1600
Wire Bus Line
	1900 950  1900 1600
Wire Bus Line
	3400 850  3400 1700
Wire Wire Line
	900  1550 1350 1550
Wire Wire Line
	1350 1400 900  1400
Wire Wire Line
	900  1150 1350 1150
Text Notes 800  1250 2    50   ~ 0
PHI0
Wire Wire Line
	1350 1150 1350 1250
Wire Wire Line
	1350 1250 3450 1250
Wire Wire Line
	3450 1250 3450 1150
Text Notes 3850 850  0    100  ~ 0
6502 CPU Access (long)
Text Notes 800  1400 2    50   ~ 0
PHI1
Wire Wire Line
	1350 1400 1350 1300
Wire Wire Line
	1350 1300 3450 1300
Wire Wire Line
	3450 1300 3450 1400
Text Notes 900  1100 0    40   ~ 0
S6
Text Notes 2700 1100 0    40   ~ 0
S2
Text Notes 2100 1100 0    40   ~ 0
S1
Wire Wire Line
	2500 1000 2800 1000
Wire Wire Line
	1350 1450 1350 1550
Wire Wire Line
	2550 1450 1350 1450
Wire Wire Line
	2550 1450 2550 1550
Text Notes 800  1550 2    50   ~ 0
Q3
Wire Wire Line
	4650 1450 4650 1550
Wire Wire Line
	3450 1450 3450 1550
Wire Wire Line
	2550 1550 3450 1550
Wire Wire Line
	3450 1450 4650 1450
Wire Wire Line
	1000 1100 1300 1100
Wire Wire Line
	1000 1000 900  1000
Wire Wire Line
	1000 1100 1000 1000
Wire Wire Line
	2800 1000 2800 1100
Text Notes 800  1100 2    50   ~ 0
C7M
Wire Wire Line
	1300 1100 1300 1000
Wire Wire Line
	1300 1000 1600 1000
Wire Wire Line
	1600 1000 1600 1100
Wire Wire Line
	1600 1100 1900 1100
Wire Wire Line
	1900 1100 1900 1000
Wire Wire Line
	1900 1000 2200 1000
Wire Wire Line
	2200 1000 2200 1100
Wire Wire Line
	2200 1100 2500 1100
Wire Wire Line
	2500 1100 2500 1000
Wire Wire Line
	2800 1100 3100 1100
Wire Wire Line
	3100 1100 3100 1000
Wire Wire Line
	3100 1000 3400 1000
Wire Wire Line
	3400 1000 3400 1100
Wire Wire Line
	3400 1100 3700 1100
Wire Wire Line
	3700 1100 3700 1000
Wire Wire Line
	3700 1000 4000 1000
Wire Wire Line
	4000 1000 4000 1100
Wire Wire Line
	4000 1100 4300 1100
Wire Wire Line
	4300 1100 4300 1000
Wire Wire Line
	4300 1000 4600 1000
Wire Wire Line
	4600 1000 4600 1100
Wire Wire Line
	4600 1100 4900 1100
Wire Wire Line
	4900 1100 4900 1000
Wire Wire Line
	4900 1000 5200 1000
Wire Wire Line
	5200 1000 5200 1100
Wire Wire Line
	9700 2400 9750 2500
Wire Wire Line
	9700 2500 9750 2400
Wire Wire Line
	9150 2500 9700 2500
Wire Wire Line
	9150 2400 9700 2400
Wire Wire Line
	9100 2500 9150 2400
Wire Wire Line
	9100 2400 9150 2500
Wire Wire Line
	9100 2500 4950 2500
Wire Wire Line
	4950 2400 9100 2400
Wire Wire Line
	4900 2400 4950 2500
Wire Wire Line
	4900 2500 4950 2400
Wire Wire Line
	4350 2500 4900 2500
Wire Wire Line
	4350 2400 4900 2400
Wire Wire Line
	4300 2500 4350 2400
Wire Wire Line
	4300 2400 4350 2500
Wire Wire Line
	900  2400 4300 2400
Wire Wire Line
	4300 2500 900  2500
Text Notes 800  2500 2    50   ~ 0
RA
Wire Wire Line
	2250 2050 2250 1950
Wire Wire Line
	2250 1950 4650 1950
Wire Wire Line
	5250 2350 5250 2250
Wire Wire Line
	5250 2250 8850 2250
Wire Wire Line
	1050 2350 1050 2250
Wire Wire Line
	1050 2250 2850 2250
Wire Wire Line
	900  2350 1050 2350
Wire Wire Line
	8850 2350 10050 2350
Wire Wire Line
	10050 2350 10050 2250
Wire Wire Line
	3450 2250 4050 2250
Wire Wire Line
	7950 1900 7950 1800
Wire Wire Line
	7950 1900 7350 1900
Wire Wire Line
	9450 2100 9450 2200
Wire Wire Line
	4650 2100 4650 2200
Text Notes 800  2200 2    50   ~ 0
~CAS~
Wire Wire Line
	2250 2200 2250 2100
Wire Wire Line
	3150 2200 3150 2100
Wire Wire Line
	2550 2100 2550 2200
Wire Wire Line
	2250 2100 2550 2100
Wire Wire Line
	7350 2100 7350 2200
Wire Wire Line
	7950 2200 7950 2100
Wire Wire Line
	7950 2200 7350 2200
Wire Wire Line
	7950 2100 9450 2100
Wire Wire Line
	4650 2200 6150 2200
Wire Wire Line
	6150 2200 6150 2100
Wire Wire Line
	6150 2100 7350 2100
Wire Wire Line
	9450 2200 10350 2200
Wire Wire Line
	10350 2200 10350 2100
Wire Wire Line
	4650 2050 6450 2050
Wire Wire Line
	6450 2050 6450 1950
Wire Wire Line
	6450 1950 9450 1950
Wire Wire Line
	900  2200 2250 2200
Wire Wire Line
	900  2050 2250 2050
Wire Wire Line
	3150 1800 7350 1800
Wire Wire Line
	900  1800 2550 1800
Wire Wire Line
	3150 2100 4650 2100
Wire Wire Line
	2550 2200 3150 2200
Wire Wire Line
	4050 2350 5250 2350
Text Notes 4550 3400 0    50   ~ 0
CSEN = S4 | S5 | S6 | S7 @ C7M\n\nRAMROM~CS~ = ~IOSEL or IOSTRB~\nRAMCS = CSEN & RAMSEL\nROM~OE~ = CSEN & (IOSEL | (IOSTRB & IOROMEN)) & R~W~\nROM~WE~ = CSEN & (IOSEL | (IOSTRB & IOROMEN)) & ~R~W
Text Notes 1350 3400 0    50   ~ 0
PHI0reg = PHI0 @ C7M\nS[3:0] = (~PHI0~ & PHI0reg) ? 1 : \n          (S==0) ? 0 : S+1 @ C7M\nSyncCnt[1:0] = SYNC ? 2’b11 : \n                SyncCnt==0 ? 0 :\n                SyncCnt-1 @ C7M in S3
Text Notes 7200 3500 0    50   ~ 0
RA[10:8] = S4 ? Addr[10:8] : Addr[21:19] @ C7M\nRA[7:0] = RAMSEL ? (S4 ? Addr[7:0] : Addr[18:11]) : \n           IOSEL ? 8’h00 : Bank[7:0] @ C7M\n\nRA[19] = Addr[19]\nRA[18:11] = RAMSEL ? Addr[18:11] : { SyncCnt[2:0]!=0, Bank[5:0] }\nRA[10:0] = Addr[10:0]
Text Notes 1300 3650 0    100  ~ 0
Select signals (registered)
Text Notes 1300 2850 0    100  ~ 0
State Synchronization
Text Notes 4500 2850 0    100  ~ 0
ROM / SRAM Control
Text Notes 1350 4500 0    50   ~ 0
BankSEL = S3 ? (A==XXXF & DEVSEL & REGEN) : BankSEL @ C7M\nRAMSEL = S3 ? (A==XXX3 & DEVSEL & REGEN) : RAMSEL @ C7M\nAddrHSEL = S3 ? (A==XXX2 & DEVSEL & REGEN) : AddrHSEL @ C7M\nAddrMSEL = S3 ? (A==XXX1 & DEVSEL & REGEN) : AddrMSEL @ C7M\nAddrLSEL = S3 ? (A==XXX0 & DEVSEL & REGEN) : AddrLSEL @ C7M\n\nREGEN = (IOSEL & S3) ? 1 : REGEN @ C7M\nIOROMEN = (A==XXFF & IOSTRB & S3) ? 0 :\n            (A==XX00 & IOSEL & S3) ? 1 :\n            IOROMEN @ C7M
Text Notes 7150 2850 0    100  ~ 0
Address Bus Routing
Text Notes 7150 3750 0    100  ~ 0
6502-Accessible Registers
Text Notes 7200 4200 0    50   ~ 0
Addr[19:16] = (S6 & AddrHSEL & ~R~W) ? D[3:0] : Addr[19:16] @ C7M\nAddr[15:8] = (S6 if AddrMSEL & ~R~W) ? D[7:0] : Addr[15:8] @ C7M\nAddr[7:0] = (S6 if AddrLSEL & ~R~W) ? D[7:0] : Addr[7:0] @ C7M\nif (RAMSEL & S1) Addr[19:0]++ @ C7M\nBank[7:0] = (S6 & BANKREG & ~R~W) ? D[7:0] : Bank[7:0] @ C7M
Text Notes 7150 4450 0    100  ~ 0
Data Bus Routing
Text Notes 7200 5000 0    50   ~ 0
RD[7:0] = (~DEVSEL~ | R~W~) ? 8’bZ : D[7:0]\nD[7:0] = (~CSEN~ | ~DEVSEL~ | ~R~W) ? 8’bZ :\n          AddrHSEL ? {4’hF, Addr[22:16]} : \n          AddrMSEL ? Addr[15:8] : \n          AddrLSEL ? Addr[7:0]
Wire Wire Line
	10350 2100 10400 2100
Wire Wire Line
	7950 1800 10400 1800
Wire Wire Line
	10050 2250 10400 2250
Wire Wire Line
	9450 2050 10400 2050
Wire Wire Line
	10400 2400 9750 2400
Wire Wire Line
	9750 2500 10400 2500
Text Notes 10000 1750 0    40   ~ 0
Latch WR data
Wire Wire Line
	10300 1000 10400 1000
Wire Wire Line
	10350 1250 10400 1250
Wire Wire Line
	10350 1300 10400 1300
Wire Wire Line
	10350 1450 10400 1450
$EndSCHEMATC
