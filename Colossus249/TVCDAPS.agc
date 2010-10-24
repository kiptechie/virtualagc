# Copyright:	Public domain.
# Filename:	TVCDAPS.agc
# Purpose:	Part of the source code for Colossus, build 249.
#		It is part of the source code for the Command Module's (CM)
#		Apollo Guidance Computer (AGC), possibly for Apollo 8 and 9.
# Assembler:	yaYUL
# Reference:	Begins at p. 925 of 1701.pdf.
# Contact:	Ron Burkey <info@sandroid.org>.
# Website:	www.ibiblio.org/apollo.
# Mod history:	08/23/04 RSB.	Began transcribing.
#		2010-10-25 JL	Fixed page number.
#
# The contents of the "Colossus249" files, in general, are transcribed 
# from a scanned document obtained from MIT's website,
# http://hrst.mit.edu/hrs/apollo/public/archive/1701.pdf.  Notations on this
# document read, in part:
#
#	Assemble revision 249 of AGC program Colossus by NASA
#	2021111-041.  October 28, 1968.  
#
#	This AGC program shall also be referred to as
#				Colossus 1A
#
#	Prepared by
#			Massachusetts Institute of Technology
#			75 Cambridge Parkway
#			Cambridge, Massachusetts
#	under NASA contract NAS 9-4065.
#
# Refer directly to the online document mentioned above for further information.
# Please report any errors (relative to 1701.pdf) to info@sandroid.org.
#
# In some cases, where the source code for Luminary 131 overlaps that of 
# Colossus 249, this code is instead copied from the corresponding Luminary 131
# source file, and then is proofed to incorporate any changes.

