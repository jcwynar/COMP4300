-- Used following sources to learn how to make testbench files
-- https://fpgatutorial.com/how-to-write-a-basic-testbench-using-vhdl/
-- https://vhdlguide.readthedocs.io/en/latest/vhdl/testbench.html

use work.bv_arithmetic.all;
use work.dlx_types.all;

------------------------------------
-- Testbench file for reg_file    --
------------------------------------
entity reg_file_tb is
end reg_file_tb;

architecture test of reg_file_tb is

	component reg_file is
		generic(prop_delay: Time := 10 ns);
		port(clock: in bit;
		     readnotwrite: in bit;
		     reg_number: in register_index;
		     data_in: in dlx_word;
		     data_out: out dlx_word
		);
	end component reg_file;

	-- Inputs --
	signal clock : bit := '0';
	signal readnotwrite : bit := '0';
	signal reg_number : register_index := "00000";
	signal data_in : dlx_word := x"00000000";

	-- Outputs --
	signal data_out : dlx_word;

	-- interval between signal changes
	constant TIME_DELTA : Time := 20 ns;

	-- Convertting single binary bit to string format for assertion of output --
	type T_bit_map is array(bit) of character;
	constant C_BIT_MAP: T_bit_map := ('0', '1');

	type reg_type is array (0 to 31) of dlx_word;

begin
	-- Instantiate Unit Under Test (UUT)
	uut: reg_file
		port map (
			clock => clock,
			readnotwrite => readnotwrite,
			reg_number => reg_number,
			data_in => data_in,
			data_out => data_out
		);

		-- Stimuli (Lines 52-61) --
		clock <= '1', '0' after 140 ns;
		readnotwrite <= '0', '1' after 30 ns, '0' after 60 ns, '1' after 90 ns, '0' after 120 ns, '0' after 170 ns;

		----------------------------------------------------------------------------------------------------------------------------
		-- For the sake of showing data_out undergoing modification during simulation, we will use the same register index value. --
		-- However, the line denoted with (*) can be used if we want to demonstrate new register indices being written to.        --
		----------------------------------------------------------------------------------------------------------------------------
		reg_number <= "00000";
		-- (*) reg_number <= "00000", "00000" after 30 ns, "00000" after 60 ns, "00000" after 90 ns, "00000" after 120 ns, "00000" after 170 ns;
		data_in <= x"11111111", x"22222222" after 30 ns, x"33333333" after 60 ns, x"44444444" after 90 ns, x"55555555" after 120 ns, x"00000000" after 170 ns;

	-- Testing
	stimulus_process: process

	begin
		-- Check UUT response
		wait for 170 ns; -- Let all input signals propagate
	  wait;
	end process;
end test;
