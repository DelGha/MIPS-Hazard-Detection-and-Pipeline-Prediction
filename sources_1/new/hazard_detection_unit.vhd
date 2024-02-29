library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hazard_detection_unit is
    Port (
        
        ID_EX_RegWrite: in STD_LOGIC;
        ID_EX_MemRead: in STD_LOGIC;
        
        --ID_EX_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        ID_EX_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        curr_RegRs: in STD_LOGIC_VECTOR (2 downto 0);
        curr_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        branch_instruction: in STD_LOGIC;     -- Input: Signal indicating a branch instruction
        
        EX_address: in STD_LOGIC_VECTOR (2 downto 0);        -- Input: Address in the EX stage for comparison
        EX_MEM_address: in STD_LOGIC_VECTOR (2 downto 0);    -- Input: Address in the EX/MEM stage for comparison
        
        --EX_MEM_MemRead: in STD_LOGIC;
        EX_MEM_RegWrite: in STD_LOGIC;
        --EX_MEM_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        
        stall: out STD_LOGIC
                
     );
end hazard_detection_unit;

architecture Behavioral of hazard_detection_unit is

begin

--    process_data_hazard1: process(ID_EX_RegWrite, ID_EX_MemRead, ID_EX_RegDst, ID_EX_RegRt, IF_ID_RegRs, IF_ID_RegRt, branch_input)
--    begin
        
--        if(((IF_ID_RegRs = ID_EX_RegRt) OR (IF_ID_RegRt = ID_EX_RegRt)) and ID_EX_MemRead = '1') then
--            stall <= '1';               -- Disable program counter
--        else 
--            stall <= '0';               -- Enable program counter
--        end if;
--    end process;

--    process_branch1: process(ID_EX_RegWrite, ID_EX_MemRead, ID_EX_RegDst, ID_EX_RegRt, IF_ID_RegRs, IF_ID_RegRt, branch_input)
--    begin
        
--        if (((EX_MEM_RegWrite = '1') and (branch_input = '1')) and 
--        ((IF_ID_RegRt = address_in_EX_MEM) OR (IF_ID_RegRs = address_in_EX_MEM))) then
--            stall <= '1'; 
--        else 
--            stall <= '0'; 
--        end if;
--    end process;
    
--    process_branch2: process(ID_EX_RegWrite, ID_EX_MemRead, ID_EX_RegDst, ID_EX_RegRt, IF_ID_RegRs, IF_ID_RegRt, branch_input)
--    begin
        
--        if (((ID_EX_RegWrite = '1') and (branch_input = '1')) and 
--        ((IF_ID_RegRt = address_in_EX) OR (IF_ID_RegRs = address_in_EX))) then
--            stall <= '1'; 
--        else 
--            stall <= '0'; 
--        end if;
--    end process;

    process_hazard_unit: process(EX_MEM_address, EX_address, EX_MEM_RegWrite, ID_EX_RegWrite, ID_EX_MemRead, ID_EX_RegRt, curr_RegRs, curr_RegRt, branch_instruction)
    begin
        -- Default assignment of output
        stall <= '0';

        -- Detecting Load data hazards in the pipeline:
        -- Check if there is a data hazard between the ID/EX and IF/ID stages
        -- 1. If either IF/ID register source matches the destination or target registers in the ID/EX stage
        -- 2. When a memory read is needed in the ID/EX stage (ID_EX_MemRead = '1')
        if (((curr_RegRs = ID_EX_RegRt) OR (curr_RegRt = ID_EX_RegRt)) and ID_EX_MemRead = '1') then
            stall <= '1';
           
        -- Detecting branch hazards involving the EX/MEM stage and the IF/ID stage
        -- 1. If the branch_instruction signal is active (indicating a branch instruction)
        -- 2. If either IF/ID register source matches the destination or target registers in the EX/MEM stage
        elsif (((EX_MEM_RegWrite = '1') and (branch_instruction = '1')) and 
               ((curr_RegRt = EX_MEM_address) OR (curr_RegRs = EX_MEM_address))) then
            stall <= '1';
            
        -- Detecting branch hazards involving the ID/EX stage and the IF/ID stage
        -- 1. If the branch_instruction signal is active (indicating a branch instruction)
        -- 2. If either IF/ID register source matches the destination or target registers in the ID/EX stage
        elsif (((ID_EX_RegWrite = '1') and (branch_instruction = '1')) and 
               ((curr_RegRt = EX_address) OR (curr_RegRs = EX_address))) then
            stall <= '1';
        end if;
        
    end process;
    
end Behavioral;