# Page 925
# PROGRAM NAME....TVCDAP, CONSISTING OF PITCHDAP, YAWDAP, ETC.
# LOG SECTION....TVCDAP				SUBROUTINE....DAPCSM
# MOD BY ENGEL					DATE....27 OCT, 1967
#
# FUNCTIONAL DESCRIPTION
#
#	SELF-PERPETUATING T5 TASKS WHICH GENERATE THE COMMAND SIGNALS
#	FOR THE PITCH AND YAW SPS GIMBAL ACTUATORS DURING TVC (SPS) BURNS,
#	IN RESPONSE TO BODY-AXIS RATE COMMANDS FROM CROSS-PRODUCT STEERING
#	(S40.8).  IF NO STEERING (IMPULSIVE BURNS) MAINTAINS ATTITUDE-HOLD
#	ABOUT THE REFERENCE (INITIAL) DIRECTIONS (ZERO RATE COMMANDS).
#
#	THE PITCH AND YAW LOOPS ARE SEPARATE, BUT STRUCTURED IDENTICALLY.
#	EACH ATTITUDE-RATE LOOP INCLUDES GIMBAL ANGLE RATE DERIVATION,
#	GIMBAL/BODY AXIS TRANSFORMATION, BODY-AXIS ATTITUDE ERROR
#	INTEGRATION WITH ERROR LIMITING, THE CSM/LEM FILTER OR THE BRANCH
#	POINTS FOR THE CSM-ALONE (GEN3DAP) FILTER, OUTPUT LIMITER,
#	CG-OFFSET TRACKER FILTER, AND THE CG-TRACKER MINOR LOOP.
#
#	THE DAPS ARE CYCLIC, CALLING EACH OTHER AT 1/2 THE DAP SAMPLE
#	TIME, AS DETERMINED BY T5TVCDT.  THE ACTUATOR COMMANDS ARE
#	REGENERATED AS ANALOG VOLTAGES BY THE OPTICS ERROR COUNTERS, WHICH
#	TRANSMIT THE SIGNAL TO THE ACTUATOR SERVOS WHEN THERE IS PROPER CDU
#	MODING.
#
#	REFERENCES FOR THE CSM/LEM FILTER DESIGN INCLUDE R503 BY STUBBS
#	(MIT IL OCT 1965) AND SGA MEMO R26-65 BY MARTIN (MIT IL OCT 1965).
#	REFERENCES FOR THE CSM FILTER DESIGN (SEE GEN3DAP) INCLUDE R533 BY
#	LU (MIT IL JUNE 1966).
#
#	OPERATIONAL ASPECTS OF THE INTEGRATED CONTROL PACKAGE, WITH DESIGN-
#	NOMINAL PARAMETER VALUES ARE DISCUSSED IN AG R336-67 BY ENGEL
#	(MIT IL OCT 1967) AND SGA MEMO R18-67 BY SCHLUNDT (MIT IL OCT 1967)
#
# CALLING SEQUENCE.... (TYPICALLY)
#
#	T5 CALL OF TVCDAPON (P40-P47) BY IGNOVER (P40-P47)
#	T5 CALL OF DAPINIT BY TVCINIT4 (P40-P47)
#	T5 CALL OF DAPINIT BY DAPINIT
#	T5 CALL OF PITCHDAP BY DAPINIT
#	T5 CALL OF YAWDAP BY PITCHDAP
#	T5 CALL OF PITCHDAP BY YAWDAP
#		ETC.
#	(AUTOMATIC SEQUENCING FROM TVCDAPON)
#
# NORMAL EXIT MODE....RESUME
#
# ALARM OR ABORT EXIT MODES....NONE
#
# SUBROUTINES CALLED....
# Page 926
#
#	HACK FOR STROKE TEST (V68) WAVEFORM GENERATION
#	NP0-, NP1-, NY0-, AND NY1NODE FOR GEN3DAP (LEM-OFF) FILTERS
#	PCOPY, YCOPY FOR COPY-CYCLES (USED ALSO BY TVC RESTART PACKAGE)
#	DAPINIT FOR INITIAL CDUS FOR RATE MEASUREMENTS
#	ERRORLIM, ACTLIM FOR INPUT (ATTITUDE-ERROR INTEGRATION) AND
#		OUTPUT (ACTUATOR COMMAND) LIMITING, COMMON TO PITCH AND
#		YAW DAPS
#	OPTVAR, NSUM, DSUM FOR CSM/LEM FILTER OPERATIONS, COMMON TO
#		PITCH AND YAW DAPS
#	RESUME
#
# OTHER INTERFACES
#
#	S40.8 CROSS-PRODUCT STEERING FOR BODY AXIS RATE COMMANDS OMEGAY,ZC
#	S40.15 FOR THE INITIAL DAP GAINS KP/KPDN (LEM-ON) OR KPGEN3 (-OFF)
#	TVCEXECUTIVE FOR VARIABLE DAP GAINS, FILTER SAMPLE-RATE CHANGE AND
#		GAIN REDUCTION AT LEM-ON SWITCHOVER, SINGLE-SHOT CG. ESTIMATION
#		AT SWITCHOVER AND REPETITIVE CG ESTIMATION AFTER SWITCHOVER.
#	TVCRESTART PACKAGE FOR TVC RESTART PROTECTION.
#
# ERASABLE INITIALIZATION REQUIRED....
#
# 	29 PAD-LOAD ERASABLES ESTROKER.....EREPFRAC +1
#	KP/KPDN (KPGEN3) AS IN S40.15 (R03)
#	CONFIGURATION BITS (14, 13) OF DAPDATR1 AS IN R03
#	ENGINE-ON BIT (11.13) FOR RESTARTS
#	TVCPHASE FOR RESTARTS (SEE IGNOVER, AND TVCINIT4)
#	T5 BITS (15,14 OF FLAGWRD6) FOR RESTARTS
#	MISCELLANEOUS VARIABLES SET UP OR COMPUTED BY TVCDAPON....TVCINIT4,
#		INCLUDING THE ZEROING OF 64 TEMPORARIES BY MRCLEAN
#	CDUX,Y,Z AND SINCDUX.... COSCDUX AS PREPARED BY CDUTRIG1 (WITH
#		UPDATES EVERY 1/2 SECOND)
#	ALSO G+N PRIMARY, TVC ENABLE, AND OPTICS ERROR COUNTER ENABLE
#		UNLESS BENCH-TESTING.
#
# OUTPUT....
#
#	TVCPITCH AND TVCYAW WITH COUNTER RELEASE (11.14 AND 11.13 INCREMENTAL
#		COMMANDS TO OPTICS ERROR COUNTERS), FILTER NODES, BODY-
#		AXIS ATTITUDE ERROR INTEGRATOR, TOTAL ACTUATOR COMMANDS,
#		OFFSET-TRACKER-FILTER OUTPUTS, ETC.
#
# DEBRIS....
#
#	MUCH, SHAREABLE WITH RCS/ENTRY, IN EBANK6 ONLY

		BANK	17
		SETLOC	DAPS2
		BANK
# Page 927
		EBANK=	BZERO
		COUNT*	$$/DAPS
		
# Page 928
# PITCH TVCDAP STARTS HERE....(INCOPORATES CSM/LEM DAP FILTER, MODOR DESIGN)

PITCHDAP	LXCH	BANKRUPT	# T5 ENTRY, NORMAL OR VIA DAPINIT
		EXTEND
		QXCH	QRUPT
		
		CAF	YAWT5		# SET UP T5 CALL FOR YAW AUTOPILOT (LOW-
		TS	T5LOC		#	ORDER PART OF 2CADR ALREADY THERE)
		CAE	T5TVCDT
		TS	TIME5
		
