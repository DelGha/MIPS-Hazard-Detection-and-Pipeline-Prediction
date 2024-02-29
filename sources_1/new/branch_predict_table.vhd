library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity branch_predict_table is
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
end branch_predict_table;

architecture Behavioral of branch_predict_table is

-- Define the structure for each entry in the branch history table (BHT)
type bht_entry is record
        predictor: std_logic_vector(1 downto 0);
        prediction_address: std_logic_vector(15 downto 0);
    end record;
    
-- Array of branch history table entries    
type bht_array is array (0 to 31) of bht_entry;

-- Signal to hold the branch history table
signal bht: bht_array := ( 
    others => (predictor => "00", prediction_address => (others => '0')) 
    ); 

--signal current_predictor: STD_LOGIC_VECTOR(1 downto 0);
signal current_prediction: STD_LOGIC_VECTOR(15 downto 0);
signal temp: STD_LOGIC_VECTOR(3 downto 0) := "0010";

begin
    
    -- Process to update the branch history table based on branch outcomes
    update_branch_history_table_process: process(bht, clk, stall, current_pc_address, new_pc_address, new_target_address, predictor_change, branch_instruction)
    variable current_predictor: std_logic_vector(1 downto 0);
    begin
        --bht(conv_integer(temp)).prediction_address <= "0000000000000001";
        
        -- Fetch the current predictor value for the given program counter (PC)
        current_predictor := bht(conv_integer(new_pc_address)).predictor;
        
        -- Check for rising clock edge and no stall condition
        if rising_edge(clk) and stall = '0' then
            -- Check if the current instruction is a branch
            if branch_instruction = '1' then 
                -- Check if the branch was taken or not in the previous clock cycle and adjust the predictor accordingly
                if predictor_change = '1' and current_predictor < "11" then -- Branch was taken, we increment the predictor
                    current_predictor := current_predictor + 1;
                elsif predictor_change = '0' and current_predictor > "00" then -- Branch was NOT taken, we decrement the predictor
                    current_predictor := current_predictor - 1;
                end if;
            end if;
            
            -- Update target address in the branch history table if the prediction was incorrect
            if predictor_change = '1' and flush = '1' then 
                bht(conv_integer(new_pc_address)).prediction_address <= new_target_address;
            end if;
            
            -- Update predictor value in the branch history table
            bht(conv_integer(new_pc_address)).predictor <= current_predictor;  
        end if;

    end process;

    -- Output signals
    prediction_address <= bht(conv_integer(current_pc_address)).prediction_address;
    predictor_bit <= bht(conv_integer(current_pc_address)).predictor(1);

end Behavioral;
