library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use std.textio.all; -- Import textio package

entity branch_predict_table_tb is
end branch_predict_table_tb;

architecture Behavioral of branch_predict_table_tb is
    -- Component declaration for the unit under test
    component branch_predict_table
        Port (
            clk: in STD_LOGIC;
            prediction_address: out STD_LOGIC_VECTOR(15 downto 0);
            predictor_bit: out STD_LOGIC;
            predictor_change: in STD_LOGIC;
            pc_enable: in STD_LOGIC;
            branch: in STD_LOGIC;
            flush: in STD_LOGIC;
            current_pc_address: in STD_LOGIC_VECTOR (3 downto 0);
            new_pc_address: in STD_LOGIC_VECTOR (3 downto 0);
            new_target_address: in STD_LOGIC_VECTOR(15 downto 0)
        );
    end component;

    -- Signals for connecting testbench to the unit under test
    signal clk_tb: std_logic := '0';
    signal prediction_address_tb: std_logic_vector(15 downto 0);
    signal predictor_bit_tb: std_logic;
    signal predictor_change_tb: std_logic;
    signal pc_enable_tb: std_logic;
    signal branch_tb: std_logic;
    signal flush_tb: std_logic;
    signal current_pc_address_tb: std_logic_vector(3 downto 0) := "0000";
    signal new_pc_address_tb: std_logic_vector(3 downto 0) := "0000";
    signal new_target_address_tb: std_logic_vector(15 downto 0) := (others => '0');

begin
    -- Instantiate the unit under test
    uut: branch_predict_table
        port map (
            clk => clk_tb,
            prediction_address => prediction_address_tb,
            predictor_bit => predictor_bit_tb,
            predictor_change => predictor_change_tb,
            pc_enable => pc_enable_tb,
            branch => branch_tb,
            flush => flush_tb,
            current_pc_address => current_pc_address_tb,
            new_pc_address => new_pc_address_tb,
            new_target_address => new_target_address_tb
        );

    -- Clock process for simulation
    clk_process: process
    begin
        while now < 100 ns loop  -- Simulate for 100 ns
            clk_tb <= not clk_tb;  -- Toggle the clock
            wait for 5 ns;   -- Clock period
        end loop;
        wait;  -- End simulation
    end process;

    -- Test scenarios process
    process
    begin
        -- Test case 1: Testing normal behavior without changes
        pc_enable_tb <= '1';
        branch_tb <= '0';
        flush_tb <= '0';
        predictor_change_tb <= '0';
        -- Let's assume a current PC address and a new PC address
        current_pc_address_tb <= "0010";
        new_pc_address_tb <= "0011";
        -- Let's assume no change in the target address
        new_target_address_tb <= (others => '0');
 
        wait for 10 ns;
        
        -- Test case 2: Testing branch taken scenario
        pc_enable_tb <= '1';
        branch_tb <= '1';  -- Branch occurred
        flush_tb <= '0';
        predictor_change_tb <= '1';  -- Predictor change happened
        -- Let's assume a current PC address and a new PC address
        current_pc_address_tb <= "0100";
        new_pc_address_tb <= "0101";
        -- Let's assume a different target address for the branch taken scenario
        new_target_address_tb <= "1100110000000000";
        
        wait for 10 ns;
        
        -- Test case 3: Testing branch not taken scenario
        pc_enable_tb <= '1';
        branch_tb <= '0';  -- No branch occurred
        flush_tb <= '0';
        predictor_change_tb <= '1';  -- Predictor change happened
        -- Let's assume a current PC address and a new PC address
        current_pc_address_tb <= "0111";
        new_pc_address_tb <= "1000";
        -- Let's assume no change in the target address
        new_target_address_tb <= (others => '0');

        wait for 10 ns;
        -- Test case : Testing normal behavior without changes - to see the output address
        pc_enable_tb <= '0';
        branch_tb <= '0';
        flush_tb <= '0';
        predictor_change_tb <= '0';
        new_pc_address_tb <= "0000";
        -- Let's assume no change in the target address
        new_target_address_tb <= (others => '0');
        current_pc_address_tb <= "0010";
        wait for 10 ns;
        -- Test case 4: Test to see if we change the addres in bht
        pc_enable_tb <= '1';
        branch_tb <= '0';  -- No branch occurred
        flush_tb <= '1';
        predictor_change_tb <= '1';  -- Predictor change happened
        -- Let's assume a current PC address and a new PC address
        current_pc_address_tb <= "0010";
        new_pc_address_tb <= "0010";
        -- Let's assume no change in the target address
        new_target_address_tb <= "1100110000110000";

        wait for 10 ns;
        

        wait;  -- End simulation
    end process;

end Behavioral;