PSTROKER	CCS	STROKER		# (STRKFLG) CHECK FOR STROKE TEST
		TC	HACK		# TEST-START OR TEST-IN-PROGRESS
		TCF	+2		# NO-TEST
		TC	HACK		# TEST-IN-PROGRESS
		
PCDUDOTS	CAE	CDUY		# COMPUTE CDUYDOT
		XCH	PCDUYPST	#	FOR PITCH AUTOPILOT
		EXTEND
		MSU	PCDUYPST
		TCR	RLIMTEST	#	RATE TEST
		TS	MCDUYDOT	#	(MINUS, SC.AT 1/2TVCDT REVS/SEC)
		
		CAE	CDUZ		# COMPUTE CDUZDOT
		XCH	PCDUZPST	#	FOR PITCH AUTOPILOT
		EXTEND
		MSU	PCDUZPST
		TCR	RLIMTEST	#	RATE TEST
		TS	MCDUZDOT	#	(MINUS, SC.AT 1/2TVCDT REVS/SEC)
		
PINTEGRL	EXTEND			# COMPUTE INTEGRAL OF BODY-AXIS PITCH-RATE
		DCA	PERRB		#	ERROR, SC.AT B-1 REVS
		DXCH	ERRBTMP
		
		EXTEND
		DCA	OMEGAYC
		DAS	ERRBTMP
		
		CS	COSCDUZ		# PREPARE BODY-AXIS PITCH RATE, OMEGAYB
		EXTEND
		MP	COSCDUX
		DDOUBL
		EXTEND
		MP	MCDUYDOT
		DDOUBL
		DXCH	OMEGAYB
		
		CS	MCDUZDOT
		EXTEND
# Page 929
		MP	SINCDUX
		DDOUBL
		DAS	OMEGAYB		# (COMPLETED OMEGAYB, SC.AT 1/2TVCDT REVS)
		
		EXTEND			# PICK UP -OMEGAYB (SIGN CHNG, INTEGRATE)
		DCS	OMEGAYB
		DAS	ERRBTMP
		
PERORLIM	TCR	ERRORLIM	# PITCH BODY-AXIS-ERROR INPUT LIMITER

P1FILJMP	CAE	DAPDATR1	# CHECK FOR LEM-ON/-OFF
		MASK	BIT14		# (BIT 14 INDICATES LEM IS ON)
		CCS	A
		TCF	+3		# USE LEM-ON FILTER
		TC	POSTJUMP	# USE LEM-OFF (GEN3DAP) FILTER
		CADR	NP0NODE
		
PFORWARD	EXTEND			# LEM-ON FILTER COMPUTATIONS.
		DCS	PDSUM		# DENOMINATOR TERMS, SC.AT B+0 SPASCREVS
		DXCH	JZERO
		
		CAE	ERRBTMP		# INPUT ERROR, SC.AT B-1 REVS
		AD	PNSUM		# NUMERATOR TERMS, SC.AT B-1 REVS
		EXTEND
		MP	KPDN		# KPDN, SC.AT B+1 SPASCREV
		DAS	JZERO
		CAE	PNSUM +1
		EXTEND
		MP	KPDN
		ADS	JZERO +1
		TS	L
		TCF	+2
		ADS	JZERO		# (SC.AT B+0 SPASCREV), (JZERO = CMDTMP)
		
JZSTORE		EXTEND			# PREPARE JZERO FOR DENOMINATOR LADDER
		DCA	JZERO		#	SC.AT B+0 SPASCREV
		DDOUBL
		DDOUBL
		DDOUBL
		DXCH	J1TMP		# 	SC.AT B-3 SPASCREV
		
OPTVARKP	TCR	OPTVARK		# PITCH VARIABLE-GAIN PACKAGE

POFFSET		EXTEND			# SIGN CHANGE IN FORWARD LOOP
		DCS	CMDTMP		#	(GEN3DAP RETURNS AT POFFSET)
		DXCH	CMDTMP
		EXTEND			# ADD IN DOUBLE-PRECISION CG OFFSETS
		DCA	PDELOFF
		DAS	CMDTMP

# Page 930
PROUND		CAE	CMDTMP +1	# ROUND UP FOR OUTPUT
		DOUBLE
		TS	L
		CAF	ZERO
		AD	CMDTMP
		
PACLIM		TCR	ACTLIM		# PITCH ACTUATOR-COMMAND-LIMITER

POUT		CS	PCMD		# INCREMENTAL PITCH COMMAND
		AD	CMDTMP
		ADS	TVCPITCH	# UPDATE THE ERROR COUNTER (NO RESTART-
					# 	PROTECT, SINCE ERROR CNTR ZEROED)
					
		CAF	BIT11		# BIT FOR TVCPITCH COUNT RELEASE
		EXTEND
		WOR	CHAN14
