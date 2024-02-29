-- MIPS16 Single Cycle

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.std_logic_arith.ALL;
use IEEE.std_logic_unsigned .ALL;

entity main is
    Port ( clk : in STD_LOGIC;
           btn : in STD_LOGIC_VECTOR (4 downto 0);
           sw : in STD_LOGIC_VECTOR (15 downto 0);
           led : out STD_LOGIC_VECTOR (15 downto 0);
           an : out STD_LOGIC_VECTOR (3 downto 0);
           cat : out STD_LOGIC_VECTOR (6 downto 0));
end main;

architecture Behavioral of main is

component MPG is
    Port ( en : out STD_LOGIC;
           input : in STD_LOGIC;
           clock : in STD_LOGIC);
end component;

component SSD is
    Port ( clk: in STD_LOGIC;
           digits: in STD_LOGIC_VECTOR(15 downto 0);
           an: out STD_LOGIC_VECTOR(3 downto 0);
           cat: out STD_LOGIC_VECTOR(6 downto 0));
end component;

component IFetch is
    Port (clk: in STD_LOGIC;
          rst : in STD_LOGIC;
          --en : in STD_LOGIC;
          BranchAddress : in STD_LOGIC_VECTOR(15 downto 0);
          --JumpAddress : in STD_LOGIC_VECTOR(15 downto 0);
          --Jump : in STD_LOGIC;
          --PCSrc : in STD_LOGIC;
          Instruction : out STD_LOGIC_VECTOR(15 downto 0);
          PCinc : out STD_LOGIC_VECTOR(15 downto 0);
          ----------------------------------------------
          stall: in STD_LOGIC;
          ----------------------------------------------
          prev_pred: in STD_LOGIC;
          branch_instruction: in STD_LOGIC;
          branch_taken: in STD_LOGIC;
          prediction: out STD_LOGIC;
          
          prev_PC: in STD_LOGIC_VECTOR(3 downto 0);
          prev_PCinc: in STD_LOGIC_VECTOR(15 downto 0);
          curr_PC: out STD_LOGIC_VECTOR(3 downto 0);
          
          flush: in STD_LOGIC 
          );
end component;

component IDecode is
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
           
           ------------------------------------------------------
           
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
end component;

component MainControl is
    Port ( Instr : in STD_LOGIC_VECTOR(15 downto 0);
           RegDst : out STD_LOGIC;
           ExtOp : out STD_LOGIC;
           ALUSrc : out STD_LOGIC;
           Branch : out STD_LOGIC;
           Jump : out STD_LOGIC;
           ALUOp : out STD_LOGIC_VECTOR(2 downto 0);
           MemRead : out STD_LOGIC;
           MemWrite : out STD_LOGIC;
           MemtoReg : out STD_LOGIC;
           RegWrite : out STD_LOGIC);
end component;

component ExecutionUnit is
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
           -------------------------------------------
           EX_MEM_RegWrite: in std_logic;
           MEM_WB_RegWrite: in std_logic;
           
           ID_EX_RegRs: in std_logic_vector(2 downto 0);
           ID_EX_RegRt: in std_logic_vector(2 downto 0);
        
           EX_MEM_RegDst: in std_logic_vector(2 downto 0);
           MEM_WB_RegDst: in std_logic_vector(2 downto 0);
           
           EX_MEM_ALU_Result: in std_logic_vector(15 downto 0);
           MEM_WB_ALU_Result: in std_logic_vector(15 downto 0));
           
           
end component;

component MEM is
    port (  clk : in STD_LOGIC;
            --en : in STD_LOGIC;
            ALUResIn : in STD_LOGIC_VECTOR(15 downto 0);
            RD2 : in STD_LOGIC_VECTOR(15 downto 0);
            MemRead: in STD_LOGIC;
            MemWrite : in STD_LOGIC;			
            MemData : out STD_LOGIC_VECTOR(15 downto 0);
            ALUResOut : out STD_LOGIC_VECTOR(15 downto 0);
           -----------------------------------------------------
            MEM_WB_RegWrite: in std_logic;
            BUF_WB_RegWrite: in std_logic;
            
            MEM_WB_Data: in std_logic_vector(15 downto 0);
            BUF_WB_Data: in std_logic_vector(15 downto 0);
            
            EX_MEM_RegRt: in std_logic_vector(2 downto 0);
            MEM_WB_RegDst: in std_logic_vector(2 downto 0);
            BUF_WB_RegDst: in std_logic_vector(2 downto 0));
end component;

