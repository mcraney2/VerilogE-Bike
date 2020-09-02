module eBike_tb();

  reg clk,RST_n;
  reg [11:0] BATT;				// analog values you apply to AnalogModel
  reg [11:0] BRAKE,TORQUE;		// analog values
  reg cadence;					// you have to have some way of applying a cadence signal
  reg tgglMd;	
  reg [15:0] YAW_RT;			// models angular rate of incline
  
  wire A2D_SS_n,A2D_MOSI,A2D_SCLK,A2D_MISO;		// A2D SPI interface
  wire highGrn,lowGrn,highYlw;					// FET control
  wire lowYlw,highBlu,lowBlu;					//   PWM signals
  wire hallGrn,hallBlu,hallYlw;					// hall sensor outputs
  wire inertSS_n,inertSCLK,inertMISO,inertMOSI,inertINT;	// Inert sensor SPI bus
  
  wire [1:0] setting;		// drive LEDs on real design
  wire [11:0] curr;			// comes from eBikePhysics back to AnalogModel
  
  //////////////////////////////////////////////////
  // Instantiate model of analog input circuitry //
  ////////////////////////////////////////////////
  AnalogModel iANLG(.clk(clk),.rst_n(RST_n),.SS_n(A2D_SS_n),.SCLK(A2D_SCLK),
                    .MISO(A2D_MISO),.MOSI(A2D_MOSI),.BATT(BATT),
		            .CURR(curr),.BRAKE(BRAKE),.TORQUE(TORQUE));

  ////////////////////////////////////////////////////////////////
  // Instantiate model inertial sensor used to measure incline //
  //////////////////////////////////////////////////////////////
  eBikePhysics iPHYS(.clk(clk),.RST_n(RST_n),.SS_n(inertSS_n),.SCLK(inertSCLK),
	             .MISO(inertMISO),.MOSI(inertMOSI),.INT(inertINT),
		     .yaw_rt(YAW_RT),.highGrn(highGrn),.lowGrn(lowGrn),
		     .highYlw(highYlw),.lowYlw(lowYlw),.highBlu(highBlu),
		     .lowBlu(lowBlu),.hallGrn(hallGrn),.hallYlw(hallYlw),
		     .hallBlu(hallBlu),.avg_curr(curr));

  //////////////////////
  // Instantiate DUT //
  ////////////////////
  eBike iDUT(.clk(clk),.RST_n(RST_n),.A2D_SS_n(A2D_SS_n),.A2D_MOSI(A2D_MOSI),
             .A2D_SCLK(A2D_SCLK),.A2D_MISO(A2D_MISO),.hallGrn(hallGrn),
			 .hallYlw(hallYlw),.hallBlu(hallBlu),.highGrn(highGrn),
			 .lowGrn(lowGrn),.highYlw(highYlw),.lowYlw(lowYlw),
			 .highBlu(highBlu),.lowBlu(lowBlu),.inertSS_n(inertSS_n),
			 .inertSCLK(inertSCLK),.inertMOSI(inertMOSI),
			 .inertMISO(inertMISO),.inertINT(inertINT),
			 .cadence(cadence),.tgglMd(tgglMd),.TX(TX),
			 .setting(setting));
	
  ///////////////////////////////////////////////////////////
  // Instantiate Something to monitor telemetry output??? //
  /////////////////////////////////////////////////////////
			 
			 
  initial begin
      This is where you magic occurs
  end
  
  always
    #10 clk = ~clk;

	
endmodule