P2FILJMP	CAE	DAPDATR1	# CHECK FOR LEM-ON/-OFF
		MASK	BIT14		# (BIT 14 INDICATES LEM IS ON)
		CCS	A
		TCF	+3		# USE LEM-ON FILTER
		TC	POSTJUMP	# USE LEM-OFF (GEN3DAP) FILTER
		CADR	NP1NODE
BZSTORE		CAE	ERRBTMP		# PREPARE BZERO (UPPER WORD OF ERRBTMP)
		DOUBLE			#	FOR NUMERATOR LATTER....SC.AT B-1
		TS	B1TMP		#	SC.AT B-2 REVS FOR LADDER
PNLADDER	EXTEND			# PREPARE TEMPORARIES, FOR UPDATING PITCH
		DCA	B1		#	NUMERATOR LADDER
		DXCH	B2TMP
		EXTEND
		DCA	B3
		DXCH	B4TMP
		EXTEND
		DCA	B5
		DXCH	B6TMP
		
PNSUMC		TCR	NSUM		# PITCH NUMERATOR SUM
PDLADDER	EXTEND			# PREPARE TEMPORARIES, FOR UPDATING PITCH
		DCA	J1		#	DENOMINATOR LADDER
		DXCH	J2TMP
		EXTEND
		DCA	J2
		DXCH	J3TMP
		EXTEND
		DCA	J3
# Page 931
		DXCH	J4TMP
		EXTEND
		DCA	J4
		DXCH	J5TMP
		EXTEND
		DCA	J5
		DXCH	J6TMP
		
PDSUMC		TCR	DSUM		# PITCH DENOMINATOR SUM

DELBARP		CAE	CMDTMP		# UPDATE PITCH OFFSET-TRACKER-FILTER
		EXTEND			# 	(GEN3DAP RETURNS AT "DELBARP")
		MP	1-E(-AT)
		DXCH	DELBRTMP
		CAE	DELPBAR
		EXTEND
		MP	E(-AT)
		DAS	DELBRTMP
		CAE	DELPBAR +1
		EXTEND
		MP	E(-AT)
		ADS	DELBRTMP +1
		TS	L
		TCF	+2
		ADS	DELBRTMP
		
PCOPYCYC	TCR	PCOPY		# PITCH COPYCYCLE

PDAPEND		TCF	RESUME		# PITCH DAP COMPLETED
RLIMTEST	TS	CMDTMP		# TEST FOR EXCESSIVE CDU RATES
		EXTEND			#	IF CDU DIFFERENCE EXCEEDS 2.33 DEG
		MP	1/RTLIM		#	IF ONE SAMPLE PERIOD, SET CDURATE=0
		EXTEND
		BZF	+3
		CAF	ZERO
		TS	CMDTMP
		CAE	CMDTMP
		TC	Q
		
# Page 932
# PITCH TVCDAP COPYCYCLE SUBROUTINE (CALLED VIA PITCH TVCDAP OR TVC RESTART PACKAGE)

PCOPY		INCR	TVCPHASE	# RESTART-PROTECT THE COPYCYCLE.
					#	NOTE POSSIBLE RE-ENTRY FROM RESTART
					#	PACKAGE, SHOULD A RESTART OCCUR
					#	DURING PITCH COPYCYCLE.
					
NEWB(S)		EXTEND			# UPDATE PITCH NUMERATOR LADDER FROM
		DCA	B1TMP		#	TEMPORARIES
		DXCH	B1
		EXTEND
		DCA	B3TMP
		DXCH	B3
		EXTEND
		DCA	B5TMP
		DXCH	B5
		
NEWJ(S)		EXTEND			# UPDATE PITCH DENOMINATOR LADDER FROM
		DCA	J1TMP		#	TEMPORARIES
		DXCH	J1
		EXTEND
		DCA	J2TMP
		DXCH	J2
		EXTEND
		DCA	J3TMP
		DXCH	J3
		EXTEND
		DCA	J4TMP
		DXCH	J4
		EXTEND			# 	(ALSO NP1TMP,+1 TO NP1,+1)
		DCA	J5TMP
		DXCH	J5
		
PMISC		EXTEND			# MISC....PITCH-RATE-ERROR INTEGRATOR
		DCA	ERRBTMP
		TS	AK1		#	FOR PITCH NEEDLES, SC.AT B-1 REVS
		DXCH	PERRB
		
		EXTEND			# 	PITCH NUMERATOR SUM
		DCA	NSUMTMP		#		(ALSO NP2TMP,+1 TO NP2,+1)
		DXCH	PNSUM
		
		EXTEND			#	PITCH DENOMINATOR SUM
		DCA	DSUMTMP		#		(ALSO NP3TMP,+1 TO NP3,+1)
		DXCH	PDSUM
		
		CAE	CMDTMP		#	PITCH ACTUATOR COMMAND
		TS	PCMD
		
		EXTEND			# 	PITCH OFFSET-TRACKER-FILTER
