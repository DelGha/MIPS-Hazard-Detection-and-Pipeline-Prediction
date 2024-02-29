library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity forward_unit_ex_mem is
  Port (
        ID_EX_RegRs: in STD_LOGIC_VECTOR (2 downto 0);
        ID_EX_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        EX_MEM_RegWrite: in STD_LOGIC;
        EX_MEM_MemWrite: in STD_LOGIC;
        EX_MEM_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        EX_MEM_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
        
        MEM_WB_RegWrite: in STD_LOGIC;
        MEM_WB_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        
        BUF_WB_RegWrite: in STD_LOGIC;
        BUF_WB_RegDst: in STD_LOGIC_VECTOR (2 downto 0);
        
        forward_A: out STD_LOGIC_VECTOR(1 downto 0);    -- Output: Signals indicating forwarding for source register
        forward_B: out STD_LOGIC_VECTOR(1 downto 0);    -- Output: Signals indicating forwarding for target register
        forward_MEM: out STD_LOGIC_VECTOR (1 downto 0)  -- Output: Signals indicating forwarding for memory
   );
end forward_unit_ex_mem;

architecture Behavioral of forward_unit_ex_mem is

begin

    process_forward_in_EX: process(ID_EX_RegRs, EX_MEM_RegWrite, EX_MEM_RegDst, MEM_WB_RegWrite, MEM_WB_RegDst, ID_EX_RegRt)
    begin
        forward_A <= "00"; -- Default: No forwarding
        forward_B <= "00"; -- Default: No forwarding
        
        -- Forwarding for source register (forward_A)
        if (MEM_WB_RegWrite = '1') and (MEM_WB_RegDst = ID_EX_RegRs) then
            forward_A <= "10"; -- Forward from MEM/WB pipeline
        end if;
        if (EX_MEM_RegWrite = '1') and (EX_MEM_RegDst = ID_EX_RegRs) then
            forward_A <= "01"; -- Forward from EX/MEM pipeline
        end if;
        
        -- Forwarding for target register (forward_B)
        if (MEM_WB_RegWrite = '1') and (MEM_WB_RegDst = ID_EX_RegRt) then
            forward_B <= "10"; -- Forward from MEM/WB pipeline
        end if;
        if (EX_MEM_RegWrite = '1') and (EX_MEM_RegDst = ID_EX_RegRt) then
            forward_B <= "01"; -- Forward from EX/MEM pipeline
        end if;       
    
    end process;
    
    process_forward_MEM: process (EX_MEM_RegRt, EX_MEM_MemWrite, MEM_WB_RegDst, MEM_WB_RegWrite, BUF_WB_RegDst, BUF_WB_RegWrite)
    begin
        forward_MEM <= "00"; -- Default: No forwarding
        
        if BUF_WB_RegWrite = '1' and EX_MEM_MemWrite = '1' and EX_MEM_RegRt = BUF_WB_RegDst then
            forward_MEM <= "10";    -- -- Forwarding from the buffered WB register file
        end if;
        
        if MEM_WB_RegWrite = '1' and EX_MEM_MemWrite = '1' and EX_MEM_RegRt = MEM_WB_RegDst then
            forward_MEM <= "01";    -- Forward from MEM/WB pipeline        
        end if;   
    end process;

end Behavioral;
