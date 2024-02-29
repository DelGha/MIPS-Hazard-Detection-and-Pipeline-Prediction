library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ExecutionUnit is
    Port ( PCinc : in STD_LOGIC_VECTOR(15 downto 0); --
           RD1 : in STD_LOGIC_VECTOR(15 downto 0); -- 
           RD2 : in STD_LOGIC_VECTOR(15 downto 0); --
           Ext_Imm : in STD_LOGIC_VECTOR(15 downto 0); -- 
           func : in STD_LOGIC_VECTOR(2 downto 0); -- 
           sa : in STD_LOGIC; --
           ALUSrc : in STD_LOGIC; --
           ALUOp : in STD_LOGIC_VECTOR(2 downto 0); -- 
           --RegDst : in STD_LOGIC;
           --BranchAddress : out STD_LOGIC_VECTOR(15 downto 0);
           ALURes : out STD_LOGIC_VECTOR(15 downto 0); --
           --Zero : out STD_LOGIC;
           --MuxOut: out std_logic_vector(2 downto 0);
           --Instr: in std_logic_vector(15 downto 0);
           
           -- Forward Unit Signals
           EX_MEM_RegWrite: in std_logic;
           MEM_WB_RegWrite: in std_logic;
           
           ID_EX_RegRs: in std_logic_vector(2 downto 0);
           ID_EX_RegRt: in std_logic_vector(2 downto 0);
        
           EX_MEM_RegDst: in std_logic_vector(2 downto 0);
           MEM_WB_RegDst: in std_logic_vector(2 downto 0);
           
           EX_MEM_ALU_Result: in std_logic_vector(15 downto 0);
           MEM_WB_ALU_Result: in std_logic_vector(15 downto 0));
           
           
end ExecutionUnit;

architecture Behavioral of ExecutionUnit is

signal ALUCtrl : STD_LOGIC_VECTOR(2 downto 0);
signal Alu_Mux_Out_A, Alu_Mux_1_Out_B, Alu_Mux_2_Out_B, ALUResAux: STD_LOGIC_VECTOR(15 downto 0);
signal forward_A, forward_B: STD_LOGIC_VECTOR(1 downto 0);

-- signals we do not need
signal forward_MEM: STD_LOGIC_VECTOR(1 downto 0); 
signal EX_MEM_MemWrite, BUF_WB_RegWrite: STD_LOGIC;
signal EX_MEM_RegRt, BUF_WB_RegDst: STD_LOGIC_VECTOR(2 downto 0);

component forward_unit_ex_mem is
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
end component;