# Page 933
		DCA	DELBRTMP
		DXCH	DELPBAR
		
		INCR	TVCPHASE	# PITCH COPYCYCLE COMPLETED
		
		TC	Q

# Page 934
# TVCDAP STARTS HERE....(INCORPORATES CSM/LEM DAP FILTER, MODOR DESIGN)

YAWDAP		LXCH	BANKRUPT	# T5 ENTRY, NORMAL
		EXTEND
		QXCH	QRUPT
		
		CAF	PITCHT5		# SET UP T5 CALL FOR PITCH AUTOPILOT (LOW-
		TS	T5LOC		#	ORDER PART OF 2CADR ALREADY THERE)
		CAE	T5TVCDT
		TS	TIME5
		
YSTROKER	CCS	STROKER		# (STRKFLG) CHECK FOR STROKE TEST
		TC	HACK		# TEST-START OR TEST-IN-PROGRESS
		TCF	+2		# NO-TEST
		TC	HACK		# TEST-IN-PROGRESS
		
					# USE BODY RATES FROM PITCHDAP (PCDUDOTS)
					
YINTEGRL	EXTEND			# COMPUTE INTEGRAL OF BODY-AXIS YAW-RATE
		DCA	YERRB		# 	ERROR, SC.AT B-1 REVS
		DXCH	ERRBTMP
		
		EXTEND
		DCA	OMEGAZC
		DAS	ERRBTMP
		
		CAE	COSCDUZ		# PREPARE BODY-AXIS YAW-RATE, OMEGAZB
		EXTEND
		MP	SINCDUX
		DDOUBL
		EXTEND
		MP	MCDUYDOT
		DDOUBL
		DXCH	OMEGAZB
		
		CS	MCDUZDOT
		EXTEND
		MP	COSCDUX
		DDOUBL
		DAS	OMEGAZB		# (COMPLETED OMEGAZB, SC.AT 1/2TVCDT REVS)
		
		EXTEND			# PICK UP -OMEGAZB (SIGN CHNG, INTEGRATE)
		DCS	OMEGAZB
		DAS	ERRBTMP
		
YERORLIM	TCR	ERRORLIM	# YAW BODY-AXIS-ERROR INPUT LIMITER

Y1FILJMP	CAE	DAPDATR1	# CHECK FOR LEM-ON/-OFF
		MASK	BIT14		# (BIT 14 INDICATES LEM IS ON)
		
# Page 935
		CCS	A
		TCF	+3		# USE LEM-ON FILTER
		TC	POSTJUMP	# USE LEM-OFF (GEN3DAP) FILTER
		CADR	NY0NODE
		
YFORWARD	EXTEND			# LEM-ON FILTER COMPUTATIONS
		DCS	YDSUM		# DENOMINATOR TERMS, SC.AT B+0 SPASCREVS
		DXCH	YZERO
		
		CAE	ERRBTMP		# INPUT ERROR, SC.AT B-1 REVS
		AD	YNSUM		# NUMERATOR TERMS, SC.AT B-1 REVS
		EXTEND
		MP	KYDN		# KYDN, SC.AT B+1 SPASCREV
		DAS	YZERO
		CAE	YNSUM +1
		EXTEND
		MP	KYDN
		ADS	YZERO +1
		TS	L
		TCF	+2
		ADS	YZERO		# (SC.AT B+0 SPASCREV), (YZERO = CMDTMP)
		
YZSTORE		EXTEND			# PREPARE YZERO FOR DENOMINATOR LADDER
		DCA	YZERO		# 	SC.AT B+0 SPASCREV
		DDOUBL
		DDOUBL
		DDOUBL
		DXCH	Y1TMP		#	SC.AT B-3 SPASCREV
		
OPTVARKY	TCR	OPTVARK		# YAW VARIABLE-GAIN PACKAGE

YOFFSET		EXTEND			# SIGN CHANGE IN FORWARD LOOP
		DCS	CMDTMP		#	(GEN3DAP RETURNS AT YOFFSET)
		DXCH	CMDTMP
		EXTEND			# ADD IN DOUBLE-PRECISION CG OFFSETS
		DCA	YDELOFF
		DAS	CMDTMP
		
YROUND		CAE	CMDTMP +1	# ROUND UP FOR OUTPUT
		DOUBLE
		TS	L
		CAF	ZERO
		AD	CMDTMP
		
