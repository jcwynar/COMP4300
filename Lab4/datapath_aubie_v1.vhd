-- datapath_aubie.vhd

-- entity reg_file (lab 3)
use work.dlx_types.all; 
use work.bv_arithmetic.all;  

entity reg_file is
	generic(prop_delay: Time := 5 ns);
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

-- entity alu (lab 2) 
use work.dlx_types.all; 
use work.bv_arithmetic.all; 

entity alu is 
     generic(prop_delay : Time := 5 ns);
     port(operand1, operand2: in dlx_word; operation: in alu_operation_code; 
          result: out dlx_word; error: out error_code); 
end entity alu; 

-- alu_operation_code values
-- 0000 unsigned add
-- 0001 signed add
-- 0010 2's compl add
-- 0011 2's compl sub
-- 0100 2's compl mul
-- 0101 2's compl divide
-- 0110 logical and
-- 0111 bitwise and
-- 1000 logical or
-- 1001 bitwise or
-- 1010 logical not (op1) 
-- 1011 bitwise not (op1)
-- 1100-1111 output all zeros

-- error code values
-- 0000 = no error
-- 0001 = overflow (too big positive) 
-- 0010 = underflow (too small neagative) 
-- 0011 = divide by zero

architecture behavior of alu is
begin
	alu_process: process(operand1, operand2, operation) is
	-- local variables
	variable temp_result: dlx_word := x"00000000";
	variable logical_true: dlx_word := x"00000001";
	variable logical_false: dlx_word := x"00000000";
	variable overflow: boolean;
	variable div_by_zero: boolean;
	variable op1_logical: bit; -- 0 means false; 1 means true
	variable op2_logical: bit; -- 0 means false; 1 means true
     
	begin
	    error <= "0000"; -- default value for port singal output error
	    case(operation) is
		when "0000" => -- unsigned add
		    bv_addu(operand1, operand2, temp_result, overflow);
		    if overflow then
			error <= "0001";
		    end if;
		    result <= temp_result after prop_delay;
		when "0001" => -- unsigned subtract
		    bv_subu(operand1, operand2, temp_result, overflow);
		    if overflow then
			error <= "0010";
			-- unsigned sub is only concerned with underflow
		    end if;
		    result <= temp_result after prop_delay;
		when "0010" => -- two's complement add
		    bv_add(operand1, operand2, temp_result, overflow);
		    if overflow then
			-- if (+A) + (+B) = -C
			if (operand1(31) = '0') AND (operand2(31) = '0') then
			    if (temp_result(31) = '1') then
				error <= "0001"; -- overflow
			    end if;
			-- if (-A) + (-B) = +C
			elsif (operand1(31) = '1') AND (operand2(31) = '1') then
			    if (temp_result(31) = '0') then
				error <= "0010"; -- underflow
			    end if;
			end if;
		    end if;
		    result <= temp_result after prop_delay;
		when "0011" => -- two's complement subtract
		    bv_sub(operand1, operand2, temp_result, overflow);
		    if overflow then
			-- if (-A) - (+B) = +C
			if (operand1(31) = '1') AND (operand2(31) = '0') then
			    if (temp_result(31) = '0') then
				error <= "0010"; -- underflow
			    end if;
			-- if (+A) - (-B) = -C
			elsif (operand1(31) = '0') AND (operand2(31) = '1') then
			    if (temp_result(31) = '1') then
				error <= "0001"; -- underflow
			    end if;
			end if;
		    end if;
		    result <= temp_result after prop_delay;
		when "0100" => -- two's complement multiply
		    bv_mult(operand1, operand2, temp_result, overflow);
		    if overflow then
			if (operand1(31) = '1') AND (operand2(31) = '0') then -- (-A x +B) = +C
			    error <= "0010"; --- underflow
			elsif (operand1(31) = '0') AND (operand2(31) = '1') then -- (+A x -B) = +C
			    error <= "0010"; -- underflow
			else -- (+A x +B) = -C OR (-A x -B) = -C
			    error <= "0001"; -- overflow
			end if;
		    end if;
		    result <= temp_result after prop_delay;
		when "0101" => -- two's complement divide
		    bv_div(operand1, operand2, temp_result, div_by_zero, overflow);
		    if div_by_zero then
			error <= "0011";
		    elsif overflow then
			error <= "0010"; -- underflow if divisor is much smaller
		    end if;
		    result <= temp_result after prop_delay;
		when "0110" => -- logical AND
		    op1_logical := '0';
		    op2_logical := '0';
		    -- check if operand1 is non-zero --
		    for i in 31 downto 0 loop
			-- if non-zero, operand1 is logical true
			if (operand1(i) = '1') then
			    op1_logical := '1';
			    exit;
			end if;
		    end loop;
		    -- check if operand2 is non-zero
		    for i in 31 downto 0 loop
			-- if non-zero, operand2 is logical true
			if (operand2(i) = '1') then
			    op2_logical := '1';
			    exit;
			end if;
		    end loop;
		    -- if operands result in --> '1' && '1' = '1'
		    if ((op1_logical AND op2_logical) = '1') then
			result <= logical_true after prop_delay; -- result is logical true x"00000001"
		    else
			result <= logical_false after prop_delay; -- result is logical false x"00000000"
		    end if;
		when "0111" => -- bitwise AND
		    for i in 31 downto 0 loop
			temp_result(i) := operand1(i) AND operand2(i);
		    end loop;
		    result <= temp_result after prop_delay;
		when "1000" => -- logical OR
		    op1_logical := '0';
		    op2_logical := '0';
		    -- check if operand1 is non-zero --
		    for i in 31 downto 0 loop
			-- if non-zero, operand1 is logical true
			if (operand1(i) = '1') then
			    op1_logical := '1';
			    exit;
			end if;
		    end loop;
		    -- check if operand2 is non-zero
		    for i in 31 downto 0 loop
			-- if non-zero, operand2 is logical true
			if (operand2(i) = '1') then
			    op2_logical := '1';
			    exit;
			end if;
		    end loop;
		    -- if operands result in --> ('1'||'1' OR '1'||'0' OR '0'||'1') = '1'
		    if ((op1_logical OR op2_logical) = '1') then
			result <= logical_true after prop_delay; -- result is logical true x"00000001"
		    else
			result <= logical_false after prop_delay; -- result is logical false x"00000000"
		    end if;
		when "1001" => -- bitwise OR
		    for i in 31 downto 0 loop
			temp_result(i) := operand1(i) OR operand2(i);
		    end loop;
		    result <= temp_result after prop_delay;
		when "1010" => -- logical NOT of operand1 (ignore operand2)
		    temp_result := logical_true; -- initial assignment to true
		    for i in 31 downto 0 loop
			if (NOT operand1(i) = '0') then -- e.g., if operand1 is non-zero
			    temp_result := logical_false; -- logical NOT resulted in false; therefore, NOT(operand1) = false
			    exit;
			end if;
		    end loop;
		    result <= temp_result after prop_delay;
		when "1011" => -- bitwise NOT of operand1 (ignore operand2)
		    for i in 31 downto 0 loop
			temp_result(i) := NOT operand1(i);
		    end loop;
		    result <= temp_result after prop_delay;
		when others => -- 1100 through 1111, output all zeroes
		    result <= x"00000000" after prop_delay;
	    end case;
	end process alu_process;
