library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity IFetch is
    Port (clk: in STD_LOGIC;
          rst : in STD_LOGIC;
          --en : in STD_LOGIC;
          BranchAddress : in STD_LOGIC_VECTOR(15 downto 0);
          --JumpAddress : in STD_LOGIC_VECTOR(15 downto 0);
          --Jump : in STD_LOGIC;
          --PCSrc : in STD_LOGIC;
          Instruction : out STD_LOGIC_VECTOR(15 downto 0);
          PCinc : out STD_LOGIC_VECTOR(15 downto 0);
          
          -- MISC signals
          stall: in STD_LOGIC;
          
          -- Branch History Table signals
          prev_pred: in STD_LOGIC;
          branch_instruction: in STD_LOGIC;
          branch_taken: in STD_LOGIC;
          prediction: out STD_LOGIC;
          
          prev_PC: in STD_LOGIC_VECTOR(3 downto 0);
          prev_PCinc: in STD_LOGIC_VECTOR(15 downto 0);
          curr_PC: out STD_LOGIC_VECTOR(3 downto 0);
          
          flush: in STD_LOGIC 
          );
end IFetch;

architecture Behavioral of IFetch is

-- Memorie ROM
type tROM is array (0 to 255) of STD_LOGIC_VECTOR (15 downto 0);
signal ROM : tROM := (
    -- -- --
    -- First test Program (forwarding to EX)
--    B"000_000_000_000_0_111", -- NOOP
--    B"000_100_011_010_0_001", --SUB $2 = $4 - $3
--    B"001_010_101_0000001", --ADDI $5 = $2 + 1
--    B"000_101_010_110_0_000", -- ADD $6 = $5 + $2
--    B"000_010_001_111_0_000", -- ADD $7 = $2 + $1
    -- -- --
    
    -- -- --
    -- Second test Program (forwarding to MEM)
--    B"000_000_000_000_0_111", -- NOOP
--    B"000_001_100_011_0_000", -- ADD $3 = $1 + $4
--    B"011_000_011_0000000", -- SW $3 $0 1
--    B"011_000_011_0000001", -- SW $3 $0 2
    -- -- --
    
    -- -- --
    -- Third test Program (Load Data Hazard)
--    B"000_000_000_000_0_111", -- NOOP
--    B"010_000_001_0000010", -- LW $1 $0 2
--    B"000_001_010_011_0_000", -- ADD $3 = $1 + $2
--    B"000_011_100_101_0_001", -- SUB $5 = $3 - $4
    -- -- --
    
    -- -- --
    -- Fourth test Program (Control Hazards)
--    B"000_000_000_000_0_111", -- NOOP
--    B"010_000_010_0000000", -- LW $2 $0 0
--    B"000_000_001_000_0_000", -- ADD $0 = $0 + $1
--    B"100_000_010_1111110", -- BNE $0 $1 -1
--    B"011_010_000_0000000", -- SW $2 $0 0
    -- -- --
    
    -- -- --
    -- Fifth test Program (Fibonacci Sequence - Adaptation from the Original Program)
    B"000_000_000_000_0_111", -- NOOP (0)
    B"011_000_001_0000001", -- SW $1 $0 1 -- store 1 in MEM (1)
    B"011_000_000_0000000", -- SW $0 $0 0 -- store 0 in MEM (2)
    B"010_000_001_0000000", -- LW $1 $0 0 -- 1st Fibonacci number (3)
    B"010_000_010_0000001", -- LW $2 $0 1 -- 2nd Fibonacci number (4)
    B"010_000_011_0000000", -- LW $3 $0 0 -- 3rd Fibonacci number (5)
    B"010_000_100_0000001", -- LW $4 $0 1 -- sum (starting from 1) (6)
    B"010_000_101_0000000", -- LW $5 $0 0 -- iterator - jump here after loop (7)
    -- loop start
    B"000_001_010_011_0_000", -- ADD $3 = $1 + $2 (8)
    B"000_000_010_001_0_000", -- ADD $1 = $0 + $2 (9)
    B"000_000_011_010_0_000", -- ADD $2 = $0 + $3 (10)
    B"000_100_011_100_0_000", -- ADD $4 = $4 + $3 (11)
    B"001_101_101_0000001", -- ADDI $5 = $5 + 1 (12)
    B"100_101_110_1111010", -- BNE $5 $6(=6) -6 (13)
    -- end loop
    B"011_000_100_0000010", -- SW $4 $0 2 - store the sum here after loop (14)
    B"111_0000000000111", -- J 7 - repeat the loop    
    -- -- --

    others => x"0000" );