YACLIM		TCR	ACTLIM		# YAW ACTUATOR-COMMAND-LIMITER

YOUT		CS	YCMD		# INCRMENTAL YAW COMMAND
		AD	CMDTMP
		ADS	TVCYAW		# UPDATE THE ERROR COUNTER (NO RESTART-
					#	PROTECT, SINCE ERROR CNTR ZEROED)
# Page 936
		CAF	BIT12		# BIT FOR TVCYAW COUNT RELEASE
		EXTEND
		WOR	CHAN14
Y2FILJMP	CAE	DAPDATR1	# CHECK FOR LEM-ON/-OFF
		MASK	BIT14		# (BIT 14 INDICATES LEM IS ON)
		CCS	A
		TCF	+3		# USE LEM-ON FILTER
		TC	POSTJUMP	# USE LEM-OFF (GEN3DAP) FILTER
		CADR	NY1NODE
CZSTORE		CAE	ERRBTMP		# PREPARE CZERO (UPPER WORD OF ERRBTMP)
		DOUBLE			#	FOR NUMERATOR LATTER....SC.AT B-1
		TS	C1TMP		#	SC.AT B-2 REVS FOR LADDER
YNLADDER	EXTEND			# PREPARE TEMPORARIES, FOR UPDATING YAW
		DCA	C1		#	NUMERATOR LADDER
		DXCH	C2TMP
		EXTEND
		DCA	C3
		DXCH	C4TMP
		EXTEND
		DCA	C5
		DXCH	C6TMP
		
YNSUMC		TCR	NSUM		# YAW NUMERATOR SUM
YDLADDER	EXTEND			# PREPARE TEMPORARIES, FOR UPDATING YAW
		DCA	Y1		#	DENOMINATOR LADDER
		DXCH	Y2TMP
		EXTEND
		DCA	Y2
		DXCH	Y3TMP
		EXTEND
		DCA	Y3
		DXCH	Y4TMP
		EXTEND
		DCA	Y4
		DXCH	Y5TMP
		EXTEND
		DCA	Y5
		DXCH	Y6TMP
		
YDSUMC		TCR	DSUM		# YAW DENOMINATOR SUM

DELBARY		CAE	CMDTMP		# UPDATE YAW OFFSET-TRACKER-FILTER
		EXTEND			#	(GEN3DAP RETURNS AT "DELBARY")
		MP	1-E(-AT)
# Page 937
		DXCH	DELBRTMP
		CAE	DELYBAR
		EXTEND
		MP	E(-AT)
		DAS	DELBRTMP
		CAE	DELYBAR +1
		EXTEND
		MP	E(-AT)
		ADS	DELBRTMP +1
		TS	L
		TCF	+2
		ADS	DELBRTMP
		
YCOPYCYC	TCR	YCOPY		# YAW COPYCYCLE

YDAPEND		TCF	RESUME		# YAW DAP COMPLETED

# Page 938
# TVCDAP COPYCYCLE SUBROUTINE (CALLED VIA YAW   TVCDAP OR TVC RESTART PACKAGE)

YCOPY		INCR	TVCPHASE	# RESTART-PROTECT THE COPYCYCLE.
					#	NOTE POSSIBLE RE-ENTRY FROM RESTART
					#	PACKAGE, SHOULD A RESTART OCCUR
					#	DURING YAW   COPYCYCLE.
					
NEWC(S)		EXTEND			# UPDATE YAW   NUMERATOR LADDER FROM
		DCA	C1TMP		#	TEMPORARIES
		DXCH	C1
		EXTEND
		DCA	C3TMP
		DXCH	C3
		EXTEND
		DCA	C5TMP
		DXCH	C5
		
NEWY(S)		EXTEND			# UPDATE YAW   DENOMINATOR LADDER FROM
		DCA	Y1TMP		#	TEMPORARIES
		DXCH	Y1
		EXTEND
		DCA	Y2TMP
		DXCH	Y2
		EXTEND
		DCA	Y3TMP
		DXCH	Y3
		EXTEND
		DCA	Y4TMP
		DXCH	Y4
		EXTEND			# 	(ALSO NYTMMP,+1 TO NY1,+1)
		DCA	Y5TMP
		DXCH	Y5
		
YMISC		EXTEND			# MISC....YAW-RATE-ERROR INTEGRATOR
		DCA	ERRBTMP
		TS	AK2		#	FOR YAW   NEEDLES, SC.AT B-1 REVS
		DXCH	YERRB
		
		EXTEND			# 	YAW	NUMERATOR SUM
		DCA	NSUMTMP		#		(ALSO NY2TMP,+1 TO NY2,+1)
		DXCH	YNSUM
		
		EXTEND			#	YAW	DENOMINATOR SUM
		DCA	DSUMTMP		#		(ALSO NY3TMP,+1 TO NY3,+1)
		DXCH	YDSUM
		
		CAE	CMDTMP		#	YAW	ACTUATOR COMMAND
		TS	YCMD
		
		EXTEND			#	YAW	OFFSET-TRACKER-FILTER
