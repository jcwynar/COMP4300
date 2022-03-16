use work.dlx_types.all;
use work.bv_arithmetic.all;

------------------------------------------------------------
-- Define entity "reg_file"                               --
-- Using a 32-bit datapath                                --
------------------------------------------------------------
entity dlx_register is
	generic(prop_delay : Time := 10 ns);
	port(in_val : in dlx_word;
	     clock : in bit;
	     out_val: out dlx_word
	);
end entity dlx_register;

----------------------------------------
-- Define architecture "dlx_register" --
----------------------------------------
architecture behavior of dlx_register is

begin
	dlx_reg_process: process(in_val, clock) is
	
	begin
		-- start process
		if (clock = '1') then
			out_val <= in_val after prop_delay;
		end if;
	end process dlx_reg_process;
end architecture behavior;