component branch_predict_table is
  Port (
        clk: in STD_LOGIC;
        
        prediction_address: out STD_LOGIC_VECTOR(15 downto 0);
        predictor_bit: out STD_LOGIC;
        predictor_change: in STD_LOGIC;
        
        stall: in STD_LOGIC;
        branch_instruction: in STD_LOGIC;
        flush: in STD_LOGIC;
        
        current_pc_address: in STD_LOGIC_VECTOR (3 downto 0);
        new_pc_address: in STD_LOGIC_VECTOR (3 downto 0);
        new_target_address: in STD_LOGIC_VECTOR(15 downto 0)
   );
end component;

signal PC_INTERNAL : STD_LOGIC_VECTOR(15 downto 0) := (others => '0');
signal PC_Aux, Next_PC_Address, branch_mux: STD_LOGIC_VECTOR(15 downto 0);
signal predictor_bit, jump_signal: STD_LOGIC;
signal branch_taken_signal: STD_LOGIC_VECTOR(1 downto 0);
signal prediction_address, instruction_aux, mux_out_address_signal, jump_address_signal: STD_LOGIC_VECTOR(15 downto 0);

begin

    branch_prediction: branch_predict_table port map(
    
        clk => clk, 
        
        prediction_address => prediction_address, 
        predictor_bit => predictor_bit, 
        predictor_change => branch_taken, 
        
        stall => stall,
        branch_instruction => branch_instruction,
        flush => flush,
        
        current_pc_address => PC_INTERNAL(3 downto 0), 
        new_pc_address => prev_PC,
        new_target_address => BranchAddress
    );

    -- Program Counter
    process(clk, rst)
    begin
        if rst = '1' then
                PC_INTERNAL <= (others => '0');
        elsif rising_edge(clk) then
            if stall = '0' then
                PC_INTERNAL <= Next_PC_Address;
            end if;
        end if;
    end process;

    -- Process for fetching instruction from ROM
    instruction_aux <= ROM(conv_integer(PC_INTERNAL(7 downto 0)));
    instruction <= instruction_aux;

    -- PC incremented
    PC_Aux <= PC_INTERNAL + 1;
    PCinc <= PC_Aux;
    curr_pc <= PC_INTERNAL(3 downto 0);
    
    -- Output the branch prediction signal for external use
    prediction <= predictor_bit;

    -- MUX for choosing between branch prediction and default PC increment
    process(predictor_bit, PC_Aux, prediction_address)
    begin
        case predictor_bit is 
            when '1' => branch_mux <= prediction_address;
            when others => branch_mux <= PC_Aux;
        end case;
    end process;
    
    -- Combine the previous prediction (prev_pred) and the current branch outcome (branch_taken)
    branch_taken_signal <= prev_pred & branch_taken;	

    -- MUX for selecting the next PC address based on the branch prediction result
    process(branch_mux, BranchAddress, branch_taken_signal, prev_PCinc)
    begin
        case branch_taken_signal is
            when "00" => mux_out_address_signal <= branch_mux;
            when "01" => mux_out_address_signal <= BranchAddress;
            when "10" => mux_out_address_signal <= prev_PCinc;
            when "11" => mux_out_address_signal <= branch_mux;
            when others => mux_out_address_signal <= PC_Aux;
        end case;
    end process;
    
    -- Logic for determining jump signal and address
    process(instruction_aux)
    begin
        if instruction_aux(15 downto 13) = "111" then
            jump_signal <= '1';
        else 
            jump_signal <= '0';
        end if;
        
        jump_address_signal <= "000" & instruction_aux(12 downto 0);
    end process;
    
    -- MUX for selecting between branch target and mux-ed out next PC
    process(jump_signal, mux_out_address_signal, jump_address_signal)
    begin
        case jump_signal is
            when '1' => Next_PC_Address <= jump_address_signal;
            when others => Next_PC_Address <= mux_out_address_signal;
        end case;
    end process;

end Behavioral;