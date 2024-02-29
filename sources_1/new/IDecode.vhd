library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity IDecode is
    Port ( clk: in STD_LOGIC;
           --en : in STD_LOGIC;    
           Instr : in STD_LOGIC_VECTOR(15 downto 0);
           WD : in STD_LOGIC_VECTOR(15 downto 0);
           RegWrite : in STD_LOGIC;
           RegDstAddress : in STD_LOGIC_VECTOR(2 downto 0);
           ExtOp : in STD_LOGIC;
           RD1 : out STD_LOGIC_VECTOR(15 downto 0);
           RD2 : out STD_LOGIC_VECTOR(15 downto 0);
           Ext_Imm : out STD_LOGIC_VECTOR(15 downto 0);
           func : out STD_LOGIC_VECTOR(2 downto 0);
           sa : out STD_LOGIC;
           WriteAddress1: out STD_LOGIC_VECTOR(2 downto 0);
           WriteAddress2: out STD_LOGIC_VECTOR(2 downto 0);
           
           -- Forward Unit Signals
           EX_MEM_RegWrite: in STD_LOGIC;
           EX_MEM_RegDst: in STD_LOGIC_VECTOR(2 downto 0);
           EX_MEM_ALU_Result: in STD_LOGIC_VECTOR(15 downto 0);
           
           -- Hazard Detection Unit Signals
           ID_EX_MemRead: in STD_LOGIC;
           ID_EX_RegRt: in STD_LOGIC_VECTOR(2 downto 0);
           stall: out STD_LOGIC;
           
           -- Branch Prediction Table Signals
           ID_EX_RegWrite: in STD_LOGIC; 
           EX_address: in STD_LOGIC_VECTOR(2 downto 0);
           PCinc: in STD_LOGIC_VECTOR(15 downto 0);
           
           branch_instruction: in STD_LOGIC;
           branch_taken: out STD_LOGIC;
           BranchAddress: out STD_LOGIC_VECTOR(15 downto 0));
end IDecode;

architecture Behavioral of IDecode is

-- RegFile
type reg_array is array(0 to 7) of STD_LOGIC_VECTOR(15 downto 0);
signal reg_file : reg_array := (
    x"0000" , -- 0
    x"0001" , -- 1
    x"0002" , -- 2
    x"0003" , -- 3
    x"0004" , -- 4
    x"0005" , -- 5
    x"0006" , -- 6
others => X"0000"
);

component hazard_detection_unit is
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
end component;

component id_forward_unit is
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
end component;

signal forward_A, forward_B: STD_LOGIC;
signal Ext_Imm_aux, mux_A, mux_B, RD1_signal, RD2_signal: STD_LOGIC_VECTOR(15 downto 0);
--signal WriteAddress: STD_LOGIC_VECTOR(2 downto 0);

begin
    -- RegFile write
--    with RegDst select
--        WriteAddress <= Instr(6 downto 4) when '1', -- rd
--                        Instr(9 downto 7) when '0', -- rt
--                        (others => 'X') when others; -- unknown  

    forwarding_unit_in_ID: id_forward_unit port map(
    
        curr_RegRs => Instr(12 downto 10),
        curr_RegRt => Instr(9 downto 7),
        
        EX_MEM_RegWrite => EX_MEM_RegWrite,
        EX_MEM_RegDst => EX_MEM_RegDst,
        
        branch_instruction => branch_instruction,

        forward_A => forward_A,
        forward_B => forward_B
    );
    
    hazard_detection_unit_port_map: hazard_detection_unit port map(
    
        ID_EX_RegWrite => ID_EX_RegWrite,
        ID_EX_MemRead => ID_EX_MemRead,
        
        ID_EX_RegRt => ID_EX_RegRt,
        
        curr_RegRs => Instr(12 downto 10),
        curr_RegRt => Instr(9 downto 7),
        
        branch_instruction => branch_instruction,
        
        EX_address => EX_address,
        EX_MEM_address => EX_MEM_RegDst,

        EX_MEM_RegWrite => EX_MEM_RegWrite,
        
        stall => stall
    );
    
    process(clk)			
    begin
        -- Write to the RegFile if RegWrite is enabled
        if rising_edge(clk) then
            if RegWrite = '1' then
                reg_file(conv_integer(RegDstAddress)) <= WD;		
            end if;
        end if;
        
        -- Read from the RegFile based on the instruction's source registers
        if falling_edge(clk) then
            RD1_signal <= reg_file(conv_integer(Instr(12 downto 10))); -- rs
            RD2_signal <= reg_file(conv_integer(Instr( 9 downto 7 ))); -- rt
        
            -- If the destination register matches the RegDstAddress, update RD1 or RD2
            if (Instr(12 downto 10) = RegDstAddress) and regWrite = '1' then
                RD1_signal <= WD;
            end if;
            
            if (Instr(9 downto 7) = RegDstAddress) and regWrite = '1' then
                RD2_signal <= WD;
            end if;
        end if;
        
    end process;
    
    -- Assign RD1 and RD2 outputs
    RD1 <= RD1_signal;
    RD2 <= RD2_signal;
    
    -- Forwarding logic for operand A
    process(forward_A, EX_MEM_ALU_Result, RD1_signal)
    begin
    if forward_A = '1' then -- forward from EX/MEM AluResult
        mux_A <= EX_MEM_ALU_Result;
    else
        mux_A <= RD1_signal; -- no forwarding
    end if;		
    end process;
    
    -- Forwarding logic for operand B
    process(forward_A, EX_MEM_ALU_Result, RD2_signal, forward_B)
    begin
    if forward_B = '1' then -- forward from EX/MEM AluResult
        mux_B <= EX_MEM_ALU_Result;
    else
        mux_B <= RD2_signal; -- no forwarding
    end if;		
    end process;
    
    -- Branch Prediction Logic
    process(mux_A, mux_B, branch_instruction, Instr)
    begin
    
        if branch_instruction = '1' then
            if Instr(15 downto 13) = "100" and (not(mux_A = mux_B)) then  -- BNE instruction
                branch_taken <= '1';
            else 
                branch_taken <= '0';
            end if;
        else 
            branch_taken <= '0';   
        end if;
    
    end process;
    
    
    
    -- immediate extend
    Ext_Imm_aux(6 downto 0) <= Instr(6 downto 0); 
    Ext_Imm_aux(15 downto 7) <= x"00" & '0' when ExtOp = '0' else
        x"FF" & '1' when Instr(6) = '1' else
        x"00" & '0';

    -- Calculate Branch Address
    BranchAddress <= Ext_Imm_aux + PCinc;                            
    Ext_Imm <= Ext_Imm_aux;

    -- other outputs
    sa <= Instr(3);
    func <= Instr(2 downto 0);  
    WriteAddress1 <= Instr(9 downto 7);
    WriteAddress2 <= Instr(6 downto 4);

end Behavioral;