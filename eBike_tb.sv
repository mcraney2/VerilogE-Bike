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
			 
int error_limit = 25;	// wait_error stops waiting for error to settle when it is within error_limit
int CADENCE_PER = 1024; // threshhold for not pedaling: 50000
int test_number = 0;	// count of how many tests ran  during each setting
int prevOmega;		// omega before wait_error()
int omega;		// compared with prevOmega
int signed dOmega;	// prevOmega - omega
int no_change_range = 750;	// dOmega must be within no_change_range to be accepted
int tests_passed = 0;
int tests_failed = 0;
	
initial begin
	clk = 0;
	RST_n = 0;
	tgglMd = 0;
	cadence = 1;
	
	TORQUE = 12'h000;
	BRAKE = 12'h802;
	BATT = 12'hB11;
	YAW_RT = 16'h0000;
	CADENCE_PER = 4096;

	@(negedge clk);	// reset DUT
	RST_n = 1;
	@(posedge clk);
	
	fork	// increase setting to start at 1
		wait_error();
		inc_setting(3);
	join
	
	for(int i = 0; i < 3; i++) begin

		case(iDUT.setting)	// changes w/ setting
			1: no_change_range = 400;
			2: no_change_range = 650;
			3: no_change_range = 750;
		endcase

		TORQUE = 12'h400;	//setup with TORQUE above minimum threshhold
		wait_error();



		$display();		//start at setting 1 -> 2 -> 3 (running same tests)
		$display("Setting: %d", iDUT.setting);
		test_number = 0;

		
		// Checks if when brake goes below the threshold if braking occurs
		$display("BRAKE_TESTS:");
		BRAKE = 12'h400;
		repeat(512*4096 / CADENCE_PER) begin
			cadence = 1;
			repeat(CADENCE_PER/2) @(posedge clk);
			cadence = 0;
			repeat(CADENCE_PER/2) @(posedge clk);
		end
		test_number = 0;
		brake_test(0);

		BRAKE = 12'h802;
		repeat(512*4096 / CADENCE_PER) begin
			cadence = 1;
			repeat(CADENCE_PER/2) @(posedge clk);
			cadence = 0;
			repeat(CADENCE_PER/2) @(posedge clk);
		end
		brake_test(1);
		
			

		$display("BATT_TESTS:");
		test_number = 0;
		
		// Battery Test 1
		TORQUE = 12'h4ff;	//torque must get changed to generate error (battery under a certain threshold will force error to zero
		BATT = 12'h000;
		run_batt(0);
		TORQUE = 12'h400;
		
		// Battery Test 2
		BATT = 12'h500;
		run_batt(0);
		TORQUE = 12'h4ff;

		// Battery Test 3
		BATT = 12'hB00;
		run_batt(1);
		TORQUE = 12'h400;

		// Battery Test 4
		BATT = 12'hFE0;
		run_batt(1);
		TORQUE = 12'h4ff;

		// Battery Test 5
		BATT = 12'hFFF;
		run_batt(1);
		TORQUE = 12'h400;

		// Battery Test 6
		BATT = 12'h800;
		run_batt(0);
		TORQUE = 12'h4ff;
		
		// Battery Test 7
		BATT = 12'hb11;
		run_batt(1);
		TORQUE = 12'h400;
		
		// Battery Test 8
		run_batt(1);
		


		$display("YAW_TESTS:");
		test_number = 0;

		// Set up Yaw Test
		fork 
			inc_yaw(1);	//holds YAW_RT (high==1, neutral==0 or low==-1) for 1 million cycles
			wait_error();
		join 
	
		// Yaw Test 1
		fork
			inc_yaw(0);
			run_test(0);
		join
	
		// Yaw Test 2
		fork
			inc_yaw(-1);
			run_test(-1);
		join

		// Yaw Test 3
		fork
			inc_yaw(-1);
			run_test(-1);
		join

		// Yaw Test 4
		fork
			inc_yaw(0);
			run_test(0);
		join
	
		// Yaw Test 5
		fork
			inc_yaw(1);
			run_test(1);
		join
	
		// Yaw Test 6
		fork
			inc_yaw(1);
			run_test(1);
		join
		
		// Yaw Test 7
		fork
			inc_yaw(1);
			run_test(1);
		join
	
		// Yaw Test 8
		fork
			inc_yaw(-1);
			wait_error();
		join
	
		// Yaw Test 9
		fork
			inc_yaw(-1);
			run_test(-1);
		join

		// Yaw Test 10
		fork
			inc_yaw(0);
			run_test(0);
		join
		
		$display("CADENCE_TESTS:");
		test_number = 0;
		
		// Cadence Test 1
		CADENCE_PER = 4096;
		run_test(0);
		
		// Cadence Test 2
		CADENCE_PER = 20000;
		run_test(-1);
		
		// Cadence Test 3
		CADENCE_PER = 500;
		run_test(1);
		
		// Cadence Test 4
		CADENCE_PER = 20000;
		run_test(-1);
		
		// Cadence Test 5
		CADENCE_PER = 50000;
		run_test(-1); 
		
		// Cadence Test 6
		CADENCE_PER = 75000;
		run_test(0);
		
		// Cadence Test 7
		CADENCE_PER = 128;
		run_test(1);
		
		// Cadence Test 8
		CADENCE_PER = 40000;
		run_test(-1);
		
		// Cadence Test 9
		CADENCE_PER = 200;
		run_test(1);

		// Cadence Test 10
		CADENCE_PER = 4096;
		run_test(-1);
		


		$display("TORQUE_TESTS:");
		test_number = 0;
		
		// Torque Test 1
		TORQUE = 12'h400;
		run_test(0);
		
		// Torque Test 2
		TORQUE = 12'h200;
		run_test(-1);
		
		// Torque Test 3
		TORQUE = 12'h00f;
		run_test(0);
	
		// Torque Test 4
		TORQUE = 12'h360;
		run_test(0);
		
		// Torque Test 5
		TORQUE = 12'h3ff;
		run_test(1);
		
		// Torque Test 6
		TORQUE = 12'h4ff;
		run_test(1);
		
		// Torque Test 7
		TORQUE = 12'h390;
		run_test(-1);
		
		// Torque Test 8
		TORQUE = 12'h37f;
		run_test(-1);
		
		// Torque Test 9
		TORQUE = 12'h000;
		run_test(0);
		
		// Torque Test 10
		TORQUE = 12'h400;
		run_test(1);



		// Increment the setting and run the tests again
		fork
			wait_error();
			inc_setting(1);
		join
		
	end

	$display();	//different tests (and expected results) for setting 0
	$display("Setting: %d", iDUT.setting);

	$display("YAW_TESTS:");
	test_number = 0;
	// Test Bench for 0
	// Set up Yaw Test
	fork 
		inc_yaw(1);
		wait_error();
	join 
	
	// Yaw Test 1
	fork
		inc_yaw(0);
		run_test(0);
	join
	
	// Yaw Test 2
	fork
		inc_yaw(-1);
		run_test(0);
	join

	// Yaw Test 3
	fork
		inc_yaw(-1);
		run_test(0);
	join

	// Yaw Test 4
	fork
		inc_yaw(1);
		run_test(0);
	join
	
	// Yaw Test 5
	fork
		inc_yaw(0);
		run_test(0);
	join
		

	$display("CADENCE_TESTS:");
	test_number = 0;
		
	// Cadence Test 1
	CADENCE_PER = 4096;
	run_test(0);
		
	// Cadence Test 2
	CADENCE_PER = 20000;
	run_test(0);
		
	// Cadence Test 3
	CADENCE_PER = 500;
	run_test(0);
		
	// Cadence Test 4
	CADENCE_PER = 20000;
	run_test(0);


	$display("TORQUE_TESTS:");
	test_number = 0;
	// Torque Test 1
	TORQUE = 12'h400;
	run_test(0);
		
	// Torque Test 2
	TORQUE = 12'h200;
	run_test(0);
		
	// Torque Test 3
	TORQUE = 12'h4ff;
	run_test(0);
	
	// Torque Test 4
	TORQUE = 12'h360;
	run_test(0);
		
	// Torque Test 5
	TORQUE = 12'h400;
	run_test(0);

	end_simulation();