signal digits: STD_LOGIC_VECTOR(15 downto 0);
signal en, rst: STD_LOGIC; 
-- main controls 
signal RegDst, ExtOp, ALUSrc, Branch, Jump, MemRead, MemWrite, MemtoReg, RegWrite: STD_LOGIC;
signal RegWrite_signal, RegDst_signal, ExtOp_signal, ALUSrc_signal, Branch_signal, Jump_signal, MemRead_signal, MemWrite_signal, en_signal, MemtoReg_signal: STD_LOGIC;
signal ALUOp, ALUOp_signal :  STD_LOGIC_VECTOR(2 downto 0);
-- IF signals 
signal IF_Instr, IF_PCinc: STD_LOGIC_VECTOR(15 downto 0);
signal IF_curr_pc: STD_LOGIC_VECTOR(3 downto 0);
signal IF_prediction: STD_LOGIC;
-- ID signals
signal ID_RD1, ID_RD2, ID_Ext_imm, ID_BranchAddress: STD_LOGIC_VECTOR(15 downto 0);
signal ID_Write_Address_1, ID_Write_Address_2, ID_func: STD_LOGIC_VECTOR(2 downto 0);
signal ID_branch_taken, ID_sa, stall, flush: STD_LOGIC;
-- EX signals
signal EX_ALURes: STD_LOGIC_VECTOR(15 downto 0);
signal EX_address: STD_LOGIC_VECTOR(2 downto 0);
-- MEM signals
signal MEM_AluRes, MEM_data: STD_LOGIC_VECTOR(15 downto 0);
-- WB signals
signal WB_Write_Data: STD_LOGIC_VECTOR(15 downto 0);

--signal RegIF_ID: STD_LOGIC_VECTOR(31 downto 0);
signal REG_IF_ID: STD_LOGIC_VECTOR(36 downto 0);
--signal REGID_EX: STD_LOGIC_VECTOR(92 downto 0);
signal REG_ID_EX: STD_LOGIC_VECTOR(89 downto 0);
--signal REGEX_MEM: STD_LOGIC_VECTOR(55 downto 0);
signal REG_EX_MEM: STD_LOGIC_VECTOR(42 downto 0);
--signal REGMEM_WB: STD_LOGIC_VECTOR(36 downto 0);
signal REG_MEM_WB: STD_LOGIC_VECTOR(36 downto 0);
signal REG_BUF_WB: STD_LOGIC_VECTOR(19 downto 0);

signal ceva_semnal_1: STD_LOGIC := '0';
signal ceva_semnal_16: STD_LOGIC_VECTOR(15 downto 0);


