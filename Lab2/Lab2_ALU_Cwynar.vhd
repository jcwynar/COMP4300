use work.dlx_types.all;
use work.bv_arithmetic.all; 

entity alu is  
	generic(prop_delay: Time := 15 ns);
	port(operand1, operand2: in dlx_word; 
	     operation: in alu_operation_code;
	     result: out dlx_word; 
	     error: out error_code);
end entity alu;

-- ADD PROP DELAY!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
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
