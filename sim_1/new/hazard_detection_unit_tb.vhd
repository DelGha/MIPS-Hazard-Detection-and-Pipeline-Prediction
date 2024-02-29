library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity hazard_detection_unit_tb is
end hazard_detection_unit_tb;

architecture Behavioral of hazard_detection_unit_tb is
    -- Component declaration for the unit under test
    component hazard_detection_unit
        Port (
            ID_EX_RegWrite: in STD_LOGIC;
            ID_EX_MemRead: in STD_LOGIC;
            ID_EX_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
            IF_ID_RegRs: in STD_LOGIC_VECTOR (2 downto 0);
            IF_ID_RegRt: in STD_LOGIC_VECTOR (2 downto 0);
            branch_input: in STD_LOGIC;
            address_in_EX: in STD_LOGIC_VECTOR (2 downto 0);
            address_in_EX_MEM: in STD_LOGIC_VECTOR (2 downto 0);
            EX_MEM_RegWrite: in STD_LOGIC;
            --pc_en: out STD_LOGIC;
            --Selection_Control: out STD_LOGIC;
            --IF_ID_en: out STD_LOGIC
            stall: out STD_LOGIC
        );
    end component;

    -- Signals for connecting testbench to the unit under test
    signal clk : std_logic := '0';  -- Clock signal
    signal ID_EX_RegWrite_tb : STD_LOGIC := '0';
    signal ID_EX_MemRead_tb : STD_LOGIC := '0';
    signal ID_EX_RegDst_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal ID_EX_RegRt_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal IF_ID_RegRs_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal IF_ID_RegRt_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal branch_input_tb : STD_LOGIC := '0';
    signal address_in_EX_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal address_in_EX_MEM_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal EX_MEM_RegWrite_tb: STD_LOGIC := '0';
--    signal pc_en_tb : STD_LOGIC;
--    signal Selection_Control_tb : STD_LOGIC;
--    signal IF_ID_en_tb : STD_LOGIC;
    signal stall_tb: STD_LOGIC := '0';

begin
    -- Instantiate the unit under test
    uut: hazard_detection_unit
        port map (
            ID_EX_RegWrite => ID_EX_RegWrite_tb,
            ID_EX_MemRead => ID_EX_MemRead_tb,
            ID_EX_RegRt => ID_EX_RegRt_tb,
            IF_ID_RegRs => IF_ID_RegRs_tb,
            IF_ID_RegRt => IF_ID_RegRt_tb,
            branch_input => branch_input_tb,
            address_in_EX => address_in_EX_tb,
            address_in_EX_MEM => address_in_EX_MEM_tb,
            EX_MEM_RegWrite => EX_MEM_RegWrite_tb,
--            pc_en => pc_en_tb,
--            Selection_Control => Selection_Control_tb,
--            IF_ID_en => IF_ID_en_tb
            stall => stall_tb
        );

    -- Clock process for simulation
    process
    begin
        while now < 100 ns loop  -- Simulate for 100 ns
            clk <= not clk;  -- Toggle the clock
            wait for 5 ns;   -- Clock period
        end loop;
        wait;  -- End simulation
    end process;

    -- Test scenarios process
    process
    begin
        -- Test case 1: No hazard detected scenario
        ID_EX_RegWrite_tb <= '0';
        ID_EX_MemRead_tb <= '0';
        ID_EX_RegDst_tb <= "000";
        ID_EX_RegRt_tb <= "000";
        IF_ID_RegRs_tb <= "000";
        IF_ID_RegRt_tb <= "001";
        branch_input_tb <= '0';
        address_in_EX_tb <= "000";
        address_in_EX_MEM_tb <= "000";
        wait for 10 ns;

        -- Test case 2: Hazard detected scenario
        ID_EX_RegWrite_tb <= '1';
        ID_EX_MemRead_tb <= '1';
        ID_EX_RegDst_tb <= "011";
        ID_EX_RegRt_tb <= "110";
        IF_ID_RegRs_tb <= "010";
        IF_ID_RegRt_tb <= "110";
        branch_input_tb <= '1';
        address_in_EX_tb <= "111";
        address_in_EX_MEM_tb <= "010";
        wait for 10 ns;


        wait;  -- End simulation
    end process;

end Behavioral;