begin
    
    -- buttons: reset, enable
    monopulse1: MPG port map(en, btn(0), clk);
    monopulse2: MPG port map(rst, btn(1), clk);
    
    -- main units
    inst_IF: IFetch port map(
    clk => clk, 
    rst => rst,
    --en => en,
    BranchAddress => ID_BranchAddress,
    --Instruction => ceva_semnal_16,
    Instruction => IF_Instr,
    PCinc => IF_PCinc,
    stall => stall,
    prev_pred => REG_IF_ID(36),
    branch_instruction => branch_signal,
    branch_taken => ID_branch_taken,
    prediction => IF_prediction,
    prev_PC => REG_IF_ID(35 downto 32),
    prev_PCinc => REG_IF_ID(31 downto 16),
    curr_PC => IF_curr_PC,
    flush => flush
    ); 
    
    inst_ID: IDecode port map(
    clk => clk,
    --en => en,
    Instr => REG_IF_ID(15 downto 0),
    WD => WB_Write_Data,
    RegWrite => REG_MEM_WB(0),
    RegDstAddress => REG_MEM_WB(36 downto 34),
    ExtOp => ExtOp_signal,
    RD1 => ID_RD1,
    RD2 => ID_RD2,
    Ext_Imm => ID_Ext_imm,
    func => ID_func,
    sa => ID_sa,
    WriteAddress1 => ID_Write_Address_1,
    WriteAddress2 => ID_Write_Address_2,
    EX_MEM_RegWrite => REG_EX_MEM(3),
    EX_MEM_RegDst => REG_EX_MEM(42 downto 40),
    EX_MEM_ALU_Result => REG_EX_MEM(39 downto 24),
    ID_EX_MemRead => REG_ID_EX(2),
    ID_EX_RegRt => REG_ID_EX(80 downto 78),
    stall => stall,
    ID_EX_RegWrite => REG_ID_EX(3),
    EX_address => EX_address,
    PCinc => REG_IF_ID(31 downto 16),
    branch_instruction => branch,
    branch_taken => ID_branch_taken,
    BranchAddress => ID_BranchAddress
    );
    
    inst_MC: MainControl port map(
    Instr => Reg_IF_ID(15 downto 0),
    RegDst => RegDst,
    ExtOp => ExtOp,
    ALUSrc => AluSrc,
    Branch => Branch,
    Jump => Jump,
    ALUOp => ALUOp,
    MemRead => MemRead,
    MemWrite => MemWrite,
    MemtoReg => MemtoReg,
    RegWrite => RegWrite
    );
    
    stall_control_unit_process: process(stall, RegDst, ExtOp, ALUSrc, Branch, Jump, ALUOp, MemRead, MemWrite, MemtoReg, RegWrite)
    begin
        if stall = '1' then
            RegDst_signal <= '0';
            ExtOp_signal <= '0';
            ALUSrc_signal <= '0';
            Branch_signal <= '0';
            Jump_signal <= '0';
            AluOp_signal <= "111";
            MemRead_signal <= '0';
            MemWrite_signal <= '0';
            MemtoReg_signal <= '0';
            RegWrite_signal <= '0';
        else 
            RegDst_signal <= RegDst;
            ExtOp_signal <= ExtOp;
            ALUSrc_signal <= ALUSrc;
            Branch_signal <= Branch;
            Jump_signal <= Jump;
            AluOp_signal <= AluOp;
            MemRead_signal <= MemRead;
            MemWrite_signal <= MemWrite;
            MemtoReg_signal <= MemtoReg;
            RegWrite_signal <= RegWrite;
        end if;    
    end process;
    
    
    inst_EX: ExecutionUnit port map(
    PCinc => REG_ID_EX(77 downto 62),
    RD1 => REG_ID_EX(26 downto 11),
    RD2 => REG_ID_EX(42 downto 27),
    Ext_Imm => REG_ID_EX(61 downto 46),
    func => REG_ID_EX(45 downto 43),
    sa => REG_ID_EX(10),
    ALUSrc => REG_ID_EX(6),
    ALUOp => REG_ID_EX(9 downto 7),
    --RegDst => RegDst,
    --BranchAddress => BranchAddress,
    ALURes => EX_ALURes,
    --Zero => zero,
    --MuxOut => MuxOut,
    --Instr => IF_Instr,
    EX_MEM_RegWrite => REG_EX_MEM(3),
    MEM_WB_RegWrite => REG_MEM_WB(0),
    ID_EX_RegRs => REG_ID_EX(83 downto 81),
    ID_EX_RegRt => REG_ID_EX(80 downto 78),
    EX_MEM_RegDst => REG_EX_MEM(42 downto 40),
    MEM_WB_RegDst => REG_MEM_WB(36 downto 34),
    EX_MEM_ALU_Result => REG_EX_MEM(39 downto 24),
    MEM_WB_ALU_Result => WB_Write_Data
    ); 
    
    -- ok
    inst_MEM: MEM port map(
     clk => clk,
     --en => en,
     ALUResIn => REG_EX_MEM(39 downto 24),
     RD2 => REG_EX_MEM(23 downto 8),
     MemRead => REG_EX_MEM(2),
     MemWrite => REG_EX_MEM(1),		
     MemData => MEM_data,
     ALUResOut => MEM_AluRes,
     MEM_WB_RegWrite => REG_MEM_WB(0),
     BUF_WB_RegWrite => REG_BUF_WB(0),
     MEM_WB_Data => WB_Write_Data,
     BUF_WB_Data => REG_BUF_WB(19 downto 4),
     EX_MEM_RegRt => REG_EX_MEM(7 downto 5),
     MEM_WB_RegDst => REG_MEM_WB(36 downto 34),
     BUF_WB_RegDst => REG_BUF_WB(3 downto 1)
     );
    
    -- WriteBack unit
