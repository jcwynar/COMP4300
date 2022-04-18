
use work.bv_arithmetic.all; 
use work.dlx_types.all; 

entity aubie_controller is
	generic(
		prop_delay : Time := 5 ns;
		ext_prop_delay : Time := 15 ns -- entended delay for allowing other signals to propagate first
	);
	port(ir_control: in dlx_word;
	     alu_out: in dlx_word; 
	     alu_error: in error_code; 
	     clock: in bit; 
	     regfilein_mux: out threeway_muxcode; 
	     memaddr_mux: out threeway_muxcode; 
	     addr_mux: out bit; 
	     pc_mux: out threeway_muxcode; 
	     alu_func: out alu_operation_code; 
	     regfile_index: out register_index;
	     regfile_readnotwrite: out bit; 
	     regfile_clk: out bit;   
	     mem_clk: out bit;
	     mem_readnotwrite: out bit;  
	     ir_clk: out bit; 
	     imm_clk: out bit; 
	     addr_clk: out bit;  
             pc_clk: out bit; 
	     op1_clk: out bit; 
	     op2_clk: out bit; 
	     result_clk: out bit
	     ); 
end aubie_controller; 

architecture behavior of aubie_controller is
begin
	behav: process(clock) is 
		type state_type is range 1 to 20; 
		variable state: state_type := 1; 
		variable opcode: byte; 
		variable destination,operand1,operand2 : register_index;
		variable stor_op : alu_operation_code := "0111";
		variable jz_op : alu_operation_code := "1100";
		variable logical_true : dlx_word := x"00000001";
		variable logical_false : dlx_word := x"00000000";

	begin
		if (clock'event and clock = '1') then
		   opcode := ir_control(31 downto 24);
		   destination := ir_control(23 downto 19);
		   operand1 := ir_control(18 downto 14);
		   operand2 := ir_control(13 downto 9); 
		   case (state) is
			when 1 => -- fetch the instruction, for all types
				-- Load the 32-bit memory word stored at the address in the PC to the Instruction Register
				-- mem[PC] --> IR
				memaddr_mux <= "00" after prop_delay;
				regfile_clk <= '0' after prop_delay;
				mem_clk <= '1' after prop_delay; -- high so we can output mem_out
				mem_readnotwrite <= '1' after prop_delay; -- in state 1, we want to read from memory and ignore data_in
				ir_clk <= '1' after prop_delay; -- high so IR can receive signals from memory
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				addr_mux <= '1' after prop_delay;
				pc_clk <= '0' after prop_delay; -- Low so PC will output current address it contains -- initially zero
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;

				state := 2; 
			when 2 =>  
				-- figure out which instruction
			 	if opcode(7 downto 4) = "0000" then -- ALU op
					state := 3; 
				elsif opcode = X"20" then  -- STO 
					state := 9;
				elsif opcode = X"30" or opcode = X"31" then -- LD or LDI
					state := 7;
				elsif opcode = X"22" then -- STOR
					state := 14;
				elsif opcode = X"32" then -- LDR
					state := 12;
				elsif opcode = X"40" or opcode = X"41" then -- JMP or JZ
					state := 16;
				elsif opcode = X"10" then -- NOOP
					state := 19;
				else -- error
				end if; 
			when 3 => -- ALU op (Step 1):  load op1 register from the regfile
				regfile_index <= operand1 after prop_delay;
				-- high b/c we are doing a read op
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '1' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 4; 
			when 4 => -- ALU op (Step 2): load op2 register from the regfile
				regfile_index <= operand2 after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '1' after prop_delay;
				result_clk <= '0' after prop_delay;
         			state := 5; 
			when 5 => -- ALU op (Step 3): perform ALU operation (copy ALU ouptut into result register)
				alu_func <= opcode(3 downto 0) after prop_delay;
				regfile_clk <= '0' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '1' after prop_delay; -- put ALU operation value in result register
            			state := 6; 
			when 6 => -- ALU op (Step 4): write back ALU operation
				regfilein_mux <= "00" after prop_delay;
				pc_mux <= "00" after prop_delay; -- pcplusone_out
				regfile_index <= destination after prop_delay;
				regfile_readnotwrite <= '0' after prop_delay; -- Write back destination
				regfile_clk <= '1' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				pc_clk <= '1' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
            			state := 1; 
			when 7 => -- LD or LDI (Step 1): get the addr or immediate word
			   	if (opcode = x"30") then -- LD
				-- load contents of address to register destination
				-- Increment PC; copy memory specified by PC into address register
				-- PC -> PC+1; Mem[PC}] --> Addr
					pc_clk <= '1' after prop_delay;
					pc_mux <= "00" after prop_delay;
					memaddr_mux <= "00" after prop_delay;
					addr_mux <= '1' after prop_delay;
					regfile_clk <= '0' after prop_delay;
					mem_clk <= '1' after prop_delay;
					mem_readnotwrite <= '1' after prop_delay;
					ir_clk <= '0' after prop_delay;
					imm_clk <= '0' after prop_delay;
					addr_clk <= '1' after prop_delay;
					op1_clk <= '0' after prop_delay;
					op2_clk <= '0' after prop_delay;
					result_clk <= '0' after prop_delay;
				elsif (opcode = x"31") then -- LDI
				-- load immediate value into register destination
				-- increment PC; copy memory specified by PC into immediate register
				-- PC -> PC+1; Mem[PC] --> Immed
					pc_clk <= '1' after prop_delay;
					pc_mux <= "00" after prop_delay;
					memaddr_mux <= "00" after prop_delay;
					regfile_clk <= '0' after prop_delay;
					mem_clk <= '1' after prop_delay;
					mem_readnotwrite <= '1' after prop_delay;
					ir_clk <= '0' after prop_delay;
					imm_clk <= '1' after prop_delay;
					addr_clk <= '0' after prop_delay;
					op1_clk <= '0' after prop_delay;
					op2_clk <= '0' after prop_delay;
					result_clk <= '0' after prop_delay;
				end if;
				state := 8; 
			when 8 => -- LD or LDI (step 2)
				if (opcode = x"30") then -- LD
				-- Copy mem location specified by address to the dest register; increment PC
				-- Mem[Addr] --> Regs[IR[dest]]; PC --> PC+1
					regfilein_mux <= "01" after prop_delay; -- mux selector for memory out
					memaddr_mux <= "01" after prop_delay;
					regfile_index <= destination after prop_delay;
					regfile_readnotwrite <= '0' after prop_delay;
					regfile_clk <= '1' after prop_delay;
					mem_clk <= '1' after prop_delay;
					mem_readnotwrite <= '1' after prop_delay;
					ir_clk <= '0' after prop_delay;
					imm_clk <= '0' after prop_delay;
					addr_clk <= '0' after prop_delay; -- addr clock should retain its old value
					op1_clk <= '0' after prop_delay;
					op2_clk <= '0' after prop_delay;
					result_clk <= '0' after prop_delay;
					pc_clk <= '0' after prop_delay, '1' after ext_prop_delay;
					pc_mux <= "00" after ext_prop_delay;
					-- NOTE: We don't want to increment PC until after other values are propagated b/c we want to read from address register first
				elsif (opcode = x"31") then -- LDI
				-- Copy immediate register into dest register; increment PC
				-- Immed --> Regs[IR[dest]]; PC --> PC+1
					regfilein_mux <= "10" after prop_delay; -- mux selector for memory out
					regfile_index <= destination after prop_delay;
					regfile_readnotwrite <= '0' after prop_delay;
					regfile_clk <= '1' after prop_delay;
					mem_clk <= '0' after prop_delay;
					ir_clk <= '0' after prop_delay;
					imm_clk <= '1' after prop_delay;
					addr_clk <= '0' after prop_delay;
					op1_clk <= '0' after prop_delay;
					op2_clk <= '0' after prop_delay;
					result_clk <= '0' after prop_delay;
					pc_clk <= '0' after prop_delay, '1' after ext_prop_delay;
					pc_mux <= "00" after ext_prop_delay;
				end if;
        			state := 1;
			when 9 => -- STO (Step 1): Store contents of register op1 specified by address word 2
			-- Increment PC
				pc_mux <= "00" after prop_delay;
				pc_clk <='1' after prop_delay;
				state := 10;
			when 10 => -- STO (Step 2): Store contents of register op1 specified by address word 2
			-- Load memory at address given by PC to the address register: mem[PC] --> addr
				memaddr_mux <= "00" after prop_delay; -- we want mem_address specified by PC
				addr_mux <= '1' after prop_delay; -- address register needs to accept value from memory
				regfile_clk <= '0' after prop_delay;
				mem_clk <= '1' after prop_delay; -- memory unit needs to be on
				mem_readnotwrite <= '1' after prop_delay; -- reading address register
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '1' after prop_delay; -- we are writing to address register so register needs to be on
				pc_clk <= '0' after prop_delay; -- incremented in previous state, so PC should have an out value
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 11;
			when 11 => -- STO (Step 3): Store contents of register op1 specified by address word 2
			-- Store contents of src register to address in memory given by address register
			-- then increment PC; regs[IR[src]] --> mem[addr]; PC -> PC+1
				memaddr_mux <= "00" after prop_delay;
				pc_mux <= "01" after prop_delay, "00" after ext_prop_delay;
				regfile_index <= operand1 after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay; -- we are reading from register file at index operand1
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '1' after prop_delay; -- turn on memory
				mem_readnotwrite <= '0' after prop_delay; -- we want to write to memory
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay; -- turn off addr b/c e need to retain its output from state 10
				pc_clk <= '1' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 1;
			when 12 => -- LDR (Step 1): Load contents of op1 reg to address register
			-- regs[IR[op1]] --> addr
				addr_mux <= '0' after prop_delay; -- we want reg file output
				regfile_index <= operand1 after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '1' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 13;
			when 13 => -- LDR (Step 2): Load contents of op1 reg to address register
			-- mem[addr] --> regs[IR[dest]]; increment PC --> PC+1
				regfilein_mux <= "01" after prop_delay; -- mux selector for memory out
				memaddr_mux <= "01" after prop_delay; -- mux selector input_1 for addr reg output
				regfile_index <= destination after prop_delay;
				regfile_readnotwrite <= '0' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '1' after prop_delay;
				mem_readnotwrite <= '1' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				pc_clk <= '0' after prop_delay, '1' after ext_prop_delay;
				pc_mux <= "00" after ext_prop_delay;
				-- we don't want to increment PC until after other values are propagated b/c we want mux to read from addr reg first
				state := 1;
			when 14 => -- STOR (Step 1): Copy contents of dest reg into addr reg
			-- regs[IR[dest]] --> addr
				addr_mux <= '0' after prop_delay;
				regfile_index <= destination after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '1' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 15;
			when 15 => -- STOR (Step 2): Copy contents of op1 reg to mem addr specified by addr reg
			-- regs[IR[op1]] --> mem[addr]; increment PC --> PC+1
			-- for STOR to work, we need to do bitwise AND of op1 and op2 so result will be whateevr unchanged value we read from specific reg file index
				memaddr_mux <= "00" after prop_delay;
				pc_mux <= "01" after prop_delay, "00" after ext_prop_delay;
				alu_func <= stor_op after prop_delay;
				regfile_index <= operand1 after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '1' after prop_delay;
				mem_readnotwrite <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay; -- turn off addr to retain value from state 14
				pc_clk <= '1' after prop_delay;
				op1_clk <= '1' after prop_delay; -- op1 AND op2 is either value of op1 or op2
				op2_clk <= '1' after prop_delay;
				result_clk <= '1' after prop_delay;
				state := 1;
			when 16 => -- JMP or JZ (Step 1): increment PC --> PC+1
				pc_mux <= "00" after prop_delay;
				pc_clk <= '1' after prop_delay;
				state := 17;
			when 17 => -- JMP or JZ (Step 2):
			-- Load memory specified by PC to addr reg: mem[PC] --> addr
			-- Essentially same as state 7, except no need to increment PC since we did that in state 16
				pc_clk <= '0' after prop_delay;
				memaddr_mux <= "00" after prop_delay; -- mux select read from pcplusone_out
				addr_mux <= '1' after prop_delay; -- input_1 select of mem_out
				regfile_clk <= '0' after prop_delay;
				mem_clk <= '1' after prop_delay;
				mem_readnotwrite <= '1' after prop_delay; -- mem read op
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '1' after prop_delay;
				op1_clk <= '0' after prop_delay;
				op2_clk <= '0' after prop_delay;
				result_clk <= '0' after prop_delay;
				state := 18;
				if (opcode = x"40") then -- JMP
					state := 18;
				else -- JZ intermediate step to check whether or not op1 == 0
					state := 20;
				end if;
			when 18 => -- JMP or JZ (Step 3):
				if (opcode = x"40") then -- JMP
				-- load addr to PC; addr --> PC
					pc_mux <= "01" after prop_delay;
					pc_clk <= '1' after prop_delay;
				end if;
				if (opcode = x"41") then -- JZ
				-- if result == 0, copy addr to PC: addr --> PC, else increment PC --> PC+1
					if (alu_out = logical_true) then
						pc_mux <= "01" after prop_delay;
						pc_clk <= '1' after prop_delay;
					else
						pc_mux <= "00" after prop_delay;
						pc_clk <= '1' after prop_delay;
					end if;
				end if;
				state := 1;
			when 19 => -- NOOP: do nothing except increment PC
				pc_mux <= "00" after prop_delay;
				pc_clk <= '1' after prop_delay;
				state := 1;
			when 20 => -- JZ intermediate cycle
			-- copy reg op1 to control: regs[IR[op1]] --> ctl
				alu_func <= jz_op after prop_delay;
				regfile_index <= operand1 after prop_delay;
				regfile_readnotwrite <= '1' after prop_delay;
				regfile_clk <= '1' after prop_delay;
				mem_clk <= '0' after prop_delay;
				ir_clk <= '0' after prop_delay;
				imm_clk <= '0' after prop_delay;
				addr_clk <= '0' after prop_delay;
				pc_clk <= '0' after prop_delay;
				op1_clk <= '1' after prop_delay;
				op2_clk <= '1' after prop_delay;
				result_clk <= '1' after prop_delay;
				state := 18;
			when others => null;
		   end case; 
		elsif clock'event and clock = '0' then
		-- reset all register clocks
			regfile_clk <= '0' after prop_delay;
			mem_clk <= '0' after prop_delay;
			ir_clk <= '0' after prop_delay;
			imm_clk <= '0' after prop_delay;
			addr_clk <= '0' after prop_delay;
			pc_clk <= '0' after prop_delay;
			op1_clk <= '0' after prop_delay;
			op2_clk <= '0' after prop_delay;
			result_clk <= '0' after prop_delay;	
		end if; 
	end process behav;
end behavior;	