# Page 939
		DCA	DELBRTMP
		DXCH	DELYBAR
		CAF	ZERO		# YAW   COPYCYCLE COMPLETED
		TS	TVCPHASE	#	RESET TVCPHASE
		
		TC	Q
		
# Page 940
# SUBROUTINES COMMON TO BOTH PITCH AND YAW DAPS....
# INITIALIZATION PACKAGE FOR CDURATES....

DAPINIT		LXCH	BANKRUPT	# T5 RUPT ENTRY (CALLED BY TVCINT4)

		CAF	NEGONE		# 	SET UP
		AD	T5TVCDT		#	T5 CALL FOR PITCHDAP IN TVCDT SECS
		AD	NEGMAX		#	(T5TVCDT = POSMAX - TVCDT/2 +1)
		AD	T5TVCDT
		TS	TIME5
		CAF	PITCHT5		#	(BBCON ALREADY THERE)
		TS	T5LOC
		
		CAE	CDUY		# READ AND STORE CDUS FOR DIFFERENTIATOR
		TS	PCDUYPST	#	PAST-VALUES
		CAE	CDUZ
		TS	PCDUZPST
		
		TCF	NOQRSM
		
# BODY-AXIS-ERROR   INPUT LIMITER PACKAGE....

ERRORLIM	CAE	ERRBTMP		# CHECK FOR INPUT-ERROR LIMIT
		EXTEND			#	CHECKS UPPER WORD ONLY
		MP	1/ERRLIM
		EXTEND
		BZF	+6
		CCS	ERRBTMP
		CAF	ERRLIM
		TCF	+2
		CS	ERRLIM
		TS	ERRBTMP		# LIMIT WRITES OVER UPPER WORD ONLY
		
		TC	Q
		
# VARIABLE-GAIN PACKAGE....

OPTVARK		CAE	CMDTMP		# VARIABLE-GAIN PACKAGE....CMDTMP CONTAINS
		EXTEND			#	JZERO OR YZERO
		MP	VARK		# VARIABLE-GAIN, SC.AT 4 ASCREV/SPASCREV
		DXCH	CMDTMP
		LXCH	A		# LO-ORDER WORD OF INPUT CMDTMP
		EXTEND
		MP	VARK
		ADS	CMDTMP +1
		TS	L
# Page 941
		TCF	+2
		ADS	CMDTMP
		
		DXCH	CMDTMP		# FIX UP SCALING
		DDOUBL
		DDOUBL
		DXCH	CMDTMP
		
		TC	Q
		
# ACTUATOR-COMMAND LIMITER PACKAGE....

ACTLIM		EXTEND			# CHECK FOR ACTUATOR COMMAND LIMIT
		MP	1/ACTSAT
		EXTEND
		BZF	+6
		CCS	CMDTMP		# APPLY LIMITS
		CAF	ACTSAT
		TCF	+2
		CS	ACTSAT
		TS	CMDTMP		# LIMITS WRITE OVER CMDTMP
		
		TC	Q
		
# NUMERATOR-SUM COMPUTATION....

NSUM		CAE	B1TMP		# PREPARE NUMERATOR SUM, SCALING IS AT
		EXTEND			#	B+0 REVS ( = B+2 x B-2 )
		MP	N1
		DXCH	NSUMTMP
		
		CAE	B2TMP
		EXTEND
		MP	N2
		DAS	NSUMTMP
		
		CAE	B3TMP
		EXTEND
		MP	N3
		DAS	NSUMTMP
		
		CAE	B4TMP
		EXTEND
		MP	N4
		DAS	NSUMTMP
		
		CAE	B5TMP
		EXTEND
# Page 942
		MP	N5
		DAS	NSUMTMP
		
		CAE	B6TMP
		EXTEND
		MP	N6
		DAS	NSUMTMP
		
		CAE	B7TMP
		EXTEND
		MP	N7
		DAS	NSUMTMP
		
NSUMSC		DXCH	NSUMTMP		# FIX UP SCALING (NOW AT B+0 REVS)
		DDOUBL
		DXCH	NSUMTMP		# SC.AT B-1 REV
		
		TC	Q
		
# DENOMINATOR-SUM COMPUTATION....