end architecture behavior;

-- entity dlx_register (lab 3)
use work.dlx_types.all; 

entity dlx_register is
	generic(prop_delay : Time := 5 ns);
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

-- entity pcplusone
use work.dlx_types.all;
use work.bv_arithmetic.all; 

entity pcplusone is
	generic(prop_delay: Time := 5 ns); 
	port (input: in dlx_word; clock: in bit;  output: out dlx_word); 
end entity pcplusone; 

architecture behavior of pcplusone is 
begin
	plusone: process(input,clock) is  -- add clock input to make it execute
		variable newpc: dlx_word;
		variable error: boolean; 
	begin
	   if clock'event and clock = '1' then
	  	bv_addu(input,"00000000000000000000000000000001",newpc,error);
		output <= newpc after prop_delay; 
	  end if; 
	end process plusone; 
end architecture behavior; 


-- entity mux
use work.dlx_types.all; 

entity mux is
     generic(prop_delay : Time := 5 ns);
     port (input_1,input_0 : in dlx_word; which: in bit; output: out dlx_word);
end entity mux;

architecture behavior of mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = '1') then
         output <= input_1 after prop_delay;
      else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux

-- entity threeway_mux 
use work.dlx_types.all; 

entity threeway_mux is
     generic(prop_delay : Time := 5 ns);
     port (input_2,input_1,input_0 : in dlx_word; which: in threeway_muxcode; output: out dlx_word);
