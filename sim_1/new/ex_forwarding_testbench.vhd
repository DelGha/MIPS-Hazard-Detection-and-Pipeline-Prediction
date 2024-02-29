library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity ex_forward_unit_tb is
end ex_forward_unit_tb;

architecture Behavioral of ex_forward_unit_tb is
    -- Component declaration for the unit under test
    component ex_forward_unit
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
            forward_A: out STD_LOGIC_VECTOR(1 downto 0);
            forward_B: out STD_LOGIC_VECTOR(1 downto 0);
            forward_MEM: out STD_LOGIC_VECTOR (1 downto 0)
        );
    end component;

    -- Signals for connecting testbench to the unit under test
    signal clk : std_logic := '0';  -- Clock signal
    signal ID_EX_RegRs_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal ID_EX_RegRt_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal EX_MEM_RegWrite_tb : STD_LOGIC := '0';
    signal EX_MEM_MemWrite_tb : STD_LOGIC := '0';
    signal EX_MEM_RegDst_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal EX_MEM_RegRt_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal MEM_WB_RegWrite_tb : STD_LOGIC := '0';
    signal MEM_WB_RegDst_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal BUF_WB_RegWrite_tb : STD_LOGIC := '0';
    signal BUF_WB_RegDst_tb : STD_LOGIC_VECTOR (2 downto 0) := "000";
    signal forward_A_tb : STD_LOGIC_VECTOR(1 downto 0);
    signal forward_B_tb : STD_LOGIC_VECTOR(1 downto 0);
    signal forward_MEM_tb : STD_LOGIC_VECTOR (1 downto 0);

begin
    -- Instantiate the unit under test
    uut: ex_forward_unit
        port map (
            ID_EX_RegRs => ID_EX_RegRs_tb,
            ID_EX_RegRt => ID_EX_RegRt_tb,
            EX_MEM_RegWrite => EX_MEM_RegWrite_tb,
            EX_MEM_MemWrite => EX_MEM_MemWrite_tb,
            EX_MEM_RegDst => EX_MEM_RegDst_tb,
            EX_MEM_RegRt => EX_MEM_RegRt_tb,
            MEM_WB_RegWrite => MEM_WB_RegWrite_tb,
            MEM_WB_RegDst => MEM_WB_RegDst_tb,
            BUF_WB_RegWrite => BUF_WB_RegWrite_tb,
            BUF_WB_RegDst => BUF_WB_RegDst_tb,
            forward_A => forward_A_tb,
            forward_B => forward_B_tb,
            forward_MEM => forward_MEM_tb
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
        -- Test case 1: Forwarding scenario 1 
        -- We want to forward A from the EX/MEM and NOT forward B
        ID_EX_RegRs_tb <= "001";
        ID_EX_RegRt_tb <= "010";
        EX_MEM_RegWrite_tb <= '1';
        EX_MEM_RegDst_tb <= "001";
        EX_MEM_RegRt_tb <= "010";
        MEM_WB_RegWrite_tb <= '0';
        MEM_WB_RegDst_tb <= "000";
        BUF_WB_RegWrite_tb <= '0';
        BUF_WB_RegDst_tb <= "000";
        wait for 10 ns;
        
        -- Test case 2: Forwarding scenario 2 
        -- We want to forward A from the EX/MEM and B from MEM/WB
        
        ID_EX_RegRs_tb <= "001";
        ID_EX_RegRt_tb <= "100";
        EX_MEM_RegWrite_tb <= '1';
        EX_MEM_RegDst_tb <= "001";
        EX_MEM_RegRt_tb <= "010";
        MEM_WB_RegWrite_tb <= '1';
        MEM_WB_RegDst_tb <= "100";
        BUF_WB_RegWrite_tb <= '0';
        BUF_WB_RegDst_tb <= "000";
        wait for 10 ns;

        -- Test case 3: Forwarding scenario 3
        -- We want to NOT forward A and forward B from EX/MEM 
        ID_EX_RegRs_tb <= "011";
        ID_EX_RegRt_tb <= "110";
        EX_MEM_RegWrite_tb <= '0';
        EX_MEM_RegDst_tb <= "000";
        EX_MEM_RegRt_tb <= "000";
        MEM_WB_RegWrite_tb <= '1';
        MEM_WB_RegDst_tb <= "110";
        BUF_WB_RegWrite_tb <= '0';
        BUF_WB_RegDst_tb <= "000";
        wait for 10 ns;

        -- Test case 4: No forwarding scenario
        -- We provide random values to the control signals random addresses for the registers 
        --(that do not match)
        ID_EX_RegRs_tb <= "101";
        ID_EX_RegRt_tb <= "001";
        EX_MEM_RegWrite_tb <= '0';
        EX_MEM_RegDst_tb <= "010";
        EX_MEM_RegRt_tb <= "000";
        MEM_WB_RegWrite_tb <= '1';
        MEM_WB_RegDst_tb <= "100";
        BUF_WB_RegWrite_tb <= '0';
        BUF_WB_RegDst_tb <= "000";
        wait for 10 ns;

        -- Test case 5: Forwarding scenario 1 + Forwarding to Memory Stage
        -- We want to forward A from the EX/MEM and NOT forward B
        -- We want to forward from MEM/WB for Memory Stage
        ID_EX_RegRs_tb <= "001";
        ID_EX_RegRt_tb <= "011";
        EX_MEM_RegWrite_tb <= '1';
        EX_MEM_RegDst_tb <= "001";
        EX_MEM_RegRt_tb <= "010";
        EX_MEM_MemWrite_tb <= '1';
        MEM_WB_RegWrite_tb <= '1';
        MEM_WB_RegDst_tb <= "010";
        BUF_WB_RegWrite_tb <= '0';
        BUF_WB_RegDst_tb <= "000";
        wait for 10 ns;

        wait;  -- End simulation
    end process;

end Behavioral;
