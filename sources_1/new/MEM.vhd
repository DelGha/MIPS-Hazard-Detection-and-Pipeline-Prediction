library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity MEM is
    port (  clk : in STD_LOGIC;
            --en : in STD_LOGIC;
            ALUResIn : in STD_LOGIC_VECTOR(15 downto 0);
            RD2 : in STD_LOGIC_VECTOR(15 downto 0);
            MemRead: in STD_LOGIC;
            MemWrite : in STD_LOGIC;			
            MemData : out STD_LOGIC_VECTOR(15 downto 0);
            ALUResOut : out STD_LOGIC_VECTOR(15 downto 0);
            
           -- Forward Unit Signals
            MEM_WB_RegWrite: in std_logic;
            BUF_WB_RegWrite: in std_logic;
            
            MEM_WB_Data: in std_logic_vector(15 downto 0);
            BUF_WB_Data: in std_logic_vector(15 downto 0);
            
            EX_MEM_RegRt: in std_logic_vector(2 downto 0);
            MEM_WB_RegDst: in std_logic_vector(2 downto 0);
            BUF_WB_RegDst: in std_logic_vector(2 downto 0));
end MEM;

architecture Behavioral of MEM is

signal forward_MEM: std_logic_vector(1 downto 0);
signal Data_signal: std_logic_vector(15 downto 0);
-- not used here signals
signal EX_MEM_RegWrite: std_logic;
signal forward_A, forward_B: std_logic_vector(1 downto 0);
signal ID_EX_RegRs, ID_EX_RegRt, EX_MEM_RegDst: std_logic_vector(2 downto 0);

type mem_type is array (0 to 255) of STD_LOGIC_VECTOR(15 downto 0);
signal MEM : mem_type := (
    X"000A",
    X"000B",
    X"000C",
    X"000D",
    X"000E",
    X"000F",
    X"0009",
    X"0008",
    
    others => X"0000");

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
    
        ID_EX_RegRs => "ZZZ", -- not used here
        ID_EX_RegRt => "ZZZ", -- not used here
        
        EX_MEM_RegWrite => 'Z', -- not used here
        EX_MEM_MemWrite => MemWrite, -- we use here
        EX_MEM_RegDst => "ZZZ", -- not used here
        EX_MEM_RegRt => EX_MEM_RegRt, -- we use here
        
        MEM_WB_RegWrite => MEM_WB_RegWrite, -- we use here
        MEM_WB_RegDst =>  MEM_WB_RegDst, -- we use here
        
        BUF_WB_RegWrite => BUF_WB_RegWrite, -- we use here
        BUF_WB_RegDst => BUF_WB_RegDst, -- we use here
        
        --forward_A => "ZZ", -- not used here
        --forward_B => "ZZ", -- not used here
        forward_MEM =>  forward_MEM -- we use here
    );
    
    -- Multiplexer for selecting data source
    MUX: process(forward_MEM, RD2, Mem_WB_Data, BUF_WB_Data)
    begin
        case forward_MEM is 
            when "00" => Data_signal <= RD2; -- No forwarding
            when "01" => Data_signal <= MEM_WB_Data; -- Forward from MEM/WB pipeline
            when "10" => Data_signal <= BUF_WB_Data; -- Forward from BUF/WB pipeline
            when others => Data_signal <= X"0000"; -- No forwarding
        end case;
    end process;
    

    -- Data Memory
    -- Writing
    process(clk) 			
    begin
        if rising_edge(clk) then
            if MemWrite='1' then
                MEM(conv_integer(ALUResIn)) <= Data_signal; -- Write data to memory	
            end if;
        end if;
    end process;
    
    -- Reading
    process(clk, MemRead, ALUResIn)
    begin
        if MemRead = '1' then
            MemData <= MEM(conv_integer(ALUResIn)); -- Read data from memory
        end if;
    end process;

    -- Output signals
    --MemData <= MEM(conv_integer(ALUResIn(4 downto 0)));
    ALUResOut <= ALUResIn;

end Behavioral;