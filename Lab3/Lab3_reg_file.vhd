use work.dlx_types.all;
use work.bv_arithmetic.all;
------------------------------------------------------------
-- Define entity "reg_file"                               --
-- Using a 32-bit datapath                                --
------------------------------------------------------------

entity reg_file is
	generic(prop_delay: Time := 10 ns);
	port(data_in : in dlx_word; 
	     readnotwrite, clock: in bit;
	     data_out: out dlx_word; 
	     reg_number : in register_index
	);
end entity reg_file;

------------------------------------
-- Define architecture "reg_file" --
------------------------------------
architecture behavior of reg_file is
	-----------------------------------------
	-- Defining a type (acts as 'storage') --
	-- "reg_type" defines data struct for  --
	-- array of 32-bit words               --
	-----------------------------------------
	type reg_type is array (0 to 31) of dlx_word;
begin
	reg_file_process: process(readnotwrite, clock, reg_number, data_in) is
	---------------------------------------------------------------------
	-- Process accepts only input signals from our entity              --
	---------------------------------------------------------------------
		---------------------------------------------------------
		-- Variable acts as 'storage'                          --
		-- registers: implements reg_type and initializes      --
		--       the registers we will use for this process    --
		---------------------------------------------------------
		variable registers: reg_type;
	begin
		-- start process
		if (clock = '1') then
			if (readnotwrite = '1') then
				------------------------------------------
				--     [Performing 'READ' operation]    --
				-- Ignore 'data_in' and copy value      --
				-- in registers at index --> reg_number --
				-- to data_out signal                   --
				------------------------------------------
				data_out <= registers(bv_to_integer(reg_number)) after prop_delay;
			else
				---------------------------------------------
				--     [Performing 'WRITE' operation]      --
				-- Value from 'data_in' is copied into     --
				-- registers at reg index --> "reg_number' --
				---------------------------------------------
				registers(bv_to_integer(reg_number)) := data_in;
				---------------------------------------------
				-- No prop_delay applied as we don't want  --
				-- to delay variable assignment            --
				---------------------------------------------
			end if;
		end if;
	end process reg_file_process;
end architecture behavior;