DSUM		CAE	J1TMP		# PREPARE DENOMINATOR SUM, SCALED
		EXTEND			#	AT B+1 SPASCREVS ( = B+4 x B-3)
		MP	D1		#	(J1TMP = J,YZERO, SC.AT B-3 REVS)
		DXCH	DSUMTMP
		CAE	J1TMP
		EXTEND
		MP	D1 +1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		CAE	J1TMP +1
		EXTEND
		MP	D1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
D2J2		CAE	J2TMP
		EXTEND
		MP	D2
		DAS	DSUMTMP
		CAE	J2TMP
		EXTEND
		MP	D2 +1
		ADS	DSUMTMP +1
		TS	L
# Page 943
		TCF	+2
		ADS	DSUMTMP
		CAE	J2TMP +1
		EXTEND
		MP	D2
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
D3J3		CAE	J3TMP
		EXTEND
		MP	D3
		DAS	DSUMTMP
		CAE	J3TMP
		EXTEND
		MP	D3 +1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		CAE	J3TMP +1
		EXTEND
		MP	D3
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
D4J4		CAE	J4TMP
		EXTEND
		MP	D4
		DAS	DSUMTMP
		CAE	J4TMP
		EXTEND
		MP	D4 +1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		CAE	J4TMP +1
		EXTEND
		MP	D4
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
D5J5		CAE	J5TMP
		EXTEND
# Page 944
		MP	D5
		DAS	DSUMTMP
		CAE	J5TMP
		EXTEND
		MP	D5 +1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		CAE	J5TMP +1
		EXTEND
		MP	D5
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
D6J6		CAE	J6TMP
		EXTEND
		MP	D6
		DAS	DSUMTMP
		CAE	J6TMP
		EXTEND
		MP	D6 +1
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		CAE	J6TMP +1
		EXTEND
		MP	D6
		ADS	DSUMTMP +1
		TS	L
		TCF	+2
		ADS	DSUMTMP
		
DSUMSC		DXCH	DSUMTMP		# FIX UP SCALING (NOW AT B+1 SPASCREV)
		DDOUBL
		DXCH	DSUMTMP		# SC.AT B+0 SPASCREV
		
		TC	Q
		
# Page 945
# CONSTANTS FOR AUTOPILOTS
# NOTE....1 ASCREV (ACTUATOR CMD SCALING) = 65.41 ARCSEC/BIT OR 1.07975111 REVS (85.41x16384/3600/360)
#	  1 SPASCREV (SPECIAL ACTUATOR CMD SCALING) = 1.04620942 REVS

ACTSAT		DEC	253		# ACTUATOR LIMIT (6 DEG), SC.AT 1ASCREV
1/ACTSAT	DEC	.0039525692	# RECIPROCAL (1/253)

ERRLIM		EQUALS	BIT13		# FILTER INPUT LIMIT....B-3 REVS (45DEG),
1/ERRLIM	EQUALS	BIT3		# 	SC.AT B-1 REV, AND ITS RECIPROCAL

1/RTLIM		DEC	0.004715	# .004715(CDUDIF) =0 IF CDUDIF < 2.33 DEG

KPDN		=	DEC45		# DESIGN-NOMINAL FILTER GAIN, SC.AT B+1
KYDN		=	KPDN		#	SPASCREV (FOR DEC45 BITS EXACTLY)
					#		KPDN = .005747 DEG/DEG
					#		SCALED KPDN = DEC45
					#		1SPASCREV = KPDN(B+14)/(2x45)
					#			  = 1.04620942 REVS

PITCHT5		GENADR	PITCHDAP	# UPPER WORDS OF T5 2CADRS, LOWER WORDS
DAPT5		GENADR	DAPINIT		#	(BBCON) ALREADY THERE.  ORDER IS
YAWT5		GENADR	YAWDAP		#	REQUIRED.
1-E(-AT)	OCT	00243		# AT = .01SEC....EITHER(1/A=4SEC, T=40MS),
E(-AT)		OCT	37535		#		     OR(1/A=8SEC, T=80MS)

N1		DEC	-2.9708385 B-2	# NUMERATOR COEFS (CSM/LEM), SC.AT B+2
N2		DEC	3.1947342 B-2
N3		DEC	-0.40962906 B-2
N4		DEC	-2.5780275 B-2
N5		DEC	2.9629319 B-2
N6		DEC	-1.5101470 B-2
N7		DEC	0.31243224 B-2

D1		2DEC	-4.7798977 B-4	# DENOMINATOR COEFS (CSM/LEM), SC.AT B+4
# Page 946
D2		2DEC	9.4452763 B-4
D3		2DEC	-9.8593475 B-4
D4		2DEC	5.7231811 B-4
D5		2DEC	-1.7484750 B-4
D6		2DEC	0.21933335 B-4