end entity threeway_mux;

architecture behavior of threeway_mux is
begin
   muxProcess : process(input_1, input_0, which) is
   begin
      if (which = "10" or which = "11" ) then
         output <= input_2 after prop_delay;
      elsif (which = "01") then 
	 output <= input_1 after prop_delay; 
       else
         output <= input_0 after prop_delay;
      end if;
   end process muxProcess;
end architecture behavior;
-- end entity mux

  
-- entity memory
use work.dlx_types.all;
use work.bv_arithmetic.all;

entity memory is
  
  port (
    address : in dlx_word;
    readnotwrite: in bit; 
    data_out : out dlx_word;
    data_in: in dlx_word; 
    clock: in bit); 
end memory;

architecture behavior of memory is

begin  -- behavior

  mem_behav: process(address,clock) is
    -- note that there is storage only for the first 1k of the memory, to speed
    -- up the simulation
    type memtype is array (0 to 1024) of dlx_word;
    variable data_memory : memtype;
  begin
    -- fill this in by hand to put some values in there
    -- some instructions
    data_memory(0) :=  X"30200000"; --LD R4, 0x100 = 256
    data_memory(1) :=  X"00000100"; -- address 0x100 for previous instruction
    -- R4 - Contents of mem addr x100 = x"5500FF00"

    data_memory(2) := X"30080000"; -- LD R1, 0x101 = 257
    data_memory(3) := X"00000101"; -- address 0x101 for previous instruction
    -- R1 = Contents of mem addr x101 = x"AA00FF00"

    data_memory(4) := X"30100000"; -- LD R2, 0x102 = 258
    data_memory(5) := X"00000102"; -- address 0x102 for previous instruction
    -- R2 = Contents of mem addr x102 = x"00000001"

    data_memory(6) :=  "00000000000110000100010000000000"; -- ADDU R3,R1,R2
    -- R3 = Contents of (R1 + R2) = x"AA00FF01"

    data_memory(7) := "00100000000000001100000000000000"; -- STO R3, 0x103
    data_memory(8) := x"00000103"; -- address 0x103 for previous instruction
    -- mem addr x"103" = data_memory(259) := contents of R3 = x"AA00FF01"

    data_memory(9) := "00110001000000000000000000000000"; -- LDI R0, 0x104
    data_memory(10) := x"00000104"; -- Imm value 0x104 for previous instruction
    -- Contents of R0 = x"00000104"

    data_memory(11) := "00100010000000001100000000000000"; -- STOR (R0), R3
    -- Contents of mem addr specified by R0 (x104 = 260) = Contents of R3 = x"AA00FF01"

    data_memory(12) := "00110010001010000000000000000000"; -- LDR R5, (R0)
    -- Contents of R5 = Contents specified by mem addr[contents of R0] = x"AA00FF01"

    data_memory(13) := x"40000000"; -- JMP to 261 = x"105"
    data_memory(14) := x"00000105"; -- Address to jump to for previous instruction
    -- JMP to mem addr x"105" is an Add op --> ADDU R11, R1 R2 => Contents of R11 = x"AA00FF01"

    -- note that this code runs every time an input signal to memory changes, 
    -- so for testing, write to some other locations besides these
    data_memory(256) := "01010101000000001111111100000000";
    data_memory(257) := "10101010000000001111111100000000";
    data_memory(258) := "00000000000000000000000000000001";

    -- we jumped here from Addr 14 = x"0000000E"
    data_memory(261) := x"00584400"; -- ADDU R11,R1,R2

    data_memory(262) := x"4101C000"; -- JZ R7, 267 = x"10B" -- If R7 == 0, GOTO Addr 267
    data_memory(263) := x"0000010B"; -- Address to jump to for previous instruction
    -- JZ to mem addr x"10B" is an Add op --> ADDU R12, R1 R2 => Contents of R12 = x"AA00FF01"

    -- we jumped here from addr 263 = x"00000107"
    data_memory(267) := x"00604400"; -- ADDU R12, R1 R2

    data_memory(268) := x"10000000"; -- NOOP

    if clock = '1' then
      if readnotwrite = '1' then
        -- do a read
        data_out <= data_memory(bv_to_natural(address)) after 5 ns;
      else
        -- do a write
        data_memory(bv_to_natural(address)) := data_in; 
      end if;
    end if;

  end process mem_behav; 

end behavior;
-- end entity memory