end

task brake_test;
	input logic over_thresh;
	begin
	test_number++;
		if(over_thresh^iDUT.brake_n==0) break_passed();
		else break_failed();
	end
endtask

task break_passed;
	begin
		$display("Test %d passed. brake_n = %d", test_number, iDUT.brake_n);
		tests_passed++;
	end
endtask

task break_failed;
	begin
		$display("Test %d FAILED. brake_n = %d", test_number, iDUT.brake_n);
		tests_failed++;
	end
endtask

task inc_setting;
	input int how_many; // how many settings to increase (loops 3 -> 0) reset @ 2
	begin
		repeat(how_many) begin
		@(posedge clk);
		tgglMd = 0;
		@(posedge clk);
		tgglMd = 1;
		@(posedge clk);
		end
	end
endtask

task inc_yaw;	//ran in parallel with a test, holds YAW_RT high for 1 million clk cycles.
	input int expected_direction;
	begin
		if(expected_direction==1) YAW_RT = 16'h2000;
		else if(expected_direction == -1) YAW_RT = 16'he000;
		else YAW_RT = 16'h0000;
		repeat(1000000) begin
			@(posedge clk);
		end
		YAW_RT = 16'h0000;
	end
endtask

  
task run_batt;
	input logic over_threshold; //1==batt over thresh; 0==batt under thresh
	begin
		test_number++;
		wait_error();
		if((iDUT.senseCndt.error==0)^over_threshold) batt_test_passed();
		else batt_test_failed();
		//omega = 0;
	end
