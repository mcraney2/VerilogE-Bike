 module eBike(clk,RST_n,A2D_SS_n,A2D_MOSI,A2D_SCLK,
             A2D_MISO,hallGrn,hallYlw,hallBlu,highGrn,
			 lowGrn,highYlw,lowYlw,highBlu,lowBlu,
			 inertSS_n,inertSCLK,inertMOSI,inertMISO,
			 inertINT,cadence,TX,tgglMd,setting);
			 
  input clk;				// 50MHz clk
  input RST_n;				// active low RST_n from push button
  output A2D_SS_n;			// Slave select to A2D on DE0
  output A2D_SCLK;			// SPI clock to A2D on DE0
  output A2D_MOSI;			// serial output to A2D (what channel to read)
  input A2D_MISO;			// serial input from A2D
  input hallGrn;			// hall position input for "Green" phase
  input hallYlw;			// hall position input for "Yellow" phase
  input hallBlu;			// hall position input for "Blue" phase
  output highGrn;			// high side gate drive for "Green" phase
  output lowGrn;			// low side gate drive for "Green" phase
  output highYlw;			// high side gate drive for "Yellow" phase
  output lowYlw;			// low side gate drive for "Yellow" phas
  output highBlu;			// high side gate drive for "Blue" phase
  output lowBlu;			// low side gate drive for "Blue" phase
  output inertSS_n;			// Slave select to inertial (tilt) sensor
  output inertSCLK;			// SCLK signal to inertial (tilt) sensor
  output inertMOSI;			// Serial out to inertial (tilt) sensor  
  input inertMISO;			// Serial in from inertial (tilt) sensor
  input inertINT;			// Alerts when inertial sensor has new reading
  input cadence;			// pulse input from pedal cadence sensor
  input tgglMd;				// used to select setting[1:0] (from PB switch)
  output reg [1:0] setting;	// 11 => easy, 10 => normal, 01 => hard, 00 => off
  output TX;				// serial output of measured batt,curr,torque
  
  ///////////////////////////////////////////////
  // Declare any needed internal signals here //
  /////////////////////////////////////////////
  wire rst_n;									// global reset from reset_synch
  ...
  
  
  ///////// Any needed macros follow /////////
  localparam FAST_SIM = 0;
  
  
  /////////////////////////////////////
  // Instantiate reset synchronizer //
  ///////////////////////////////////

  
  ///////////////////////////////////////////////////////
  // Instantiate A2D_intf to read torque & batt level //
  /////////////////////////////////////////////////////

				 
  ////////////////////////////////////////////////////////////
  // Instantiate SensorCondition block to filter & average //
  // readings and provide cadence_vec, and zero_cadence   //
  // Don't forget to pass FAST_SIM parameter!!           //
  ////////////////////////////////////////////////////////


  ///////////////////////////////////////////////////
  // Instantiate PID to determine drive magnitude //
  // Don't forget to pass FAST_SIM parameter!!   //
  ////////////////////////////////////////////////	
  
  
  ////////////////////////////////////////////////
  // Instantiate brushless DC motor controller //
  //////////////////////////////////////////////


  ///////////////////////////////
  // Instantiate motor driver //
  /////////////////////////////



  /////////////////////////////////////////////////////////////
  // Instantiate inertial sensor to measure incline (pitch) //
  ///////////////////////////////////////////////////////////

					
  ////////////////////////////////////////////////////////
  // Instantiate (or infer) tggleMd/setting[1:0] logic //
  //////////////////////////////////////////////////////
  
  ///////////////////////////////////////////////////////////////////////
  // brake_n should be asserted if brake A2D reading lower than 0x800 //
  /////////////////////////////////////////////////////////////////////


endmodule
