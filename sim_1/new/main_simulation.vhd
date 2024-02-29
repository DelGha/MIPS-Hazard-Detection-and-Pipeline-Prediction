library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity main_tb is
end main_tb;

architecture Behavioral of main_tb is

    component main is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
    end component;

    signal clk : STD_LOGIC := '0';  -- Clock signal
    signal btn : STD_LOGIC_VECTOR (4 downto 0) := "00000";
    signal sw : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
    signal led : STD_LOGIC_VECTOR (15 downto 0) := "0000000000000000";
    signal an : STD_LOGIC_VECTOR (3 downto 0) := "0000";
    signal cat : STD_LOGIC_VECTOR (6 downto 0) := "0000000";
    
    -- Declare signals matching your main architecture here
    
    constant CLK_PERIOD : time := 20 ns;  -- Define your clock period

begin

    sw(7 downto 5) <= "101";
    -- Instantiate the main architecture
    UUT: main port map (
            clk => clk,
            btn => btn,
            sw => sw,
            led => led,
            an => an,
            cat => cat
        );

    -- Clock generation process
    clk_process: process
    begin
        while now < 15000 ns loop  -- Simulate for 5000 ns
            clk <= '0';
            wait for CLK_PERIOD / 2;
            clk <= '1';
            wait for CLK_PERIOD / 2;
        end loop;
        wait;
    end process;
    
    reset_process: process
    begin
        btn(1) <= '1';
        wait for 5ns;
        btn(1) <= '0';
        wait;
    end process;
    
--    process
--    begin
--        btn(1) <= '1';
--        wait for CLK_PERIOD;
--        btn(1) <= '0';
--        wait for CLK_PERIOD;
--        wait;
--    end process;

    -- Initialize signals, apply stimuli, and monitor outputs here

end Behavioral;