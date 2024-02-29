library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity id_forward_unit is
  Port (
  
        curr_RegRs: in STD_LOGIC_VECTOR (2 downto 0);
        curr_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        EX_MEM_RegWrite: in STD_LOGIC;
        EX_MEM_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        
        branch_instruction: in STD_LOGIC;
        --MEM_WB_regWrite: in STD_LOGIC;
        --MEM_WB_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        forward_A: out STD_LOGIC;
        forward_B: out STD_LOGIC
   );
end id_forward_unit;

architecture Behavioral of id_forward_unit is

begin

    process_forward_A_B: process(curr_RegRs, curr_RegRt, EX_MEM_RegWrite, EX_MEM_RegDst, branch_instruction)
    begin
        forward_A <= '0';
        forward_B <= '0';
    
        -- Check if forwarding for source register is needed based on conditions:
        -- 1. EX/MEM stage is writing to a register (EX_MEM_RegWrite = '1')
        -- 2. It is a branch instruction (branch_instruction = '1')
        -- 3. Destination of EX/MEM matches the source register (EX_MEM_RegDst = ID_EX_RegRs)
        
        if ((EX_MEM_RegWrite = '1') and (branch_instruction = '1') and (EX_MEM_RegDst = curr_RegRs)) then
            forward_A <= '1';   -- Set forwarding signal for source register
        end if;


        -- Check if forwarding for target register is needed based on conditions:
        -- 1. EX/MEM stage is writing to a register (EX_MEM_RegWrite = '1')
        -- 2. It is a branch instruction (branch_instruction = '1')
        -- 3. Destination of EX/MEM matches the target register (EX_MEM_RegDst = ID_EX_RegRt)
        
        if((EX_MEM_RegWrite = '1') and (branch_instruction = '1') and (EX_MEM_RegDst = curr_RegRt)) then
            forward_B <= '1';   -- Set forwarding signal for target register
        end if;
        
    end process;
end Behavioral;