--    WB_unit: WB_write_DATA <= REG_MEM_WB (17 downto 2) when REG_MEM_WB(1) = '1'
--        else REG_MEM_WB(33 downto 18);
    
    
    -- Select the proper data for Write Back based on the control signal
    with REG_MEM_WB(1) select
        WB_Write_Data <= REG_MEM_WB (17 downto 2) when '1',
              REG_MEM_WB (33 downto 18) when '0',
              (others => 'X') when others;
    
    -- Determine if a flush is needed based on branch prediction and branch taken signal
    flush <= ID_branch_taken xor REG_IF_ID(36);   
    
    -- Select the execution address based on the branch prediction result
    process(REG_ID_EX)
    begin
        if REG_ID_EX(5) = '0' then
            EX_address <= REG_ID_EX(89 downto 87);
        else 
            EX_address <= REG_ID_EX(86 downto 84);
        end if;
    end process;
    
    process(clk, stall, rst)
    begin
        if rst = '1' then 
            REG_IF_ID(36 downto 0) <= (others => '0');
        end if;
        if rising_edge(clk) and stall = '0' then
            if flush = '0' then
                REG_IF_ID(36) <= IF_prediction;
                REG_IF_ID(35 downto 32) <= IF_curr_pc;
                REG_IF_ID(31 downto 16) <= IF_PCinc;
                REG_IF_ID(15 downto 0) <= IF_Instr;
            else 
                REG_IF_ID(36 downto 0) <= (others => '0');    
            end if;
        end if;
    end process;
    
    process(clk, rst)
    begin
        if rst = '1' then 
            REG_ID_EX(89 downto 0) <= (others => '0');
        end if;
        if rising_edge(clk) then
            REG_ID_EX(89 downto 87) <= ID_Write_Address_1;
            REG_ID_EX(86 downto 84) <= ID_Write_Address_2;
            REG_ID_EX(83 downto 81) <= REG_IF_ID(12 downto 10); -- RS
            REG_ID_EX(80 downto 78) <= REG_IF_ID(9 downto 7); -- RT
            REG_ID_EX(77 downto 62) <= REG_IF_ID(31 downto 16);
            REG_ID_EX(61 downto 46) <= ID_Ext_imm;
            REG_ID_EX(45 downto 43) <= ID_func;
            Reg_ID_EX(42 downto 27) <= ID_RD2;
            Reg_ID_EX(26 downto 11) <= ID_RD1;
            REG_ID_EX(10) <= ID_sa;
            REG_ID_EX(9 downto 7) <= AluOp_signal;
            REG_ID_EX(6) <= AluSrc_signal;
            REG_ID_EX(5) <= RegDst_signal;
            REG_ID_EX(4) <= MemToReg_signal;
            REG_ID_EX(3) <= RegWrite_signal;
            REG_ID_EX(2) <= MemRead_signal;
            REG_ID_EX(1) <= MemWrite_signal;
            REG_ID_EX(0) <= Branch_signal;
        end if;
    end process;
    
    process(clk, rst)
    begin
        if rst = '1' then 
            REG_EX_MEM(42 downto 0) <= (others => '0');
        end if;
        if rising_edge(clk) then
            REG_EX_MEM(42 downto 40) <= EX_address;
            REG_EX_MEM(39 downto 24) <= EX_AluRes;
            REG_EX_MEM(23 downto 8) <= REG_ID_EX(42 downto 27);
            REG_EX_MEM(7 downto 5) <= REG_ID_EX(80 downto 78);
            REG_EX_MEM(4 downto 3) <= REG_ID_EX(4 downto 3);
            REG_EX_MEM(2 downto 0) <= REG_ID_EX(2 downto 0);
        end if;
    end process;
    
    process(clk, rst)
    begin
        if rst = '1' then 
            REG_MEM_WB(36 downto 0) <= (others => '0');
        end if;
        if rising_edge(clk) then
            REG_MEM_WB(36 downto 34) <= Reg_EX_MEM(42 downto 40);
            REG_MEM_WB (33 downto 18) <= MEM_AluRes;
            REG_MEM_WB (17 downto 2) <= MEM_data;
            REG_MEM_WB(1 downto 0) <= Reg_EX_MEM(4 downto 3);
        end if;
    end process;
    
    process(clk, rst)
    begin
        if rst = '1' then
            REG_BUF_WB(19 downto 0) <= (others => '0');
        end if;
        if rising_edge(clk) then
            REG_BUF_WB(19 downto 4) <= WB_Write_Data;
            REG_BUF_WB(3 downto 1) <= REG_MEM_WB(36 downto 34);
            REG_BUF_WB(0) <= REG_MEM_WB(0);
        end if;
    end process;
    
   -- SSD display MUX
    with sw(7 downto 5) select
        digits <=  IF_Instr when "000", 
                   IF_PCinc when "001",
                   ID_RD1 when "010",
                   ID_RD2 when "011",
                   ID_Ext_Imm when "100",
                   REG_MEM_WB (33 downto 18) when "101",
                   MEM_DATA when "110",
                   WB_Write_Data when "111",
                   (others => 'X') when others; 

    display : SSD port map (clk, digits, an, cat);
    
    -- main controls on the leds
    led(12 downto 0) <= stall & flush & ALUOp_signal & RegDst_signal & ExtOp_signal & ALUSrc_signal & Branch_signal & Jump_signal & MemWrite_signal & MemtoReg_signal & RegWrite_signal;
    
end Behavioral;