endtask

task batt_test_passed;
	begin
		$display("Test %d passed. Error = %d", test_number, iDUT.senseCndt.error);
		tests_passed++;
	end
endtask

task batt_test_failed;
	begin
		$display("Test %d FAILED. Error = %d", test_number, iDUT.senseCndt.error);
		tests_passed++;
	end
endtask
   
task run_test;
  input int expected_omega_change_direction;	//-1 for decrease; 1 for increase; 0 for stay the same (see no_change_range)
	begin
		test_number++;
		prevOmega = iPHYS.omega;
		wait_error();
		omega = iPHYS.omega;
		case(expected_omega_change_direction)
			1: begin 
				if(omega > prevOmega + no_change_range) test_passed();
				else test_failed();
			end
			0: begin
				if(omega < prevOmega + no_change_range && omega > prevOmega - no_change_range) test_passed();
				else test_failed();
			end
			-1: begin
				if(omega < prevOmega - no_change_range) test_passed();
				else test_failed();
			end
		endcase
	end
  endtask
	
	
	
	task end_simulation;
		begin
			if(tests_failed==0) $display("ALL TESTS PASSED!!!");
			else begin 
				$display("%d tests passed. %d tests failed.", tests_passed, tests_failed);
				$display("TEST FINISHED.");
			end
			$stop();
		end
	endtask
	
	task test_passed;
		begin
			dOmega = omega - prevOmega;
			$display("Test %d passed. omega = %d; dOmega = %d", test_number, omega, dOmega);
			tests_passed++;
		end
	endtask
	
	task test_failed;
		begin
			dOmega = omega - prevOmega;
			$display("Test %d FAILED. omega = %d; dOmega = %d", test_number, omega, dOmega);
			tests_failed++;
		end
	endtask
  
  task wait_error;
	begin	//front porch (error will not respond immediately to stimulus
		repeat(512*4096 / CADENCE_PER) begin
			cadence = 1;
			repeat(CADENCE_PER/2) @(posedge clk);
			cadence = 0;
			repeat(CADENCE_PER/2) @(posedge clk);
		end	//after front porch, wait for error to get within error_limit of 0. 
		while(iDUT.senseCndt.error > error_limit || iDUT.senseCndt.error < -error_limit) begin
			cadence = 1;
			repeat(CADENCE_PER/2) @(posedge clk);
			cadence = 0;
			repeat(CADENCE_PER/2) @(posedge clk);
		end
	end

  endtask
  
  always 
    #5 clk = ~clk;
  

	
endmodule