begin

    forwarding_unit: forward_unit_ex_mem port map(
    
        ID_EX_RegRs => ID_EX_RegRs, -- we use here
        ID_EX_RegRt => ID_EX_RegRt, -- we use here
        
        EX_MEM_RegWrite => EX_MEM_RegWrite, -- we use here
        EX_MEM_MemWrite => 'Z', -- not used here
        EX_MEM_RegDst => EX_MEM_RegDst, -- we use here
        EX_MEM_RegRt => "ZZZ", -- not used here
        
        MEM_WB_RegWrite => MEM_WB_RegWrite, -- we use here
        MEM_WB_RegDst => MEM_WB_RegDst, -- we use here
        
        BUF_WB_RegWrite => 'Z', -- not used here
        BUF_WB_RegDst => "ZZZ", -- not used here
        
        forward_A => forward_A, -- we use here
        forward_B => forward_B -- we use here
        --forward_MEM => "ZZ" -- not used here
    );

    -- Process for handling forwarding of operand A
    ProcessForwardA: process(forward_A, EX_MEM_ALU_Result, MEM_WB_ALU_Result, RD1)
    begin
        case forward_A is
            when "00" => Alu_Mux_Out_A <= RD1; -- No forwarding
            when "01" => Alu_Mux_Out_A <= EX_MEM_ALU_Result; -- Forward from EX/MEM pipeline
            when "10" => Alu_Mux_Out_A <= MEM_WB_ALU_Result; -- Forward from MEM/WB pipeline
            when others => Alu_Mux_Out_A <= RD1; -- No forwarding
        end case;
    end process;
    
    -- Process for handling forwarding of operand B
    ProcessForwardB: process(forward_B, EX_MEM_ALU_Result, MEM_WB_ALU_Result, RD2)
    begin
        case forward_B is
            when "00" => Alu_Mux_1_Out_B <= RD2; -- No forwarding
            when "01" => Alu_Mux_1_Out_B <= EX_MEM_ALU_Result; -- Forward from EX/MEM pipeline
            when "10" => Alu_Mux_1_Out_B <= MEM_WB_ALU_Result; -- Forward from MEM/WB pipeline
            when others => Alu_Mux_1_Out_B <= RD2; -- No forwarding
        end case;
    end process;

    -- MUX for ALU input 2
    with ALUSrc select
        Alu_Mux_2_Out_B <= Alu_Mux_1_Out_B when '0', 
	              Ext_Imm when '1',
	              (others => 'X') when others;
			  
    -- ALU Control
    process(ALUOp, func)
    begin
        case ALUOp is
            when "000" => -- R type 
                case func is
                    when "000" => ALUCtrl <= "000"; -- ADD
                    when "001" => ALUCtrl <= "001"; -- SUB
                    when "010" => ALUCtrl <= "010"; -- SLL
                    when "011" => ALUCtrl <= "011"; -- SRL
                    when "100" => ALUCtrl <= "100"; -- AND
                    when "101" => ALUCtrl <= "101"; -- OR
                    when "110" => ALUCtrl <= "110"; -- XOR
                    when "111" => ALUCtrl <= "111"; -- NOOP
                    when others => ALUCtrl <= (others => 'X'); -- unknown
                end case;
            when "001" => AluCtrl <= "000"; -- ADDI -- ASTA E OKE
            when "010" => AluCtrl <= "000"; -- LW
            when "011" => AluCtrl <= "000"; -- SW
            when "100" => AluCtrl <= "111"; -- BEQ - incercam BNEQ
            when "101" => AluCtrl <= "100"; -- ANDi
            when "110" => AluCtrl <= "101"; -- ORi
            when "111" => AluCtrl <= "111"; -- J
            when others => ALUCtrl <= (others => 'X'); -- unknown
        end case;
    end process;

    -- ALU operation
    process(ALUCtrl, Alu_Mux_Out_A, Alu_Mux_2_Out_B, sa, ALUResAux)
    begin
        case ALUCtrl  is
            when "000" => -- ADD
                ALUResAux <= Alu_Mux_Out_A + Alu_Mux_2_Out_B;
            when "001" =>  -- SUB
                ALUResAux <= Alu_Mux_Out_A - Alu_Mux_2_Out_B;                                  
            when "010" => -- SLL
                case sa is
                    when '1' => ALUResAux <= Alu_Mux_Out_A(14 downto 0) & '0';
                    when '0' => ALUResAux <= Alu_Mux_Out_A;
                    when others => ALUResAux <= (others => 'X');
                 end case;
            when "011" => -- SRL
                case sa is
                    when '1' => ALUResAux <= '0' & Alu_Mux_Out_A(15 downto 1);
                    when '0' => ALUResAux <= Alu_Mux_Out_A;
                    when others => ALUResAux <= (others => 'X');
                end case;
            when "100" => -- AND
                ALUResAux<= Alu_Mux_Out_A and Alu_Mux_2_Out_B;		
            when "101" => -- OR
                ALUResAux<= Alu_Mux_Out_A or Alu_Mux_2_Out_B; 
            when "110" => -- XOR
                ALUResAux<= Alu_Mux_Out_A xor Alu_Mux_2_Out_B;		
--            when "111" => -- SLT
--                if signed(RD1) < signed(ALUIn2) then
--                    ALUResAux <= X"0001";
--                else 
--                    ALUResAux <= X"0000";
--                end if;
            when "111" => ALUResAux <= Alu_Mux_Out_A; -- NOOP
            when others => -- unknown
                ALUResAux <= (others => 'X');              
        end case;

        -- zero detector
--        case ALUResAux is
--            when X"0000" => Zero <= '1';
--            when others => Zero <= '0';
--        end case;
    
    end process;

    -- ALU result
    ALURes <= ALUResAux;

    -- generate branch address
    --BranchAddress <= PCinc + Ext_Imm;

end Behavioral;